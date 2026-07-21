import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Theme data shared across all MI Academy games.
///
/// Child-friendly colors, large touch targets, rounded corners.
class GameTheme {
  GameTheme._();

  // --- Color palette ---

  // Values track docs/brand/BRAND_GUIDELINES.md via design_system.
  static const Color primary = MiColors.primary;
  static const Color secondary = MiColors.discovery;
  static const Color success = MiColors.success;
  static const Color warning = MiColors.accent;
  static const Color background = MiColors.background;
  static const Color surface = MiColors.surface;
  static const Color onPrimary = MiColors.textOnPrimary;
  static const Color textPrimary = MiColors.textPrimary;
  static const Color textSecondary = MiColors.textSecondary;

  // --- Touch target (min 48x48 per accessibility guidelines) ---

  static const double minTouchTarget = 48.0;
  static const double cardRadius = MiTokens.radiusLg;
  static const double buttonRadius = MiTokens.radiusFull;
  static const double overlayRadius = MiTokens.radiusXl;

  // --- Text styles ---

  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    fontFamily: 'NunitoRounded',
    color: textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    fontFamily: 'NunitoRounded',
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: 'NunitoRounded',
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: 'NunitoRounded',
    color: textSecondary,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    fontFamily: 'NunitoRounded',
    color: onPrimary,
  );

  // --- Padding ---

  static const EdgeInsets screenPadding = EdgeInsets.all(MiTokens.space4);
  static const EdgeInsets cardPadding = EdgeInsets.all(MiTokens.space4);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
      horizontal: MiTokens.space6, vertical: MiTokens.space4);

  // --- Shadows ---

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: MiColors.shadow, blurRadius: 14, offset: Offset(0, 6)),
  ];
}
