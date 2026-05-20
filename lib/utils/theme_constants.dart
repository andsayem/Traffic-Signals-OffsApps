import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeConstants {
  // Brand/Signal Colors
  static const Color signalRed = Color(0xFFFF3B30);
  static const Color signalYellow = Color(0xFFFFCC00);
  static const Color signalGreen = Color(0xFF34C759);
  static const Color signalBlue = Color(0xFF007AFF);
  static const Color signalOrange = Color(0xFFFF9500);

  // Dark Theme Colors
  static const Color darkBgStart = Color(0xFF0F172A); // Slate 900
  static const Color darkBgEnd = Color(0xFF020617); // Slate 950
  static const Color darkCardColor = Color(0x1AFFFFFF); // Glass white with low opacity
  static const Color darkBorderColor = Color(0x1FFFFFFF);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400

  // Light Theme Colors
  static const Color lightBgStart = Color(0xFFF8FAFC); // Slate 50
  static const Color lightBgEnd = Color(0xFFE2E8F0); // Slate 200
  static const Color lightCardColor = Color(0x99FFFFFF); // Glass white with higher opacity
  static const Color lightBorderColor = Color(0x2B000000);
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600

  // Dark ThemeData
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent, // Handled by gradient container
      colorScheme: const ColorScheme.dark(
        primary: signalRed,
        secondary: signalYellow,
        tertiary: signalGreen,
        surface: Color(0xFF1E293B),
        onSurface: darkTextPrimary,
        error: signalRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: darkTextPrimary),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: darkTextPrimary),
        bodyLarge: GoogleFonts.outfit(color: darkTextPrimary),
        bodyMedium: GoogleFonts.outfit(color: darkTextSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // Light ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent, // Handled by gradient container
      colorScheme: const ColorScheme.light(
        primary: signalRed,
        secondary: signalYellow,
        tertiary: signalGreen,
        surface: Colors.white,
        onSurface: lightTextPrimary,
        error: signalRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: lightTextPrimary),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: lightTextPrimary),
        bodyLarge: GoogleFonts.outfit(color: lightTextPrimary),
        bodyMedium: GoogleFonts.outfit(color: lightTextSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
