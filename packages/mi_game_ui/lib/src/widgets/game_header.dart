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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: GameTheme.warning, size: 24),
                  const SizedBox(width: 4),
                  Text(
                    score.toString(),
                    style: GameTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Audio toggle
          if (onAudioToggle != null)
            _HeaderButton(
              icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
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
        child: IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          tooltip: semanticsLabel,
        ),
      ),
    );
  }
}
