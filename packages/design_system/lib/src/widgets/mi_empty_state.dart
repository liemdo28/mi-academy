import 'package:flutter/material.dart';
import '../assets/mi_brand_assets.dart';
import '../widgets/mi_brand_components.dart';
import '../theme/mi_theme.dart';

/// Empty state — shown when a list has no items.
class MiEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final MiBrandIcon? brandIcon;
  final String? emoji;
  final Widget? action;

  const MiEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.brandIcon,
    this.emoji,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MiTokens.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (brandIcon != null)
              MiBrandIconView(
                icon: brandIcon!,
                size: MiTokens.icon2xl,
                semanticLabel: title,
              )
            else
              Text(
                emoji ?? '',
                style: const TextStyle(fontSize: MiTokens.icon2xl),
              ),
            const SizedBox(height: MiTokens.space4),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: MiTokens.space2),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: MiTokens.space6),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
