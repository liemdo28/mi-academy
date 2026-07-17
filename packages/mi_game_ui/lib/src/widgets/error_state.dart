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
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GameTheme.overlayRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MiCharacter(
                    expression: MiExpression.errorRecovery,
                    size: 64,
                    semanticLabel: 'MI đang nghĩ cách giúp con',
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: GameTheme.headingMedium),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: GameTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(retryLabel, style: GameTheme.buttonLabel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(GameTheme.buttonRadius),
                        ),
                      ),
                      onPressed: onRetry,
                    ),
                  ),
                  if (onExit != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.home_rounded),
                        label: Text(
                          exitLabel,
                          style: GameTheme.buttonLabel.copyWith(
                            color: GameTheme.textSecondary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(GameTheme.buttonRadius),
                          ),
                        ),
                        onPressed: onExit,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
