import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// Full-screen completion overlay shown when a level is finished.
class CompletionOverlay extends StatelessWidget {
  const CompletionOverlay({
    super.key,
    required this.starsEarned,
    required this.maxStars,
    required this.message,
    required this.onNext,
    required this.onReplay,
    required this.onExit,
    this.score = 0,
  });

  /// 0..maxStars — never shows "lose" messaging.
  final int starsEarned;
  final int maxStars;
  final String message;
  final int score;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MiColors.scrim,
      child: Center(
        child: Container(
          margin: GameTheme.screenPadding,
          padding: const EdgeInsets.all(MiTokens.space6),
          decoration: BoxDecoration(
            color: MiColors.surface,
            borderRadius: BorderRadius.circular(GameTheme.overlayRadius),
            boxShadow: MiShadows.raised,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiMascotReaction(
                emotion: MiMascotEmotion.celebration,
                size: MiTokens.mascotReactionMd,
                semanticLabel: 'MI chúc mừng con',
              ),
              const SizedBox(height: MiTokens.space4),
              Text(
                message,
                style: GameTheme.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MiTokens.space4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(maxStars, (i) {
                  final earned = i < starsEarned;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: MiBrandIconView(
                      icon: MiBrandIcon.rewardStar,
                      size: 48,
                      color: earned ? GameTheme.warning : MiColors.border,
                      semanticLabel: earned ? 'Sao đã nhận' : 'Sao chưa nhận',
                    ),
                  );
                }),
              ),
              if (score > 0) ...[
                const SizedBox(height: MiTokens.space4),
                Text('Điểm: $score', style: GameTheme.bodyLarge),
              ],
              const SizedBox(height: MiTokens.space6),
              MiPrimaryButton(
                label: 'Tiếp tục',
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: onNext,
                width: double.infinity,
              ),
              const SizedBox(height: MiTokens.space3),
              MiSecondaryButton(
                label: 'Chơi lại',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: onReplay,
                width: double.infinity,
              ),
              const SizedBox(height: MiTokens.space3),
              MiSecondaryButton(
                label: 'Trang chính',
                icon: const Icon(Icons.home_rounded),
                onPressed: onExit,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
