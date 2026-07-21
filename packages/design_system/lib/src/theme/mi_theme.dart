import 'package:flutter/material.dart';

/// MI Academy semantic color tokens — Design System v1.1 ("Play Learn Grow").
///
/// Single source of truth for color. Screens reference these semantic
/// names, never hex literals and never the deprecated [MiTokens] palette.
/// Spec: docs/brand/BRAND_GUIDELINES.md
abstract class MiColors {
  // Brand
  static const Color primary = Color(0xFFFF8A00);
  static const Color primarySoft = Color(0xFFFFE3BF);
  static const Color secondary = Color(0xFF4CAF50);
  static const Color secondarySoft = Color(0xFFDDF3DE);
  static const Color discovery = Color(0xFF4A90E2);
  static const Color discoverySoft = Color(0xFFD9ECFF);
  static const Color creative = Color(0xFF8E6BFF);
  static const Color creativeSoft = Color(0xFFE9E2FF);
  static const Color accent = Color(0xFFFFD23F);
  static const Color accentSoft = Color(0xFFFFF3BF);
  static const Color navy = Color(0xFF1E2A44);

  // Surfaces
  static const Color background = Color(0xFFF4F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceRaised = Color(0xFFFFFFFF);

  // Content
  static const Color textPrimary = navy;
  static const Color textSecondary = Color(0xFF526079);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDDE3EE);

  // Feedback — color is never the only signal; pair with icon + text/audio.
  static const Color success = secondary;
  static const Color warning = accent;
  static const Color error = Color(0xFFE0523F); // soft, child-safe
  static const Color info = discovery;

  // Elevation
  static const Color shadow = Color(0x14000000);
  static const Color scrim = Color(0x661E2A44);

  // High-contrast variants (accessibility mode)
  static const Color primaryHc = Color(0xFFD96B00);
  static const Color textPrimaryHc = Color(0xFF0B1428);
  static const Color borderHc = Color(0xFF8792A8);
  static const Color errorHc = Color(0xFFC73320);

  // Parent Mode surface overrides (restrained skin, same hues)
  static const Color parentBackground = Color(0xFFF5F6F8);
}

/// Motion duration tokens. Full rules (easing, reduced-motion substitution
/// table) in docs/animation/MOTION_SYSTEM.md.
abstract class MiMotion {
  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration celebration = Duration(milliseconds: 1200);

  /// Resolves a motion token against the platform reduced-motion setting.
  /// Widgets use this instead of checking [MediaQuery.disableAnimations]
  /// themselves.
  static Duration resolve(BuildContext context, Duration duration) {
    return MediaQuery.of(context).disableAnimations ? instant : duration;
  }
}

/// MI Academy Design Tokens
///
/// All design tokens are defined here so they can be referenced
/// throughout the app without magic numbers or hex codes.
abstract class MiTokens {
  // Colors — deprecated aliases retained for one wave so existing screens
  // keep compiling while they migrate to [MiColors].
  @Deprecated('Use MiColors.primary')
  static const Color primaryBlue = MiColors.discovery;
  @Deprecated('Use MiColors.primaryHc')
  static const Color primaryBlueDark = MiColors.primaryHc;
  @Deprecated('Use MiColors.primarySoft')
  static const Color primaryBlueLight = MiColors.primarySoft;
  @Deprecated('Use MiColors.warning')
  static const Color accentOrange = MiColors.primary;
  @Deprecated('Use MiColors.success')
  static const Color accentGreen = MiColors.success;
  @Deprecated('Use MiColors.primary')
  static const Color accentPurple = MiColors.creative;
  @Deprecated('Use MiColors.secondary')
  static const Color accentPink = Color(0xFFFF5C9B);
  @Deprecated('Use MiColors.accent')
  static const Color starYellow = MiColors.accent;

  // Age group colors — pending age-tier design (see UI_UX_GAP_ANALYSIS §2).
  @Deprecated('Age-tier palette not finalized; do not build on these')
  static const Color juniorBlue = Color(0xFF60A5FA);
  @Deprecated('Age-tier palette not finalized; do not build on these')
  static const Color explorerGreen = Color(0xFF34D399);
  @Deprecated('Age-tier palette not finalized; do not build on these')
  static const Color masterPurple = Color(0xFFA78BFA);

  // Backgrounds
  @Deprecated('Use MiColors.background')
  static const Color backgroundPrimary = MiColors.background;
  @Deprecated('Use MiColors.surface')
  static const Color backgroundSecondary = MiColors.surface;
  @Deprecated('Use MiColors.surface')
  static const Color backgroundCard = MiColors.surface;

  // Text
  @Deprecated('Use MiColors.textPrimary')
  static const Color textPrimary = MiColors.textPrimary;
  @Deprecated('Use MiColors.textSecondary')
  static const Color textSecondary = MiColors.textSecondary;
  @Deprecated('Use MiColors.textSecondary')
  static const Color textMuted = MiColors.textSecondary;
  @Deprecated('Use MiColors.textOnPrimary')
  static const Color textOnPrimary = MiColors.textOnPrimary;

