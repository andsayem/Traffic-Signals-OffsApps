import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/traffic_provider.dart';
import '../utils/translations.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/traffic_sign_painter.dart';
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
      appBar: AppBar(
        title: Text(widget.categoryName),
      ),
      child: Consumer<TrafficDataProvider>(
        builder: (context, provider, child) {
          final signs = provider.getSignsByCategory(widget.category);
          final filteredSigns = signs.where((s) {
            return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.meaning.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              // Category Sign Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                          style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      )
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.9,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredSigns.length,
                        itemBuilder: (context, index) {
                          final sign = filteredSigns[index];
                          return GlassCard(
                            onTap: () {
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
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
