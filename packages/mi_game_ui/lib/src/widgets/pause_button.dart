import 'package:design_system/design_system.dart';
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
        child: Material(
          color: MiColors.surface,
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: MiColors.shadow,
          child: IconButton(
            icon: const Icon(Icons.pause_rounded),
            onPressed: onPressed,
            color: GameTheme.textPrimary,
          ),
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
    this.title = 'Tạm dừng',
    this.resumeLabel = 'Tiếp tục',
    this.restartLabel = 'Chơi lại',
    this.exitLabel = 'Thoát',
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  final String title;
  final String resumeLabel;
  final String restartLabel;
  final String exitLabel;

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
              Text(
                title,
                style: GameTheme.headingLarge,
              ),
              const SizedBox(height: MiTokens.space6),
              _PauseButton(
                icon: Icons.play_arrow_rounded,
                label: resumeLabel,
                onPressed: onResume,
              ),
              const SizedBox(height: MiTokens.space3),
              _PauseButton(
                icon: Icons.refresh_rounded,
                label: restartLabel,
                onPressed: onRestart,
              ),
              const SizedBox(height: MiTokens.space3),
              _PauseButton(
                icon: Icons.exit_to_app_rounded,
                label: exitLabel,
                onPressed: onExit,
              ),
            ],
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
    return MiPrimaryButton(
      label: label,
      icon: Icon(icon),
      onPressed: onPressed,
      width: double.infinity,
    );
  }
}
