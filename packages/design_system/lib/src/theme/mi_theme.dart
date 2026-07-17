import 'package:flutter/material.dart';

/// MI Academy Design Tokens
///
/// All design tokens are defined here so they can be referenced
/// throughout the app without magic numbers or hex codes.
abstract class MiTokens {
  // Colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueDark = Color(0xFF1D4ED8);
  static const Color primaryBlueLight = Color(0xFF93C5FD);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color starYellow = Color(0xFFFBBF24);

  // Age group colors
  static const Color juniorBlue = Color(0xFF60A5FA);
  static const Color explorerGreen = Color(0xFF34D399);
  static const Color masterPurple = Color(0xFFA78BFA);

  // Backgrounds
  static const Color backgroundPrimary = Color(0xFFF0F9FF);
  static const Color backgroundSecondary = Color(0xFFFFFFFF);
  static const Color backgroundCard = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Borders & shadows
  static const Color border = Color(0xFFE2E8F0);
  static const Color shadowColor = Color(0x1A000000);

  // Spacing scale (8pt grid)
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;
  static const double space10 = 40.0;
  static const double space12 = 48.0;

  // Border radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 9999.0;

  // Font sizes
  static const double fontXs = 12.0;
  static const double fontSm = 14.0;
  static const double fontBase = 16.0;
  static const double fontLg = 18.0;
  static const double fontXl = 20.0;
  static const double font2xl = 24.0;
  static const double font3xl = 30.0;
  static const double font4xl = 36.0;

  // Icon sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
  static const double icon2xl = 64.0;
}

/// MI Academy Theme
///
/// Bright, playful theme suitable for children aged 5-12.
/// Always uses light mode (kids app — no dark theme).
class MiTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: MiTokens.primaryBlue,
        brightness: Brightness.light,
        primary: MiTokens.primaryBlue,
        onPrimary: MiTokens.textOnPrimary,
        secondary: MiTokens.accentOrange,
        surface: MiTokens.backgroundSecondary,
        onSurface: MiTokens.textPrimary,
      ),
      scaffoldBackgroundColor: MiTokens.backgroundPrimary,
      fontFamily: 'Nunito',
      appBarTheme: const AppBarTheme(
        backgroundColor: MiTokens.primaryBlue,
        foregroundColor: MiTokens.textOnPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: MiTokens.backgroundCard,
        elevation: 2,
        shadowColor: MiTokens.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MiTokens.radiusLg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MiTokens.primaryBlue,
          foregroundColor: MiTokens.textOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: MiTokens.space6,
            vertical: MiTokens.space4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MiTokens.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: MiTokens.fontBase,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MiTokens.primaryBlue,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MiTokens.primaryBlue,
          side: const BorderSide(color: MiTokens.primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MiTokens.radiusMd),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MiTokens.backgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MiTokens.radiusMd),
          borderSide: const BorderSide(color: MiTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MiTokens.radiusMd),
          borderSide: const BorderSide(color: MiTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MiTokens.radiusMd),
          borderSide: const BorderSide(color: MiTokens.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MiTokens.radiusMd),
          borderSide: const BorderSide(color: MiTokens.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MiTokens.space4,
          vertical: MiTokens.space4,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: MiTokens.font4xl,
          fontWeight: FontWeight.w800,
          color: MiTokens.textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: MiTokens.font3xl,
          fontWeight: FontWeight.w700,
          color: MiTokens.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: MiTokens.font2xl,
          fontWeight: FontWeight.w700,
          color: MiTokens.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: MiTokens.fontXl,
          fontWeight: FontWeight.w600,
          color: MiTokens.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: MiTokens.fontLg,
          fontWeight: FontWeight.w600,
          color: MiTokens.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: MiTokens.fontBase,
          fontWeight: FontWeight.w600,
          color: MiTokens.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: MiTokens.fontBase,
          fontWeight: FontWeight.w400,
          color: MiTokens.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: MiTokens.fontSm,
          fontWeight: FontWeight.w400,
          color: MiTokens.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: MiTokens.fontSm,
          fontWeight: FontWeight.w600,
          color: MiTokens.textPrimary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: MiTokens.border,
        thickness: 1,
      ),
    );
  }
}
