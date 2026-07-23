import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/providers/providers.dart';
import 'package:mi_academy/screens/game_screen.dart';
import 'package:mi_academy/services/parent_settings_store.dart';
import 'package:mi_academy/services/progress_store.dart';
import 'package:mi_academy/services/reward_store.dart';
import 'package:mi_academy/services/snapshot_store.dart';

/// See game_screen_render_missing_letter_test.dart's doc comment for why
/// this GameScreen render test lives in its own file/isolate.
void main() {
  testWidgets('renders the real Word Builder game for gameType word_builder',
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
          home: GameScreen(childId: 'offline-child', gameType: 'word_builder'),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 800));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Ghép chữ thành từ!'), findsOneWidget);
  });
}
