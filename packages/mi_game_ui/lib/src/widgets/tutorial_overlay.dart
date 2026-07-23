import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// Tutorial overlay — shown at the start of a game or level.
///
/// Per blueprint §3.2, tutorials are part of the shared UI.
class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({
    super.key,
    required this.title,
    required this.message,
    required this.onContinue,
    this.imageHint,
    this.pageNumber,
    this.totalPages,
    this.continueLabel = 'Tiếp tục',
    this.startLabel = 'Bắt đầu',
    this.mascotSemanticLabel = 'MI hướng dẫn cách chơi',
  });

  final String title;
  final String message;
  final VoidCallback onContinue;
  final IconData? imageHint;
  final int? pageNumber;
  final int? totalPages;
  final String continueLabel;
  final String startLabel;
  final String mascotSemanticLabel;

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
              if (imageHint != null)
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: MiColors.discoverySoft,
                    borderRadius: BorderRadius.circular(MiTokens.radiusXl),
                  ),
                  child: Icon(imageHint, size: 56, color: GameTheme.secondary),
                )
              else
                MiMascotReaction(
                  emotion: MiMascotEmotion.encouraging,
                  size: MiTokens.mascotReactionMd,
                  semanticLabel: mascotSemanticLabel,
                ),
              const SizedBox(height: MiTokens.space4),
              Text(title, style: GameTheme.headingMedium),
              const SizedBox(height: MiTokens.space3),
              Text(
                message,
                style: GameTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (pageNumber != null && totalPages != null) ...[
                const SizedBox(height: MiTokens.space4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MiTokens.space3,
                    vertical: MiTokens.space1,
                  ),
                  decoration: BoxDecoration(
                    color: MiColors.primarySoft,
                    borderRadius: BorderRadius.circular(MiTokens.radiusFull),
                  ),
                  child: Text(
                    '${pageNumber!}/${totalPages!}',
                    style: GameTheme.bodyMedium,
                  ),
                ),
              ],
              const SizedBox(height: MiTokens.space6),
              MiPrimaryButton(
                label: pageNumber != null ? continueLabel : startLabel,
                onPressed: onContinue,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
