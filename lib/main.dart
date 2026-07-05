import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/traffic_provider.dart';
import 'providers/quiz_provider.dart';
import 'services/storage_service.dart';
import 'ads/ad_service.dart';
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

  // Initialize AdMob
  await AdService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => TrafficDataProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

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
          
          // Root Screen
          home: const SplashScreen(),
        );
      },
    );
  }
}
