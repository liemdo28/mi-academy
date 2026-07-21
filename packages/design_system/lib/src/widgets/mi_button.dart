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
          backgroundColor: backgroundColor ?? MiColors.primary,
          foregroundColor: foregroundColor ?? MiColors.textOnPrimary,
          disabledBackgroundColor: MiColors.border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MiTokens.radiusFull),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(MiColors.textOnPrimary),
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

/// Primary brand button for child-facing actions.
class MiPrimaryButton extends StatelessWidget {
  const MiPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: MiTokens.touchTargetChildLarge,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: MiColors.primary,
          foregroundColor: MiColors.textOnPrimary,
          disabledBackgroundColor: MiColors.border,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: MiTokens.space6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MiTokens.radiusFull),
          ),
        ),
        child: AnimatedSwitcher(
          duration: MiMotion.resolve(context, MiMotion.fast),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('mi-primary-loading'),
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(MiColors.textOnPrimary),
                  ),
                )
              : Row(
                  key: const ValueKey('mi-primary-content'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: MiTokens.space2),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: MiColors.textOnPrimary),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Secondary brand button for quiet navigation and support actions.
class MiSecondaryButton extends StatelessWidget {
  const MiSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: MiTokens.touchTargetChild,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: MiColors.textPrimary,
          side: const BorderSide(color: MiColors.border, width: 2),
          backgroundColor: MiColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MiTokens.radiusFull),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: MiTokens.space2),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
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
        foregroundColor: borderColor ?? MiColors.primary,
        side: BorderSide(color: borderColor ?? MiColors.primary, width: 2),
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
