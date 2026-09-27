import 'package:flutter/material.dart';
import '../ads/ad_service.dart';
import '../utils/theme_constants.dart';
import 'glass_card.dart';

/// Offers a rewarded interstitial in exchange for
/// [AdService.adFreeDuration] without ads. Hidden for Pro users by the
/// caller.
class AdFreeRewardCard extends StatefulWidget {
  const AdFreeRewardCard({super.key});

  @override
  State<AdFreeRewardCard> createState() => _AdFreeRewardCardState();
}

class _AdFreeRewardCardState extends State<AdFreeRewardCard> {
  bool _isShowing = false;

  Future<void> _watchAd() async {
    final ads = AdService.instance;
    if (!ads.isRewardedInterstitialReady) {
      _showSnack('Ad is not ready yet. Please try again in a moment.');
      return;
    }
    setState(() => _isShowing = true);
    final rewarded = await ads.showRewardedInterstitialForAdFree();
    if (!mounted) return;
    setState(() => _isShowing = false);
    if (rewarded) {
      _showSnack('Ads removed for ${AdService.adFreeDuration.inMinutes} minutes. Enjoy!');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minutes = AdService.adFreeDuration.inMinutes;

    return ValueListenableBuilder<bool>(
      valueListenable: AdService.instance.adsHidden,
      builder: (context, _, _) {
        final remaining = AdService.instance.adFreeRemaining;
        final active = remaining != null;
        final subtitle = active
            ? 'Ad-free for ${remaining.inMinutes + 1} more min'
            : 'Watch a short ad to go ad-free for $minutes minutes';

        return GlassCard(
          onTap: active || _isShowing ? null : _watchAd,
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ThemeConstants.signalGreen.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  active ? Icons.check_circle_rounded : Icons.ondemand_video_rounded,
                  color: ThemeConstants.signalGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remove Ads for Free',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: isDark ? Colors.white : ThemeConstants.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : ThemeConstants.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isShowing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (!active)
                const Icon(Icons.play_circle_fill_rounded, color: ThemeConstants.signalGreen),
            ],
          ),
        );
      },
    );
  }
}
