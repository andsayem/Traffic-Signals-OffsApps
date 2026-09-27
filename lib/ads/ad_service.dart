import 'dart:async';

import 'package:admob_kit/admob_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/storage_service.dart';

/// App-side facade over `admob_kit`. The kit owns loading, caching, retry
/// and cooldowns (ad unit IDs live in `packages/admob_kit/lib/config/
/// admob_config.dart`); this class owns the single "remove ads" rule:
///
/// Ads are hidden when the user is **Pro** or inside a **rewarded ad-free
/// window** (see [adsHidden]). Every ad in the app — banner, native,
/// interstitial, App Open — checks it, and nothing is even requested while
/// it is `true`. The rewarded interstitial is the one exception: it is how
/// a user earns the ad-free window.
///
/// The App Open ad is shown once on cold start only, never on resume.
class AdService {
  static final AdService _instance = AdService._();
  static AdService get instance => _instance;
  AdService._();

  bool _initialized = false;

  /// How long one watched rewarded interstitial keeps ads hidden.
  static const Duration adFreeDuration = Duration(minutes: 30);

  bool _isProUser = false;
  DateTime? _adFreeUntil;
  Timer? _adFreeTimer;

  /// `true` while ads must be hidden (Pro, or inside an ad-free window).
  /// Ad widgets listen to this so they disappear/reappear immediately.
  final ValueNotifier<bool> adsHidden = ValueNotifier<bool>(false);

  bool get isProUser => _isProUser;

  bool get isAdFreeActive {
    final until = _adFreeUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  /// Time left in the current ad-free window, or `null` if none.
  Duration? get adFreeRemaining =>
      isAdFreeActive ? _adFreeUntil!.difference(DateTime.now()) : null;

  /// Single source of truth for "should this user see ads right now".
  bool get shouldHideAds => _isProUser || isAdFreeActive;

  // Set by SubscriptionProvider whenever Pro status changes.
  void setProUser(bool value) {
    _isProUser = value;
    _refreshAdsHidden();
  }

  void _refreshAdsHidden() {
    final wasHidden = adsHidden.value;
    adsHidden.value = shouldHideAds;
    // Ads just came back (ad-free window ended / Pro lapsed): warm the
    // full-screen caches so the next placement has something to show.
    if (_initialized && wasHidden && !adsHidden.value) _preload();
  }

  String get bannerAdUnitId => AdMobConfig.bannerId;

  Future<void> init() async {
    if (_initialized) return;

    // Restore state before any ad is requested, so a Pro user or an
    // active ad-free window never triggers a load on launch.
    _isProUser = StorageService.isPro();
    _restoreAdFreeWindow();
    adsHidden.value = shouldHideAds;

    await AdMobService.initialize();
    _initialized = true;
    if (shouldHideAds) {
      // Only the rewarded interstitial (used to earn ad-free time).
      RewardedInterstitialAdManager.load();
      return;
    }
    _preload();

    // Shown exactly once on cold start, a short moment after launch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        showAppOpenOnColdStart();
      });
    });
  }

  void _preload() {
    // Interstitial, rewarded and rewarded interstitial.
    AdManager.preloadAll();
    // App Open: preload without AppOpenAdManager.initialize() so the kit's
    // on-resume trigger stays off.
    AppOpenAdManager.instance.load();
  }

  // ---------------- BANNER ----------------

  /// Creates and loads a Medium Rectangle (300x250) [BannerAd]. The caller
  /// owns the returned ad and must dispose it.
  BannerAd createMediumRectangleBanner({
    required void Function(BannerAd ad) onLoaded,
    required void Function() onFailed,
  }) {
    final BannerAd bannerAd = BannerAd(
      adUnitId: AdMobConfig.bannerId,
      size: AdSize.mediumRectangle, // 300x250
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded(ad as BannerAd),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed();
        },
      ),
    );

    bannerAd.load();
    return bannerAd;
  }

  // ---------------- INTERSTITIAL ----------------

  void loadInterstitial() {
    if (shouldHideAds) return;
    InterstitialAdManager.load();
  }

  bool get isInterstitialReady => AdManager.isInterstitialReady;

  /// Shows an interstitial (subject to the kit's cooldown) and calls
  /// [onDismissed] once the user is back in the app — or right away if no
  /// ad was shown.
  void showInterstitial({VoidCallback? onDismissed}) {
    if (shouldHideAds) {
      onDismissed?.call();
      return;
    }
    AdManager.showInterstitial().then((_) => onDismissed?.call());
  }

  /// Counts a light navigation step (opening a sign, "Next sign"). Every
  /// few steps an interstitial is shown, subject to the kit's cooldown, so
  /// browsing earns without an ad on every tap.
  void registerAction() {
    if (shouldHideAds) return;
    AdManager.registerAction();
  }

  // ---------------- REWARDED ----------------

  bool get isRewardedReady => AdManager.isRewardedReady;

  /// Shows a rewarded video the user opted into. Returns whether the reward
  /// was earned. Not blocked by [shouldHideAds]: the user asked for it.
  Future<bool> showRewarded() async {
    var rewarded = false;
    await AdManager.showRewarded(onReward: () => rewarded = true);
    return rewarded;
  }

  // ---------------- REWARDED INTERSTITIAL ----------------

  bool get isRewardedInterstitialReady => AdManager.isRewardedInterstitialReady;

  /// Shows a rewarded interstitial; when the reward is earned, ads are
  /// hidden for [adFreeDuration]. Returns whether the reward was granted.
  Future<bool> showRewardedInterstitialForAdFree() async {
    var rewarded = false;
    await AdManager.showRewardedInterstitial(onReward: () => rewarded = true);
    if (rewarded) _startAdFreeWindow(DateTime.now().add(adFreeDuration));
    return rewarded;
  }

  void _restoreAdFreeWindow() {
    final until = StorageService.getAdFreeUntil();
    if (until == null) return;
    if (DateTime.now().isBefore(until)) {
      _startAdFreeWindow(until, persist: false);
    } else {
      StorageService.setAdFreeUntil(null);
    }
  }

  void _startAdFreeWindow(DateTime until, {bool persist = true}) {
    _adFreeUntil = until;
    if (persist) StorageService.setAdFreeUntil(until);
    _adFreeTimer?.cancel();
    _adFreeTimer = Timer(until.difference(DateTime.now()), () {
      _adFreeUntil = null;
      StorageService.setAdFreeUntil(null);
      _refreshAdsHidden();
    });
    _refreshAdsHidden();
  }

  // ---------------- APP OPEN ----------------

  bool get isAppOpenReady => AdManager.isAppOpenReady;

  /// Shows the app-open ad on cold start (first launch). Skipped while ads
  /// are hidden. [onDismissed] runs once the show attempt resolves.
  void showAppOpenOnColdStart({VoidCallback? onDismissed}) {
    if (shouldHideAds) {
      onDismissed?.call();
      return;
    }
    AdManager.showAppOpen().then((_) => onDismissed?.call());
  }

  // ---------------- CLEANUP ----------------

  void dispose() {
    _adFreeTimer?.cancel();
    InterstitialAdManager.dispose();
    RewardedAdManager.dispose();
    RewardedInterstitialAdManager.dispose();
    AppOpenAdManager.instance.dispose();
  }
}
