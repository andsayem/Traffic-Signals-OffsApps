import 'package:flutter/material.dart';
import '../models/country_model.dart';
import '../utils/translations.dart';
import '../utils/theme_constants.dart';
import 'glass_card.dart';

class CountryCard extends StatelessWidget {
  final CountryModel country;
  final VoidCallback onTap;

  const CountryCard({
    super.key,
    required this.country,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12.0),
      borderRadius: 18.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Country Flag Emoji with Hero for smooth details transition
              Hero(
                tag: 'flag-${country.id}',
                child: Text(
                  country.flagEmoji,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
              // Driving side icon helper
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ThemeConstants.signalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  country.drivingSide.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: ThemeConstants.signalBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            country.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            "${context.tr('speed_highway')}: ${country.speedLimitHighway}",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
