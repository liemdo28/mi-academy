import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// MI's expression states — see docs/design/MI_CHARACTER_GUIDE.md §4.
/// Reduced-motion mode always shows one of these stills instead of an
/// animated rig (docs/animation/MOTION_SYSTEM.md).
enum MiExpression {
  neutral,
  welcome,
  thinking,
  hinting,
  happy,
  celebrating,
  encouraging,
  surprised,
  listening,
  idleSleep,
  errorRecovery,
  goodbye,
}

/// MI's basic gesture poses — see docs/design/MI_CHARACTER_GUIDE.md §5.
/// Only the v1 subset (wave, pointRight) has art; the rest are queued in
/// docs/design/ASSET_PRODUCTION_STATUS.md.
enum MiPose { wave, pointRight }

String _kebabCase(String camelCase) => camelCase.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (m) => '-${m[1]!.toLowerCase()}',
    );

/// Renders a still of the MI character in a given [expression].
///
/// This is Direction B ("Screen-Face Companion", MI_CHARACTER_GUIDE.md §2) —
/// static SVG production art. The animated Rive rig is a follow-up
/// production step; every state here already doubles as its own
/// reduced-motion fallback.
class MiCharacter extends StatelessWidget {
  const MiCharacter({
    super.key,
    this.expression = MiExpression.neutral,
    this.pose,
    this.size = 120,
    this.semanticLabel,
  });

  final MiExpression expression;

  /// When set, renders the pose asset instead of the plain expression body
  /// (poses bundle a fixed, appropriate expression — see asset kit).
  final MiPose? pose;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final path = pose != null
        ? 'packages/design_system/assets/characters/mi/character_mi_pose_${_kebabCase(pose!.name)}_v01.svg'
        : 'packages/design_system/assets/characters/mi/character_mi_face_${_kebabCase(expression.name)}_v01.svg';
    return SvgPicture.asset(
      path,
      width: size,
      height: size * 1.25,
      semanticsLabel: semanticLabel,
    );
  }
}

/// Small icon-form of MI's head (`icon_mi_head_v01`, docs/design/MI_CHARACTER_GUIDE.md
/// §6). Used where the full body doesn't fit — progress markers, small
/// badges — never as a substitute for the full character in a game shell.
class MiCharacterHead extends StatelessWidget {
  const MiCharacterHead({super.key, this.size = 32, this.semanticLabel});

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'packages/design_system/assets/characters/mi/icon_mi_head_v01.svg',
      width: size,
      height: size * (200 / 240),
      semanticsLabel: semanticLabel,
    );
  }
}
