import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mastery_core/mastery_core.dart';
import 'package:mi_academy/services/mastery_state_store.dart';
import 'package:mi_academy/services/progress_store.dart';
import 'package:mi_academy/services/reward_store.dart';
import 'package:mi_game_progress/mi_game_progress.dart';

/// Covers the real Hive-backed stores GameScreen/GardenScreen use in
/// production. Widget tests elsewhere override these with the in-memory
/// fakes (no platform channel available in `flutter test`); this file is
/// the one place that proves the real Hive round trip actually works,
/// using `Hive.init(tempDir)` the same way packages/offline_sync's tests
/// do.
void main() {
  late Directory tempDir;
  late Box masteryBox;
  late Box rewardsBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mi-progress-store-test-');
    Hive.init(tempDir.path);
    masteryBox = await Hive.openBox('mastery');
    rewardsBox = await Hive.openBox('rewards');
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HiveProgressStore', () {
    test('returns null for a child with no saved progress', () {
      final store = HiveProgressStore(masteryBox);
      expect(store.load('child-1'), isNull);
    });

    test('round-trips attempts and skills through Hive', () async {
      final store = HiveProgressStore(masteryBox);
      final tracker = ProgressTracker(childId: 'child-1');
      tracker.recordCompletion(
        gameId: 'alphabet_explorer',
        levelId: 'lv-1',
        correct: true,
        duration: const Duration(seconds: 20),
        skillIds: ['letters.recognition'],
      );

      await store.save(tracker);
      final restored = store.load('child-1');

      expect(restored, isNotNull);
      expect(restored!.attempts.single.gameId, 'alphabet_explorer');
      expect(restored.getMastery('letters.recognition'), greaterThan(0));
    });

    test('keeps each child\'s progress independent', () async {
      final store = HiveProgressStore(masteryBox);
      final childA = ProgressTracker(childId: 'child-a')
        ..recordCompletion(
          gameId: 'math_race',
          levelId: 'lv-1',
          correct: true,
          duration: const Duration(seconds: 10),
          skillIds: ['math.addition'],
        );
      await store.save(childA);

      expect(store.load('child-b'), isNull);
      expect(store.load('child-a')!.attempts, hasLength(1));
    });
  });

  group('HiveRewardStore', () {
    test('a child with no unlocks has an empty set', () {
      final store = HiveRewardStore(rewardsBox);
      expect(store.unlockedIds('child-1'), isEmpty);
    });

    test('unlock persists and is idempotent', () async {
      final store = HiveRewardStore(rewardsBox);
      await store.unlock('child-1', 'first_completion');
      await store.unlock('child-1', 'first_completion');
      await store.unlock('child-1', 'lessons_completed_5');

      expect(
        store.unlockedIds('child-1'),
        {'first_completion', 'lessons_completed_5'},
      );
    });

    test('keeps each child\'s unlocks independent', () async {
      final store = HiveRewardStore(rewardsBox);
      await store.unlock('child-a', 'first_completion');

      expect(store.unlockedIds('child-b'), isEmpty);
      expect(store.unlockedIds('child-a'), {'first_completion'});
    });
  });

  group('HiveMasteryStateStore', () {
    test('returns null for a child+skill with no saved state', () {
      final store = HiveMasteryStateStore(masteryBox);
      expect(store.load('child-1', 'math.addition.basic'), isNull);
    });

    test('round-trips a MasteryState through Hive', () async {
      final store = HiveMasteryStateStore(masteryBox);
      const state = MasteryState(
        childId: 'child-1',
        skillId: 'math.addition.basic',
        masteryScore: 0.42,
        confidence: 0.3,
        evidenceCount: 2,
        correctCount: 2,
      );

      await store.save(state);
      final restored = store.load('child-1', 'math.addition.basic');

      expect(restored, state);
    });

    test(
        'shares the mastery box with HiveProgressStore without key '
        'collisions', () async {
      final progressStore = HiveProgressStore(masteryBox);
      final masteryStateStore = HiveMasteryStateStore(masteryBox);

      final tracker = ProgressTracker(childId: 'child-1')
        ..recordCompletion(
          gameId: 'math_race',
          levelId: 'lv-1',
          correct: true,
          duration: const Duration(seconds: 10),
          skillIds: ['math.addition'],
        );
      await progressStore.save(tracker);
      await masteryStateStore.save(const MasteryState(
        childId: 'child-1',
        skillId: 'math.addition.basic',
        evidenceCount: 1,
      ));

      expect(progressStore.load('child-1')!.attempts, hasLength(1));
      expect(
        masteryStateStore.load('child-1', 'math.addition.basic')!.evidenceCount,
        1,
      );
    });

    test('keeps each child\'s mastery independent', () async {
      final store = HiveMasteryStateStore(masteryBox);
      await store.save(const MasteryState(
        childId: 'child-a',
        skillId: 'math.addition.basic',
        evidenceCount: 3,
      ));

      expect(store.load('child-b', 'math.addition.basic'), isNull);
      expect(
        store.load('child-a', 'math.addition.basic')!.evidenceCount,
        3,
      );
    });

    test(
        'loadAll returns every skill for a child, sees no other child\'s '
        'data, and is not confused by HiveProgressStore\'s bare-childId key '
        'in the same box', () async {
      final progressStore = HiveProgressStore(masteryBox);
      final masteryStateStore = HiveMasteryStateStore(masteryBox);

      // Same box, unrelated key shape -- must not show up in loadAll.
      await progressStore.save(ProgressTracker(childId: 'child-1'));

      await masteryStateStore.save(const MasteryState(
        childId: 'child-1',
        skillId: 'math.addition.basic',
        evidenceCount: 1,
      ));
      await masteryStateStore.save(const MasteryState(
        childId: 'child-1',
        skillId: 'letters.recognition.uppercase',
        evidenceCount: 4,
      ));
      await masteryStateStore.save(const MasteryState(
        childId: 'child-2',
        skillId: 'math.addition.basic',
        evidenceCount: 9,
      ));

      final childOne = masteryStateStore.loadAll('child-1');
      expect(childOne, hasLength(2));
      expect(
        childOne.map((s) => s.skillId).toSet(),
        {'math.addition.basic', 'letters.recognition.uppercase'},
      );
      expect(childOne.every((s) => s.childId == 'child-1'), isTrue);
    });
  });
}
