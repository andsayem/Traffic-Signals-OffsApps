import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/country_model.dart';
import '../providers/traffic_provider.dart';
import '../utils/translations.dart';
import '../utils/theme_constants.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  CountryModel? _countryA;
  CountryModel? _countryB;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TrafficDataProvider>(context, listen: false);
    if (provider.allCountries.isNotEmpty) {
      _countryA = provider.allCountries[0]; // Bangladesh by default
      if (provider.allCountries.length > 1) {
        _countryB = provider.allCountries[1]; // India by default
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<TrafficDataProvider>(context);
    final countries = provider.allCountries;

    return AppBackground(
      appBar: AppBar(
        title: Text(context.tr('compare_countries')),
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Selectors Row
          Row(
            children: [
              // Selector Country A
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  borderRadius: 14,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CountryModel>(
                      isExpanded: true,
                      value: _countryA,
                      dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                      items: countries.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                            "${c.flagEmoji} ${c.name}",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _countryA = val;
                        });
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),
              
              const Icon(Icons.compare_arrows_rounded, color: ThemeConstants.signalRed),

              const SizedBox(width: 12),

              // Selector Country B
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  borderRadius: 14,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CountryModel>(
                      isExpanded: true,
                      value: _countryB,
                      dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                      items: countries.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                            "${c.flagEmoji} ${c.name}",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _countryB = val;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (_countryA != null && _countryB != null) ...[
            // Side by Side Stats
            Text(
              context.tr('comparison'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            _buildComparisonRow(
              context,
              labelKey: 'driving_side',
              valA: _countryA!.drivingSide,
              valB: _countryB!.drivingSide,
              icon: Icons.directions_car_rounded,
              highlightDifferent: true,
            ),
            _buildComparisonRow(
              context,
              labelKey: 'emergency_no',
              valA: _countryA!.emergencyNumber,
              valB: _countryB!.emergencyNumber,
              icon: Icons.phone_in_talk_rounded,
            ),
            _buildComparisonRow(
              context,
              labelKey: 'speed_city',
              valA: _countryA!.speedLimitCity,
              valB: _countryB!.speedLimitCity,
              icon: Icons.speed_rounded,
            ),
            _buildComparisonRow(
              context,
              labelKey: 'speed_highway',
              valA: _countryA!.speedLimitHighway,
              valB: _countryB!.speedLimitHighway,
              icon: Icons.add_road_rounded,
            ),
            _buildComparisonRow(
              context,
              labelKey: 'alcohol_limit',
              valA: _countryA!.alcoholLimit,
              valB: _countryB!.alcoholLimit,
              icon: Icons.local_bar_rounded,
              highlightDifferent: true,
            ),

            const SizedBox(height: 24),

            // Country A General Summary
            Text(
              "${_countryA!.flagEmoji} ${_countryA!.name} Quick Tips",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            _buildTipsCard(context, _countryA!),

            const SizedBox(height: 20),

            // Country B General Summary
            Text(
              "${_countryB!.flagEmoji} ${_countryB!.name} Quick Tips",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            _buildTipsCard(context, _countryB!),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    BuildContext context, {
    required String labelKey,
    required String valA,
    required String valB,
    required IconData icon,
    bool highlightDifferent = false,
  }) {
    final isDifferent = highlightDifferent && (valA != valB);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        customBorderColor: isDifferent ? ThemeConstants.signalYellow.withValues(alpha: 0.5) : null,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: ThemeConstants.signalYellow),
                const SizedBox(width: 8),
                Text(
                  context.tr(labelKey),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white60),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    valA,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDifferent ? ThemeConstants.signalYellow : Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.white24,
                ),
                Expanded(
                  child: Text(
                    valB,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDifferent ? ThemeConstants.signalYellow : Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context, CountryModel country) {
    return GlassCard(
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: country.tips.map((t) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.circle, size: 6, color: ThemeConstants.signalRed),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
