import 'package:flutter_test/flutter_test.dart';
import 'package:mastery_core/mastery_core.dart';
import 'package:mi_academy/services/level_selector.dart';
import 'package:mi_game_content/mi_game_content.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_progress/mi_game_progress.dart';

SkillTaxonomy _taxonomy() {
  return SkillTaxonomy.fromJson({
    'version': '1.0.0',
    'masteryThreshold': 0.8,
    'reviewIntervalDays': 3,
    'spacedRecallDays': 2,
    'subjects': [
      {
        'subjectId': 'math',
        'name': {'vi': 'x', 'en': 'x'},
        'skills': [
          {
            'skillId': 'math.counting',
            'name': {'vi': 'x', 'en': 'x'},
            'ageGroup': 'junior',
            'difficultyMin': 1,
            'difficultyMax': 2,
            'prerequisites': <String>[],
            'evidenceRules': {
              'minimumAttempts': 4,
              'minimumAccuracy': 0.75,
              'maximumHintRatio': 0.5,
            },
          },
          {
            'skillId': 'math.addition',
            'name': {'vi': 'x', 'en': 'x'},
            'ageGroup': 'junior',
            'difficultyMin': 2,
            'difficultyMax': 4,
            'prerequisites': ['math.counting'],
            'evidenceRules': {
              'minimumAttempts': 4,
              'minimumAccuracy': 0.75,
              'maximumHintRatio': 0.5,
            },
          },
        ],
      },
    ],
  });
}

CurriculumMap _curriculum() {
  return CurriculumMap.fromAgeFiles([
    {
      'version': '1.0.0',
      'ageGroup': 'junior',
      'label': {'vi': 'x', 'en': 'x'},
      'subjects': {
        'math': {
          'skills': ['math.counting', 'math.addition'],
          'description': {'vi': 'x', 'en': 'x'},
        },
      },
      'dailyTimeMinutes': {'min': 15, 'max': 25},
      'lessonsPerDay': {'min': 1, 'max': 3},
    },
  ]);
}

const _game = GameDescriptor(
  gameId: 'math_race',
  subjectId: 'math',
  ageBands: ['junior'],
);

MiLevel _level({
  required String id,
  required int difficulty,
  required String skillId,
  String ageGroup = 'junior',
  Map<String, Map<String, dynamic>>? localizedContent,
}) {
  return MiLevel(
    id: id,
    gameId: 'math_race',
    levelNumber: 1,
    difficulty: difficulty,
    localizedContent: localizedContent ??
        const {
          'vi': {'prompt': 'x'},
          'en': {'prompt': 'x'},
        },
    hints: const [],
    metadata: {'ageGroup': ageGroup, 'skillIds': [skillId]},
  );
}

MasteryState _mastery({
  required String skillId,
  double masteryScore = 0.5,
  int currentDifficulty = 2,
  DateTime? nextReviewAt,
}) {
  return MasteryState(
    childId: 'child-1',
    skillId: skillId,
    masteryScore: masteryScore,
    currentDifficulty: currentDifficulty,
    evidenceCount: 3,
    nextReviewAt: nextReviewAt,
  );
}

