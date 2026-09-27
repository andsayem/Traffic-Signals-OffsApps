import 'package:flutter/material.dart';

class AppColors {
  static const bgTop = Color(0xFF1B2230);
  static const bgBottom = Color(0xFF0B0E13);
  static const panel = Color(0xFF1A1F27);
  static const card = Color(0xFF232A34);
  static const accent = Color(0xFFFFA000);
  static const text = Color(0xFFECEFF1);
  static const muted = Color(0xFF90A4AE);
}

const garageGradient = BoxDecoration(
  gradient: RadialGradient(
    center: Alignment(0, -0.3),
    radius: 1.2,
    colors: [AppColors.bgTop, AppColors.bgBottom],
  ),
);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
      primary: AppColors.accent,
    ),
    scaffoldBackgroundColor: AppColors.bgBottom,
  );
  return base.copyWith(
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
