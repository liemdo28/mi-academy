import 'package:flutter/material.dart';
import '../theme/mi_theme.dart';

/// Primary button — filled, large, accessible for children.
class MiButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final IconData? icon;

  const MiButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? MiTokens.primaryBlue,
          foregroundColor: foregroundColor ?? MiTokens.textOnPrimary,
          disabledBackgroundColor: MiTokens.border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MiTokens.radiusMd),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(MiTokens.textOnPrimary),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: MiTokens.iconMd),
                    const SizedBox(width: MiTokens.space2),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: MiTokens.fontLg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Secondary outline button.
class MiOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? borderColor;

  const MiOutlinedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: borderColor ?? MiTokens.primaryBlue,
        side: BorderSide(color: borderColor ?? MiTokens.primaryBlue, width: 2),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MiTokens.radiusMd),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon),
            const SizedBox(width: MiTokens.space2),
          ],
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Icon-only button for child-friendly tap targets (min 48x48).
class MiIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const MiIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: backgroundColor ?? MiTokens.primaryBlue,
        borderRadius: BorderRadius.circular(MiTokens.radiusMd),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(MiTokens.radiusMd),
          child: Center(
            child: Icon(
              icon,
              color: iconColor ?? MiTokens.textOnPrimary,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
