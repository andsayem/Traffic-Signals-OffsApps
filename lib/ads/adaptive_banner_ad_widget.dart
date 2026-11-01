import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import 'ad_service.dart';

class AdaptiveBannerAdWidget extends StatefulWidget {
  const AdaptiveBannerAdWidget({
    super.key,
    this.backgroundColor = Colors.white,
  });

  final Color backgroundColor;

  @override
  State<AdaptiveBannerAdWidget> createState() => _AdaptiveBannerAdWidgetState();
}

class _AdaptiveBannerAdWidgetState extends State<AdaptiveBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _hasRequested = false;

  Future<void> _loadAd() async {
    if (_hasRequested) return;
    _hasRequested = true;
    // No request before UMP consent and SDK start-up have finished.
    await AdService.instance.whenReady();
    if (!mounted) return;

    AdService.instance.createMediumRectangleBanner(
      onLoaded: (ad) {
        if (!mounted) {
          ad.dispose();
          return;
        }
        setState(() {
          _bannerAd = ad;
          _isLoaded = true;
        });
      },
      onFailed: () {
        if (mounted) setState(() => _isLoaded = false);
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<SubscriptionProvider>().isPro;
    // Hidden tabs (kept alive by the IndexedStack) never load an ad.
    if (isPro || !TabVisibility.of(context)) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: AdService.instance.adsHidden,
      builder: (context, hidden, _) =>
          hidden ? const SizedBox.shrink() : _buildAd(),
    );
  }

  Widget _buildAd() {
    if (!_hasRequested) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAd());
    }

    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    final BannerAd ad = _bannerAd!;

    return Container(
      width: double.infinity,
      color: widget.backgroundColor,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}

/// Tells in-content ads whether their tab is the one on screen. The main
/// shell keeps every tab alive in an IndexedStack (so a running quiz keeps
/// its state); without this, hidden tabs would load and hold ads nobody
/// sees. Screens outside the shell have no [TabVisibility] and count as
/// visible.
class TabVisibility extends InheritedWidget {
  const TabVisibility({super.key, required this.visible, required super.child});

  final bool visible;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabVisibility>()?.visible ??
      true;

  @override
  bool updateShouldNotify(TabVisibility oldWidget) =>
      visible != oldWidget.visible;
}
