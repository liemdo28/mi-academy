import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../icons/mi_icon.dart';
import '../theme/mi_theme.dart';

/// The six world-map zones (docs/design/MI_DESIGN_SYSTEM.md, §13 of the
/// product brief). Each has a distinct silhouette so zones are never
/// distinguished by color alone.
enum MiWorldZone {
  alphabetCity,
  mathKingdom,
  logicIsland,
  scienceLab,
  creativeHouse,
  achievementGarden,
}

/// Zone unlock/progress state. One illustration per zone covers all states
/// (§23 asset budget) — locked/completed are expressed as a color filter
/// plus a small badge, not as separate hand-painted variants.
enum MiZoneState { locked, available, inProgress, completed }

const _grayscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

String _kebabCase(String camelCase) => camelCase.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (m) => '-${m[1]!.toLowerCase()}',
    );

/// Renders one world-map zone tile: illustration + state treatment + label.
/// The label is always present (never color/icon alone) per the child
/// usability rule that zones must be identifiable by shape and text.
class MiWorldZoneTile extends StatelessWidget {
  const MiWorldZoneTile({
    super.key,
    required this.zone,
    required this.label,
    this.state = MiZoneState.available,
    this.size = 128,
    this.onTap,
  });

  final MiWorldZone zone;
  final String label;
  final MiZoneState state;
  final double size;
  final VoidCallback? onTap;

  bool get _isLocked => state == MiZoneState.locked;

  @override
  Widget build(BuildContext context) {
    final path =
        'packages/design_system/assets/worlds/world_${_kebabCase(zone.name)}_v01.svg';
    final illustration = Opacity(
      opacity: _isLocked ? 0.55 : 1.0,
      child: ColorFiltered(
        colorFilter: _isLocked
            ? _grayscale
            : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
        child: SvgPicture.asset(path, width: size, height: size),
      ),
    );

    return Semantics(
      label: '$label, ${_stateLabel(state)}',
      button: onTap != null,
      child: InkWell(
        onTap: _isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(MiTokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(MiTokens.space2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  illustration,
                  if (state == MiZoneState.completed)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: _Badge(
                        color: MiColors.success,
                        icon: MiIconName.complete,
                      ),
                    ),
                  if (state == MiZoneState.inProgress)
                    const Positioned(
                      right: -2,
                      bottom: -2,
                      child: _Dot(color: MiColors.primary),
                    ),
                  if (_isLocked)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: _Badge(
                        color: MiColors.textSecondary,
                        icon: MiIconName.lock,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: MiTokens.space2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stateLabel(MiZoneState state) {
    switch (state) {
      case MiZoneState.locked:
        return 'chưa mở khóa';
      case MiZoneState.available:
        return 'sẵn sàng';
      case MiZoneState.inProgress:
        return 'đang học';
      case MiZoneState.completed:
        return 'đã hoàn thành';
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.color, required this.icon});

  final Color color;
  final MiIconName icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: MiColors.surface, width: 2),
      ),
      child: Center(
        child: MiIcon(icon, size: 16, color: MiColors.surface),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: MiColors.surface, width: 2),
      ),
    );
  }
}
