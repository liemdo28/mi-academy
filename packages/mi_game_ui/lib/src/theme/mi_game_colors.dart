import 'package:flutter/material.dart';

/// Centralized color palette for all MI Academy games.
///
/// All colors use the Material Design color system with custom
/// MI Academy brand colors. Games should reference these constants
/// rather than hardcoding color values.
class MiGameColors {
  MiGameColors._();

  // --- Brand Colors ---

  /// Primary brand color — purple accent.
  static const Color primary = Color(0xFF6C63FF);

  /// Secondary brand color — pink/coral accent.
  static const Color secondary = Color(0xFFFF6584);

  /// Tertiary brand color — teal accent.
  static const Color tertiary = Color(0xFF00BCD4);

  // --- Semantic Colors ---

  /// Success / correct answer feedback.
  static const Color success = Color(0xFF2BB673);

  /// Warning / hint used feedback.
  static const Color warning = Color(0xFFF5A623);

  /// Error / incorrect answer feedback (soft, not scary).
  static const Color error = Color(0xFFFF7043);

  /// Information / hint available.
  static const Color info = Color(0xFF42A5F5);

  // --- Neutral Colors ---

  /// Main background color.
  static const Color background = Color(0xFFF7F7FE);

  /// Surface / card background.
  static const Color surface = Colors.white;

  /// Primary text color.
  static const Color textPrimary = Color(0xFF2D2D5F);

  /// Secondary / muted text color.
  static const Color textSecondary = Color(0xFF6B6B8E);

  /// Divider / subtle lines.
  static const Color divider = Color(0xFFE3E2F2);

  // --- Card Specific ---

  /// Card face background (Memory Cards).
  static const Color cardFace = Colors.white;

  /// Card back pattern color.
  static const Color cardBack = Color(0xFF6C63FF);

  /// Matched pair glow.
  static const Color matchedGlow = Color(0xFF2BB673);

  // --- Star Rating ---

  /// Active / earned star color.
  static const Color starActive = Color(0xFFFFC94D);

  /// Inactive / unearned star color.
  static const Color starInactive = Color(0xFFE3E2F2);

  // --- Accessibility ---

  /// High contrast overlay color.
  static const Color highContrastOverlay = Color(0xFF000000);

  /// Focus ring color for accessibility.
  static const Color focusRing = Color(0xFF6C63FF);

  /// Reduced motion indicator color.
  static const Color motionIndicator = Color(0xFF42A5F5);
}
