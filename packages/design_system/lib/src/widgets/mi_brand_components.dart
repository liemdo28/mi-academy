import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../assets/mi_brand_assets.dart';
import '../theme/mi_theme.dart';

/// Centralized temporary mascot placeholder.
///
/// This is intentionally a simple vector construction, not production mascot
/// art. Replace this widget's internals when final approved mascot assets land;
/// screen code should keep using [MiMascotReaction].
class MiMascotReaction extends StatelessWidget {
  const MiMascotReaction({
    super.key,
    this.emotion = MiMascotEmotion.welcome,
    this.size = MiTokens.mascotReactionMd,
    this.message,
    this.semanticLabel,
    this.animationMode = MiBrandAnimationMode.auto,
    this.decorative = false,
  });

  final MiMascotEmotion emotion;
  final double size;
  final String? message;
  final String? semanticLabel;
  final MiBrandAnimationMode animationMode;
  final bool decorative;

  @override
  Widget build(BuildContext context) {
    final resolvedEmotion = emotion;
    final motionMode = MediaQuery.of(context).disableAnimations
        ? MiBrandAnimationMode.still
        : animationMode;
    final mascot = SizedBox.square(
      dimension: size,
      child: _BrandSvgWithFallback(
        assetPath: MiBrandAssets.mascot(resolvedEmotion),
        fallbackAssetPath: MiBrandAssets.mascotFallback(resolvedEmotion),
        width: size,
        height: size,
        fallback: CustomPaint(
          painter: _MiMascotPainter(resolvedEmotion),
        ),
      ),
    );

    final visual = motionMode == MiBrandAnimationMode.subtle ||
            motionMode == MiBrandAnimationMode.auto
        ? AnimatedScale(
            scale: 1,
            duration: MiMotion.resolve(context, MiMotion.normal),
            child: mascot,
          )
        : mascot;

    final content = message == null
        ? visual
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              visual,
              const SizedBox(height: MiTokens.space2),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: size * 2.2),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textScaler: MediaQuery.textScalerOf(context),
                ),
              ),
            ],
          );

    if (decorative) return ExcludeSemantics(child: content);

    return Semantics(
      image: true,
      label: semanticLabel ?? _defaultMascotSemanticLabel(resolvedEmotion),
      child: content,
    );
  }
}

class MiAcademyLogo extends StatelessWidget {
  const MiAcademyLogo({
    super.key,
    this.variant = MiLogoVariant.primary,
    this.size = 156,
    this.darkBackground = false,
    this.compact = false,
    this.semanticLabel = 'Mi Academy',
  });

  final MiLogoVariant variant;
  final double size;
  final bool darkBackground;
  final bool compact;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final width = switch (variant) {
      MiLogoVariant.symbol => size,
      MiLogoVariant.stacked => size,
      MiLogoVariant.primary ||
      MiLogoVariant.monochrome =>
        compact ? size * 1.4 : size * 2,
    };
    final height = switch (variant) {
      MiLogoVariant.symbol => size,
      MiLogoVariant.stacked => size,
      MiLogoVariant.primary || MiLogoVariant.monochrome => size,
    };

    return Semantics(
      image: true,
      label: semanticLabel,
      child: _BrandSvgWithFallback(
        assetPath: MiBrandAssets.logo(variant),
        fallbackAssetPath: MiBrandAssets.logoFallback(variant),
        width: width,
        height: height,
        colorFilter: variant == MiLogoVariant.monochrome
            ? ColorFilter.mode(
                darkBackground ? MiColors.textOnPrimary : MiColors.textPrimary,
                BlendMode.srcIn,
              )
            : null,
        fallback: _MiLogoPlaceholder(
          variant: variant,
          width: width,
          height: height,
          darkBackground: darkBackground,
        ),
      ),
    );
  }
}

