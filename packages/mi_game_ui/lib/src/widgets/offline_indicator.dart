import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// Small bar displayed at the top of the screen when offline.
///
/// Uses a non-scary design — no red "ERROR" messaging. Just a gentle
/// reminder that the device is offline. Child-friendly wording.
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({
    super.key,
    this.message = 'Đang chơi ngoại tuyến',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: MiTokens.space2,
        horizontal: MiTokens.space4,
      ),
      decoration: BoxDecoration(
        color: MiColors.accentSoft,
        border: Border(
          bottom: BorderSide(color: MiColors.accent.withValues(alpha: 0.35)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 16,
            color: GameTheme.textPrimary,
          ),
          const SizedBox(width: MiTokens.space2),
          Flexible(
            child: Text(
              message,
              style: GameTheme.bodyMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
