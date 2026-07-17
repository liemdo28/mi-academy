import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// Progress dots — visual progress indicator for game levels.
class ProgressDots extends StatelessWidget {
  const ProgressDots({
    super.key,
    required this.total,
    required this.completed,
    this.color = GameTheme.primary,
  });

  final int total;
  final int completed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isDone = i < completed;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? color : color.withValues(alpha: 0.3),
            ),
          ),
        );
      }),
    );
  }
}
