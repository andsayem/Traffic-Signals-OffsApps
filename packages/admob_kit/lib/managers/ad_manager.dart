import 'package:flutter/foundation.dart';

import '../config/admob_settings.dart';
import '../core/admob_logger.dart';
import '../core/admob_utils.dart';
import '../models/ad_result.dart';
import 'app_open_ad_manager.dart';
import 'interstitial_ad_manager.dart';
import 'rewarded_ad_manager.dart';
import 'rewarded_interstitial_ad_manager.dart';

/// The single entry point host apps should use day-to-day. It coordinates
/// every ad manager so the app never needs to know about caching, retry,
/// cooldown, or frequency-control internals.
///
/// ```dart
/// AdManager.showInterstitial();
///
/// AdManager.showRewarded(onReward: () => unlockFeature());
///
/// AdManager.registerAction(); // auto-shows an interstitial every Nth call
/// ```
class AdManager {
  AdManager._();

  static int _actionCount = 0;

  // ---------------------------------------------------------------------
  // Availability
  // ---------------------------------------------------------------------

  static bool get isInterstitialReady => InterstitialAdManager.isReady;
  static bool get isRewardedReady => RewardedAdManager.isReady;
  static bool get isRewardedInterstitialReady =>
      RewardedInterstitialAdManager.isReady;
  static bool get isAppOpenReady => AppOpenAdManager.instance.isReady;

  /// Whether any full-screen ad is currently on screen.
  static bool get isFullScreenAdShowing => FullScreenAdGuard.isShowing;

  // ---------------------------------------------------------------------
  // Preloading
  // ---------------------------------------------------------------------

  /// Preloads every enabled full-screen ad type except App Open, which is
  /// preloaded by `AppOpenAdManager.initialize()`. Call once after
  /// `AdMobService.initialize()`.
  static Future<void> preloadAll() async {
    await Future.wait([
      InterstitialAdManager.load(),
      RewardedAdManager.load(),
      RewardedInterstitialAdManager.load(),
    ]);
  }

  // ---------------------------------------------------------------------
  // Showing ads
  // ---------------------------------------------------------------------

  static Future<AdShowResult> showInterstitial() {
    return InterstitialAdManager.show();
  }

  static Future<AdShowResult> showRewarded({required VoidCallback onReward}) {
    return RewardedAdManager.show(onReward: onReward);
  }

  static Future<AdShowResult> showRewardedInterstitial({
    required VoidCallback onReward,
  }) {
    return RewardedInterstitialAdManager.show(onReward: onReward);
  }

  static Future<AdShowResult> showAppOpen() {
    return AppOpenAdManager.instance.showAdIfAvailable();
  }

  // ---------------------------------------------------------------------
  // Interstitial frequency control
  // ---------------------------------------------------------------------

  /// Call once per user action that could reasonably be followed by an
  /// interstitial (finishing a level, closing a tool screen, etc). Every
  /// [AdMobSettings.interstitialActionInterval]-th call attempts to show
  /// an interstitial, subject to cooldown and availability.
  ///
  /// ```dart
  /// AdManager.registerAction();
  /// ```
  static Future<AdShowResult> registerAction() async {
    if (!AdMobSettings.enableInterstitial) return AdShowResult.disabled;
    if (!AdMobUtils.isSupportedPlatform) {
      return AdShowResult.unsupportedPlatform;
    }

    _actionCount++;
    AdMobLogger.log(
      'Action registered ($_actionCount/'
      '${AdMobSettings.interstitialActionInterval})',
    );

    if (_actionCount % AdMobSettings.interstitialActionInterval != 0) {
      return AdShowResult.frequencyNotMet;
    }

    return showInterstitial();
  }

  /// Resets the action counter, e.g. when starting a new session/game.
  static void resetActionCount() => _actionCount = 0;
}
