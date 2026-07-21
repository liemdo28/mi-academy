import 'package:design_system/design_system.dart';
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
            const MiMascotReaction(
              emotion: MiMascotEmotion.encouraging,
              size: MiTokens.mascotReactionSm,
              semanticLabel: 'MI đang chuẩn bị trò chơi',
            ),
            const SizedBox(height: MiTokens.space4),
            SizedBox(
              width: 64,
              child: LinearProgressIndicator(
                minHeight: 8,
                backgroundColor: MiColors.primarySoft,
                valueColor: const AlwaysStoppedAnimation(GameTheme.primary),
                borderRadius: BorderRadius.circular(MiTokens.radiusFull),
              ),
            ),
            const SizedBox(height: MiTokens.space4),
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
