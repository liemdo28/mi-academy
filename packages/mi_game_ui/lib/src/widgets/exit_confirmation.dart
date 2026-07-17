import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// Confirmation dialog shown before exiting a game.
///
/// Child-friendly wording: "Bạn có muốn thoát không?" with clear
/// continue/exit options. No "lose progress" threats.
class ExitConfirmation extends StatelessWidget {
  const ExitConfirmation({
    super.key,
    required this.onConfirm,
    required this.onCancel,
    this.title = 'Bạn có muốn thoát không?',
    this.subtitle = 'Tiến trình của bạn đã được lưu',
    this.confirmLabel = 'Thoát',
    this.cancelLabel = 'Tiếp tục chơi',
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String title;
  final String subtitle;
  final String confirmLabel;
  final String cancelLabel;

  /// Show the exit confirmation dialog.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ExitConfirmation(
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GameTheme.overlayRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.exit_to_app_rounded,
              size: 48,
              color: GameTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(title, style: GameTheme.headingMedium),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GameTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(cancelLabel, style: GameTheme.buttonLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GameTheme.buttonRadius),
                  ),
                ),
                onPressed: onCancel,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.exit_to_app_rounded),
                label: Text(
                  confirmLabel,
                  style: GameTheme.buttonLabel.copyWith(
                    color: GameTheme.textSecondary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GameTheme.buttonRadius),
                  ),
                ),
                onPressed: onConfirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
