import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// Full-screen loading state shown while a game initializes.
///
/// Child-friendly with animated dots and gentle messaging.
class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    this.message = 'Đang tải...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GameTheme.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                backgroundColor: GameTheme.primary.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(GameTheme.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: GameTheme.headingMedium,
            ),
          ],
        ),
      ),
    );
  }
}
