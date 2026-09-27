import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/admob_config.dart';
import '../core/admob_logger.dart';

/// Builds and loads a [NativeAd].
///
/// Unlike the full-screen ad types, native ads are not app-wide singletons
/// - multiple native ads can be on screen (and loading) at once, so each
/// `AdNative` widget instance owns and disposes its own ad. This class
/// only factors out the SDK call so the widget stays UI-only.
///
/// The actual visual layout of a native ad is rendered natively and must
/// be registered per platform - see the package README's "Native Ad
/// setup" section - via a factory id that must match [factoryId].
class NativeAdManager {
  NativeAdManager._();

  static void load({
    required String factoryId,
    required void Function(NativeAd ad) onLoaded,
    required void Function(Object error) onFailed,
  }) {
    final adUnitId = AdMobConfig.nativeId;
    if (adUnitId.isEmpty) {
      AdMobLogger.log('Native ad unit ID is empty, skipping load');
      return;
    }

    AdMobLogger.log('Native loading');

    NativeAd(
      adUnitId: adUnitId,
      factoryId: factoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          AdMobLogger.log('Native loaded');
          onLoaded(ad as NativeAd);
        },
        onAdFailedToLoad: (ad, error) {
          AdMobLogger.error('Native failed', error);
          ad.dispose();
          onFailed(error);
        },
      ),
    ).load();
  }
}
