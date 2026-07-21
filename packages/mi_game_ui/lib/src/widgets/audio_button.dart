import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// Audio toggle button with muted/unmuted states.
///
/// Displays appropriate icon and semantics for screen readers.
class AudioButton extends StatelessWidget {
  const AudioButton({
    super.key,
    required this.isMuted,
    required this.onToggle,
  });

  final bool isMuted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isMuted ? 'Bật âm thanh' : 'Tắt âm thanh',
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
            icon: Icon(
              isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: MiColors.textPrimary,
            ),
            onPressed: onToggle,
            tooltip: isMuted ? 'Bật âm thanh' : 'Tắt âm thanh',
          ),
        ),
      ),
    );
  }
}
