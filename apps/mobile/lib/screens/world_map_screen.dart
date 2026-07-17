import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// World map — shows the six zone illustrations.
///
/// Zone unlock/progress state (locked/in-progress/completed) depends on
/// child progress data that Dev 1 owns and hasn't wired up yet, so every
/// zone renders as [MiZoneState.available] rather than inventing fake
/// progress. Tapping is intentionally a no-op for the same reason — there
/// is no real per-zone lesson route yet — but the illustrations are the
/// real production art (docs/design/MI_DESIGN_SYSTEM.md, design/games/).
class WorldMapScreen extends StatelessWidget {
  const WorldMapScreen({super.key});

  static const _zones = [
    (zone: MiWorldZone.alphabetCity, label: 'Thành phố\nchữ cái'),
    (zone: MiWorldZone.mathKingdom, label: 'Vương quốc\ntoán học'),
    (zone: MiWorldZone.logicIsland, label: 'Đảo\ntư duy'),
    (zone: MiWorldZone.scienceLab, label: 'Phòng thí nghiệm\nkhoa học'),
    (zone: MiWorldZone.creativeHouse, label: 'Nhà\nsáng tạo'),
    (zone: MiWorldZone.achievementGarden, label: 'Vườn\nthành tích'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ thế giới')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MiTokens.space4),
          child: Column(
            children: [
              Row(
                children: [
                  const MiCharacter(
                    expression: MiExpression.welcome,
                    size: 48,
                    semanticLabel: 'MI',
                  ),
                  const SizedBox(width: MiTokens.space3),
                  Expanded(
                    child: Text(
                      'Chọn một vùng đất để bắt đầu khám phá!',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MiTokens.space6),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: MiTokens.space4,
                  crossAxisSpacing: MiTokens.space4,
                  childAspectRatio: 0.85,
                ),
                itemCount: _zones.length,
                itemBuilder: (context, index) {
                  final entry = _zones[index];
                  return MiWorldZoneTile(
                    zone: entry.zone,
                    label: entry.label.replaceAll('\n', ' '),
                    state: MiZoneState.available,
                    size: 120,
                    onTap: () {
                      // TODO(dev1): route to the zone's lesson/game list
                      // once real per-zone content data exists.
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
