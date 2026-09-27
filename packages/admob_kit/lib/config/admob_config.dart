import '../core/admob_utils.dart';
import 'admob_settings.dart';

/// The only file most apps need to edit.
///
/// Fill in the real App ID / Ad Unit ID from your AdMob console for each
/// platform you support. Leave a platform's field as `null` if you don't
/// support that platform (e.g. an Android-only app leaves every
/// `ios...Id` as `null`) - `AdMobUtils.pick` treats a `null` platform ID
/// the same as an empty one, and every ad manager already skips loading
/// when its resolved ID is empty. Everything else in this library reads
/// IDs through the getters at the bottom of this class, which
/// automatically:
///
/// * pick the Android or iOS ID for the current platform, and
/// * substitute Google's official test ad unit IDs while
///   `AdMobSettings.useTestAds` is `true`, so you never have to remember
///   to swap IDs in and out while developing.
class AdMobConfig {
  AdMobConfig._();

  // ---------------------------------------------------------------------
  // App IDs (used in AndroidManifest.xml / Info.plist - see README)
  // ---------------------------------------------------------------------
  static const String androidAppId = 'ca-app-pub-1195883693665145~6554943240';
  static const String? iosAppId = null;

  // ---------------------------------------------------------------------
  // Banner
  // ---------------------------------------------------------------------
  static const String androidBannerId =
      'ca-app-pub-1195883693665145/8169196259';
  static const String? iosBannerId = null;

  // ---------------------------------------------------------------------
  // Adaptive banner (reuses the banner unit)
  // ---------------------------------------------------------------------
  static const String androidAdaptiveBannerId =
      'ca-app-pub-1195883693665145/8169196259';
  static const String? iosAdaptiveBannerId = null;

  // ---------------------------------------------------------------------
  // Interstitial
  // ---------------------------------------------------------------------
  static const String androidInterstitialId =
      'ca-app-pub-1195883693665145/9668191741';
  static const String? iosInterstitialId = null;

  // ---------------------------------------------------------------------
  // Rewarded
  // ---------------------------------------------------------------------
  static const String androidRewardedId =
      'ca-app-pub-1195883693665145/9288048250';
  static const String? iosRewardedId = null;

  // ---------------------------------------------------------------------
  // Rewarded interstitial
  // ---------------------------------------------------------------------
  static const String androidRewardedInterstitialId =
      'ca-app-pub-1195883693665145/5205522301';
  static const String? iosRewardedInterstitialId = null;

  // ---------------------------------------------------------------------
  // Native
  // ---------------------------------------------------------------------
  static const String androidNativeId =
      'ca-app-pub-1195883693665145/8250313036';
  static const String? iosNativeId = null;

  /// Must match the `factoryId` registered natively via
  /// `registerNativeAdFactory` (Android) / a `FLTNativeAdFactory`
  /// (iOS) - see README "Native Ad setup".
  static const String nativeAdFactoryId = 'adFactoryExample';

  // ---------------------------------------------------------------------
  // App Open
  // ---------------------------------------------------------------------
  static const String androidAppOpenId =
      'ca-app-pub-1195883693665145/5543032919';
  static const String? iosAppOpenId = null;

  // ---------------------------------------------------------------------
  // Resolved IDs - use these from ad managers/widgets, never the raw
  // constants above directly, so test-ad substitution always applies.
  // ---------------------------------------------------------------------

  static String get appId => AdMobSettings.useTestAds
      ? _TestAdUnitIds.appId
      : AdMobUtils.pick(android: androidAppId, ios: iosAppId);

  static String get bannerId => AdMobSettings.useTestAds
      ? _TestAdUnitIds.banner
      : AdMobUtils.pick(android: androidBannerId, ios: iosBannerId);

  static String get adaptiveBannerId => AdMobSettings.useTestAds
      ? _TestAdUnitIds.adaptiveBanner
      : AdMobUtils.pick(
          android: androidAdaptiveBannerId,
          ios: iosAdaptiveBannerId,
        );

  static String get interstitialId => AdMobSettings.useTestAds
      ? _TestAdUnitIds.interstitial
      : AdMobUtils.pick(
          android: androidInterstitialId,
          ios: iosInterstitialId,
        );

  static String get rewardedId => AdMobSettings.useTestAds
      ? _TestAdUnitIds.rewarded
      : AdMobUtils.pick(android: androidRewardedId, ios: iosRewardedId);

  static String get rewardedInterstitialId => AdMobSettings.useTestAds
      ? _TestAdUnitIds.rewardedInterstitial
      : AdMobUtils.pick(
          android: androidRewardedInterstitialId,
          ios: iosRewardedInterstitialId,
        );

  static String get nativeId => AdMobSettings.useTestAds
      ? _TestAdUnitIds.native
      : AdMobUtils.pick(android: androidNativeId, ios: iosNativeId);

  static String get appOpenId => AdMobSettings.useTestAds
      ? _TestAdUnitIds.appOpen
      : AdMobUtils.pick(android: androidAppOpenId, ios: iosAppOpenId);
}

/// Google's official AdMob test ad unit IDs. These are publicly documented
/// constants (https://developers.google.com/admob/android/test-ads and
/// https://developers.google.com/admob/ios/test-ads) - always safe to use
/// during development, never real ad units.
///
/// This app is Android-only, so the iOS test values are left empty; add
/// them back from Google's docs above if you ever add iOS support.
class _TestAdUnitIds {
  _TestAdUnitIds._();

  static String get appId => AdMobUtils.pick(
        android: 'ca-app-pub-1195883693665145~1254577778',
        ios: '',
      );

  static String get banner => AdMobUtils.pick(
        android: 'ca-app-pub-3940256099942544/6300978111',
        ios: '',
      );

  static String get adaptiveBanner => AdMobUtils.pick(
        android: 'ca-app-pub-3940256099942544/9214589741',
        ios: '',
      );

  static String get interstitial => AdMobUtils.pick(
        android: 'ca-app-pub-3940256099942544/1033173712',
        ios: '',
      );

  static String get rewarded => AdMobUtils.pick(
        android: 'ca-app-pub-3940256099942544/5224354917',
        ios: '',
      );

  static String get rewardedInterstitial => AdMobUtils.pick(
        android: 'ca-app-pub-3940256099942544/5354046379',
        ios: '',
      );

  static String get native => AdMobUtils.pick(
        android: 'ca-app-pub-3940256099942544/2247696110',
        ios: '',
      );

  static String get appOpen => AdMobUtils.pick(
        android: 'ca-app-pub-3940256099942544/9257395921',
        ios: '',
      );
}
