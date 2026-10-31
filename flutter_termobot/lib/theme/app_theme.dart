import 'package:flutter/material.dart';

class AppTheme {
  // Deep Tactile Obsidian Palettes
  static const Color background = Color(0xFF090D16);
  static const Color surface = Color(0xFF131926);
  static const Color surfaceElevated = Color(0xFF1A2234);
  static const Color border = Color(0xFF26334D);

  // Accent & Telemetry Colors
  static const Color flameOrange = Color(0xFFFF6A00);
  static const Color flameAmber = Color(0xFFFFAA00);
  static const Color flameRed = Color(0xFFFF3344);
  static const Color cyanCool = Color(0xFF00E5FF);
  static const Color purpleNeon = Color(0xFF9D4EDD);
  static const Color greenEco = Color(0xFF10B981);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: flameOrange,
      colorScheme: const ColorScheme.dark(
        primary: flameOrange,
        secondary: cyanCool,
        surface: surface,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0E1420),
        selectedItemColor: flameOrange,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
      ),
    );
  }
}
