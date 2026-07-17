import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// Feedback bubble shown after each action.
///
/// Color-independent feedback (icon + text + color) per accessibility guidelines.
class FeedbackBubble extends StatelessWidget {
  const FeedbackBubble({
    super.key,
    required this.isCorrect,
    required this.message,
    this.icon,
  });

  final bool isCorrect;
  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? GameTheme.success : GameTheme.warning;
    final defaultIcon =
        isCorrect ? Icons.check_circle_rounded : Icons.refresh_rounded;

    return Card(
      color: color,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? defaultIcon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                message,
                style: GameTheme.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Visibility controller for FeedbackBubble (auto-dismiss timer).
class FeedbackController {
  FeedbackController({this.duration = const Duration(milliseconds: 1800)});

  final Duration duration;

  Future<void> showAndHide() async {
    // UI layer typically uses a stateful widget. This is a typed wrapper
    // that documents the expected behaviour.
    await Future.delayed(duration);
  }
}
