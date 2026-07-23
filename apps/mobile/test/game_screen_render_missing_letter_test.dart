import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/providers/providers.dart';
import 'package:mi_academy/screens/game_screen.dart';
import 'package:mi_academy/services/parent_settings_store.dart';
import 'package:mi_academy/services/progress_store.dart';
import 'package:mi_academy/services/reward_store.dart';
import 'package:mi_academy/services/snapshot_store.dart';

/// Split out of game_screen_test.dart into its own file/isolate: running
/// more than one GameScreen render test that goes through
/// activityMappingResolverProvider's asset-backed loader in the same test
/// isolate leaves every test after the first unable to find its expected
/// text -- a pre-existing test-binding asset-cache timing quirk (see
/// game_completion_rewards_test.dart and garden_screen_empty_test.dart for
/// the same pattern with other asset-backed providers), not a production
/// bug.
void main() {
  testWidgets('renders Missing Letter for gameType missing_letter',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          parentSettingsStoreProvider.overrideWithValue(
            MemoryParentSettingsStore(
              const ParentSettingsSnapshot(
                  language: 'vi', localeConfirmed: true),
            ),
          ),
          snapshotStoreProvider.overrideWithValue(InMemorySnapshotStore()),
          progressStoreProvider.overrideWithValue(InMemoryProgressStore()),
          rewardStoreProvider.overrideWithValue(InMemoryRewardStore()),
        ],
        child: const MaterialApp(
          home: GameScreen(
            childId: 'offline-child',
            gameType: 'missing_letter',
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 800));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Chọn chữ còn thiếu: M_O'), findsOneWidget);
  });
}
