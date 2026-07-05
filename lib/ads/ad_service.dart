import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';

class AdService with WidgetsBindingObserver {
  static final AdService _instance = AdService._();
  static AdService get instance => _instance;
  AdService._();

  bool _initialized = false;
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  AppOpenAd? _appOpenAd;
  bool _isBannerLoaded = false;
  bool _isInterstitialLoading = false;
  bool _isAppOpenLoading = false;

  // Tracks whether ANY full-screen ad (interstitial or app open) is
  // currently visible. Used so app-open doesn't fire on top of one.
  bool _isShowingFullScreenAd = false;

  String get bannerAdUnitId => AdIds.banner;
  String get _bannerId => AdIds.banner;
  String get _interstitialId => AdIds.interstitial;
  String get _appOpenId => AdIds.appOpen;

  Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    WidgetsBinding.instance.addObserver(this);
    _initialized = true;

    // Preload the first app-open ad so it's ready the moment the
    // app is backgrounded and resumed.
    loadAppOpen();
  }

  /// Called automatically by Flutter whenever the app's lifecycle
  /// state changes (e.g. backgrounded, resumed, paused).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeShowAppOpenOnResume();
    }
  }

  void _maybeShowAppOpenOnResume() {
    // Skip if an interstitial/app-open ad is already showing
    // (showing one triggers a resume event too — don't double-show),
    // or if the SDK isn't ready yet.
    if (_isShowingFullScreenAd || !_initialized) return;

    if (isAppOpenReady) {
      showAppOpen();
    } else {
      // Not ready yet — load one for next time.
      loadAppOpen();
    }
  }

  // ---------------- BANNER ----------------

  void loadBanner({VoidCallback? onLoaded, VoidCallback? onFailed}) {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerLoaded = false;

    _bannerAd = BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerLoaded = true;
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          _isBannerLoaded = false;
          onFailed?.call();
        },
      ),
    )..load();
  }

  BannerAd? get bannerAd => _isBannerLoaded ? _bannerAd : null;
  bool get isBannerLoaded => _isBannerLoaded;

  /// Creates and loads a bigger, adaptive-size [BannerAd] sized for the
  /// given [width] (usually MediaQuery.of(context).size.width).
  ///
  /// Unlike [loadBanner], this does NOT store the ad on AdService —
  /// it returns a fresh, independent BannerAd instance to the caller.
  /// This avoids the "Ad with id could not be found" crash that happens
  /// when multiple widgets/rebuilds share and dispose the same ad object.
  /// The caller (typically a widget's State) owns the returned ad and is
  /// responsible for disposing it in its own dispose().
  Future<BannerAd?> createAdaptiveBanner({
    required int width,
    required void Function(BannerAd ad) onLoaded,
    required void Function() onFailed,
  }) async {
    final AdSize? adaptiveSize = await AdSize.getAnchoredAdaptiveBannerAdSize(
        Orientation.portrait, width);

    if (adaptiveSize == null) {
      onFailed();
      return null;
    }

    final BannerAd bannerAd = BannerAd(
      adUnitId: _bannerId,
      size: adaptiveSize,
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

  /// Creates and loads a Medium Rectangle (300x250) [BannerAd] — a bigger,
  /// fixed-size box ad format (IAB MREC standard). Bigger than adaptive
  /// banners, good for in-feed or content-break placements.
  ///
  /// Same ownership rules as [createAdaptiveBanner]: the caller owns the
  /// returned ad and must dispose it themselves.
  BannerAd createMediumRectangleBanner({
    required void Function(BannerAd ad) onLoaded,
    required void Function() onFailed,
  }) {
    final BannerAd bannerAd = BannerAd(
      adUnitId: _bannerId,
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
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _isShowingFullScreenAd = true;
            },
            onAdDismissedFullScreenContent: (ad) {
              _isShowingFullScreenAd = false;
              ad.dispose();
              _interstitialAd = null;
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _isShowingFullScreenAd = false;
              ad.dispose();
              _interstitialAd = null;
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  bool get isInterstitialReady => _interstitialAd != null;

  void showInterstitial({VoidCallback? onDismissed}) {
    final ad = _interstitialAd;
    if (ad == null) {
      onDismissed?.call();
      return;
    }
    // Replace callback so we know when user dismisses the ad
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingFullScreenAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingFullScreenAd = false;
        ad.dispose();
        _interstitialAd = null;
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingFullScreenAd = false;
        ad.dispose();
        _interstitialAd = null;
        onDismissed?.call();
      },
    );
    ad.show();
  }

  // ---------------- APP OPEN ----------------

  void loadAppOpen() {
    if (_isAppOpenLoading || _appOpenAd != null) return;
    _isAppOpenLoading = true;

    AppOpenAd.load(
      adUnitId: _appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isAppOpenLoading = false;
        },
      ),
    );
  }

  bool get isAppOpenReady => _appOpenAd != null;

  /// Shows the app-open ad manually (also called automatically on resume).
  void showAppOpen() {
    if (_appOpenAd == null) return;
    _attachFullScreenCallbacks();
    _appOpenAd!.show();
  }

  /// Shows the app-open ad on cold start (first launch).
  /// Calls [onDismissed] after the ad is dismissed or fails to show.
  void showAppOpenOnColdStart({VoidCallback? onDismissed}) {
    if (_appOpenAd == null) {
      onDismissed?.call();
      return;
    }
    _attachFullScreenCallbacks(
      onDismissed: () {
        onDismissed?.call();
      },
    );
    _appOpenAd!.show();
  }

  void _attachFullScreenCallbacks({VoidCallback? onDismissed}) {
    _appOpenAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingFullScreenAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingFullScreenAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpen();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingFullScreenAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpen();
        onDismissed?.call();
      },
    );
  }

  // ---------------- CLEANUP ----------------

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _appOpenAd?.dispose();
    _bannerAd = null;
    _interstitialAd = null;
    _appOpenAd = null;
    _isBannerLoaded = false;
  }
}
