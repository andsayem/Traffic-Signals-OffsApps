import 'package:flutter/foundation.dart';

/// Behavior controls for every ad type. All fields are mutable `static`
/// values, so a host app can tune them once at startup - before calling
/// `AdMobService.initialize()` - and every manager picks the change up
/// immediately. Nothing here is app-specific business logic; it only
/// controls *when* and *how often* ads may appear.
class AdMobSettings {
  AdMobSettings._();

  // ---------------------------------------------------------------------
  // Feature toggles - flip any of these off to fully disable that ad type
  // across the app without touching call sites.
  // ---------------------------------------------------------------------
  static bool enableBanner = true;
  static bool enableAdaptiveBanner = true;
  static bool enableInterstitial = true;
  static bool enableRewarded = true;
  static bool enableRewardedInterstitial = true;
  static bool enableNative = true;
  static bool enableAppOpen = true;

  // ---------------------------------------------------------------------
  // Interstitial frequency control
  // ---------------------------------------------------------------------

  /// `AdManager.registerAction()` shows an interstitial once every
  /// [interstitialActionInterval] calls (e.g. 3 -> action 3, 6, 9, ...).
  static int interstitialActionInterval = 3;

  /// Minimum number of seconds between two interstitial displays,
  /// regardless of the action interval above.
  static int interstitialCooldownSeconds = 30;

  // ---------------------------------------------------------------------
  // App Open
  // ---------------------------------------------------------------------

  /// Minimum number of seconds between two App Open displays.
  static int appOpenCooldownSeconds = 60;

  /// The app must have been backgrounded for at least this long before an
  /// auto-triggered App Open ad is eligible to show on resume. Filters
  /// out near-zero-viewability "returns" (a permission dialog, a quick
  /// notification peek, an app switch that bounced right back) that
  /// would otherwise waste an impression and train the ad auction on
  /// low-quality signal.
  static int appOpenMinBackgroundSeconds = 20;

  /// AdMob discards App Open ads after roughly four hours; a cached ad
  /// older than this is dropped and reloaded rather than shown stale.
  static int appOpenMaxCacheHours = 4;

  // ---------------------------------------------------------------------
  // Retry
  // ---------------------------------------------------------------------

  /// Maximum number of automatic reload attempts after a load failure,
  /// per ad instance lifecycle. Set to 0 to disable retries.
  static int maxLoadRetry = 3;

  /// Base delay used to space out retries: attempt N waits
  /// `retryBaseDelaySeconds * N` seconds. Keeps retries from hammering
  /// AdMob after a no-fill or network failure.
  static int retryBaseDelaySeconds = 2;

  // ---------------------------------------------------------------------
  // Test ads
  // ---------------------------------------------------------------------

  /// When `true`, every ad manager resolves Google's official test ad
  /// unit IDs instead of the IDs configured in `AdMobConfig`.
  ///
  /// Defaults to [kDebugMode] so a freshly copied app never accidentally
  /// serves production ad requests from a debug build. Override it
  /// explicitly (e.g. from a QA build flavor) if you need production IDs
  /// while debugging, or test IDs in a release/profile build.
  static bool useTestAds = kDebugMode;

  /// Optional AdMob test device IDs (see the device's logcat/console
  /// output for `Use RequestConfiguration.Builder...`) so specific real
  /// devices always receive test ads even when [useTestAds] is false.
  static List<String> testDeviceIds = const [];

  // ---------------------------------------------------------------------
  // Logging
  // ---------------------------------------------------------------------

  /// Master switch for `AdMobLogger` output.
  static bool enableDebugLogs = true;

  /// Logs are suppressed in release builds unless this is also `true`.
  static bool enableLogsInRelease = false;
}
