import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// Full-screen error state shown when a game fails to load.
///
/// Child-friendly — never shows scary error codes or stack traces.
/// Offers a retry button and an exit option.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title = 'Ôi không!',
    this.message = 'Đã có lỗi xảy ra',
    required this.onRetry,
    this.onExit,
    this.retryLabel = 'Thử lại',
    this.exitLabel = 'Về trang chính',
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onExit;
  final String retryLabel;
  final String exitLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GameTheme.background,
      child: Center(
        child: Padding(
          padding: GameTheme.screenPadding,
          child: Container(
            padding: const EdgeInsets.all(MiTokens.space4),
            decoration: BoxDecoration(
              color: MiColors.surface,
              borderRadius: BorderRadius.circular(GameTheme.overlayRadius),
              boxShadow: MiShadows.raised,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MiMascotReaction(
                  emotion: MiMascotEmotion.thinking,
                  size: MiTokens.mascotReactionSm,
                  semanticLabel: 'MI đang nghĩ cách giúp con',
                ),
                const SizedBox(height: MiTokens.space4),
                Text(title, style: GameTheme.headingMedium),
                const SizedBox(height: MiTokens.space2),
                Text(
                  message,
                  style: GameTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: MiTokens.space4),
                MiPrimaryButton(
                  label: retryLabel,
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: onRetry,
                  width: double.infinity,
                ),
                if (onExit != null) ...[
                  const SizedBox(height: MiTokens.space3),
                  MiSecondaryButton(
                    label: exitLabel,
                    icon: const Icon(Icons.home_rounded),
                    onPressed: onExit,
                    width: double.infinity,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
