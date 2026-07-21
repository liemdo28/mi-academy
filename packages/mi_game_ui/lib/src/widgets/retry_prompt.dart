import 'package:design_system/design_system.dart';
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
    return Container(
      padding: const EdgeInsets.all(MiTokens.space4),
      decoration: BoxDecoration(
        color: MiColors.accentSoft,
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
        boxShadow: MiShadows.soft,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiMascotReaction(
                emotion: MiMascotEmotion.tryAgain,
                size: MiTokens.mascotReactionSm,
                semanticLabel: 'MI rủ con thử lại',
              ),
              const SizedBox(width: MiTokens.space3),
              Flexible(
                child: Text(
                  message,
                  style: GameTheme.bodyLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: MiTokens.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: MiPrimaryButton(
                  label: 'Thử lại',
                  icon: const Icon(Icons.replay_rounded),
                  onPressed: onRetry,
                ),
              ),
              if (onUseHint != null) ...[
                const SizedBox(width: MiTokens.space2),
                Expanded(
                  child: MiSecondaryButton(
                    label: 'Gợi ý',
                    icon: const Icon(Icons.lightbulb_rounded),
                    onPressed: onUseHint,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
