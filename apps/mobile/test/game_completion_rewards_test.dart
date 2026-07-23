import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/providers/providers.dart';
import 'package:mi_academy/screens/game_screen.dart';
import 'package:mi_academy/services/parent_settings_store.dart';
import 'package:mi_academy/services/progress_store.dart';
import 'package:mi_academy/services/reward_store.dart';
import 'package:mi_academy/services/snapshot_store.dart';

/// Covers the reward/progress wiring GameScreen adds on top of the launcher
/// behavior already covered by game_screen_test.dart.
///
/// Kept in its own file (own isolate) rather than added to
/// game_screen_test.dart: `mi_game_content`'s level loader appears to hold
/// state across repeated loads of the same game within one test isolate --
/// loading 'alphabet_explorer' a second time in the same file left the
/// Choice Engine's option buttons ('A'/'B'/'G') unrendered, even though the
/// prompt text still rendered. That's a pre-existing test-isolation quirk
/// unrelated to this feature; a fresh isolate per file sidesteps it rather
/// than papering over it.
void main() {
  testWidgets(
      'completing a level unlocks the first_completion reward locally',
      (tester) async {
    final rewardStore = InMemoryRewardStore();
    final progressStore = InMemoryProgressStore();

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
          progressStoreProvider.overrideWithValue(progressStore),
          rewardStoreProvider.overrideWithValue(rewardStore),
        ],
        child: const MaterialApp(
          home: GameScreen(
            childId: 'offline-child',
            gameType: 'alphabet_explorer',
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(rewardStore.unlockedIds('offline-child'), isEmpty);

    // Level ae-lv001's prompt is "Tìm chữ A." with 'A' the correct choice
    // (see apps/mobile/assets/levels/alphabet_explorer.json) -- Choice
    // Engine calls onComplete synchronously on a correct tap.
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      rewardStore.unlockedIds('offline-child'),
      contains('first_completion'),
    );
    expect(
      progressStore.load('offline-child')?.attempts,
      isNotEmpty,
    );
    // Proves the canonical mapping actually resolved and was used: the
    // fallback path would have recorded a generic 'alphabet_explorer.general'
    // tag instead of this real, taxonomy-validated skill ID (see
    // content/skills/skill_taxonomy.json and
    // apps/mobile/assets/levels/alphabet_explorer.json's ae-lv001 metadata).
    expect(
      progressStore.load('offline-child')!.getMastery(
            'letters.recognition.uppercase',
          ),
      greaterThan(0),
    );
  });
}
