import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/traffic_provider.dart';
import '../utils/translations.dart';
import '../utils/theme_constants.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/motion.dart';
import '../ads/ad_service.dart';
import '../ads/native_ad_widget.dart';
import 'sign_details_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final String category;
  final String categoryName;
  final String countryId;

  const CategoriesScreen({
    super.key,
    required this.category,
    required this.categoryName,
    required this.countryId,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBackground(
      appBar: AppBar(title: Text(widget.categoryName)),
      child: Consumer<TrafficDataProvider>(
        builder: (context, provider, child) {
          final signs = provider.getSignsByCategory(widget.category);
          final filteredSigns = signs.where((s) {
            return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.meaning.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              // Lesson header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: FadeSlideIn(
                  child: _LessonHeader(
                    title: widget.categoryName,
                    count: signs.length,
                    signId: signs.isNotEmpty ? signs.first.id : 'stop',
                  ),
                ),
              ),
              // In-feed native ad between the lesson header and the signs.
              const NativeAdWidget(padding: EdgeInsets.fromLTRB(16, 6, 16, 0)),
              // Category Sign Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  borderRadius: 14,
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: context.tr('search_sign'),
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black45,
                      ),
                      border: InputBorder.none,
                      icon: Icon(
                        Icons.search_rounded,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Signs Grid
              Expanded(
                child: filteredSigns.isEmpty
                    ? Center(
                        child: Text(
                          "No signs found",
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      )
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.9,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: filteredSigns.length,
                        itemBuilder: (context, index) {
                          final sign = filteredSigns[index];
                          return FadeSlideIn(
                            index: index,
                            child: GlassCard(
                              onTap: () {
                                AdService.instance.registerAction();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignDetailsScreen(
                                      sign: sign,
                                      countryId: widget.countryId,
                                    ),
                                  ),
                                );
                              },
                              padding: const EdgeInsets.all(12),
                              borderRadius: 16,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Programmatic Vector Sign with Hero
                                  Hero(
                                    tag: 'sign-${sign.id}',
                                    child: SpinningSign(
                                      signId: sign.id,
                                      size: 72,
                                      delay: Duration(
                                        milliseconds: 700 * (index % 6),
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
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LessonHeader extends StatelessWidget {
  const _LessonHeader({
    required this.title,
    required this.count,
    required this.signId,
  });

  final String title;
  final int count;
  final String signId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF0E4C92)],
        ),
      ),
      child: Row(
        children: [
          SpinningSign(signId: signId, size: 64, isGlowing: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count signs in this lesson · tap any sign to learn it',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.school_rounded, color: ThemeConstants.signalYellow),
        ],
      ),
    );
  }
}
