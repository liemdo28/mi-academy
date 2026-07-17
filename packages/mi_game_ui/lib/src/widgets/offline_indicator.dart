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
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: GameTheme.warning.withValues(alpha: 0.9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 16,
            color: GameTheme.textPrimary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: GameTheme.bodyMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
