import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// Gentle retry prompt — never shows "you lose" or penalty messaging.
class RetryPrompt extends StatelessWidget {
  const RetryPrompt({
    super.key,
    required this.message,
    required this.onRetry,
    this.onUseHint,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onUseHint;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: GameTheme.warning,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    message,
                    style: GameTheme.bodyLarge.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: GameTheme.textPrimary,
                    ),
                    onPressed: onRetry,
                  ),
                ),
                if (onUseHint != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lightbulb_rounded),
                      label: const Text('Gợi ý'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: GameTheme.textPrimary,
                      ),
                      onPressed: onUseHint,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
