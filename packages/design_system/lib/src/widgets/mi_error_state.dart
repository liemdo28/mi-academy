import 'package:flutter/material.dart';
import '../character/mi_character.dart';
import '../icons/mi_icon.dart';
import '../theme/mi_theme.dart';

/// Error state — shown when something goes wrong.
class MiErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;

  const MiErrorState({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MiTokens.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiCharacter(
              expression: MiExpression.errorRecovery,
              size: 72,
              semanticLabel: 'MI đang nghĩ cách giúp con',
            ),
            const SizedBox(height: MiTokens.space4),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: MiTokens.space2),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: MiTokens.space6),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const MiIcon(MiIconName.replay,
                    color: MiColors.textOnPrimary),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
