import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// Standardized game header bar shown at the top of every game screen.
///
/// Includes: back/exit button, score, pause button, audio toggle.
class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.title,
    this.score,
    this.onPause,
    this.onAudioToggle,
    this.onExit,
    this.isMuted = false,
  });

  final String title;
  final int? score;
  final VoidCallback? onPause;
  final VoidCallback? onAudioToggle;
  final VoidCallback? onExit;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: MiTokens.space3,
        vertical: MiTokens.space2,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: MiTokens.space2,
        vertical: MiTokens.space1,
      ),
      decoration: BoxDecoration(
        color: MiColors.surface,
        borderRadius: BorderRadius.circular(MiTokens.radiusFull),
        boxShadow: MiShadows.soft,
      ),
      child: Row(
        children: [
          // Back button
          if (onExit != null)
            _HeaderButton(
              icon: Icons.arrow_back_rounded,
              onPressed: onExit!,
              semanticsLabel: 'Quay lại',
            ),

          // Title
          Expanded(
            child: Text(
              title,
              style: GameTheme.headingMedium,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Score display
          if (score != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MiTokens.space3,
                  vertical: MiTokens.space2,
                ),
                decoration: BoxDecoration(
                  color: MiColors.accentSoft,
                  borderRadius: BorderRadius.circular(MiTokens.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MiBrandIconView(
                      icon: MiBrandIcon.rewardStar,
                      color: GameTheme.warning,
                      size: 24,
                      decorative: true,
                    ),
                    const SizedBox(width: MiTokens.space1),
                    Text(
                      score.toString(),
                      style: GameTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Audio toggle
          if (onAudioToggle != null)
            _HeaderButton(
              icon:
                  isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              onPressed: onAudioToggle!,
              semanticsLabel: isMuted ? 'Bật âm thanh' : 'Tắt âm thanh',
            ),

          // Pause button
          if (onPause != null)
            _HeaderButton(
              icon: Icons.pause_rounded,
              onPressed: onPause!,
              semanticsLabel: 'Tạm dừng',
            ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.onPressed,
    required this.semanticsLabel,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: SizedBox(
        width: GameTheme.minTouchTarget,
        height: GameTheme.minTouchTarget,
        child: Material(
          color: MiColors.background,
          shape: const CircleBorder(),
          child: IconButton(
            icon: Icon(icon, color: MiColors.textPrimary),
            onPressed: onPressed,
            tooltip: semanticsLabel,
          ),
        ),
      ),
    );
  }
}
