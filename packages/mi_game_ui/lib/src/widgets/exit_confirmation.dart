import 'package:design_system/design_system.dart';
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
      backgroundColor: MiColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GameTheme.overlayRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MiTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: MiColors.discoverySoft,
                borderRadius: BorderRadius.circular(MiTokens.radiusXl),
              ),
              child: Icon(
                Icons.exit_to_app_rounded,
                size: 40,
                color: GameTheme.secondary,
              ),
            ),
            const SizedBox(height: MiTokens.space4),
            Text(title, style: GameTheme.headingMedium),
            const SizedBox(height: MiTokens.space2),
            Text(
              subtitle,
              style: GameTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MiTokens.space6),
            MiPrimaryButton(
              label: cancelLabel,
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: onCancel,
              width: double.infinity,
            ),
            const SizedBox(height: MiTokens.space3),
            MiSecondaryButton(
              label: confirmLabel,
              icon: const Icon(Icons.exit_to_app_rounded),
              onPressed: onConfirm,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