class MiBrandIconView extends StatelessWidget {
  const MiBrandIconView({
    super.key,
    required this.icon,
    this.size = MiTokens.iconXl,
    this.color,
    this.darkSurface = false,
    this.enabled = true,
    this.semanticLabel,
    this.decorative = false,
  });

  final MiBrandIcon icon;
  final double size;
  final Color? color;
  final bool darkSurface;
  final bool enabled;
  final String? semanticLabel;
  final bool decorative;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = enabled
        ? color ??
            (darkSurface
                ? MiColors.textOnPrimary
                : _defaultBrandIconColor(icon))
        : (darkSurface ? MiColors.textOnPrimary : MiColors.textSecondary)
            .withValues(alpha: 0.48);
    final visual = SizedBox.square(
      dimension: size,
      child: _BrandSvgWithFallback(
        assetPath: MiBrandAssets.brandIcon(icon),
        fallbackAssetPath: MiBrandAssets.brandIconFallback(icon),
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
        fallback: _MiBrandIconPlaceholder(
          icon: icon,
          size: size,
          color: resolvedColor,
          darkSurface: darkSurface,
          enabled: enabled,
        ),
      ),
    );

    if (decorative) return ExcludeSemantics(child: visual);

    return Semantics(
      image: true,
      label: semanticLabel ?? _defaultBrandIconSemanticLabel(icon),
      enabled: enabled,
      child: visual,
    );
  }
}

class MiSectionHeader extends StatelessWidget {
  const MiSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: MiTokens.space1),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class MiAchievementBadge extends StatelessWidget {
  const MiAchievementBadge({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = MiColors.accent,
  });

  final String label;
  final String value;
  final MiBrandIcon icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: MiTokens.touchTargetParent),
      padding: const EdgeInsets.symmetric(
        horizontal: MiTokens.space3,
        vertical: MiTokens.space2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(MiTokens.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiBrandIconView(
            icon: icon,
            color: color,
            size: MiTokens.iconMd,
            decorative: true,
          ),
          const SizedBox(width: MiTokens.space2),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: MiTokens.fontXs,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MiProgressCard extends StatelessWidget {
  const MiProgressCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    this.color = MiColors.secondary,
  });

  final String title;
  final String subtitle;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MiTokens.space4),
      decoration: BoxDecoration(
        color: MiColors.surface,
        borderRadius: BorderRadius.circular(MiTokens.radiusLg),
        boxShadow: MiShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: MiTokens.space1),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: MiTokens.space3),
          ClipRRect(
            borderRadius: BorderRadius.circular(MiTokens.radiusFull),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress.clamp(0, 1),
              backgroundColor: color.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class MiGameCard extends StatelessWidget {
  const MiGameCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final MiBrandIcon icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(MiTokens.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 148),
          padding: const EdgeInsets.all(MiTokens.space4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MiTokens.radiusLg),
            boxShadow: MiShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: MiColors.surface.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(MiTokens.radiusMd),
                  border: Border.all(
                    color: MiColors.surface.withValues(alpha: 0.42),
                  ),
                ),
                child: MiBrandIconView(
                  icon: icon,
                  size: MiTokens.iconXl,
                  color: MiColors.textOnPrimary,
                  darkSurface: true,
                  semanticLabel: title,
                ),
              ),
              const SizedBox(height: MiTokens.space4),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: MiColors.textOnPrimary,
                    ),
              ),
              const SizedBox(height: MiTokens.space1),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MiColors.textOnPrimary.withValues(alpha: 0.9),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MiBottomNavigationDestination {
  const MiBottomNavigationDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final MiBrandIcon icon;
  final MiBrandIcon activeIcon;
}