void main() {
  late ActivityMappingResolver resolver;

  setUp(() {
    resolver = ActivityMappingResolver(
      taxonomy: _taxonomy(),
      curriculum: _curriculum(),
    );
  });

  const selector = LevelSelector();

  test(
      'a brand-new child (no mastery data) gets the easiest no-prerequisite '
      'level -- guaranteed success', () {
    final levels = [
      _level(id: 'lv-hard', difficulty: 4, skillId: 'math.addition'),
      _level(id: 'lv-easy', difficulty: 1, skillId: 'math.counting'),
      _level(id: 'lv-mid', difficulty: 2, skillId: 'math.counting'),
    ];

    final result = selector.select(
      levels: levels,
      game: _game,
      resolver: resolver,
      masteryBySkill: const {},
      recentAttempts: const [],
      locale: 'vi',
      ageBand: 'junior',
    );

    expect(result.level.id, 'lv-easy');
    expect(result.reasonCodes, contains('NEW_SKILL_EASY_START'));
    expect(result.reasonCodes, contains('PREREQUISITES_MET'));
  });

  test('prefers the level whose difficulty matches persisted mastery', () {
    final levels = [
      _level(id: 'lv-1', difficulty: 1, skillId: 'math.counting'),
      _level(id: 'lv-2', difficulty: 2, skillId: 'math.counting'),
      _level(id: 'lv-3', difficulty: 3, skillId: 'math.counting'),
    ];

    final result = selector.select(
      levels: levels,
      game: _game,
      resolver: resolver,
      masteryBySkill: {
        'math.counting': _mastery(
          skillId: 'math.counting',
          currentDifficulty: 2,
          // Far-future review date -- not due, so REVIEW_DUE never fires
          // and difficulty match is the deciding signal.
          nextReviewAt: DateTime.now().add(const Duration(days: 30)),
        ),
      },
      recentAttempts: const [],
      locale: 'vi',
      ageBand: 'junior',
    );

    expect(result.level.id, 'lv-2');
    expect(result.reasonCodes, contains('DIFFICULTY_MATCH'));
  });

  test('prefers a level whose skill is due for spaced-repetition review',
      () {
    final levels = [
      _level(id: 'lv-counting', difficulty: 2, skillId: 'math.counting'),
      _level(id: 'lv-addition', difficulty: 2, skillId: 'math.addition'),
    ];

    final result = selector.select(
      levels: levels,
      game: _game,
      resolver: resolver,
      masteryBySkill: {
        // Not due -- matches its own difficulty exactly (would otherwise win).
        'math.counting': _mastery(
          skillId: 'math.counting',
          currentDifficulty: 2,
          nextReviewAt: DateTime.now().add(const Duration(days: 30)),
        ),
        // Overdue for review -- must win despite a mismatched difficulty.
        'math.addition': _mastery(
          skillId: 'math.addition',
          currentDifficulty: 4,
          nextReviewAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      },
      recentAttempts: const [],
      locale: 'vi',
      ageBand: 'junior',
    );

    expect(result.level.id, 'lv-addition');
    expect(result.reasonCodes, contains('REVIEW_DUE'));
  });

  test('deprioritizes a level whose prerequisite is not yet introduced', () {
    final levels = [
      _level(id: 'lv-counting', difficulty: 2, skillId: 'math.counting'),
      _level(id: 'lv-addition', difficulty: 2, skillId: 'math.addition'),
    ];

    // math.addition requires math.counting, which has zero mastery evidence.
    final result = selector.select(
      levels: levels,
      game: _game,
      resolver: resolver,
      masteryBySkill: const {},
      recentAttempts: const [],
      locale: 'vi',
      ageBand: 'junior',
    );

    expect(result.level.id, 'lv-counting');
    expect(result.reasonCodes, contains('PREREQUISITES_MET'));
  });

  test('avoids immediately repeating the level just played when an '
      'equally-good alternative exists', () {
    final levels = [
      _level(id: 'lv-a', difficulty: 2, skillId: 'math.counting'),
      _level(id: 'lv-b', difficulty: 2, skillId: 'math.counting'),
    ];
    final mastery = {
      'math.counting': _mastery(
        skillId: 'math.counting',
        currentDifficulty: 2,
        nextReviewAt: DateTime.now().add(const Duration(days: 30)),
      ),
    };

    final result = selector.select(
      levels: levels,
      game: _game,
      resolver: resolver,
      masteryBySkill: mastery,
      recentAttempts: [
        AttemptRecord(
          childId: 'child-1',
          gameId: 'math_race',
          levelId: 'lv-a',
          correct: true,
          attemptedAt: DateTime.now(),
          duration: const Duration(seconds: 30),
        ),
      ],
      locale: 'vi',
      ageBand: 'junior',
    );

    expect(result.level.id, 'lv-b');
    expect(result.reasonCodes, isNot(contains('AVOID_IMMEDIATE_REPEAT')));
  });

  test('falls back to levels.first when nothing resolves a canonical '
      'mapping (e.g. no metadata.skillIds anywhere)', () {
    final levels = [
      const MiLevel(
        id: 'lv-unmapped-1',
        gameId: 'math_race',
        levelNumber: 1,
        difficulty: 1,
        localizedContent: {
          'vi': {'prompt': 'x'},
        },
        hints: [],
      ),
      const MiLevel(
        id: 'lv-unmapped-2',
        gameId: 'math_race',
        levelNumber: 2,
        difficulty: 1,
        localizedContent: {
          'vi': {'prompt': 'x'},
        },
        hints: [],
      ),
    ];

    final result = selector.select(
      levels: levels,
      game: _game,
      resolver: resolver,
      masteryBySkill: const {},
      recentAttempts: const [],
      locale: 'vi',
      ageBand: 'junior',
    );

    expect(result.level.id, 'lv-unmapped-1');
    expect(result.reasonCodes, ['NO_CANONICAL_MAPPING_FALLBACK']);
  });

  test('throws for an empty level list rather than silently picking nothing',
      () {
    expect(
      () => selector.select(
        levels: const [],
        game: _game,
        resolver: resolver,
        masteryBySkill: const {},
        recentAttempts: const [],
        locale: 'vi',
        ageBand: 'junior',
      ),
      throwsArgumentError,
    );
  });

  group('classifyAll -- per-level progression states', () {
    test('a level whose prerequisite is not yet introduced is locked', () {
      final levels = [
        _level(id: 'lv-counting', difficulty: 2, skillId: 'math.counting'),
        _level(id: 'lv-addition', difficulty: 2, skillId: 'math.addition'),
      ];

      final result = selector.classifyAll(
        levels: levels,
        game: _game,
        resolver: resolver,
        masteryBySkill: const {}, // math.counting has zero evidence
        recentAttempts: const [],
        locale: 'vi',
        ageBand: 'junior',
      );

      final addition = result.firstWhere((r) => r.level.id == 'lv-addition');
      expect(addition.state, LevelProgressState.locked);
    });

    test('the level select() would pick is tagged recommended', () {
      final levels = [
        _level(id: 'lv-1', difficulty: 1, skillId: 'math.counting'),
        _level(id: 'lv-2', difficulty: 2, skillId: 'math.counting'),
        _level(id: 'lv-3', difficulty: 3, skillId: 'math.counting'),
      ];
      final mastery = {
        'math.counting': _mastery(
          skillId: 'math.counting',
          currentDifficulty: 2,
          nextReviewAt: DateTime.now().add(const Duration(days: 30)),
        ),
      };

      final selected = selector.select(
        levels: levels,
        game: _game,
        resolver: resolver,
        masteryBySkill: mastery,
        recentAttempts: const [],
        locale: 'vi',
        ageBand: 'junior',
      );
      final classified = selector.classifyAll(
        levels: levels,
        game: _game,
        resolver: resolver,
        masteryBySkill: mastery,
        recentAttempts: const [],
        locale: 'vi',
        ageBand: 'junior',
      );

      final recommended = classified.firstWhere(
        (r) => r.state == LevelProgressState.recommended,
      );
      expect(recommended.level.id, selected.level.id);
    });

    test('a skill overdue for spaced-repetition review marks its level as '
        'review (on a level other than the one select() recommends for '
        'that same overdue skill)', () {
      final levels = [
        _level(id: 'lv-counting', difficulty: 2, skillId: 'math.counting'),
        // Two levels on the overdue skill: select() will recommend
        // whichever matches currentDifficulty exactly (lv-addition-4);
        // the other (lv-addition-3) should still surface as "review",
        // not just fall through to "available".
        _level(id: 'lv-addition-3', difficulty: 3, skillId: 'math.addition'),
        _level(id: 'lv-addition-4', difficulty: 4, skillId: 'math.addition'),
      ];
      final mastery = {
        'math.counting': _mastery(
          skillId: 'math.counting',
          currentDifficulty: 2,
          nextReviewAt: DateTime.now().add(const Duration(days: 30)),
        ),
        'math.addition': _mastery(
          skillId: 'math.addition',
          currentDifficulty: 4,
          nextReviewAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      };

      final result = selector.classifyAll(
        levels: levels,
        game: _game,
        resolver: resolver,
        masteryBySkill: mastery,
        recentAttempts: const [],
        locale: 'vi',
        ageBand: 'junior',
      );

      final recommendedId = result
          .firstWhere((r) => r.state == LevelProgressState.recommended)
          .level
          .id;
      expect(recommendedId, 'lv-addition-4');

      final other = result.firstWhere((r) => r.level.id == 'lv-addition-3');
      expect(other.state, LevelProgressState.review);
    });

    test('a fully mastered skill at or below its current difficulty marks '
        'the level as mastered (on a level other than the recommended '
        'pick)', () {
      final mastery = {
        'math.counting': MasteryState(
          childId: 'child-1',
          skillId: 'math.counting',
          masteryScore: 0.95,
          currentDifficulty: 2,
          evidenceCount: 8,
          status: MasteryStatus.mastered,
          nextReviewAt: DateTime.now().add(const Duration(days: 30)),
        ),
      };
      // Two levels of the same mastered skill so the recommended pick
      // (DIFFICULTY_MATCH on lv-counting-2) doesn't also claim
      // lv-counting-1, isolating the mastered classification.
      final levels = [
        _level(id: 'lv-counting-1', difficulty: 1, skillId: 'math.counting'),
        _level(id: 'lv-counting-2', difficulty: 2, skillId: 'math.counting'),
      ];

      final result = selector.classifyAll(
        levels: levels,
        game: _game,
        resolver: resolver,
        masteryBySkill: mastery,
        recentAttempts: const [],
        locale: 'vi',
        ageBand: 'junior',
      );

      final easyLevel = result.firstWhere((r) => r.level.id == 'lv-counting-1');
      expect(easyLevel.state, LevelProgressState.mastered);
    });

    test('a level explicitly flagged bonus in content metadata is tagged '
        'bonus once prerequisites are met and it is not the recommended '
        'pick', () {
      const bonusLevel = MiLevel(
        id: 'lv-bonus',
        gameId: 'math_race',
        levelNumber: 9,
        difficulty: 2,
        localizedContent: {
          'vi': {'prompt': 'x'},
          'en': {'prompt': 'x'},
        },
        hints: [],
        metadata: {
          'ageGroup': 'junior',
          'skillIds': ['math.counting'],
          'bonus': true,
        },
      );
      final levels = [
        _level(id: 'lv-main', difficulty: 2, skillId: 'math.counting'),
        bonusLevel,
      ];
      final mastery = {
        'math.counting': _mastery(
          skillId: 'math.counting',
          currentDifficulty: 2,
          nextReviewAt: DateTime.now().add(const Duration(days: 30)),
        ),
      };

      final result = selector.classifyAll(
        levels: levels,
        game: _game,
        resolver: resolver,
        masteryBySkill: mastery,
        recentAttempts: const [],
        locale: 'vi',
        ageBand: 'junior',
      );

      final bonus = result.firstWhere((r) => r.level.id == 'lv-bonus');
      expect(bonus.state, LevelProgressState.bonus);
    });

    test('a level meaningfully harder than current mastery is tagged '
        'challenge', () {
      final levels = [
        _level(id: 'lv-current', difficulty: 2, skillId: 'math.addition'),
        _level(id: 'lv-stretch', difficulty: 4, skillId: 'math.addition'),
      ];
      final mastery = {
        // math.addition's own prerequisite (math.counting) must be
        // introduced, or every math.addition level -- including the
        // stretch one under test -- would be locked instead.
        'math.counting': _mastery(
          skillId: 'math.counting',
          currentDifficulty: 2,
          nextReviewAt: DateTime.now().add(const Duration(days: 30)),
        ),
        'math.addition': _mastery(
          skillId: 'math.addition',
          currentDifficulty: 2,
          nextReviewAt: DateTime.now().add(const Duration(days: 30)),
        ),
      };

      final result = selector.classifyAll(
        levels: levels,
        game: _game,
        resolver: resolver,
        masteryBySkill: mastery,
        recentAttempts: const [],
        locale: 'vi',
        ageBand: 'junior',
      );

      final stretch = result.firstWhere((r) => r.level.id == 'lv-stretch');
      expect(stretch.state, LevelProgressState.challenge);
    });

    test('returns an empty list for an empty level list rather than '
        'throwing', () {
      final result = selector.classifyAll(
        levels: const [],
        game: _game,
        resolver: resolver,
        masteryBySkill: const {},
        recentAttempts: const [],
        locale: 'vi',
        ageBand: 'junior',
      );
      expect(result, isEmpty);
    });
  });
}
