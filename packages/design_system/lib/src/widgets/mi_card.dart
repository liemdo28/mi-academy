import 'package:flutter/material.dart';
import '../theme/mi_theme.dart';

/// Standard card with MI Academy styling and optional accent color.
class MiCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double? elevation;

  const MiCard({
    super.key,
    required this.child,
    this.accentColor,
    this.onTap,
    this.padding = const EdgeInsets.all(MiTokens.space4),
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: MiTokens.backgroundCard,
        borderRadius: BorderRadius.circular(MiTokens.radiusLg),
        border: accentColor != null
            ? Border.all(color: accentColor!, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: MiTokens.shadowColor,
            blurRadius: elevation ?? 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

/// Subject card with icon, title, and progress indicator.
class MiSubjectCard extends StatelessWidget {
  final String title;
  final String? icon;
  final double progress; // 0.0 - 1.0
  final Color color;
  final VoidCallback? onTap;

  const MiSubjectCard({
    super.key,
    required this.title,
    this.icon,
    required this.progress,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MiCard(
      accentColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon ?? '📚',
            style: const TextStyle(fontSize: MiTokens.iconXl),
          ),
          const SizedBox(height: MiTokens.space2),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: MiTokens.space3),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: MiTokens.border,
            valueColor: AlwaysStoppedAnimation(color),
            borderRadius: BorderRadius.circular(MiTokens.radiusFull),
            minHeight: 6,
          ),
          const SizedBox(height: MiTokens.space1),
          Text(
            '${(progress * 100).round()}%',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
