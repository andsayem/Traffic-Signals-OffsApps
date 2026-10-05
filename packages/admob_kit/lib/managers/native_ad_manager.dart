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

  /// A loaded ad whose widget was gone before it arrived. It was never
  /// rendered, so the next native slot shows it instead of requesting a
  /// new one - otherwise that request is paid for with no impression.
  static NativeAd? _spare;
  static DateTime? _spareLoadedAt;

  /// Native ads should be shown within about an hour of loading.
  static const Duration _spareMaxAge = Duration(minutes: 50);

  /// Keeps an unrendered [ad] for the next native slot, disposing any
  /// older spare.
  static void park(NativeAd ad) {
    _spare?.dispose();
    _spare = ad;
    _spareLoadedAt = DateTime.now();
    AdMobLogger.log('Native parked for reuse');
  }

  /// Returns the parked ad, if one is fresh enough, and clears the slot.
  static NativeAd? takeSpare() {
    final ad = _spare;
    final loadedAt = _spareLoadedAt;
    _spare = null;
    _spareLoadedAt = null;
    if (ad == null || loadedAt == null) return null;
    if (DateTime.now().difference(loadedAt) > _spareMaxAge) {
      ad.dispose();
      return null;
    }
    AdMobLogger.log('Native reused from spare');
    return ad;
  }

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
