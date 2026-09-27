import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/admob_config.dart';
import '../config/admob_settings.dart';
import '../core/admob_logger.dart';
import '../core/admob_utils.dart';
import '../models/ad_result.dart';

/// Loads, caches, and displays rewarded ads with automatic retry and
/// reload-after-show behavior baked in.
///
/// ```dart
/// await RewardedAdManager.load();
/// final result = await RewardedAdManager.show(onReward: () => unlock());
/// ```
///
/// Most apps should go through `AdManager.showRewarded()` instead of
/// calling this directly.
class RewardedAdManager {
  RewardedAdManager._();

  static RewardedAd? _ad;
  static bool _isLoading = false;
  static int _retryCount = 0;

  /// Whether a fully loaded ad is cached and ready to show right now.
  static bool get isReady => _ad != null;

  /// Loads a rewarded ad if one isn't already cached or in flight.
  static Future<void> load() async {
    if (!AdMobSettings.enableRewarded) return;
    if (!AdMobUtils.isSupportedPlatform) return;
    if (_isLoading || _ad != null) return;

    final adUnitId = AdMobConfig.rewardedId;
    if (adUnitId.isEmpty) {
      AdMobLogger.log('Rewarded ad unit ID is empty, skipping load');
      return;
    }

    _isLoading = true;
    AdMobLogger.log('Rewarded loading');

    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _retryCount = 0;
          _ad = ad;
          AdMobLogger.log('Rewarded loaded');
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _ad = null;
          AdMobLogger.error('Rewarded failed to load', error);
          _retryLoad();
        },
      ),
    );
  }

  static void _retryLoad() {
    if (_retryCount >= AdMobSettings.maxLoadRetry) {
      AdMobLogger.log('Rewarded retry limit reached, giving up');
      return;
    }
    _retryCount++;
    final delay = Duration(
      seconds: AdMobSettings.retryBaseDelaySeconds * _retryCount,
    );
    AdMobLogger.log('Rewarded retry #$_retryCount in ${delay.inSeconds}s');
    Future.delayed(delay, load);
  }

  /// Shows the cached rewarded ad. [onReward] is only invoked when the
  /// Google Mobile Ads SDK itself reports a valid, earned reward - never
  /// speculatively. Always resolves, never throws.
  static Future<AdShowResult> show({required VoidCallback onReward}) async {
    try {
      if (!AdMobSettings.enableRewarded) return AdShowResult.disabled;
      if (!AdMobUtils.isSupportedPlatform) {
        return AdShowResult.unsupportedPlatform;
      }
      if (FullScreenAdGuard.isShowing) return AdShowResult.alreadyShowing;

      final ad = _ad;
      if (ad == null) {
        unawaited(load());
        return AdShowResult.notReady;
      }

      // Consume the cached ad immediately so a second, overlapping call to
      // show() can't reuse (and double-show) the same instance.
      _ad = null;

      final completer = Completer<AdShowResult>();

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          FullScreenAdGuard.markShowing();
          AdMobLogger.log('Rewarded shown');
        },
        onAdDismissedFullScreenContent: (ad) {
          AdMobLogger.log('Rewarded dismissed');
          FullScreenAdGuard.markDismissed();
          ad.dispose();
          load();
          if (!completer.isCompleted) completer.complete(AdShowResult.shown);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          AdMobLogger.error('Rewarded failed to show', error);
          FullScreenAdGuard.markDismissed();
          ad.dispose();
          load();
          if (!completer.isCompleted) completer.complete(AdShowResult.error);
        },
      );

      await ad.show(
        onUserEarnedReward: (ad, reward) {
          AdMobLogger.log('Reward earned: ${reward.amount} ${reward.type}');
          onReward();
        },
      );

      return await completer.future;
    } catch (e, st) {
      AdMobLogger.error('Rewarded show failed', e, st);
      return AdShowResult.error;
    }
  }

  /// Releases the cached ad without showing it.
  static void dispose() {
    _ad?.dispose();
    _ad = null;
    _isLoading = false;
  }
}
