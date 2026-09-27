import 'package:admob_kit/admob_kit.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import 'ad_service.dart';

/// Native ad rendered by the Android `native_ad_layout.xml` factory,
/// hidden for Pro users and during a rewarded ad-free window.
class NativeAdWidget extends StatelessWidget {
  const NativeAdWidget({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsetsGeometry padding;

  /// Must match the height of `native_ad_layout.xml`.
  static const double _height = 96;

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<SubscriptionProvider>().isPro;
    if (isPro) return const SizedBox.shrink();

    return ValueListenableBuilder<bool>(
      valueListenable: AdService.instance.adsHidden,
      builder: (context, hidden, _) {
        if (hidden) return const SizedBox.shrink();
        return Padding(
          padding: padding,
          child: const AdNative(height: _height),
        );
      },
    );
  }
}
