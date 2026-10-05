import 'package:flutter/material.dart';

import '../../ads/ad_service.dart';

import '../data/levels.dart';
import '../data/vehicles.dart';
import '../l10n/strings.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'assembly_screen.dart';

/// The difficulty ladder for one vehicle.
class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key, required this.vehicle, required this.paint});

  final Vehicle vehicle;
  final Color paint;

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  @override
  void initState() {
    super.initState();
    // Ready for the "unlock with an ad" offer on locked levels.
    AdService.instance.preloadRewarded();
  }

  Future<void> _play(Level level) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AssemblyScreen(
          vehicle: widget.vehicle,
          level: level,
          paint: widget.paint,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  /// Locked level: offer to unlock it by watching a rewarded ad.
  Future<void> _offerUnlock(Level level) async {
    if (AdService.instance.isProUser) {
      // Paid users never have to watch ads: just open the level.
      await Progress.unlockWithAd(widget.vehicle.id, level.number);
      if (mounted) setState(() {});
      return;
    }
    final watch = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        icon: const Icon(
          Icons.ondemand_video_rounded,
          color: AppColors.accent,
          size: 36,
        ),
        title: Text(tr('unlock_title', {'n': level.number})),
        content: Text(
          tr('unlock_body', {'n': level.number - 1}),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(tr('watch_ad')),
          ),
        ],
      ),
    );
    if (watch != true || !mounted) return;
    final ads = AdService.instance;
    if (!ads.isRewardedReady) {
      ads.preloadRewarded();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('ad_not_ready'))),
      );
      return;
    }
    if (!await ads.showRewarded()) return;
    await Progress.unlockWithAd(widget.vehicle.id, level.number);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('unlocked_msg', {'n': level.number}))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    return Scaffold(
      body: DecoratedBox(
        decoration: garageGradient,
        child: SafeArea(
          child: Column(
            children: [
              ScreenBar(
                title: tr('levels_title', {'v': vehicleName(v)}),
                subtitle:
                    '${Progress.totalStars(v.id)} / ${levels.length * 3} ★',
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: levels.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final level = levels[i];
                    final open = Progress.unlocked(v.id, level.number);
                    final best = Progress.bestScore(v.id, level.number);
                    return _LevelCard(
                      level: level,
                      open: open,
                      stars: Progress.stars(v.id, level.number),
                      best: best,
                      onTap: open
                          ? () => _play(level)
                          : () => _offerUnlock(level),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.open,
    required this.stars,
    required this.best,
    required this.onTap,
  });

  final Level level;
  final bool open;
  final int stars;
  final int? best;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Difficulty bar: one segment per level number.
    final difficulty = Row(
      children: [
        for (var i = 1; i <= levels.length; i++)
          Container(
            width: 14,
            height: 5,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: i <= level.number
                  ? Color.lerp(
                      const Color(0xFF66BB6A),
                      const Color(0xFFEF5350),
                      (level.number - 1) / (levels.length - 1),
                    )
                  : Colors.white12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
    return Opacity(
      opacity: open ? 1 : 0.5,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: open ? AppColors.accent : AppColors.panel,
                  foregroundColor: Colors.black,
                  child: open
                      ? Text(
                          '${level.number}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : const Icon(Icons.lock_rounded, color: AppColors.muted),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('level_n', {'n': level.number}),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        open
                            ? tr('lvl_desc_${level.number}')
                            : tr('level_locked', {'n': level.number - 1}),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      difficulty,
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StarRow(filled: stars, size: 20),
                    if (best != null)
                      Text(
                        tr('best_score', {'n': best!}),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
