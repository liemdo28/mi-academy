import 'package:flutter/material.dart';

class MITheme {
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFFFF6584);
  static const Color accent = Color(0xFFFFD166);
  static const Color background = Color(0xFFF0F0FF);
  static const Color success = Color(0xFF06D6A0);
  static const Color danger = Color(0xFFEF476F);
  static const Color textPrimary = Color(0xFF2D2D5F);
  static const Color textSecondary = Color(0xFF6B6B8E);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: background,
      ),
      scaffoldBackgroundColor: background,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w800, color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w500, color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary,
        ),
        labelLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(120, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(120, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w800, color: textPrimary,
        ),
      ),
    );
  }
}
