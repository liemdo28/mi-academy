import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_progress/mi_game_progress.dart';

AttemptRecord _attempt(
  String gameId,
  DateTime day, {
  bool correct = true,
  String levelId = 'lv-1',
}) {
  return AttemptRecord(
    childId: 'child-1',
    gameId: gameId,
    levelId: '$gameId-$levelId-${day.toIso8601String()}',
    correct: correct,
    attemptedAt: day,
    duration: const Duration(seconds: 30),
  );
}

AttemptRecord _participationAttempt(String gameId, DateTime day) {
  return AttemptRecord(
    childId: 'child-1',
    gameId: gameId,
    levelId: '$gameId-participation-${day.toIso8601String()}',
    correct: null,
    attemptedAt: day,
    duration: const Duration(seconds: 30),
    assessmentType: AttemptAssessmentType.participation,
    completionModel: AttemptCompletionModel.participation,
  );
}

const _categories = {
  'alphabet_explorer': 'letters',
  'word_builder': 'letters',
  'math_race': 'math',
  'math_supermarket': 'math',
  'memory_cards': 'logic',
  'robot_commands': 'logic',
};

void main() {
  const engine = RewardEngine();
  final day1 = DateTime.utc(2026, 7, 20);

  test('first_completion unlocks after any single correct attempt', () {
    final catalog = RewardCatalog([
      const RewardDefinition(
        id: 'first_completion',
        name: {'vi': 'Sao đầu tiên', 'en': 'First Star'},
        description: {'vi': 'Hoàn thành bài đầu tiên', 'en': 'First lesson'},
        rule: RewardRule.firstCompletion(),
      ),
    ]);

    final unlocked = engine.evaluate(
      catalog: catalog,
      attempts: [_attempt('alphabet_explorer', day1)],
      gameCategories: _categories,
      alreadyUnlocked: {},
    );

    expect(unlocked, ['first_completion']);
  });

  test('first_completion does not unlock from an incorrect attempt', () {
    final catalog = RewardCatalog([
      const RewardDefinition(
        id: 'first_completion',
        name: {'vi': 'x', 'en': 'x'},
        description: {'vi': 'x', 'en': 'x'},
        rule: RewardRule.firstCompletion(),
      ),
    ]);

    final unlocked = engine.evaluate(
      catalog: catalog,
      attempts: [_attempt('alphabet_explorer', day1, correct: false)],
      gameCategories: _categories,
      alreadyUnlocked: {},
    );

    expect(unlocked, isEmpty);
  });

  test('first_completion does not unlock from participation attempts', () {
    final catalog = RewardCatalog([
      const RewardDefinition(
        id: 'first_completion',
        name: {'vi': 'x', 'en': 'x'},
        description: {'vi': 'x', 'en': 'x'},
        rule: RewardRule.firstCompletion(),
      ),
      const RewardDefinition(
        id: 'two_lessons',
        name: {'vi': 'x', 'en': 'x'},
        description: {'vi': 'x', 'en': 'x'},
        rule: RewardRule.completionCount(2),
      ),
    ]);

    final unlocked = engine.evaluate(
      catalog: catalog,
      attempts: [
        _participationAttempt('free_creativity', day1),
        _participationAttempt(
            'free_creativity', day1.add(const Duration(days: 1))),
      ],
      gameCategories: _categories,
      alreadyUnlocked: {},
    );

    expect(unlocked, isEmpty);
  });

  test('already-unlocked rewards are never returned again', () {
    final catalog = RewardCatalog([
      const RewardDefinition(
        id: 'first_completion',
        name: {'vi': 'x', 'en': 'x'},
        description: {'vi': 'x', 'en': 'x'},
        rule: RewardRule.firstCompletion(),
      ),
    ]);

    final unlocked = engine.evaluate(
      catalog: catalog,
      attempts: [_attempt('alphabet_explorer', day1)],
      gameCategories: _categories,
      alreadyUnlocked: {'first_completion'},
    );

    expect(unlocked, isEmpty);
  });

  test('completion_count requires at least N correct completions', () {
    final catalog = RewardCatalog([
      const RewardDefinition(
        id: 'five_lessons',
        name: {'vi': 'x', 'en': 'x'},
        description: {'vi': 'x', 'en': 'x'},
        rule: RewardRule.completionCount(5),
      ),
    ]);

    final fourAttempts = List.generate(
      4,
      (i) => _attempt('math_race', day1, levelId: 'lv-$i'),
    );
    expect(
      engine.evaluate(
        catalog: catalog,
        attempts: fourAttempts,
        gameCategories: _categories,
        alreadyUnlocked: {},
      ),
      isEmpty,
    );

    final fiveAttempts = List.generate(
      5,
      (i) => _attempt('math_race', day1, levelId: 'lv-$i'),
    );
    expect(
      engine.evaluate(
        catalog: catalog,
        attempts: fiveAttempts,
        gameCategories: _categories,
        alreadyUnlocked: {},
      ),
      ['five_lessons'],
    );
  });

  test('category_completed requires every game in that category', () {
    final catalog = RewardCatalog([
      const RewardDefinition(
        id: 'letters_master',
        name: {'vi': 'x', 'en': 'x'},
        description: {'vi': 'x', 'en': 'x'},
        rule: RewardRule.categoryCompleted('letters'),
      ),
    ]);

    // Only one of the two 'letters' games completed -- not enough.
    expect(
      engine.evaluate(
        catalog: catalog,
        attempts: [_attempt('alphabet_explorer', day1)],
        gameCategories: _categories,
        alreadyUnlocked: {},
      ),
      isEmpty,
    );

    // Both 'letters' games completed.
    expect(
      engine.evaluate(
        catalog: catalog,
        attempts: [
          _attempt('alphabet_explorer', day1),
          _attempt('word_builder', day1),
        ],
        gameCategories: _categories,
        alreadyUnlocked: {},
      ),
      ['letters_master'],
    );
  });

  test('all_categories_explored requires at least one game per category', () {
    final catalog = RewardCatalog([
      const RewardDefinition(
        id: 'explorer',
        name: {'vi': 'x', 'en': 'x'},
        description: {'vi': 'x', 'en': 'x'},
        rule: RewardRule.allCategoriesExplored(),
      ),
    ]);

    expect(
      engine.evaluate(
        catalog: catalog,
        attempts: [
          _attempt('alphabet_explorer', day1),
          _attempt('math_race', day1),
        ],
        gameCategories: _categories,
        alreadyUnlocked: {},
      ),
      isEmpty,
    );

    expect(
      engine.evaluate(
        catalog: catalog,
        attempts: [
          _attempt('alphabet_explorer', day1),
          _attempt('math_race', day1),
          _attempt('memory_cards', day1),
        ],
        gameCategories: _categories,
        alreadyUnlocked: {},
      ),
      ['explorer'],
    );
  });

  group('streak_days', () {
    final catalog = RewardCatalog([
      const RewardDefinition(
        id: 'streak_3',
        name: {'vi': 'x', 'en': 'x'},
        description: {'vi': 'x', 'en': 'x'},
        rule: RewardRule.streakDays(3),
      ),
    ]);

    test('does not unlock for non-consecutive days', () {
      final unlocked = engine.evaluate(
        catalog: catalog,
        attempts: [
          _attempt('math_race', DateTime.utc(2026, 7, 1)),
          _attempt('math_race', DateTime.utc(2026, 7, 3)),
          _attempt('math_race', DateTime.utc(2026, 7, 5)),
        ],
        gameCategories: _categories,
        alreadyUnlocked: {},
      );
      expect(unlocked, isEmpty);
    });

    test('unlocks for 3 consecutive calendar days', () {
      final unlocked = engine.evaluate(
        catalog: catalog,
        attempts: [
          _attempt('math_race', DateTime.utc(2026, 7, 1)),
          _attempt('math_race', DateTime.utc(2026, 7, 2)),
          _attempt('math_race', DateTime.utc(2026, 7, 3)),
        ],
        gameCategories: _categories,
        alreadyUnlocked: {},
      );
      expect(unlocked, ['streak_3']);
    });

    test('multiple same-day attempts count as a single streak day', () {
      final unlocked = engine.evaluate(
        catalog: catalog,
        attempts: [
          _attempt('math_race', DateTime.utc(2026, 7, 1, 8)),
          _attempt('math_race', DateTime.utc(2026, 7, 1, 20)),
          _attempt('math_race', DateTime.utc(2026, 7, 2)),
        ],
        gameCategories: _categories,
        alreadyUnlocked: {},
      );
      expect(unlocked, isEmpty); // only 2 distinct days, not 3
    });
  });

  test('RewardDefinition and RewardRule round-trip through JSON', () {
    const definition = RewardDefinition(
      id: 'letters_master',
      name: {'vi': 'Chuyên gia chữ cái', 'en': 'Letters Master'},
      description: {'vi': 'x', 'en': 'x'},
      rule: RewardRule.categoryCompleted('letters'),
    );

    final restored = RewardDefinition.fromJson(definition.toJson());
    expect(restored, definition);
  });
}
