import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/translations.dart';
import '../utils/theme_constants.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/traffic_sign_painter.dart';
import 'main_navigation_wrapper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = [
      _OnboardingData(
        titleKey: 'onboarding_title_1',
        subtitleKey: 'onboarding_subtitle_1',
        signId: 'keep_left',
      ),
      _OnboardingData(
        titleKey: 'onboarding_title_2',
        subtitleKey: 'onboarding_subtitle_2',
        signId: 'school_zone',
      ),
      _OnboardingData(
        titleKey: 'onboarding_title_3',
        subtitleKey: 'onboarding_subtitle_3',
        signId: 'stop',
      ),
    ];

    return AppBackground(
      child: Stack(
        children: [
          // Slide views
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final page = pages[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Vector Sign Illustration
                    TrafficSignWidget(
                      signId: page.signId,
                      size: 180,
                      isGlowing: true,
                    ),
                    const SizedBox(height: 60),
                    // Onboarding Glass Card Info
                    GlassCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr(page.titleKey),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr(page.subtitleKey),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120), // Leave space for indicators & buttons
                  ],
                ),
              );
            },
          ),

          // Bottom elements (Skip, dots, next)
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Skip Button
                _currentPage < pages.length - 1
                    ? TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          context.tr('skip'),
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const SizedBox(width: 60),

                // Dot Indicators
                Row(
                  children: List.generate(
                    pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? ThemeConstants.signalRed
                            : (isDark ? Colors.white30 : Colors.black26),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                // Next or Get Started Button
                _currentPage < pages.length - 1
                    ? ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeConstants.signalRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(context.tr('next')),
                      )
                    : ElevatedButton(
                        onPressed: _completeOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeConstants.signalGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(context.tr('get_started')),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _completeOnboarding() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.completeOnboarding();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationWrapper()),
    );
  }
}

class _OnboardingData {
  final String titleKey;
  final String subtitleKey;
  final String signId;

  const _OnboardingData({
    required this.titleKey,
    required this.subtitleKey,
    required this.signId,
  });
}
