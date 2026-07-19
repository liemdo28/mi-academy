import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// World map — placeholder shell.
///
/// The six zones (Alphabet City, Math Kingdom, Logic Island, Science Lab,
/// Creative House, Achievement Garden) are specified in
/// docs/design/RESPONSIVE_LAYOUT_GUIDE.md §4 and docs/design/MI_DESIGN_SYSTEM.md,
/// but zone illustrations and the locked/available/in-progress/completed
/// state machine are a later production wave (Dev 1 owns the navigation
/// data; Dev 4 owns the zone art). This screen exists so the Child Home
/// "Bản đồ thế giới" entry point is never a dead tap.
class WorldMapScreen extends StatelessWidget {
  const WorldMapScreen({super.key});

  static const _zones = [
    'Thành phố chữ cái',
    'Vương quốc toán học',
    'Đảo tư duy',
    'Phòng thí nghiệm khoa học',
    'Nhà sáng tạo',
    'Vườn thành tích',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ thế giới')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(MiTokens.space8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MiCharacter(
                  expression: MiExpression.thinking,
                  size: 96,
                  semanticLabel: 'MI đang chuẩn bị bản đồ',
                ),
                const SizedBox(height: MiTokens.space6),
                Text(
                  'Bản đồ đang được xây dựng',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: MiTokens.space3),
                Text(
                  'MI sẽ sớm dẫn con khám phá 6 vùng đất học tập:',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: MiTokens.space4),
                Wrap(
                  spacing: MiTokens.space2,
                  runSpacing: MiTokens.space2,
                  alignment: WrapAlignment.center,
                  children: _zones
                      .map(
                        (z) => Chip(
                          label: Text(z),
                          backgroundColor: MiColors.primarySoft,
                          side: BorderSide.none,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
