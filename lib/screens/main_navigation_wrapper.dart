import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        // First visit: teach the app with the guided tour instead of
        // opening with a paywall.
        if (!StorageService.isHomeTourDone()) {
          HomeScreen.startTour(context);
          return;
        }
        // Later launches: auto-show the paywall once per cold start,
        // unless the user is already subscribed.
        if (context.read<SubscriptionProvider>().isPro) return;
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
      body: IndexedStack(index: _currentIndex, children: _screens),
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
