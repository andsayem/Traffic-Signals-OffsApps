import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/admob_config.dart';
import '../core/admob_logger.dart';

/// Shared banner-loading helpers used by the `AdBanner` and
/// `AdaptiveBannerAd` widgets.
///
/// Banner ads are lightweight and tied to widget lifecycle, so unlike the
/// full-screen ad types there is no app-wide cache here - each widget
/// instance owns and disposes its own [BannerAd]. Most apps should just
/// use the widgets; this class exists for apps that need a fully custom
/// banner UI.
class BannerAdManager {
  BannerAdManager._();

  /// Creates and loads a fixed-size banner ad ([size] defaults to 320x50;
  /// pass `AdSize.mediumRectangle` for an in-content 300x250).
  static void loadStandardBanner({
    required void Function(BannerAd ad) onLoaded,
    required void Function(Object error) onFailed,
    AdSize size = AdSize.banner,
  }) {
    AdMobLogger.log('Banner loading (${size.width}x${size.height})');
    BannerAd(
      adUnitId: AdMobConfig.bannerId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          AdMobLogger.log('Banner loaded');
          onLoaded(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          AdMobLogger.error('Banner failed', error);
          ad.dispose();
          onFailed(error);
        },
      ),
    ).load();
  }

  /// Resolves the anchored adaptive size for [width] and creates + loads
  /// a banner ad at that size.
  ///
  /// [width] must be the actual available width the ad will render into
  /// (e.g. from a `LayoutBuilder`'s constraints) - not necessarily the
  /// full screen width, since a banner placed inside padding or a
  /// constrained column is narrower than the screen. Requesting a size
  /// wider than the ad's true render width causes the ad to overflow its
  /// layout. Fails via [onFailed] if AdMob can't determine a size for
  /// this width.
  ///
  /// [collapsible] requests Google's collapsible banner ('bottom'): it opens
  /// larger once and collapses to a normal banner, which usually earns more
  /// than a plain banner. Use it on at most one or two key screens.
  static Future<void> loadAdaptiveBanner({
    required int width,
    required void Function(BannerAd ad) onLoaded,
    required void Function(Object error) onFailed,
    bool collapsible = false,
  }) async {
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);

    if (size == null) {
      AdMobLogger.log('Adaptive banner size unavailable for width $width');
      onFailed(StateError('No adaptive banner size for width $width'));
      return;
    }

    AdMobLogger.log('Adaptive banner loading (${size.width}x${size.height})');

    BannerAd(
      adUnitId: AdMobConfig.adaptiveBannerId,
      size: size,
      request: collapsible ? const AdRequest(extras: {'collapsible': 'bottom'}) : const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          AdMobLogger.log('Adaptive banner loaded');
          onLoaded(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          AdMobLogger.error('Adaptive banner failed', error);
          ad.dispose();
          onFailed(error);
        },
      ),
    ).load();
  }
}
