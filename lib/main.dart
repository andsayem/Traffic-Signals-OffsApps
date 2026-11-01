import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/traffic_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/subscription_provider.dart';
import 'services/storage_service.dart';
import 'ads/ad_service.dart';
import 'ads/root_navigator_key.dart';
import 'services/app_upgrader.dart';
import 'utils/theme_constants.dart';
import 'screens/splash_screen.dart';

void main() async {
  // Ensure Flutter engine is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set system navigation/status bar styles to align with premium dark look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize SharedPreferences wrapper
  await StorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => TrafficDataProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: const MyApp(),
    ),
  );
  // Ads (UMP consent first) start in the background after runApp, so the
  // consent form is never hidden behind the splash screen.
  unawaited(AdService.instance.init());
}

final AppUpgrader _upgrader = AppUpgrader();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return MaterialApp(
          title: 'Traffic Signals & Signs',
          debugShowCheckedModeBanner: false,

          // Theme Setup
          theme: ThemeConstants.lightTheme,
          darkTheme: ThemeConstants.darkTheme,
          themeMode: appProvider.isDarkTheme ? ThemeMode.dark : ThemeMode.light,

          navigatorKey: rootNavigatorKey,
          // The update prompt sits above the Navigator, so it stays visible
          // across every route change (see UpdateGate).
          builder: (context, child) =>
              UpdateGate(upgrader: _upgrader, child: child ?? const SizedBox()),

          // Root Screen
          home: const SplashScreen(),
        );
      },
    );
  }
}