class MiBottomNavigation extends StatelessWidget {
  const MiBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.destinations,
    required this.onTap,
  });

  final int currentIndex;
  final List<MiBottomNavigationDestination> destinations;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: MiTokens.bottomNavigationHeight,
        margin: const EdgeInsets.fromLTRB(
          MiTokens.space4,
          0,
          MiTokens.space4,
          MiTokens.space3,
        ),
        padding: const EdgeInsets.symmetric(horizontal: MiTokens.space2),
        decoration: BoxDecoration(
          color: MiColors.surface,
          borderRadius: BorderRadius.circular(MiTokens.radiusFull),
          boxShadow: MiShadows.raised,
        ),
        child: Row(
          children: [
            for (var index = 0; index < destinations.length; index++)
              Expanded(
                child: _MiBottomNavigationItem(
                  destination: destinations[index],
                  selected: index == currentIndex,
                  onTap: () => onTap(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiBottomNavigationItem extends StatelessWidget {
  const _MiBottomNavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final MiBottomNavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? MiColors.primary : MiColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MiTokens.radiusFull),
      child: SizedBox(
        height: MiTokens.touchTargetChild,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MiBrandIconView(
              icon: selected ? destination.activeIcon : destination.icon,
              color: color,
              size: MiTokens.iconMd,
              semanticLabel: destination.label,
            ),
            const SizedBox(height: MiTokens.space1),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontSize: MiTokens.fontXs,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandSvgWithFallback extends StatelessWidget {
  const _BrandSvgWithFallback({
    required this.assetPath,
    required this.fallbackAssetPath,
    required this.width,
    required this.height,
    required this.fallback,
    this.colorFilter,
  });

  final String assetPath;
  final String fallbackAssetPath;
  final double width;
  final double height;
  final Widget fallback;
  final ColorFilter? colorFilter;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      colorFilter: colorFilter,
      placeholderBuilder: (_) => fallback,
      errorBuilder: (_, __, ___) => SvgPicture.asset(
        fallbackAssetPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        colorFilter: colorFilter,
        placeholderBuilder: (_) => fallback,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class _MiLogoPlaceholder extends StatelessWidget {
  const _MiLogoPlaceholder({
    required this.variant,
    required this.width,
    required this.height,
    required this.darkBackground,
  });

  final MiLogoVariant variant;
  final double width;
  final double height;
  final bool darkBackground;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _MiLogoPlaceholderPainter(
        variant: variant,
        darkBackground: darkBackground,
      ),
    );
  }
}

class _MiBrandIconPlaceholder extends StatelessWidget {
  const _MiBrandIconPlaceholder({
    required this.icon,
    required this.size,
    required this.color,
    required this.darkSurface,
    required this.enabled,
  });

  final MiBrandIcon icon;
  final double size;
  final Color color;
  final bool darkSurface;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MiBrandIconPlaceholderPainter(
        icon: icon,
        color: color,
        darkSurface: darkSurface,
        enabled: enabled,
      ),
    );
  }
}

class _MiMascotPainter extends CustomPainter {
  const _MiMascotPainter(this.reaction);

  final MiMascotEmotion reaction;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120;
    canvas.scale(scale);

    final outline = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final navyStroke = Paint()
      ..color = MiColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final skin = Paint()..color = const Color(0xFFFFC59D);
    final hair = Paint()..color = const Color(0xFF3A2118);
    final hoodie = Paint()..color = MiColors.primary;
    final blue = Paint()..color = MiColors.discovery;

    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(31, 66, 58, 48),
      const Radius.circular(18),
    );
    canvas.drawRRect(body, outline);
    canvas.drawRRect(body, hoodie);

    final collar = Path()
      ..moveTo(54, 67)
      ..lineTo(66, 67)
      ..lineTo(60, 79)
      ..close();
    canvas.drawPath(collar, blue);

    final head = RRect.fromRectAndRadius(
      const Rect.fromLTWH(25, 18, 70, 62),
      const Radius.circular(26),
    );
    canvas.drawRRect(head, outline);
    canvas.drawRRect(head, skin);

    final hairPath = Path()
      ..moveTo(29, 40)
      ..quadraticBezierTo(38, 15, 65, 18)
      ..quadraticBezierTo(90, 20, 93, 42)
      ..quadraticBezierTo(78, 34, 66, 36)
      ..quadraticBezierTo(52, 36, 44, 30)
      ..quadraticBezierTo(42, 42, 29, 40);
    canvas.drawPath(hairPath, hair);

    canvas.drawCircle(const Offset(46, 51), 4.8, hair);
    canvas.drawCircle(const Offset(75, 51), 4.8, hair);
    canvas.drawCircle(
        const Offset(44.5, 49.5), 1.4, Paint()..color = Colors.white);
    canvas.drawCircle(
        const Offset(73.5, 49.5), 1.4, Paint()..color = Colors.white);

    final mouth = Path()..moveTo(50, 64);
    switch (reaction) {
      case MiMascotEmotion.thinking:
      case MiMascotEmotion.confused:
      case MiMascotEmotion.apology:
      case MiMascotEmotion.sleeping:
        mouth.quadraticBezierTo(60, 60, 70, 64);
      case MiMascotEmotion.welcome:
      case MiMascotEmotion.success:
      case MiMascotEmotion.excited:
      case MiMascotEmotion.encouraging:
      case MiMascotEmotion.tryAgain:
      case MiMascotEmotion.celebration:
      case MiMascotEmotion.love:
      case MiMascotEmotion.surprised:
        mouth.quadraticBezierTo(60, 76, 72, 63);
    }
    canvas.drawPath(mouth, navyStroke);

    final cheek = Paint()
      ..color = const Color(0xFFFF8F75).withValues(alpha: 0.38);
    canvas.drawOval(const Rect.fromLTWH(32, 58, 12, 7), cheek);
    canvas.drawOval(const Rect.fromLTWH(78, 58, 12, 7), cheek);

    final leftArm = Path()
      ..moveTo(34, 75)
      ..quadraticBezierTo(15, 66, 16, 48);
    canvas.drawPath(leftArm, outline);
    canvas.drawPath(leftArm, navyStroke);
    canvas.drawCircle(const Offset(16, 47), 6, skin);

    final rightArm = Path()
      ..moveTo(87, 75)
      ..quadraticBezierTo(104, 67, 101, 48);
    canvas.drawPath(rightArm, outline);
    canvas.drawPath(rightArm, navyStroke);
    canvas.drawCircle(const Offset(101, 47), 6, skin);

    final star = Paint()..color = MiColors.accent;
    _drawStar(canvas, const Offset(98, 20), 11, star, outline);

    if (reaction == MiMascotEmotion.thinking ||
        reaction == MiMascotEmotion.confused) {
      canvas.drawCircle(
          const Offset(101, 35), 4, Paint()..color = MiColors.discovery);
      canvas.drawCircle(
          const Offset(108, 27), 2.8, Paint()..color = MiColors.discovery);
    }
  }

  void _drawStar(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
    Paint outline,
  ) {
    final path = Path();
    const points = 10;
    for (var i = 0; i < points; i++) {
      final r = i.isEven ? radius : radius * 0.46;
      final angle = -1.5708 + i * 0.6283;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, outline);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiMascotPainter oldDelegate) {
    return oldDelegate.reaction != reaction;
  }
}

class _MiBrandIconPlaceholderPainter extends CustomPainter {
  const _MiBrandIconPlaceholderPainter({
    required this.icon,
    required this.color,
    required this.darkSurface,
    required this.enabled,
  });

  final MiBrandIcon icon;
  final Color color;
  final bool darkSurface;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final surface = Paint()
      ..color = (darkSurface ? MiColors.textOnPrimary : color)
          .withValues(alpha: enabled ? 0.18 : 0.08);
    final stroke = Paint()
      ..color = color.withValues(alpha: enabled ? 1 : 0.48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, size.shortestSide * 0.08)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color.withValues(alpha: enabled ? 1 : 0.48)
      ..style = PaintingStyle.fill;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.shortestSide * 0.24),
    );
    canvas.drawRRect(rect, surface);

    final center = Offset(size.width / 2, size.height / 2);
    final unit = size.shortestSide / 64;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(unit);

    switch (icon) {
      case MiBrandIcon.alphabet:
        _drawGlyph(canvas, 'A', const Offset(-13, -21), 33, fill);
      case MiBrandIcon.numbers:
        _drawGlyph(canvas, '1', const Offset(-18, -21), 32, fill);
        _drawGlyph(canvas, '2', const Offset(0, -21), 32, fill);
      case MiBrandIcon.logic:
        _drawPuzzle(canvas, stroke);
      case MiBrandIcon.memory:
        _drawCards(canvas, stroke);
      case MiBrandIcon.writing:
        _drawPencil(canvas, stroke);
      case MiBrandIcon.listening:
        _drawSound(canvas, stroke);
      case MiBrandIcon.rewardStar:
      case MiBrandIcon.achievement:
        _drawStar(canvas, Offset.zero, 22, fill);
      case MiBrandIcon.progress:
        _drawProgress(canvas, stroke);
      case MiBrandIcon.profile:
        _drawProfile(canvas, stroke);
      case MiBrandIcon.parent:
        _drawParent(canvas, stroke);
      case MiBrandIcon.world:
      case MiBrandIcon.exploration:
        _drawWorld(canvas, stroke);
      case MiBrandIcon.garden:
        _drawGarden(canvas, stroke);
      case MiBrandIcon.offline:
        _drawOffline(canvas, stroke);
      case MiBrandIcon.report:
        _drawReport(canvas, stroke);
    }
    canvas.restore();
  }

  void _drawGlyph(
    Canvas canvas,
    String text,
    Offset offset,
    double fontSize,
    Paint paint,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: paint.color,
          fontFamily: 'NunitoRounded',
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  void _drawPuzzle(Canvas canvas, Paint stroke) {
    final path = Path()
      ..moveTo(-20, -18)
      ..lineTo(0, -18)
      ..quadraticBezierTo(0, -27, 8, -27)
      ..quadraticBezierTo(16, -27, 16, -18)
      ..lineTo(22, -18)
      ..lineTo(22, 20)
      ..lineTo(-20, 20)
      ..close();
    canvas.drawPath(path, stroke);
  }

  void _drawCards(Canvas canvas, Paint stroke) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-20, -17, 24, 32),
        const Radius.circular(5),
      ),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3, -13, 24, 32),
        const Radius.circular(5),
      ),
      stroke,
    );
  }

  void _drawPencil(Canvas canvas, Paint stroke) {
    canvas.drawLine(const Offset(-18, 18), const Offset(18, -18), stroke);
    canvas.drawLine(const Offset(10, -23), const Offset(23, -10), stroke);
    canvas.drawLine(const Offset(-22, 22), const Offset(-12, 16), stroke);
  }

  void _drawSound(Canvas canvas, Paint stroke) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-24, -10, 12, 20),
        const Radius.circular(4),
      ),
      stroke,
    );
    canvas.drawLine(const Offset(-12, -10), const Offset(2, -20), stroke);
    canvas.drawLine(const Offset(-12, 10), const Offset(2, 20), stroke);
    canvas.drawArc(
      const Rect.fromLTWH(-4, -18, 28, 36),
      -0.75,
      1.5,
      false,
      stroke,
    );
  }

  void _drawProgress(Canvas canvas, Paint stroke) {
    canvas.drawLine(const Offset(-22, 18), const Offset(22, 18), stroke);
    canvas.drawLine(const Offset(-14, 18), const Offset(-14, 2), stroke);
    canvas.drawLine(const Offset(0, 18), const Offset(0, -12), stroke);
    canvas.drawLine(const Offset(14, 18), const Offset(14, -4), stroke);
  }

  void _drawProfile(Canvas canvas, Paint stroke) {
    canvas.drawCircle(const Offset(0, -11), 10, stroke);
    canvas.drawArc(
      const Rect.fromLTWH(-21, 4, 42, 32),
      math.pi,
      math.pi,
      false,
      stroke,
    );
  }

  void _drawParent(Canvas canvas, Paint stroke) {
    canvas.drawCircle(const Offset(-9, -9), 8, stroke);
    canvas.drawCircle(const Offset(11, -5), 7, stroke);
    canvas.drawArc(
      const Rect.fromLTWH(-24, 5, 30, 26),
      math.pi,
      math.pi,
      false,
      stroke,
    );
    canvas.drawArc(
      const Rect.fromLTWH(0, 7, 28, 24),
      math.pi,
      math.pi,
      false,
      stroke,
    );
  }

  void _drawWorld(Canvas canvas, Paint stroke) {
    canvas.drawCircle(Offset.zero, 22, stroke);
    canvas.drawOval(const Rect.fromLTWH(-10, -22, 20, 44), stroke);
    canvas.drawLine(const Offset(-22, 0), const Offset(22, 0), stroke);
  }

  void _drawGarden(Canvas canvas, Paint stroke) {
    canvas.drawLine(const Offset(0, 20), const Offset(0, -8), stroke);
    canvas.drawOval(const Rect.fromLTWH(-23, -8, 21, 16), stroke);
    canvas.drawOval(const Rect.fromLTWH(2, -8, 21, 16), stroke);
    canvas.drawCircle(const Offset(0, -18), 8, stroke);
  }

  void _drawOffline(Canvas canvas, Paint stroke) {
    canvas.drawArc(
      const Rect.fromLTWH(-24, -18, 48, 34),
      math.pi * 1.12,
      math.pi * 0.76,
      false,
      stroke,
    );
    canvas.drawLine(const Offset(-20, 20), const Offset(20, -20), stroke);
    canvas.drawCircle(const Offset(0, 20), 2, stroke);
  }

  void _drawReport(Canvas canvas, Paint stroke) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-16, -24, 32, 48),
        const Radius.circular(5),
      ),
      stroke,
    );
    canvas.drawLine(const Offset(-8, -8), const Offset(8, -8), stroke);
    canvas.drawLine(const Offset(-8, 4), const Offset(8, 4), stroke);
    canvas.drawLine(const Offset(-8, 16), const Offset(2, 16), stroke);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.46;
      final angle = -1.5708 + i * 0.6283;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiBrandIconPlaceholderPainter oldDelegate) {
    return oldDelegate.icon != icon ||
        oldDelegate.color != color ||
        oldDelegate.darkSurface != darkSurface ||
        oldDelegate.enabled != enabled;
  }
}

