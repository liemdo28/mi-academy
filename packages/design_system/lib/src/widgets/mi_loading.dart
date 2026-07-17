import 'package:flutter/material.dart';
import '../theme/mi_theme.dart';

/// Loading indicator for MI Academy.
class MiLoading extends StatelessWidget {
  final String? message;
  final double size;

  const MiLoading({super.key, this.message, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(MiTokens.primaryBlue),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: MiTokens.space4),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen loading overlay.
class MiLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const MiLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black26,
            child: MiLoading(message: message),
          ),
      ],
    );
  }
}
