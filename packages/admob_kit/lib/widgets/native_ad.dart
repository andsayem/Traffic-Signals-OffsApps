import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/admob_config.dart';
import '../config/admob_settings.dart';
import '../core/admob_logger.dart';
import '../core/admob_utils.dart';
import '../managers/native_ad_manager.dart';

/// A self-contained native ad.
///
/// ```dart
/// const AdNative()                                   // native factory layout
/// const AdNative(templateType: TemplateType.small)   // built-in template
/// ```
///
/// Without [templateType], the pixel-level layout is rendered by a native
/// factory registered per platform - see the package README's "Native Ad
/// setup" section. [factoryId] must match the id used when registering
/// that factory; defaults to [AdMobConfig.nativeAdFactoryId].
///
/// With [templateType], Google's built-in small/medium template is used
/// instead (no platform code needed), coloured from the current [Theme].
///
/// [height] should match the layout's actual height; when null it defaults
/// to a size that fits the chosen template.
class AdNative extends StatefulWidget {
  const AdNative({super.key, this.factoryId, this.templateType, this.height});

  final String? factoryId;
  final TemplateType? templateType;
  final double? height;

  @override
  State<AdNative> createState() => _AdNativeState();
}

class _AdNativeState extends State<AdNative> with AutomaticKeepAliveClientMixin {
  NativeAd? _readyAd;
  bool _disposed = false;
  bool _started = false;
  int _retryCount = 0;

  // Keeps a loaded ad alive while it scrolls off-screen in a list, so it
  // isn't reloaded (and re-requested) every time it scrolls back in.
  @override
  bool get wantKeepAlive => _readyAd != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Loaded here rather than initState because template colours come
    // from Theme.of(context).
    if (!_started) {
      _started = true;
      _load();
    }
  }

  NativeTemplateStyle? _templateStyle() {
    final type = widget.templateType;
    if (type == null) return null;
    final scheme = Theme.of(context).colorScheme;
    final card = Theme.of(context).cardTheme.color ?? scheme.surface;
    return NativeTemplateStyle(
      templateType: type,
      mainBackgroundColor: card,
      cornerRadius: 16,
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: scheme.onPrimary,
        backgroundColor: scheme.primary,
        style: NativeTemplateFontStyle.bold,
        size: 15,
      ),
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: scheme.onSurface,
        style: NativeTemplateFontStyle.bold,
        size: 15,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: scheme.onSurfaceVariant,
        size: 13,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: scheme.onSurfaceVariant,
        size: 13,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    AdSuppression.notifier.addListener(_onSuppressionChanged);
  }

  void _onSuppressionChanged() {
    if (_disposed) return;
    if (AdSuppression.isActive) {
      _readyAd?.dispose();
      _readyAd = null;
      updateKeepAlive();
    } else if (_readyAd == null) {
      _retryCount = 0;
      _load();
    }
    setState(() {});
  }

  void _load() {
    if (!AdMobSettings.enableNative || !AdMobUtils.isSupportedPlatform || AdSuppression.isActive) {
      return;
    }
    NativeAdManager.load(
      factoryId: widget.factoryId ?? AdMobConfig.nativeAdFactoryId,
      templateStyle: _templateStyle(),
      onLoaded: (ad) {
        if (_disposed) {
          ad.dispose();
          return;
        }
        setState(() => _readyAd = ad);
        updateKeepAlive();
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
    AdSuppression.notifier.removeListener(_onSuppressionChanged);
    _disposed = true;
    _readyAd?.dispose();
    super.dispose();
  }

  double get _height {
    if (widget.height != null) return widget.height!;
    switch (widget.templateType) {
      case TemplateType.small:
        return 110;
      case TemplateType.medium:
        return 340;
      case null:
        return 320;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ad = _readyAd;
    if (ad == null) return const SizedBox.shrink();
    return SizedBox(height: _height, child: AdWidget(ad: ad));
  }
}