class _MiLogoPlaceholderPainter extends CustomPainter {
  const _MiLogoPlaceholderPainter({
    required this.variant,
    required this.darkBackground,
  });

  final MiLogoVariant variant;
  final bool darkBackground;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = darkBackground ? MiColors.navy : MiColors.background;
    final orange = Paint()..color = MiColors.primary;
    final green = Paint()..color = MiColors.secondary;
    final navy = Paint()
      ..color = darkBackground ? MiColors.textOnPrimary : MiColors.textPrimary;
    final star = Paint()..color = MiColors.accent;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.shortestSide * 0.16),
    );
    canvas.drawRRect(rect, bgPaint);

    final symbolOnly = variant == MiLogoVariant.symbol;
    final scale = size.shortestSide / 120;
    canvas.save();
    canvas.translate(
        size.width * (symbolOnly ? 0.18 : 0.08), size.height * 0.18);
    canvas.scale(scale);
    _drawRoundedLetter(canvas, 'M', const Offset(0, 55), 58, orange);
    canvas.drawCircle(const Offset(75, 45), 14, green);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(63, 61, 24, 52),
        const Radius.circular(12),
      ),
      green,
    );
    _drawStar(canvas, const Offset(92, 18), 14, star);
    canvas.restore();

    if (!symbolOnly) {
      final tp = TextPainter(
        text: TextSpan(
          text: variant == MiLogoVariant.stacked ? 'ACADEMY' : 'MI ACADEMY',
          style: TextStyle(
            color: navy.color,
            fontFamily: 'NunitoRounded',
            fontWeight: FontWeight.w800,
            fontSize: size.height * 0.18,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width * 0.82);
      tp.paint(
        canvas,
        Offset(size.width * 0.08, size.height * 0.72),
      );
    }
  }

  void _drawRoundedLetter(
    Canvas canvas,
    String text,
    Offset offset,
    double fontSize,
    Paint paint,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: paint.color,
          fontFamily: 'NunitoRounded',
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.46;
      final angle = -1.5708 + i * 0.6283;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiLogoPlaceholderPainter oldDelegate) {
    return oldDelegate.variant != variant ||
        oldDelegate.darkBackground != darkBackground;
  }
}

