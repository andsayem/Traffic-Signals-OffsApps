import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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

  void _loadAd() {
    if (_hasRequested) return;
    _hasRequested = true;

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
