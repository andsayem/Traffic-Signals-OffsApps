import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ads/ad_service.dart';
import '../ads/adaptive_banner_ad_widget.dart';
import '../providers/subscription_provider.dart';
import '../services/storage_service.dart';
import '../utils/theme_constants.dart';
import '../widgets/custom_nav_bar.dart';
import 'home_screen.dart';
import 'quiz_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'subscription_screen.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;

  void _goToTab(int index) => setState(() => _currentIndex = index);

  late final List<Widget> _screens = [
    HomeScreen(onStartQuiz: () => _goToTab(1)),
    const QuizScreen(),
    FavoritesScreen(onBrowse: () => _goToTab(0)),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 900), () async {
        // Never start the tour or the paywall under the post-onboarding ad.
        await AdService.instance.onboardingAdDone;
        if (!mounted) return;
        // First visit: teach the app with the guided tour instead of
        // opening with a paywall.
        if (!StorageService.isHomeTourDone()) {
          HomeScreen.startTour(context);
          return;
        }
        // Later launches: auto-show the paywall at most once a day, unless
        // the user is already subscribed. (Every cold start was too pushy.)
        if (context.read<SubscriptionProvider>().isPro) return;
        final today = DateTime.now().toIso8601String().substring(0, 10);
        if (StorageService.getPaywallPromptDate() == today) return;
        StorageService.setPaywallPromptDate(today);
        SubscriptionScreen.show(context);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? ThemeConstants.darkBgEnd
          : ThemeConstants.lightBgEnd,
      // The IndexedStack keeps a running quiz alive across tab switches;
      // TabVisibility stops the hidden tabs from loading in-content ads.
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (var i = 0; i < _screens.length; i++)
            TabVisibility(visible: i == _currentIndex, child: _screens[i]),
        ],
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
