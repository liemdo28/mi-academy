import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// Standardized hint button with progressive indicator.
class HintButton extends StatelessWidget {
  const HintButton({
    super.key,
    required this.onPressed,
    required this.hintsAvailable,
    required this.hintsRemaining,
    this.availableSemanticLabel = 'Xin gợi ý',
    this.emptySemanticLabel = 'Đã hết gợi ý',
  });

  final VoidCallback onPressed;
  final int hintsAvailable;
  final int hintsRemaining;
  final String availableSemanticLabel;
  final String emptySemanticLabel;

  @override
  Widget build(BuildContext context) {
    final canHint = hintsRemaining > 0;
    return Semantics(
      label: canHint ? availableSemanticLabel : emptySemanticLabel,
      button: true,
      enabled: canHint,
      child: SizedBox(
        width: GameTheme.minTouchTarget,
        height: GameTheme.minTouchTarget,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Material(
              color: canHint ? MiColors.accentSoft : MiColors.background,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.lightbulb_outline_rounded),
                onPressed: canHint ? onPressed : null,
                color:
                    canHint ? GameTheme.textPrimary : GameTheme.textSecondary,
              ),
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
    return Container(
      padding: const EdgeInsets.all(MiTokens.space4),
      decoration: BoxDecoration(
        color: MiColors.accentSoft,
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
        boxShadow: MiShadows.soft,
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_rounded,
              color: GameTheme.textPrimary, size: 28),
          const SizedBox(width: MiTokens.space3),
          Expanded(
            child: Text(
              hintText,
              style: GameTheme.bodyLarge,
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon:
                  const Icon(Icons.close_rounded, color: GameTheme.textPrimary),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
