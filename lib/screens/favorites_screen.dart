import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/traffic_provider.dart';
import '../utils/translations.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/traffic_sign_painter.dart';
import 'sign_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBackground(
      appBar: AppBar(
        title: Text(context.tr('favorites')),
      ),
      child: Consumer<TrafficDataProvider>(
        builder: (context, provider, child) {
          final favorites = provider.favoriteSigns;

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Dimmed vector sign placeholder (no parking or stop)
                  Opacity(
                    opacity: 0.25,
                    child: const TrafficSignWidget(
                      signId: 'no_parking',
                      size: 100,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.tr('no_favorites'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.9,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final sign = favorites[index];
              return GlassCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignDetailsScreen(
                        sign: sign,
                        countryId: 'usa', // Default back context
                      ),
                    ),
                  ).then((_) {
                    // Refresh favorites list if toggled off inside details
                    provider.refreshFromStorage();
                  });
                },
                padding: const EdgeInsets.all(12),
                borderRadius: 16,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'sign-${sign.id}',
                      child: TrafficSignWidget(
                        signId: sign.id,
                        size: 70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      sign.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
