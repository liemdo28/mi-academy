import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/providers/providers.dart';
import 'package:mi_academy/screens/game_screen.dart';
import 'package:mi_academy/services/parent_settings_store.dart';
import 'package:mi_academy/services/progress_store.dart';
import 'package:mi_academy/services/reward_store.dart';
import 'package:mi_academy/services/snapshot_store.dart';

void main() {
  testWidgets('reloads levels when the routed game type changes',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          parentSettingsStoreProvider.overrideWithValue(
            MemoryParentSettingsStore(
              const ParentSettingsSnapshot(
                language: 'vi',
                localeConfirmed: true,
              ),
            ),
          ),
          snapshotStoreProvider.overrideWithValue(InMemorySnapshotStore()),
          progressStoreProvider.overrideWithValue(InMemoryProgressStore()),
          rewardStoreProvider.overrideWithValue(InMemoryRewardStore()),
        ],
        child: const MaterialApp(
          home: _GameRouteHarness(gameType: 'word_builder'),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 800));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Ghép chữ thành từ!'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          parentSettingsStoreProvider.overrideWithValue(
            MemoryParentSettingsStore(
              const ParentSettingsSnapshot(
                language: 'vi',
                localeConfirmed: true,
              ),
            ),
          ),
          snapshotStoreProvider.overrideWithValue(InMemorySnapshotStore()),
          progressStoreProvider.overrideWithValue(InMemoryProgressStore()),
          rewardStoreProvider.overrideWithValue(InMemoryRewardStore()),
        ],
        child: const MaterialApp(
          home: _GameRouteHarness(gameType: 'math_race'),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 800));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Đường đua cộng trừ'), findsOneWidget);
    expect(find.text('Có 3 quả táo. Có mấy quả tất cả?'), findsOneWidget);
    expect(find.text('Ghép chữ thành từ!'), findsNothing);
  });
}

class _GameRouteHarness extends StatelessWidget {
  const _GameRouteHarness({required this.gameType});

  final String gameType;

  @override
  Widget build(BuildContext context) {
    return GameScreen(
      childId: 'offline-child',
      gameType: gameType,
    );
  }
}
