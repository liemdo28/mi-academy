import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// Standardized pause button.
class PauseButton extends StatelessWidget {
  const PauseButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tạm dừng trò chơi',
      button: true,
      child: SizedBox(
        width: GameTheme.minTouchTarget,
        height: GameTheme.minTouchTarget,
        child: IconButton(
          icon: const Icon(Icons.pause_rounded),
          onPressed: onPressed,
          color: GameTheme.textPrimary,
        ),
      ),
    );
  }
}

/// Full pause overlay — shown when the game is paused.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: GameTheme.screenPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameTheme.overlayRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tạm dừng',
                  style: GameTheme.headingLarge,
                ),
                const SizedBox(height: 24),
                _PauseButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'Tiếp tục',
                  onPressed: onResume,
                ),
                const SizedBox(height: 12),
                _PauseButton(
                  icon: Icons.refresh_rounded,
                  label: 'Chơi lại',
                  onPressed: onRestart,
                ),
                const SizedBox(height: 12),
                _PauseButton(
                  icon: Icons.exit_to_app_rounded,
                  label: 'Thoát',
                  onPressed: onExit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label, style: GameTheme.buttonLabel),
        style: ElevatedButton.styleFrom(
          backgroundColor: GameTheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameTheme.buttonRadius),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
