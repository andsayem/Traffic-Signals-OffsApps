import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/admob_config.dart';
import '../config/admob_settings.dart';
import '../core/admob_logger.dart';
import '../core/admob_utils.dart';
import '../models/ad_result.dart';

/// Loads, caches, and displays rewarded interstitial ads. Same
/// load/cache/retry/reward behavior as [RewardedAdManager], for the
/// rewarded-interstitial ad format.
///
/// ```dart
/// await RewardedInterstitialAdManager.load();
/// final result =
///     await RewardedInterstitialAdManager.show(onReward: () => unlock());
/// ```
///
/// Most apps should go through `AdManager.showRewardedInterstitial()`
/// instead of calling this directly.
class RewardedInterstitialAdManager {
  RewardedInterstitialAdManager._();

  static RewardedInterstitialAd? _ad;
  static bool _isLoading = false;
  static int _retryCount = 0;

  /// Whether a fully loaded ad is cached and ready to show right now.
  static bool get isReady => _ad != null;

  /// Loads a rewarded interstitial ad if one isn't already cached or in
  /// flight.
  static Future<void> load() async {
    if (!AdMobSettings.enableRewardedInterstitial) return;
    if (!AdMobUtils.isSupportedPlatform) return;
    if (_isLoading || _ad != null) return;

    final adUnitId = AdMobConfig.rewardedInterstitialId;
    if (adUnitId.isEmpty) {
      AdMobLogger.log(
        'Rewarded interstitial ad unit ID is empty, skipping load',
      );
      return;
    }

    _isLoading = true;
    AdMobLogger.log('Rewarded interstitial loading');

    await RewardedInterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _retryCount = 0;
          _ad = ad;
          AdMobLogger.log('Rewarded interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _ad = null;
          AdMobLogger.error('Rewarded interstitial failed to load', error);
          _retryLoad();
        },
      ),
    );
  }

  static void _retryLoad() {
    if (_retryCount >= AdMobSettings.maxLoadRetry) {
      AdMobLogger.log('Rewarded interstitial retry limit reached, giving up');
      return;
    }
    _retryCount++;
    final delay = Duration(
      seconds: AdMobSettings.retryBaseDelaySeconds * _retryCount,
    );
    AdMobLogger.log(
      'Rewarded interstitial retry #$_retryCount in ${delay.inSeconds}s',
    );
    Future.delayed(delay, load);
  }

  /// Shows the cached rewarded interstitial ad. [onReward] is only
  /// invoked when the SDK reports a valid, earned reward. Always
  /// resolves, never throws.
  static Future<AdShowResult> show({required VoidCallback onReward}) async {
    try {
      if (!AdMobSettings.enableRewardedInterstitial) {
        return AdShowResult.disabled;
      }
      if (!AdMobUtils.isSupportedPlatform) {
        return AdShowResult.unsupportedPlatform;
      }
      if (FullScreenAdGuard.isShowing) return AdShowResult.alreadyShowing;

      final ad = _ad;
      if (ad == null) {
        unawaited(load());
        return AdShowResult.notReady;
      }

      _ad = null;

      final completer = Completer<AdShowResult>();

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          FullScreenAdGuard.markShowing();
          AdMobLogger.log('Rewarded interstitial shown');
        },
        onAdDismissedFullScreenContent: (ad) {
          AdMobLogger.log('Rewarded interstitial dismissed');
          FullScreenAdGuard.markDismissed();
          ad.dispose();
          load();
          if (!completer.isCompleted) completer.complete(AdShowResult.shown);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          AdMobLogger.error('Rewarded interstitial failed to show', error);
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
      AdMobLogger.error('Rewarded interstitial show failed', e, st);
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
