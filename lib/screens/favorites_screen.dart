import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/traffic_provider.dart';
import '../utils/translations.dart';
import '../utils/theme_constants.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/motion.dart';
import '../ads/native_ad_widget.dart';
import 'sign_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, this.onBrowse});

  /// Takes the user to Home to find signs (shown on the empty state).
  final VoidCallback? onBrowse;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBackground(
      appBar: AppBar(title: Text(context.tr('favorites'))),
      child: Consumer<TrafficDataProvider>(
        builder: (context, provider, child) {
          final favorites = provider.favoriteSigns;

          if (favorites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            ThemeConstants.signalRed.withValues(alpha: 0.22),
                            ThemeConstants.signalRed.withValues(alpha: 0),
                          ],
                        ),
                      ),
                      child: const Opacity(
                        opacity: 0.8,
                        child: SpinningSign(signId: 'no_parking', size: 110),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.tr('no_favorites'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 16,
                          color: ThemeConstants.signalRed,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tap the heart on any sign to save it here',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    if (onBrowse != null) ...[
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: onBrowse,
                        style: FilledButton.styleFrom(
                          backgroundColor: ThemeConstants.signalRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.school_rounded),
                        label: const Text(
                          'Browse road signs',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Saved signs',
                  subtitle: '${favorites.length} signs to revise',
                  icon: Icons.favorite_rounded,
                  color: ThemeConstants.signalRed,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final sign = favorites[index];
                    return FadeSlideIn(
                      index: index,
                      child: GlassCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignDetailsScreen(
                                sign: sign,
                                countryId: provider.selectedCountry.id,
                              ),
                            ),
                          ).then((_) {
                            // Refresh if the favorite was toggled off inside details.
                            provider.refreshFromStorage();
                          });
                        },
                        padding: const EdgeInsets.all(12),
                        borderRadius: 20,
                        child: Stack(
                          children: [
                            const Positioned(
                              top: 0,
                              right: 0,
                              child: Icon(
                                Icons.favorite_rounded,
                                size: 16,
                                color: ThemeConstants.signalRed,
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Hero(
                                    tag: 'sign-${sign.id}',
                                    child: SpinningSign(
                                      signId: sign.id,
                                      size: 72,
                                      delay: Duration(
                                        milliseconds: 800 * index,
                                      ),
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
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: favorites.length),
                ),
              ),
              const SliverToBoxAdapter(
                child: NativeAdWidget(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 100),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
