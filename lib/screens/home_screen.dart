import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/traffic_provider.dart';
import '../utils/translations.dart';
import '../utils/theme_constants.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/country_card.dart';
import '../widgets/traffic_sign_painter.dart';
import 'country_details_screen.dart';
import 'comparison_screen.dart';
import 'sign_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBackground(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App Logo - A tiny vector red/yellow/green signal dot indicator
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: ThemeConstants.signalRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: ThemeConstants.signalYellow,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: ThemeConstants.signalGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Text(
              context.tr('app_title'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ComparisonScreen()),
              );
            },
            tooltip: context.tr('compare_countries'),
          ),
        ],
      ),
      child: Consumer<TrafficDataProvider>(
        builder: (context, provider, child) {
          final recent = provider.recentCountries;
          final filtered = provider.filteredCountries;
          // Take a few signs as featured
          final featuredSigns = provider.allSigns.take(6).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Search Field
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    borderRadius: 16,
                    child: TextField(
                      onChanged: (val) {
                        provider.setCountryQuery(val);
                        provider.setSignQuery(val);
                      },
                      decoration: InputDecoration(
                        hintText: "Search countries or road signs...",
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
              ),

              // If searching, display search results sections
              if (provider.countryQuery.isNotEmpty) ...[
                // Countries Search Section
                if (provider.filteredCountries.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        "Countries",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ThemeConstants.signalRed,
                            ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.25,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final c = provider.filteredCountries[index];
                          return CountryCard(
                            country: c,
                            onTap: () {
                              provider.addRecentCountry(c.id);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CountryDetailsScreen(country: c),
                                ),
                              );
                            },
                          );
                        },
                        childCount: provider.filteredCountries.length,
                      ),
                    ),
                  ),
                ],

                // Signs Search Section
                if (provider.filteredSigns.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        "Road Signs",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ThemeConstants.signalBlue,
                            ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.95,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final s = provider.filteredSigns[index];
                          return GlassCard(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignDetailsScreen(
                                    sign: s,
                                    countryId: 'usa',
                                  ),
                                ),
                              );
                            },
                            padding: const EdgeInsets.all(12),
                            borderRadius: 16,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TrafficSignWidget(
                                  signId: s.id,
                                  size: 65,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  s.name,
                                  style: const TextStyle(
                                    fontSize: 12,
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
                        childCount: provider.filteredSigns.length,
                      ),
                    ),
                  ),
                ],

                if (provider.filteredCountries.isEmpty && provider.filteredSigns.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          "No countries or road signs match your query",
                          style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ),
                  ),
              ] else ...[
                // Default View (No Search Query)
                
                // Country Comparison Quick Access Card
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  sliver: SliverToBoxAdapter(
                    child: GlassCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ComparisonScreen()),
                        );
                      },
                      padding: const EdgeInsets.all(16),
                      borderRadius: 16,
                      customColor: ThemeConstants.signalBlue.withOpacity(0.12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.compare_rounded,
                            size: 32,
                            color: ThemeConstants.signalBlue,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('compare_countries'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark ? Colors.white : ThemeConstants.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Compare speed limits, rules & signs",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : ThemeConstants.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: ThemeConstants.signalBlue,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Recently Viewed section
                if (recent.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Text(
                            context.tr('recent_countries'),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: ThemeConstants.signalRed,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: recent.length,
                            itemBuilder: (context, index) {
                              final c = recent[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: GlassCard(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CountryDetailsScreen(country: c),
                                      ),
                                    );
                                  },
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  borderRadius: 14,
                                  child: Row(
                                    children: [
                                      Text(
                                        c.flagEmoji,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        c.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                // Country Grid
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      context.tr('popular_countries'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.25,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final c = filtered[index];
                        return CountryCard(
                          country: c,
                          onTap: () {
                            provider.addRecentCountry(c.id);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CountryDetailsScreen(country: c),
                              ),
                            );
                          },
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),

                // Featured Traffic Signs (Horizontal study cards)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      context.tr('featured_signs'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 160,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: featuredSigns.length,
                      itemBuilder: (context, index) {
                        final s = featuredSigns[index];
                        return Container(
                          width: 140,
                          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: GlassCard(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignDetailsScreen(
                                    sign: s,
                                    countryId: 'usa',
                                  ),
                                ),
                              );
                            },
                            padding: const EdgeInsets.all(12),
                            borderRadius: 16,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TrafficSignWidget(
                                  signId: s.id,
                                  size: 60,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  s.name,
                                  style: const TextStyle(
                                    fontSize: 12,
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
                ),
              ],

              // Safe padding space for bottom navigation bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
    );
  }
}