  // Status
  @Deprecated('Use MiColors.success')
  static const Color success = MiColors.success;
  @Deprecated('Use MiColors.warning')
  static const Color warning = MiColors.warning;
  @Deprecated('Use MiColors.error')
  static const Color error = MiColors.error;
  @Deprecated('Use MiColors.info')
  static const Color info = MiColors.info;

  // Borders & shadows
  @Deprecated('Use MiColors.border')
  static const Color border = MiColors.border;
  @Deprecated('Use MiColors.shadow')
  static const Color shadowColor = MiColors.shadow;

  // Spacing scale (8pt grid)
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  @Deprecated('Off the official scale — use space4 or space6')
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;
  @Deprecated('Off the official scale — use space8 or space12')
  static const double space10 = 40.0;
  static const double space12 = 48.0;
  static const double space16 = 64.0;
  static const double space20 = 80.0;

  // Border radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 28.0;
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

  // Touch targets (docs/design/MI_DESIGN_SYSTEM.md §7)
  static const double touchTargetChild = 56.0;
  static const double touchTargetChildLarge = 64.0;
  static const double touchTargetParent = 48.0;
  static const double touchTargetGap = 8.0;

  // Component sizing
  static const double bottomNavigationHeight = 76.0;
  static const double mascotReactionSm = 72.0;
  static const double mascotReactionMd = 112.0;
  static const double mascotReactionLg = 156.0;
}

enum MiDeviceClass { phone, tablet, desktop }

extension MiDeviceClassX on BuildContext {
  MiDeviceClass get miDeviceClass {
    final width = MediaQuery.sizeOf(this).width;
    if (width >= 1024) return MiDeviceClass.desktop;
    if (width >= 700) return MiDeviceClass.tablet;
    return MiDeviceClass.phone;
  }
}

abstract class MiShadows {
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: MiColors.shadow,
      blurRadius: 14,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> raised = [
    BoxShadow(
      color: MiColors.shadow,
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];
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
        seedColor: MiColors.primary,
        brightness: Brightness.light,
        primary: MiColors.primary,
        onPrimary: MiColors.textOnPrimary,
        secondary: MiColors.secondary,
        error: MiColors.error,
        surface: MiColors.surface,
        onSurface: MiColors.textPrimary,
      ),
      scaffoldBackgroundColor: MiColors.background,
      fontFamily: 'NunitoRounded',
      appBarTheme: const AppBarTheme(
        backgroundColor: MiColors.background,
        foregroundColor: MiColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: MiColors.surface,
        elevation: 2,
        shadowColor: MiColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MiTokens.radiusLg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MiColors.primary,
          foregroundColor: MiColors.textOnPrimary,
          elevation: 2,
          minimumSize: const Size(
            MiTokens.touchTargetChild,
            MiTokens.touchTargetChild,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: MiTokens.space6,
            vertical: MiTokens.space4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MiTokens.radiusFull),
          ),
          textStyle: const TextStyle(
            fontSize: MiTokens.fontLg,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MiColors.primary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MiColors.primary,
          side: const BorderSide(color: MiColors.primary),
          minimumSize: const Size(
            MiTokens.touchTargetChild,
            MiTokens.touchTargetChild,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MiTokens.radiusMd),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MiColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MiTokens.radiusMd),
          borderSide: const BorderSide(color: MiColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MiTokens.radiusMd),
          borderSide: const BorderSide(color: MiColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MiTokens.radiusMd),
          borderSide: const BorderSide(color: MiColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MiTokens.radiusMd),
          borderSide: const BorderSide(color: MiColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MiTokens.space4,
          vertical: MiTokens.space4,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MiColors.surface,
        selectedItemColor: MiColors.primary,
        unselectedItemColor: MiColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: MiTokens.fontXs,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: MiTokens.fontXs,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: MiTokens.font4xl,
          fontWeight: FontWeight.w800,
          color: MiColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: MiTokens.font3xl,
          fontWeight: FontWeight.w800,
          color: MiColors.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: MiTokens.font2xl,
          fontWeight: FontWeight.w800,
          color: MiColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: MiTokens.fontXl,
          fontWeight: FontWeight.w800,
          color: MiColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: MiTokens.fontLg,
          fontWeight: FontWeight.w800,
          color: MiColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: MiTokens.fontBase,
          fontWeight: FontWeight.w800,
          color: MiColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: MiTokens.fontBase,
          fontWeight: FontWeight.w500,
          color: MiColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: MiTokens.fontSm,
          fontWeight: FontWeight.w600,
          color: MiColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: MiTokens.fontSm,
          fontWeight: FontWeight.w800,
          color: MiColors.textPrimary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: MiColors.border,
        thickness: 1,
      ),
    );
  }
}
