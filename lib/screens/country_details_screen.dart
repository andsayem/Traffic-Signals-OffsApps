import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/country_model.dart';
import '../providers/traffic_provider.dart';
import '../utils/translations.dart';
import '../utils/theme_constants.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/traffic_sign_painter.dart';
import 'sign_details_screen.dart';

class CountryDetailsScreen extends StatelessWidget {
  final CountryModel country;

  const CountryDetailsScreen({
    super.key,
    required this.country,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 6,
      child: AppBackground(
        appBar: AppBar(
          title: Text(country.name),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Hero(
                tag: 'flag-${country.id}',
                child: Text(
                  country.flagEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            physics: const BouncingScrollPhysics(),
            indicatorColor: ThemeConstants.signalYellow,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: context.tr('overview') != 'overview' ? context.tr('overview') : 'Overview'),
              Tab(text: context.tr('warning').split(' ').first),
              Tab(text: context.tr('regulatory').split(' ').first),
              Tab(text: context.tr('mandatory').split(' ').first),
              Tab(text: context.tr('information').split(' ').first),
              Tab(text: context.tr('signal_light').split(' ').first),
            ],
          ),
        ),
        child: Consumer<TrafficDataProvider>(
          builder: (context, provider, child) {
            return TabBarView(
              physics: const BouncingScrollPhysics(),
              children: [
                // Tab 1: Overview (driving info and tips)
                _buildOverviewTab(context, isDark),

                // Tab 2: Warning Signs
                _buildSignsGrid(context, provider, 'warning', country.id),

                // Tab 3: Regulatory Signs
                _buildSignsGrid(context, provider, 'regulatory', country.id),

                // Tab 4: Mandatory Signs
                _buildSignsGrid(context, provider, 'mandatory', country.id),

                // Tab 5: Information Signs
                _buildSignsGrid(context, provider, 'information', country.id),

                // Tab 6: Signal Lights
                _buildSignsGrid(context, provider, 'signal_light', country.id),
              ],
            );
          },
        ),
      ),
    );
  }

  // Build Overview Tab (General information and rules/tips)
  Widget _buildOverviewTab(BuildContext context, bool isDark) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Country Profile Card
        GlassCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    country.flagEmoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      country.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                country.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              
              // Key Stats grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildStatItem(context, Icons.directions_car_rounded, 'driving_side', country.drivingSide),
                  _buildStatItem(context, Icons.phone_in_talk_rounded, 'emergency_no', country.emergencyNumber),
                  _buildStatItem(context, Icons.speed_rounded, 'speed_city', country.speedLimitCity),
                  _buildStatItem(context, Icons.add_road_rounded, 'speed_highway', country.speedLimitHighway),
                  _buildStatItem(context, Icons.local_bar_rounded, 'alcohol_limit', country.alcoholLimit),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Rules & Tips Header
        Text(
          context.tr('general_rules'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeConstants.signalRed,
              ),
        ),
        const SizedBox(height: 12),
        
        // Tips List
        ...country.tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                borderRadius: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: ThemeConstants.signalGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
            
        const SizedBox(height: 40),
      ],
    );
  }

  // Build Grid for Traffic Signs inside Tabs
  Widget _buildSignsGrid(
    BuildContext context,
    TrafficDataProvider provider,
    String categoryId,
    String countryId,
  ) {
    final signs = provider.getSignsByCategory(categoryId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (signs.isEmpty) {
      return Center(
        child: Text(
          "No signs found",
          style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
        ),
      );
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: signs.length,
      itemBuilder: (context, index) {
        final sign = signs[index];
        return GlassCard(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SignDetailsScreen(
                  sign: sign,
                  countryId: countryId,
                ),
              ),
            );
          },
          padding: const EdgeInsets.all(12),
          borderRadius: 16,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'sign-${sign.id}-$countryId',
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
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String labelKey,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: ThemeConstants.signalYellow),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.tr(labelKey),
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
