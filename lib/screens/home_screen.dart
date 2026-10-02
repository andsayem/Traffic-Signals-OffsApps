import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:traffic_signal_symbols/ads/adaptive_banner_ad_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ads/ad_service.dart';
import '../ads/native_ad_widget.dart';
import '../models/country_model.dart';
import '../models/traffic_sign_model.dart';
import '../game/car_assembly_game.dart';
import '../providers/app_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/traffic_provider.dart';
import '../services/storage_service.dart';
import '../utils/translations.dart';
import '../utils/theme_constants.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/coach_tour.dart';
import '../widgets/motion.dart';
import '../widgets/traffic_sign_painter.dart';
import 'categories_screen.dart';
import 'country_details_screen.dart';
import 'comparison_screen.dart';
import 'sign_details_screen.dart';
import 'subscription_screen.dart';

/// Learning categories shown on Home, in teaching order.
class _Category {
  const _Category(this.id, this.color, this.icon);
  final String id;
  final Color color;
  final IconData icon;
}

const _categories = [
  _Category('regulatory', ThemeConstants.signalRed, Icons.block_rounded),
  _Category(
    'warning',
    ThemeConstants.signalOrange,
    Icons.warning_amber_rounded,
  ),
  _Category('mandatory', ThemeConstants.signalBlue, Icons.turn_right_rounded),
  _Category('signal_light', ThemeConstants.signalGreen, Icons.traffic_rounded),
  _Category('information', Color(0xFF5856D6), Icons.info_rounded),
  _Category('safety', Color(0xFF00A6A6), Icons.health_and_safety_rounded),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onStartQuiz});

  /// Switches the bottom navigation to the Quiz tab.
  final VoidCallback? onStartQuiz;

  // Targets for the first-run guided tour.
  static final _heroKey = GlobalKey();
  static final _pathKey = GlobalKey();
  static final _learnKey = GlobalKey();
  static final _helpKey = GlobalKey();

  /// Spotlight tour explaining Home and the tabs. Shown once on first run
  /// and whenever the user taps the help button.
  static void startTour(BuildContext context) {
    Future<void> reveal(GlobalKey key) async {
      final ctx = key.currentContext;
      if (ctx == null) return;
      await Scrollable.ensureVisible(
        ctx,
        alignment: 0.2,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }

    final steps = [
      CoachStep(
        targetKey: _heroKey,
        title: 'Your country',
        body:
            'We picked your country from your phone. All signs and rules '
            'follow this country. Wrong one? Tap "Change".',
        icon: Icons.public_rounded,
        color: ThemeConstants.signalBlue,
      ),
      CoachStep(
        targetKey: _pathKey,
        title: 'Your learning path',
        body:
            'Just follow these 3 steps. Each one turns green when done — '
            'tap the button on a step to do it.',
        icon: Icons.route_rounded,
        color: ThemeConstants.signalGreen,
      ),
      CoachStep(
        targetKey: _learnKey,
        title: 'Learn road signs',
        body:
            'Tap "Learn" to start. The cards below are lessons — each '
            'shows how many signs you have learned.',
        icon: Icons.school_rounded,
        color: ThemeConstants.signalRed,
      ),
      CoachStep(
        fallbackRect: (s) => Rect.fromLTWH(12, s.height - 96, s.width - 24, 84),
        title: 'Tabs at the bottom',
        body:
            'Home: learn · Quiz: test yourself · Favorites: signs you '
            'saved with ♥ · Settings: language, theme and more.',
        icon: Icons.touch_app_rounded,
        color: ThemeConstants.signalOrange,
      ),
      CoachStep(
        targetKey: _helpKey,
        title: 'Need help later?',
        body: 'Tap this ? button any time to see this guide again.',
        icon: Icons.help_rounded,
        color: ThemeConstants.signalYellow,
      ),
    ];

    CoachTour.show(
      context,
      steps,
      beforeStep: (i) async {
        final key = steps[i].targetKey;
        if (key != null && key != _helpKey) await reveal(key);
        if (key == _helpKey) await reveal(_heroKey); // scroll back to top
      },
      onFinish: StorageService.setHomeTourDone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPro = context.watch<SubscriptionProvider>().isPro;

    return AppBackground(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _TrafficLightBadge(),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                context.tr('app_title'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!isPro)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => SubscriptionScreen.show(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        ThemeConstants.signalYellow,
                        ThemeConstants.signalOrange,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.block_rounded, color: Colors.white, size: 15),
                      SizedBox(width: 4),
                      Text(
                        'NO ADS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            key: _helpKey,
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => startTour(context),
            tooltip: 'How to use',
          ),
        ],
      ),
      child: Consumer<TrafficDataProvider>(
        builder: (context, provider, child) {
          final country = provider.selectedCountry;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: _SearchField(provider: provider, isDark: isDark),
                ),
              ),

              if (provider.countryQuery.isNotEmpty)
                ..._buildSearchResults(context, provider, country, isDark)
              else ...[
                // 1. Your country (auto-detected)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: FadeSlideIn(
                      child: _CountryHero(
                        key: _heroKey,
                        country: country,
                        autoDetected: provider.isCountryAutoDetected,
                        onOpen: () => _openCountryDetails(context, country),
                        onChange: () => _pickCountry(context, provider),
                        onLearn: () =>
                            _continueLearning(context, provider, country),
                        learned: provider.learnedCount,
                        total: provider.allSigns.length,
                      ),
                    ),
                  ),
                ),

                // Big banner ad as the second section, visible without scrolling
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: AdaptiveBannerAdWidget(),
                  ),
                ),

                // Play & learn: the Car Assembly mini-game
                const SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Play & Learn',
                    subtitle: 'Build vehicles part by part in 3D',
                    icon: Icons.sports_esports_rounded,
                    color: ThemeConstants.signalOrange,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: FadeSlideIn(
                      child: _GameCard(
                        onPlay: () => CarAssemblyGame.open(
                          context,
                          hostLanguage: context
                              .read<AppProvider>()
                              .languageCode,
                        ),
                      ),
                    ),
                  ),
                ),

                // Guided next steps for new users
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: FadeSlideIn(
                      index: 1,
                      child: _LearningPath(
                        key: _pathKey,
                        countryConfirmed: !provider.isCountryAutoDetected,
                        learned: provider.learnedCount,
                        quizzes: provider.quizzesDone,
                        onConfirmCountry: provider.confirmCountry,
                        onLearn: () =>
                            _continueLearning(context, provider, country),
                        onQuiz: onStartQuiz,
                      ),
                    ),
                  ),
                ),

                // 2. Learning — the main focus of Home
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Start Learning',
                    subtitle:
                        '${provider.allSigns.length} road signs · '
                        '${_categories.length} categories',
                    icon: Icons.school_rounded,
                    color: ThemeConstants.signalGreen,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: FadeSlideIn(
                      index: 1,
                      child: _LearningBanner(
                        key: _learnKey,
                        country: country,
                        signCount: provider.allSigns.length,
                        learnedCount: provider.learnedCount,
                        onBrowse: () =>
                            _continueLearning(context, provider, country),
                        onQuiz: onStartQuiz,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.05,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final cat = _categories[index];
                      final signs = provider.getSignsByCategory(cat.id);
                      return FadeSlideIn(
                        index: index + 2,
                        child: _CategoryTile(
                          category: cat,
                          signs: signs,
                          learned: provider.learnedInCategory(cat.id),
                          delay: Duration(milliseconds: 900 * index),
                          onTap: () => _openCategory(context, cat, country),
                        ),
                      );
                    }, childCount: _categories.length),
                  ),
                ),

                // 3. Featured signs — 360° spinning cards
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: context.tr('featured_signs'),
                    icon: Icons.auto_awesome_rounded,
                    color: ThemeConstants.signalYellow,
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 170,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: 8,
                      itemBuilder: (context, index) {
                        final s = provider
                            .allSigns[(index * 5) % provider.allSigns.length];
                        return FadeSlideIn(
                          index: index,
                          child: _FeaturedSignCard(
                            sign: s,
                            delay: Duration(milliseconds: 700 * index),
                            onTap: () => _openSign(context, s, country),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 5. Compare
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _CompareCard(isDark: isDark),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: NativeAdWidget(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: _DisclaimerFooter(
                      provider: provider,
                      isDark: isDark,
                    ),
                  ),
                ),
              ],

              // Space for the floating bottom navigation bar
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildSearchResults(
    BuildContext context,
    TrafficDataProvider provider,
    CountryModel country,
    bool isDark,
  ) {
    return [
      if (provider.filteredSigns.isNotEmpty) ...[
        const SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Road Signs',
            icon: Icons.signpost_rounded,
            color: ThemeConstants.signalBlue,
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
            delegate: SliverChildBuilderDelegate((context, index) {
              final s = provider.filteredSigns[index];
              return GlassCard(
                onTap: () => _openSign(context, s, country),
                padding: const EdgeInsets.all(12),
                borderRadius: 16,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TrafficSignWidget(signId: s.id, size: 65),
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
            }, childCount: provider.filteredSigns.length),
          ),
        ),
      ],
      if (provider.filteredSigns.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Opacity(
                    opacity: 0.5,
                    child: SpinningSign(signId: 'no_entry', size: 80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No road signs match your search',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  void _openSign(
    BuildContext context,
    TrafficSignModel sign,
    CountryModel country,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SignDetailsScreen(sign: sign, countryId: country.id),
      ),
    );
  }

  void _openCategory(
    BuildContext context,
    _Category cat,
    CountryModel country,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriesScreen(
          category: cat.id,
          categoryName: context.tr(cat.id) == cat.id
              ? 'Safety Signs'
              : context.tr(cat.id),
          countryId: country.id,
        ),
      ),
    );
  }

  /// Opens the next sign the user hasn't learned yet (lesson order), or
  /// the first lesson when everything is already learned.
  void _continueLearning(
    BuildContext context,
    TrafficDataProvider provider,
    CountryModel country,
  ) {
    final next = provider.nextSignToLearn([for (final c in _categories) c.id]);
    if (next == null) {
      _openCategory(context, _categories.first, country);
    } else {
      _openSign(context, next, country);
    }
  }

  void _pickCountry(BuildContext context, TrafficDataProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CountryPickerSheet(
        countries: provider.allCountries,
        selectedId: provider.selectedCountry.id,
        onSelect: (id) {
          provider.selectCountry(id);
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  void _openCountryDetails(BuildContext context, CountryModel country) {
    context.read<TrafficDataProvider>().addRecentCountry(country.id);
    AdService.instance.showInterstitial(
      onDismissed: () {
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CountryDetailsScreen(country: country),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Pieces
// ---------------------------------------------------------------------------

class _TrafficLightBadge extends StatelessWidget {
  const _TrafficLightBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in const [
            ThemeConstants.signalRed,
            ThemeConstants.signalYellow,
            ThemeConstants.signalGreen,
          ])
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: c.withValues(alpha: 0.7), blurRadius: 4),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.provider, required this.isDark});

  final TrafficDataProvider provider;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      borderRadius: 18,
      child: TextField(
        onChanged: (val) {
          provider.setCountryQuery(val);
          provider.setSignQuery(val);
        },
        decoration: InputDecoration(
          hintText: 'Search road signs...',
          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
          border: InputBorder.none,
          icon: Icon(
            Icons.search_rounded,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
      ),
    );
  }
}

/// Big card for the user's (auto-detected) country.
class _CountryHero extends StatelessWidget {
  const _CountryHero({
    super.key,
    required this.country,
    required this.autoDetected,
    required this.onOpen,
    required this.onChange,
    required this.onLearn,
    required this.learned,
    required this.total,
  });

  final CountryModel country;
  final bool autoDetected;
  final VoidCallback onOpen;
  final VoidCallback onChange;

  /// Opens the next sign to learn.
  final VoidCallback onLearn;
  final int learned, total;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F766E), Color(0xFF0E4C92)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0E4C92).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        autoDetected
                            ? Icons.my_location_rounded
                            : Icons.check_circle_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        autoDetected ? 'Auto-detected' : 'Your country',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onChange,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 15,
                          color: Color(0xFF0E4C92),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Change',
                          style: TextStyle(
                            color: Color(0xFF0E4C92),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Spin360(
                  duration: const Duration(milliseconds: 7000),
                  child: Text(
                    country.flagEmoji,
                    style: const TextStyle(fontSize: 52),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        country.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Drives on the ${country.drivingSide.toLowerCase()} · '
                        'Emergency ${country.emergencyNumber}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _HeroStat(
                  icon: Icons.location_city_rounded,
                  label: 'City',
                  value: country.speedLimitCity,
                ),
                const SizedBox(width: 8),
                _HeroStat(
                  icon: Icons.add_road_rounded,
                  label: 'Highway',
                  value: country.speedLimitHighway,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Main call to action: jump straight into the next lesson.
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onLearn,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0E4C92),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(
                  learned == 0
                      ? Icons.school_rounded
                      : Icons.play_circle_fill_rounded,
                ),
                label: Text(
                  learned == 0
                      ? 'Start Learning ${country.name} Signs'
                      : 'Continue Learning · $learned/$total',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The highlighted "learn" call-to-action.
class _LearningBanner extends StatelessWidget {
  const _LearningBanner({
    super.key,
    required this.learnedCount,
    required this.country,
    required this.signCount,
    required this.onBrowse,
    required this.onQuiz,
  });

  final CountryModel country;
  final int signCount;
  final int learnedCount;
  final VoidCallback onBrowse;
  final VoidCallback? onQuiz;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ThemeConstants.signalRed, Color(0xFFB91C1C)],
        ),
        boxShadow: [
          BoxShadow(
            color: ThemeConstants.signalRed.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Master road signs\nfor ${country.name} ${country.flagEmoji}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  learnedCount == 0
                      ? 'Learn all $signCount signs, then test yourself.'
                      : 'You have learned $learnedCount of $signCount signs. Keep going!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _BannerButton(
                      label: learnedCount == 0 ? 'Learn' : 'Continue',
                      icon: Icons.menu_book_rounded,
                      filled: true,
                      onTap: onBrowse,
                    ),
                    const SizedBox(width: 8),
                    if (onQuiz != null)
                      _BannerButton(
                        label: 'Quiz',
                        icon: Icons.quiz_rounded,
                        filled: false,
                        onTap: onQuiz!,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SpinningSign(signId: 'stop', size: 92, isGlowing: true),
        ],
      ),
    );
  }
}

