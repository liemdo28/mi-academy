import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Stable icon identifiers for the MI Academy icon set.
///
/// Code must reference [MiIconName], never a raw asset filename — see
/// docs/design/MI_DESIGN_SYSTEM.md §8 and assets/manifests/README.md.
enum MiIconName {
  play,
  pause,
  replay,
  audio,
  mute,
  slowAudio,
  hint,
  exit,
  home,
  world,
  parent,
  settings,
  download,
  offline,
  lock,
  complete,
  star,
  badge,
  garden,
  language,
  accessibility,
}

/// Icons that ship both an outlined (default) and filled (active) asset.
/// Requesting [MiIcon.filled] for any other icon falls back to outlined.
const _iconsWithFilledVariant = {
  MiIconName.home,
  MiIconName.world,
  MiIconName.parent,
  MiIconName.star,
  MiIconName.garden,
};

String _kebabCase(String camelCase) => camelCase.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (m) => '-${m[1]!.toLowerCase()}',
    );

/// Renders one icon from the MI Academy icon set (assets/icons/, SVG,
/// 24x24 grid, `currentColor` strokes tinted via [color]).
class MiIcon extends StatelessWidget {
  const MiIcon(
    this.name, {
    super.key,
    this.size = 24,
    this.color,
    this.filled = false,
    this.semanticLabel,
  });

  final MiIconName name;
  final double size;
  final Color? color;
  final bool filled;

  /// Accessibility label (§27 — every element needs a real label, e.g.
  /// "Nghe lại từ cá", never "Button 4"). Screens should always pass a
  /// localized label; this falls back to the icon's identifier only so
  /// the widget never ships with no label at all.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final variant =
        filled && _iconsWithFilledVariant.contains(name) ? 'filled' : 'outlined';
    final path = 'assets/icons/icon_${_kebabCase(name.name)}_${variant}_v01.svg';
    return SvgPicture.asset(
      path,
      width: size,
      height: size,
      colorFilter:
          color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      semanticsLabel: semanticLabel ?? name.name,
    );
  }
}
