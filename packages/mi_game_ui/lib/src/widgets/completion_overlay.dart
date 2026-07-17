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
      color: Colors.black54,
      child: Center(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameTheme.overlayRadius),
          ),
          margin: GameTheme.screenPadding,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: GameTheme.headingMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(maxStars, (i) {
                    final earned = i < starsEarned;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.star_rounded,
                        size: 48,
                        color: earned ? GameTheme.warning : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),
                if (score > 0) ...[
                  const SizedBox(height: 16),
                  Text('Điểm: $score', style: GameTheme.bodyLarge),
                ],
                const SizedBox(height: 24),
                _ActionButton(
                  icon: Icons.arrow_forward_rounded,
                  label: 'Tiếp tục',
                  onPressed: onNext,
                  primary: true,
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Chơi lại',
                  onPressed: onReplay,
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.home_rounded,
                  label: 'Trang chính',
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label, style: GameTheme.buttonLabel),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary ? GameTheme.primary : Colors.white,
          foregroundColor: primary ? Colors.white : GameTheme.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameTheme.buttonRadius),
            side: primary
                ? BorderSide.none
                : const BorderSide(color: GameTheme.primary),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
