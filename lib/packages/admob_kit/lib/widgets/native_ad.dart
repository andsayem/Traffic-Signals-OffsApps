import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/admob_config.dart';
import '../config/admob_settings.dart';
import '../core/admob_logger.dart';
import '../core/admob_utils.dart';
import '../managers/native_ad_manager.dart';

/// A self-contained native ad.
///
/// ```dart
/// const AdNative()
/// ```
///
/// The actual pixel-level layout of a native ad (headline, body, icon,
/// media, call-to-action) is rendered by a native factory registered per
/// platform - see the package README's "Native Ad setup" section for the
/// Android/iOS template files to copy into your app. That keeps the
/// design fully in your control and editable without touching this
/// widget: change the native layout file, not this class.
///
/// [factoryId] must match the id used when registering that native
/// factory; defaults to [AdMobConfig.nativeAdFactoryId]. [height] should
/// match the native layout's actual height.
class AdNative extends StatefulWidget {
  const AdNative({super.key, this.factoryId, this.height = 320});

  final String? factoryId;
  final double height;

  @override
  State<AdNative> createState() => _AdNativeState();
}

class _AdNativeState extends State<AdNative> {
  NativeAd? _readyAd;
  bool _disposed = false;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (!AdMobSettings.enableNative || !AdMobUtils.isSupportedPlatform) {
      return;
    }
    NativeAdManager.load(
      factoryId: widget.factoryId ?? AdMobConfig.nativeAdFactoryId,
      onLoaded: (ad) {
        if (_disposed) {
          ad.dispose();
          return;
        }
        setState(() => _readyAd = ad);
      },
      onFailed: (error) {
        if (_disposed) return;
        _retry();
      },
    );
  }

  void _retry() {
    if (_retryCount >= AdMobSettings.maxLoadRetry) return;
    _retryCount++;
    final delay = Duration(
      seconds: AdMobSettings.retryBaseDelaySeconds * _retryCount,
    );
    AdMobLogger.log('Native retry #$_retryCount in ${delay.inSeconds}s');
    Future.delayed(delay, () {
      if (!_disposed) _load();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _readyAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _readyAd;
    if (ad == null) return const SizedBox.shrink();
    return SizedBox(height: widget.height, child: AdWidget(ad: ad));
  }
}
