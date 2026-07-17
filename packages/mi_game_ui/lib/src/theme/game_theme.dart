import 'package:flutter/material.dart';

/// Theme data shared across all MI Academy games.
///
/// Child-friendly colors, large touch targets, rounded corners.
class GameTheme {
  GameTheme._();

  // --- Color palette ---

  // Values track MiColors in packages/design_system (Soft Violet system,
  // docs/design/MI_DESIGN_SYSTEM.md). Keep in sync until this package can
  // depend on design_system directly.
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFFFF6584);
  static const Color success = Color(0xFF2BB673);
  static const Color warning = Color(0xFFF5A623);
  static const Color background = Color(0xFFF7F7FE);
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;
  static const Color textPrimary = Color(0xFF2D2D5F);
  static const Color textSecondary = Color(0xFF6B6B8E);

  // --- Touch target (min 48x48 per accessibility guidelines) ---

  static const double minTouchTarget = 48.0;
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double overlayRadius = 24.0;

  // --- Text styles ---

  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    color: textSecondary,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: onPrimary,
  );

  // --- Padding ---

  static const EdgeInsets screenPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPadding = EdgeInsets.all(12);
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: 24, vertical: 14);

  // --- Shadows ---

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
}
