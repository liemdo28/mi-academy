import 'package:flutter/material.dart';

/// Accessible, child-friendly button with guaranteed minimum touch target.
class MiAccessibleButton extends StatelessWidget {
  const MiAccessibleButton({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
    this.child,
    this.label,
    this.icon,
    this.largeTarget = false,
  });

  final VoidCallback? onPressed;
  final String semanticLabel;
  final Widget? child;
  final String? label;
  final IconData? icon;
  final bool largeTarget;

  double get _minSize => largeTarget ? 64.0 : 48.0;

  @override
  Widget build(BuildContext context) {
    final content = child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon),
            if (icon != null && label != null) const SizedBox(width: 8),
            if (label != null) Text(label!),
          ],
        );

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: SizedBox(
        width: _minSize,
        height: _minSize,
        child: ElevatedButton(
          onPressed: onPressed,
          child: content,
        ),
      ),
    );
  }
}

/// Accessible icon-only button with a semantic label.
class MiAccessibleIconButton extends StatelessWidget {
  const MiAccessibleIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.largeTarget = false,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool largeTarget;

  double get _minSize => largeTarget ? 64.0 : 48.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: SizedBox(
        width: _minSize,
        height: _minSize,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
        ),
      ),
    );
  }
}