String _defaultMascotSemanticLabel(MiMascotEmotion emotion) =>
    switch (emotion) {
      MiMascotEmotion.welcome => 'MI chào con',
      MiMascotEmotion.success => 'MI chúc mừng con',
      MiMascotEmotion.thinking => 'MI đang suy nghĩ',
      MiMascotEmotion.confused => 'MI cần con thử lại',
      MiMascotEmotion.excited => 'MI rất hào hứng',
      MiMascotEmotion.encouraging => 'MI động viên con',
      MiMascotEmotion.tryAgain => 'MI gợi ý thử lại',
      MiMascotEmotion.celebration => 'MI ăn mừng cùng con',
      MiMascotEmotion.apology => 'MI xin lỗi',
      MiMascotEmotion.love => 'MI gửi lời yêu thương',
      MiMascotEmotion.sleeping => 'MI đang nghỉ ngơi',
      MiMascotEmotion.surprised => 'MI ngạc nhiên',
    };

Color _defaultBrandIconColor(MiBrandIcon icon) => switch (icon) {
      MiBrandIcon.alphabet => MiColors.discovery,
      MiBrandIcon.numbers => MiColors.secondary,
      MiBrandIcon.logic => MiColors.creative,
      MiBrandIcon.memory => MiColors.creative,
      MiBrandIcon.writing => MiColors.primary,
      MiBrandIcon.listening => MiColors.discovery,
      MiBrandIcon.rewardStar => MiColors.accent,
      MiBrandIcon.achievement => MiColors.accent,
      MiBrandIcon.progress => MiColors.secondary,
      MiBrandIcon.profile => MiColors.primary,
      MiBrandIcon.parent => MiColors.navy,
      MiBrandIcon.world => MiColors.discovery,
      MiBrandIcon.exploration => MiColors.discovery,
      MiBrandIcon.garden => MiColors.secondary,
      MiBrandIcon.offline => MiColors.primary,
      MiBrandIcon.report => MiColors.discovery,
    };

String _defaultBrandIconSemanticLabel(MiBrandIcon icon) => switch (icon) {
      MiBrandIcon.alphabet => 'Alphabet learning',
      MiBrandIcon.numbers => 'Number learning',
      MiBrandIcon.logic => 'Logic learning',
      MiBrandIcon.memory => 'Memory learning',
      MiBrandIcon.writing => 'Writing practice',
      MiBrandIcon.listening => 'Listening practice',
      MiBrandIcon.rewardStar => 'Reward star',
      MiBrandIcon.achievement => 'Achievement',
      MiBrandIcon.progress => 'Progress',
      MiBrandIcon.profile => 'Profile',
      MiBrandIcon.parent => 'Parent area',
      MiBrandIcon.world => 'World map',
      MiBrandIcon.exploration => 'Exploration',
      MiBrandIcon.garden => 'Achievement garden',
      MiBrandIcon.offline => 'Offline learning',
      MiBrandIcon.report => 'Progress report',
    };
