import 'package:admob_kit/admob_kit.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import 'ad_service.dart';

/// Full-width anchored banner for the bottom of a screen. Hidden for Pro
/// users and during a rewarded ad-free window.
class FooterBannerAd extends StatelessWidget {
  const FooterBannerAd({super.key, this.background});

  final Color? background;

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<SubscriptionProvider>().isPro;
    if (isPro) return const SizedBox.shrink();
    return ValueListenableBuilder<bool>(
      valueListenable: AdService.instance.adsHidden,
      builder: (context, hidden, _) => hidden
          ? const SizedBox.shrink()
          : ColoredBox(
              color: background ?? Colors.transparent,
              child: const AdaptiveBannerAd(),
            ),
    );
  }
}
