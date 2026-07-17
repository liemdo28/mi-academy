import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// Standardized hint button with progressive indicator.
class HintButton extends StatelessWidget {
  const HintButton({
    super.key,
    required this.onPressed,
    required this.hintsAvailable,
    required this.hintsRemaining,
  });

  final VoidCallback onPressed;
  final int hintsAvailable;
  final int hintsRemaining;

  @override
  Widget build(BuildContext context) {
    final canHint = hintsRemaining > 0;
    return Semantics(
      label: canHint ? 'Xin gợi ý' : 'Đã hết gợi ý',
      button: true,
      enabled: canHint,
      child: SizedBox(
        width: GameTheme.minTouchTarget,
        height: GameTheme.minTouchTarget,
        child: Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.lightbulb_outline_rounded),
              onPressed: canHint ? onPressed : null,
              color: canHint ? GameTheme.warning : GameTheme.textSecondary,
            ),
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: GameTheme.warning,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$hintsRemaining',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a hint in a bubble on screen.
class HintBubble extends StatelessWidget {
  const HintBubble({
    super.key,
    required this.hintText,
    this.onDismiss,
  });

  final String hintText;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
      ),
      color: GameTheme.warning,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hintText,
                style: GameTheme.bodyLarge.copyWith(color: Colors.white),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: onDismiss,
              ),
          ],
        ),
      ),
    );
  }
}
