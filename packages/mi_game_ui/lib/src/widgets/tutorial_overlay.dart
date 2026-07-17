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
  });

  final String title;
  final String message;
  final VoidCallback onContinue;
  final IconData? imageHint;
  final int? pageNumber;
  final int? totalPages;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
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
                if (imageHint != null)
                  Icon(imageHint, size: 80, color: GameTheme.primary),
                const SizedBox(height: 16),
                Text(title, style: GameTheme.headingMedium),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: GameTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                if (pageNumber != null && totalPages != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    '${pageNumber!}/${totalPages!}',
                    style: GameTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GameTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(GameTheme.buttonRadius),
                      ),
                    ),
                    child: Text(
                      pageNumber != null ? 'Tiếp tục' : 'Bắt đầu',
                      style: GameTheme.buttonLabel,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