class _BannerButton extends StatelessWidget {
  const _BannerButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? ThemeConstants.signalRed : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: filled ? null : Border.all(color: Colors.white54),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.learned,
    required this.category,
    required this.signs,
    required this.delay,
    required this.onTap,
  });

  final _Category category;
  final List<TrafficSignModel> signs;
  final int learned;
  final Duration delay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final done = signs.isNotEmpty && learned >= signs.length;
    final name = context.tr(category.id) == category.id
        ? 'Safety Signs'
        : context.tr(category.id);
    return GlassCard(
      onTap: onTap,
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      customColor: category.color.withValues(alpha: isDark ? 0.12 : 0.10),
      customBorderColor: category.color.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (signs.isNotEmpty)
                SpinningSign(signId: signs.first.id, size: 54, delay: delay)
              else
                Icon(category.icon, size: 40, color: category.color),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: category.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${signs.length}',
                  style: TextStyle(
                    color: category.color == ThemeConstants.signalYellow
                        ? Colors.black
                        : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : ThemeConstants.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: signs.isEmpty ? 0 : learned / signs.length,
              minHeight: 5,
              color: category.color,
              backgroundColor: category.color.withValues(alpha: 0.18),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  done
                      ? 'Completed'
                      : learned == 0
                      ? 'Start lesson'
                      : 'Continue · $learned/${signs.length}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: category.color,
                  ),
                ),
              ),
              Icon(
                done ? Icons.verified_rounded : Icons.arrow_forward_rounded,
                size: 14,
                color: category.color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturedSignCard extends StatelessWidget {
  const _FeaturedSignCard({
    required this.sign,
    required this.delay,
    required this.onTap,
  });

  final TrafficSignModel sign;
  final Duration delay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        borderRadius: 20,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinningSign(signId: sign.id, size: 66, delay: delay),
            const SizedBox(height: 12),
            Text(
              sign.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ComparisonScreen()),
      ),
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      customColor: ThemeConstants.signalBlue.withValues(alpha: 0.12),
      customBorderColor: ThemeConstants.signalBlue.withValues(alpha: 0.35),
      child: Row(
        children: [
          const RotatingIcon(
            Icons.sync_alt_rounded,
            size: 30,
            color: ThemeConstants.signalBlue,
            duration: Duration(seconds: 6),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('compare_countries'),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: isDark
                        ? Colors.white
                        : ThemeConstants.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Compare speed limits, rules & signs',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white70
                        : ThemeConstants.lightTextSecondary,
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
    );
  }
}

class _CountryPickerSheet extends StatelessWidget {
  const _CountryPickerSheet({
    required this.countries,
    required this.selectedId,
    required this.onSelect,
  });

  final List<CountryModel> countries;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? ThemeConstants.darkBgStart : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SectionHeader(
              title: 'Choose your country',
              subtitle: 'Signs and rules follow this country',
              icon: Icons.public_rounded,
              color: ThemeConstants.signalBlue,
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                itemCount: countries.length,
                itemBuilder: (context, index) {
                  final c = countries[index];
                  final selected = c.id == selectedId;
                  return FadeSlideIn(
                    index: index,
                    step: const Duration(milliseconds: 35),
                    child: ListTile(
                      onTap: () => onSelect(c.id),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      tileColor: selected
                          ? ThemeConstants.signalBlue.withValues(alpha: 0.12)
                          : null,
                      leading: Text(
                        c.flagEmoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(
                        c.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'Drives on the ${c.drivingSide.toLowerCase()}',
                      ),
                      trailing: selected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: ThemeConstants.signalBlue,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerFooter extends StatelessWidget {
  const _DisclaimerFooter({required this.provider, required this.isDark});

  final TrafficDataProvider provider;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: ThemeConstants.signalYellow,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Disclaimer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: ThemeConstants.signalYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('disclaimer'),
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.link_rounded,
                color: ThemeConstants.signalBlue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('sources_title'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...[provider.selectedCountry].map(
            (c) => InkWell(
              onTap: () => launchUrl(
                Uri.parse(c.sourceUrl),
                mode: LaunchMode.externalApplication,
              ),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(c.flagEmoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        c.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        c.sourceUrl,
                        style: const TextStyle(
                          fontSize: 9,
                          color: ThemeConstants.signalBlue,
                          decoration: TextDecoration.underline,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "What do I do now?" card: three steps that tick off as the user
/// confirms their country, learns signs and takes a quiz.
class _LearningPath extends StatelessWidget {
  const _LearningPath({
    super.key,
    required this.countryConfirmed,
    required this.learned,
    required this.quizzes,
    required this.onConfirmCountry,
    required this.onLearn,
    required this.onQuiz,
  });

  static const _learnGoal = 5;

  final bool countryConfirmed;
  final int learned;
  final int quizzes;
  final VoidCallback onConfirmCountry;
  final VoidCallback onLearn;
  final VoidCallback? onQuiz;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final learnDone = learned >= _learnGoal;
    final quizDone = quizzes > 0;
    final doneCount = [
      countryConfirmed,
      learnDone,
      quizDone,
    ].where((d) => d).length;

    // All done: collapse to a compact "keep going" strip.
    if (doneCount == 3) {
      final quizWord = quizzes == 1 ? 'quiz' : 'quizzes';
      return GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(14),
        customColor: ThemeConstants.signalGreen.withValues(alpha: 0.12),
        customBorderColor: ThemeConstants.signalGreen.withValues(alpha: 0.4),
        child: Row(
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: ThemeConstants.signalYellow,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Great job! $learned signs learned · $quizzes $quizWord taken',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(onPressed: onLearn, child: const Text('Keep going')),
          ],
        ),
      );
    }

    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.route_rounded,
                color: ThemeConstants.signalGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your learning path',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? Colors.white
                        : ThemeConstants.lightTextPrimary,
                  ),
                ),
              ),
              Text(
                '$doneCount / 3 done',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: ThemeConstants.signalGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PathStep(
            number: 1,
            title: 'Confirm your country',
            subtitle: 'Signs and rules follow this country',
            done: countryConfirmed,
            active: !countryConfirmed,
            actionLabel: "Yes, it's right",
            onAction: onConfirmCountry,
          ),
          _PathStep(
            number: 2,
            title: 'Learn $_learnGoal road signs',
            subtitle: learnDone
                ? '$learned signs learned'
                : '${learned.clamp(0, _learnGoal)} of $_learnGoal · open a sign to learn it',
            done: learnDone,
            active: countryConfirmed && !learnDone,
            actionLabel: learned == 0 ? 'Start' : 'Continue',
            onAction: onLearn,
            progress: (learned / _learnGoal).clamp(0.0, 1.0),
          ),
          _PathStep(
            number: 3,
            title: 'Take a quiz',
            subtitle: 'Anytime — no need to finish learning first',
            done: quizDone,
            active: learnDone && !quizDone,
            alwaysShowAction: !quizDone,
            actionLabel: 'Quiz',
            onAction: onQuiz,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _PathStep extends StatelessWidget {
  const _PathStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.active,
    required this.actionLabel,
    required this.onAction,
    this.progress,
    this.isLast = false,
    this.alwaysShowAction = false,
  });

  final int number;
  final String title;
  final String subtitle;
  final bool done;
  final bool active;
  final String actionLabel;
  final VoidCallback? onAction;
  final double? progress;
  final bool isLast;

  /// Show the button even when this is not the current step.
  final bool alwaysShowAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const green = ThemeConstants.signalGreen;
    final idle = isDark ? Colors.white24 : Colors.black26;
    final circleColor = done
        ? green
        : (active ? ThemeConstants.signalRed : idle);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Number / tick with a connector line down to the next step
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || active ? circleColor : Colors.transparent,
                  border: Border.all(color: circleColor, width: 2),
                ),
                alignment: Alignment.center,
                child: done
                    ? const Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: Colors.white,
                      )
                    : Text(
                        '$number',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: active ? Colors.white : idle,
                        ),
                      ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: done ? green : idle,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 6 : 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : null,
                            color: done
                                ? (isDark ? Colors.white54 : Colors.black45)
                                : (isDark
                                      ? Colors.white
                                      : ThemeConstants.lightTextPrimary),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        if (progress != null && !done) ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              color: ThemeConstants.signalRed,
                              backgroundColor: ThemeConstants.signalRed
                                  .withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if ((active || alwaysShowAction) && onAction != null) ...[
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onAction,
                      style: FilledButton.styleFrom(
                        backgroundColor: active
                            ? ThemeConstants.signalRed
                            : ThemeConstants.signalOrange,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        actionLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Entry card for the Car Assembly mini-game.
class _GameCard extends StatelessWidget {
  const _GameCard({required this.onPlay});

  final VoidCallback onPlay;

  static const _vehicles = [
    (Icons.pedal_bike_rounded, 'Bicycle'),
    (Icons.sports_motorsports_rounded, 'Sports Bike'),
    (Icons.directions_car_filled_rounded, 'Car'),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPlay,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const RadialGradient(
            center: Alignment(0.7, -0.4),
            radius: 1.3,
            colors: [Color(0xFF3A2A12), Color(0xFF1B2230), Color(0xFF0B0E13)],
          ),
          border: Border.all(
            color: const Color(0xFFFFA000).withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFA000).withValues(alpha: 0.25),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA000),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'NEW GAME',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Car Assembly 3D',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Put every part in the right place, earn stars and learn '
                    'how vehicles are built.',
                    style: TextStyle(
                      color: Color(0xFF90A4AE),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final (icon, label) in _vehicles)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Tooltip(
                            message: label,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                icon,
                                size: 18,
                                color: const Color(0xFFFFA000),
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: onPlay,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA000),
                          foregroundColor: Colors.black,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text(
                          'Play',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Spin360(
              duration: Duration(milliseconds: 5500),
              child: Icon(
                Icons.directions_car_filled_rounded,
                size: 64,
                color: Color(0xFFFFA000),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
