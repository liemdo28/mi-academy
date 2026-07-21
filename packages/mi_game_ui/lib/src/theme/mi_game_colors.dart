import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Centralized color palette for all MI Academy games.
///
/// All colors use the Material Design color system with custom
/// MI Academy brand colors. Games should reference these constants
/// rather than hardcoding color values.
class MiGameColors {
  MiGameColors._();

  // --- Brand Colors ---

  /// Primary brand color — Mi Academy orange.
  static const Color primary = MiColors.primary;

  /// Secondary brand color — discovery blue.
  static const Color secondary = MiColors.discovery;

  /// Tertiary brand color — creative purple.
  static const Color tertiary = MiColors.creative;

  // --- Semantic Colors ---

  /// Success / correct answer feedback.
  static const Color success = MiColors.success;

  /// Warning / hint used feedback.
  static const Color warning = MiColors.accent;

  /// Error / incorrect answer feedback (soft, not scary).
  static const Color error = MiColors.error;

  /// Information / hint available.
  static const Color info = MiColors.info;

  // --- Neutral Colors ---

  /// Main background color.
  static const Color background = MiColors.background;

  /// Surface / card background.
  static const Color surface = MiColors.surface;

  /// Primary text color.
  static const Color textPrimary = MiColors.textPrimary;

  /// Secondary / muted text color.
  static const Color textSecondary = MiColors.textSecondary;

  /// Divider / subtle lines.
  static const Color divider = MiColors.border;

  // --- Card Specific ---

  /// Card face background (Memory Cards).
  static const Color cardFace = Colors.white;

  /// Card back pattern color.
  static const Color cardBack = MiColors.primary;

  /// Matched pair glow.
  static const Color matchedGlow = MiColors.success;

  // --- Star Rating ---

  /// Active / earned star color.
  static const Color starActive = MiColors.accent;

  /// Inactive / unearned star color.
  static const Color starInactive = MiColors.border;

  // --- Accessibility ---

  /// High contrast overlay color.
  static const Color highContrastOverlay = Color(0xFF000000);

  /// Focus ring color for accessibility.
  static const Color focusRing = MiColors.discovery;

  /// Reduced motion indicator color.
  static const Color motionIndicator = MiColors.discovery;
}
