import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme_constants.dart';
import '../widgets/traffic_sign_painter.dart';
import 'onboarding_screen.dart';
import 'main_navigation_wrapper.dart'; // We will create this as a wrapper for home/quiz/fav/settings

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _activeSignal = 'red_signal';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAnimationSequence();
  }

  void _startAnimationSequence() {
    // Red Light phase
    _timer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _activeSignal = 'yellow_signal';
      });

      // Yellow Light phase
      _timer = Timer(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        setState(() {
          _activeSignal = 'green_signal';
        });

        // Green Light phase, then route
        _timer = Timer(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          _routeToNext();
        });
      });
    });
  }

  void _routeToNext() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (appProvider.isOnboarded) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationWrapper()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [ThemeConstants.darkBgStart, ThemeConstants.darkBgEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing Animated Vector Traffic Light
              TrafficSignWidget(
                signId: _activeSignal,
                size: 200,
                isGlowing: true,
              ),
              const SizedBox(height: 40),
              // App Title
              Text(
                'TRAFFIC SIGNALS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'BY COUNTRY',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: ThemeConstants.signalRed,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  ThemeConstants.signalGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
