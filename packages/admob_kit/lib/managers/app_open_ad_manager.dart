import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/admob_config.dart';
import '../config/admob_settings.dart';
import '../core/admob_logger.dart';
import '../core/admob_utils.dart';
import '../models/ad_result.dart';

/// Loads, caches, and automatically displays App Open ads whenever the
/// app returns to the foreground.
///
/// Call once, near the top of `main()`, after `AdMobService.initialize()`:
///
/// ```dart
/// AppOpenAdManager.initialize();
/// ```
///
/// The host app never has to touch `WidgetsBindingObserver` itself - this
/// manager registers its own observer and handles the resume/pause
/// lifecycle internally.
class AppOpenAdManager with WidgetsBindingObserver {
  AppOpenAdManager._();

  static final AppOpenAdManager instance = AppOpenAdManager._();

  AppOpenAd? _ad;
  bool _isLoading = false;
  bool _isShowingAd = false;
  int _retryCount = 0;
  DateTime? _adLoadedAt;
  DateTime? _lastShownAt;
  bool _observerAttached = false;
  bool _hasSeenFirstResume = false;
  DateTime? _backgroundedAt;

  /// Whether a fully loaded, non-expired ad is cached and ready to show.
  bool get isReady => _ad != null && !_isAdExpired;

  bool get _isAdExpired {
    final loadedAt = _adLoadedAt;
    if (loadedAt == null) return true;
    final maxAge = Duration(hours: AdMobSettings.appOpenMaxCacheHours);
    return DateTime.now().difference(loadedAt) > maxAge;
  }

  bool get _isInCooldown {
    final lastShown = _lastShownAt;
    if (lastShown == null) return false;
    final elapsed = DateTime.now().difference(lastShown).inSeconds;
    return elapsed < AdMobSettings.appOpenCooldownSeconds;
  }

  /// Attaches the app lifecycle observer and preloads the first ad. Safe
  /// to call more than once; only initializes on the first call.
  static void initialize() => instance._initialize();

  void _initialize() {
    if (!AdMobSettings.enableAppOpen) return;
    if (!AdMobUtils.isSupportedPlatform) return;
    if (!_observerAttached) {
      WidgetsBinding.instance.addObserver(this);
      _observerAttached = true;
    }
    load();
  }

  /// Loads an App Open ad if one isn't already cached, fresh, or in
  /// flight.
  Future<void> load() async {
    if (!AdMobSettings.enableAppOpen) return;
    if (!AdMobUtils.isSupportedPlatform) return;
    if (_isLoading || isReady) return;

    final adUnitId = AdMobConfig.appOpenId;
    if (adUnitId.isEmpty) {
      AdMobLogger.log('App Open ad unit ID is empty, skipping load');
      return;
    }

    _isLoading = true;
    AdMobLogger.log('App Open loading');

    await AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _retryCount = 0;
          _ad = ad;
          _adLoadedAt = DateTime.now();
          _attachCallbacks(ad);
          AdMobLogger.log('App Open loaded');
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _ad = null;
          AdMobLogger.error('App Open failed to load', error);
          _retryLoad();
        },
      ),
    );
  }

  void _retryLoad() {
    if (_retryCount >= AdMobSettings.maxLoadRetry) {
      AdMobLogger.log('App Open retry limit reached, giving up');
      return;
    }
    _retryCount++;
    final delay = Duration(
      seconds: AdMobSettings.retryBaseDelaySeconds * _retryCount,
    );
    AdMobLogger.log('App Open retry #$_retryCount in ${delay.inSeconds}s');
    Future.delayed(delay, load);
  }

  void _attachCallbacks(AppOpenAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        FullScreenAdGuard.markShowing();
        AdMobLogger.log('App Open shown');
      },
      onAdDismissedFullScreenContent: (ad) {
        AdMobLogger.log('App Open dismissed');
        _handleClosed(ad);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        AdMobLogger.error('App Open failed to show', error);
        _handleClosed(ad);
      },
    );
  }

  void _handleClosed(AppOpenAd ad) {
    _isShowingAd = false;
    FullScreenAdGuard.markDismissed();
    _lastShownAt = DateTime.now();
    ad.dispose();
    _ad = null;
    _adLoadedAt = null;
    load();
  }

  /// Shows the cached App Open ad if every guard passes. Can also be
  /// called manually, e.g. right after a splash screen finishes. Always
  /// resolves, never throws.
  Future<AdShowResult> showAdIfAvailable() async {
    try {
      if (!AdMobSettings.enableAppOpen) return AdShowResult.disabled;
      if (!AdMobUtils.isSupportedPlatform) {
        return AdShowResult.unsupportedPlatform;
      }
      if (_isShowingAd || FullScreenAdGuard.isShowing) {
        return AdShowResult.alreadyShowing;
      }
      if (_isInCooldown) return AdShowResult.cooldown;

      if (_isAdExpired && _ad != null) {
        _ad?.dispose();
        _ad = null;
        _adLoadedAt = null;
      }

      final ad = _ad;
      if (ad == null) {
        unawaited(load());
        return AdShowResult.notReady;
      }

      await ad.show();
      return AdShowResult.shown;
    } catch (e, st) {
      AdMobLogger.error('App Open show failed', e, st);
      return AdShowResult.error;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
      return;
    }
    if (state != AppLifecycleState.resumed) return;

    if (!_hasSeenFirstResume) {
      // The very first "resumed" event corresponds to cold start, which
      // the host app's own splash/init flow is already handling - skip it
      // so this doesn't race with that.
      _hasSeenFirstResume = true;
      return;
    }

    final backgroundedAt = _backgroundedAt;
    if (backgroundedAt != null) {
      final backgroundedFor = DateTime.now().difference(backgroundedAt);
      if (backgroundedFor.inSeconds < AdMobSettings.appOpenMinBackgroundSeconds) {
        // Too brief to be a real "return to the app" moment (e.g. a
        // permission dialog, a quick notification peek, an app switch
        // that bounced right back) - showing here would waste an
        // impression on a near-zero-viewability session and train the
        // auction on low-quality signal, hurting eCPM over time.
        AdMobLogger.log(
          'App Open skipped - only backgrounded for '
          '${backgroundedFor.inSeconds}s',
        );
        return;
      }
    }

    showAdIfAvailable();
  }

  /// Detaches the lifecycle observer and releases the cached ad, e.g. in
  /// tests.
  void dispose() {
    if (_observerAttached) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAttached = false;
    }
    _ad?.dispose();
    _ad = null;
  }
}
