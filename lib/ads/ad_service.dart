import 'dart:async';

import 'package:admob_kit/admob_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/storage_service.dart';
import 'ad_break_notice.dart';

/// App-side facade over `admob_kit`. The kit owns loading, caching, retry
/// and cooldowns (ad unit IDs live in `packages/admob_kit/lib/config/
/// admob_config.dart`); this class owns the placement rules and the single
/// "remove ads" rule.
///
/// Placements (kept conservative after the AdMob "more ads than content" /
/// "modified ad behavior" review of the sibling apps):
/// * Medium rectangle (300x250, `AdaptiveBannerAdWidget`) - at most one per
///   browsing screen, as its second section. Never on Settings, and never
///   pinned outside the scrolling content.
/// * Interstitial - only at natural breaks ([registerBreak]: opening a
///   country or sign, finishing a quiz or a build), every 2nd break, at
///   most once a minute, always behind the "Ad starts in" countdown.
/// * One full-screen ad after the first-run onboarding ([showAfterOnboarding]).
/// * Rewarded / rewarded interstitial only when the user opts in (unlock a
///   level, 30 ad-free minutes).
/// * App Open only on returning to the app after 30 s+ away (never on cold
///   start), at most once every 2 minutes.
/// * No sticky banner, no native ads.
///
/// Ads are hidden when the user is **Pro** or inside a **rewarded ad-free
/// window** (see [adsHidden]); nothing is even requested while it is `true`.
class AdService {
  static final AdService _instance = AdService._();
  static AdService get instance => _instance;
  AdService._();

  bool _initialized = false;
  final _ready = Completer<void>();

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

  /// Completes once consent and SDK start-up are done (bounded, so a slow
  /// network never blocks a screen forever).
  Future<void> whenReady() =>
      _ready.future.timeout(const Duration(seconds: 10), onTimeout: () {});

  // Set by SubscriptionProvider whenever Pro status changes.
  void setProUser(bool value) {
    _isProUser = value;
    _refreshAdsHidden();
  }

  void _refreshAdsHidden() {
    final wasHidden = adsHidden.value;
    adsHidden.value = shouldHideAds;
    // The kit's own App Open (on-resume) and interstitial checks read this.
    AdSuppression.setPermanent(shouldHideAds);
    // Ads just came back (ad-free window ended / Pro lapsed): warm the
    // interstitial so the next placement has something to show.
    if (_initialized && wasHidden && !adsHidden.value) {
      loadInterstitial();
      AppOpenAdManager.initialize();
    }
  }

  /// Delay before the interstitial is preloaded, so quick-bounce sessions
  /// (open and close within seconds) don't spend a request on an ad that
  /// can never be shown.
  static const Duration _interstitialPreloadDelay = Duration(seconds: 8);

  /// Call from `main()` right after `runApp` (not awaited), so the UMP
  /// consent form is never hidden behind the splash screen.
  Future<void> init() async {
    if (_initialized) return;
    try {
      await _init();
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  Future<void> _init() async {
    // Restore state before any ad is requested, so a Pro user or an
    // active ad-free window never triggers a load on launch.
    _isProUser = StorageService.isPro();
    _restoreAdFreeWindow();
    adsHidden.value = shouldHideAds;
    AdSuppression.setPermanent(shouldHideAds);

    // App Open only when the user comes back to the app after a real
    // break (30 s+ away), at most once every 2 minutes; never on cold
    // start, where consent, splash, onboarding and the paywall already
    // compete for the screen.
    AdMobSettings.appOpenMinBackgroundSeconds = 30;
    AdMobSettings.appOpenCooldownSeconds = 120;
    AdMobSettings.enableAdaptiveBanner = false;
    AdMobSettings.enableNative = false;
    AdMobSettings.interstitialActionInterval = 2;
    AdMobSettings.interstitialCooldownSeconds = 60;
    // A short countdown before every interstitial, so it never lands mid-tap.
    AdMobSettings.beforeInterstitial = AdBreakNotice.show;

    // UMP consent (GDPR / US privacy) before the first ad request.
    await AdMobConsent.gather();
    await AdMobService.initialize();
    _initialized = true;
    // Rewarded formats are loaded on demand by the screens that offer
    // them (see preloadRewarded / preloadRewardedInterstitial).
    if (shouldHideAds) return;

    // Attaches the on-resume trigger and preloads; the kit skips the
    // cold-start resume itself.
    AppOpenAdManager.initialize();
    Timer(_interstitialPreloadDelay, loadInterstitial);
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

  /// Counts one natural break (opening a country or sign, "Next sign",
  /// finishing a quiz or a build). Every 2nd break may show an interstitial,
  /// behind the countdown and subject to the kit's cooldown. Never call it
  /// right before navigation as a gate: navigate first, then count.
  void registerBreak() {
    if (shouldHideAds || !_initialized) return;
    AdManager.registerAction();
  }

  Future<void> _onboardingAd = Future<void>.value();

  /// Completes once the post-onboarding ad (if any) is over, so the Home
  /// guided tour never starts underneath it.
  Future<void> get onboardingAdDone => _onboardingAd;

  /// Starts the one full-screen ad shown when a first-time user taps
  /// "Get Started"; the caller navigates on without waiting for it.
  void startOnboardingAd() => _onboardingAd = _showAfterOnboarding();

  /// Never blocks the flow when no ad is ready.
  Future<void> _showAfterOnboarding() async {
    await whenReady();
    if (shouldHideAds || !_initialized) return;
    // The first interstitial is usually still loading this early; give it
    // a short bounded window instead of skipping straight away.
    InterstitialAdManager.load();
    final deadline = DateTime.now().add(const Duration(seconds: 4));
    while (!AdManager.isInterstitialReady &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    await AdManager.showInterstitial();
  }

  // ---------------- REWARDED ----------------

  bool get isRewardedReady => AdManager.isRewardedReady;

  /// Call when a screen that offers a rewarded ad opens, so it is ready by
  /// the time the user taps. Skipped for Pro users, who never watch one.
  void preloadRewarded() {
    if (_isProUser) return;
    RewardedAdManager.load();
  }

  /// Shows a rewarded video the user opted into. Returns whether the reward
  /// was earned. Not blocked by [shouldHideAds]: the user asked for it.
  Future<bool> showRewarded() async {
    var rewarded = false;
    await AdManager.showRewarded(onReward: () => rewarded = true);
    return rewarded;
  }

  // ---------------- REWARDED INTERSTITIAL ----------------

  bool get isRewardedInterstitialReady => AdManager.isRewardedInterstitialReady;

  /// Call when the "remove ads for free" offer is on screen. Skipped when
  /// the offer can't be used (Pro, or an ad-free window already running).
  void preloadRewardedInterstitial() {
    if (shouldHideAds) return;
    RewardedInterstitialAdManager.load();
  }

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

  // ---------------- CLEANUP ----------------

  void dispose() {
    _adFreeTimer?.cancel();
    InterstitialAdManager.dispose();
    RewardedAdManager.dispose();
    RewardedInterstitialAdManager.dispose();
    AppOpenAdManager.instance.dispose();
  }
}
