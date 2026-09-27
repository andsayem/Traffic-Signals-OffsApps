import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/admob_config.dart';
import '../config/admob_settings.dart';
import '../core/admob_logger.dart';
import '../core/admob_utils.dart';
import '../models/ad_result.dart';

/// Loads, caches, and displays interstitial ads with automatic retry,
/// cooldown, and reload-after-show behavior baked in.
///
/// ```dart
/// await InterstitialAdManager.load();
/// final result = await InterstitialAdManager.show();
/// ```
///
/// Most apps should go through `AdManager.showInterstitial()` /
/// `AdManager.registerAction()` instead of calling this directly.
class InterstitialAdManager {
  InterstitialAdManager._();

  static InterstitialAd? _ad;
  static bool _isLoading = false;
  static int _retryCount = 0;
  static DateTime? _lastShownAt;

  /// Whether a fully loaded ad is cached and ready to show right now.
  static bool get isReady => _ad != null;

  static bool get _isInCooldown {
    final lastShown = _lastShownAt;
    if (lastShown == null) return false;
    final elapsed = DateTime.now().difference(lastShown).inSeconds;
    return elapsed < AdMobSettings.interstitialCooldownSeconds;
  }

  /// Loads an interstitial ad if one isn't already cached or in flight.
  /// Safe to call repeatedly (e.g. on every screen) - it is a no-op while
  /// a load is already pending or a fresh ad is already cached.
  static Future<void> load() async {
    if (!AdMobSettings.enableInterstitial) return;
    if (!AdMobUtils.isSupportedPlatform) return;
    if (_isLoading || _ad != null) return;

    final adUnitId = AdMobConfig.interstitialId;
    if (adUnitId.isEmpty) {
      AdMobLogger.log('Interstitial ad unit ID is empty, skipping load');
      return;
    }

    _isLoading = true;
    AdMobLogger.log('Interstitial loading');

    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _retryCount = 0;
          _ad = ad;
          _attachCallbacks(ad);
          AdMobLogger.log('Interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _ad = null;
          AdMobLogger.error('Interstitial failed to load', error);
          _retryLoad();
        },
      ),
    );
  }

  static void _retryLoad() {
    if (_retryCount >= AdMobSettings.maxLoadRetry) {
      AdMobLogger.log('Interstitial retry limit reached, giving up');
      return;
    }
    _retryCount++;
    final delay = Duration(
      seconds: AdMobSettings.retryBaseDelaySeconds * _retryCount,
    );
    AdMobLogger.log('Interstitial retry #$_retryCount in ${delay.inSeconds}s');
    Future.delayed(delay, load);
  }

  static void _attachCallbacks(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        FullScreenAdGuard.markShowing();
        AdMobLogger.log('Interstitial shown');
      },
      onAdDismissedFullScreenContent: (ad) {
        AdMobLogger.log('Interstitial dismissed');
        _handleClosed(ad);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        AdMobLogger.error('Interstitial failed to show', error);
        _handleClosed(ad);
      },
      onAdClicked: (ad) => AdMobLogger.log('Interstitial clicked'),
      onAdImpression: (ad) => AdMobLogger.log('Interstitial impression'),
    );
  }

  static void _handleClosed(InterstitialAd ad) {
    FullScreenAdGuard.markDismissed();
    _lastShownAt = DateTime.now();
    ad.dispose();
    _ad = null;
    load();
  }

  /// Shows the cached interstitial if every guard (enabled, cooldown, no
  /// other full-screen ad showing, ad actually loaded) passes. Always
  /// resolves, never throws.
  static Future<AdShowResult> show() async {
    try {
      if (!AdMobSettings.enableInterstitial) return AdShowResult.disabled;
      if (!AdMobUtils.isSupportedPlatform) {
        return AdShowResult.unsupportedPlatform;
      }
      if (FullScreenAdGuard.isShowing) return AdShowResult.alreadyShowing;
      if (_isInCooldown) return AdShowResult.cooldown;

      final ad = _ad;
      if (ad == null) {
        unawaited(load());
        return AdShowResult.notReady;
      }

      await ad.show();
      return AdShowResult.shown;
    } catch (e, st) {
      AdMobLogger.error('Interstitial show failed', e, st);
      return AdShowResult.error;
    }
  }

  /// Releases the cached ad without showing it, e.g. on app teardown or
  /// in tests. A subsequent [load] call will fetch a fresh ad.
  static void dispose() {
    _ad?.dispose();
    _ad = null;
    _isLoading = false;
  }
}
