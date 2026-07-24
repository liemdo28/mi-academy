import 'package:flutter_test/flutter_test.dart';
import 'package:mastery_core/mastery_core.dart';
import 'package:mi_academy/services/level_selector.dart';
import 'package:mi_academy/services/world_progression_service.dart';
import 'package:mi_game_content/mi_game_content.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_progress/mi_game_progress.dart';

/// Uses real, registered [GameRegistry] game IDs (`math_race`,
/// `memory_cards`) throughout -- [WorldProgressionService.buildWorlds]
/// loops over the real static registry internally, so tests can't inject
/// a fake one. The taxonomy/curriculum fixtures below define their own
/// skills for those two real games' real categories ('math', 'logic'),
/// same pattern as `level_selector_test.dart`.
SkillTaxonomy _taxonomy() {
  return SkillTaxonomy.fromJson({
    'version': '1.0.0',
    'masteryThreshold': 0.8,
    'reviewIntervalDays': 3,
    'spacedRecallDays': 2,
    'subjects': [
      {
        'subjectId': 'math',
        'name': {'vi': 'Toán học', 'en': 'Mathematics'},
        'skills': [
          {
            'skillId': 'math.addition',
            'name': {'vi': 'Phép cộng', 'en': 'Addition'},
            'ageGroup': 'junior',
            'difficultyMin': 1,
            'difficultyMax': 4,
            'prerequisites': <String>[],
            'evidenceRules': {
              'minimumAttempts': 4,
              'minimumAccuracy': 0.75,
              'maximumHintRatio': 0.5,
            },
          },
        ],
      },
      {
        'subjectId': 'logic',
        'name': {'vi': 'Tư duy logic', 'en': 'Logic'},
        'skills': [
          {
            'skillId': 'logic.memory',
            'name': {'vi': 'Ghi nhớ', 'en': 'Memory'},
            'ageGroup': 'junior',
            'difficultyMin': 1,
            'difficultyMax': 3,
            'prerequisites': <String>[],
            'evidenceRules': {
              'minimumAttempts': 3,
              'minimumAccuracy': 0.7,
              'maximumHintRatio': 0.5,
            },
          },
        ],
      },
      {
        // Zero games map here -- must still surface as a real, empty
        // world, never fabricated content.
        'subjectId': 'science',
        'name': {'vi': 'Khoa học', 'en': 'Science'},
        'skills': [
          {
            'skillId': 'science.observation',
            'name': {'vi': 'Quan sát', 'en': 'Observation'},
            'ageGroup': 'explorer',
            'difficultyMin': 1,
            'difficultyMax': 3,
            'prerequisites': <String>[],
            'evidenceRules': {
              'minimumAttempts': 3,
              'minimumAccuracy': 0.7,
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
          'skills': ['math.addition'],
          'description': {'vi': 'x', 'en': 'x'},
        },
        'logic': {
          'skills': ['logic.memory'],
          'description': {'vi': 'x', 'en': 'x'},
        },
      },
      'dailyTimeMinutes': {'min': 15, 'max': 25},
      'lessonsPerDay': {'min': 1, 'max': 3},
    },
  ]);
}

MiLevel _level({
  required String id,
  required String gameId,
  required int difficulty,
  required String skillId,
  String ageGroup = 'junior',
}) {
  return MiLevel(
    id: id,
    gameId: gameId,
    levelNumber: 1,
    difficulty: difficulty,
    localizedContent: const {
      'vi': {'prompt': 'x'},
      'en': {'prompt': 'x'},
    },
    hints: const [],
    metadata: {
      'ageGroup': ageGroup,
      'skillIds': [skillId]
    },
  );
}

MasteryState _mastery({
  required String skillId,
  double masteryScore = 0.5,
  int currentDifficulty = 2,
  int evidenceCount = 3,
  DateTime? nextReviewAt,
}) {
  return MasteryState(
    childId: 'child-1',
    skillId: skillId,
    masteryScore: masteryScore,
    currentDifficulty: currentDifficulty,
    evidenceCount: evidenceCount,
    nextReviewAt: nextReviewAt,
  );
}

void main() {
  late ActivityMappingResolver resolver;
  const service = WorldProgressionService();

  setUp(() {
    resolver = ActivityMappingResolver(
        taxonomy: _taxonomy(), curriculum: _curriculum());
  });

  group('buildWorlds', () {
    test(
        'every taxonomy subject gets a world, including one with zero '
        'registered games', () {
      final worlds = service.buildWorlds(
        taxonomy: _taxonomy(),
        resolver: resolver,
        levelsByGame: {
          'math_race': [
            _level(
                id: 'mr-1',
                gameId: 'math_race',
                difficulty: 1,
                skillId: 'math.addition'),
          ],
        },
        masteryBySkill: const {},
        recentAttempts: const [],
        locale: 'vi',
        ageBand: 'junior',
      );

      expect(worlds.map((w) => w.subjectId),
          containsAll(['math', 'logic', 'science']));

      final science = worlds.firstWhere((w) => w.subjectId == 'science');
      expect(science.totalNodes, 0);
      expect(science.completionPercent, 0.0);
      expect(science.name['en'], 'Science');
    });

    test(
        'nodes group under the taxonomy-resolved subjectId, and the '
        'recommended node carries real reason codes', () {
      final worlds = service.buildWorlds(
        taxonomy: _taxonomy(),
        resolver: resolver,
        levelsByGame: {
          'math_race': [
            _level(
                id: 'mr-easy',
                gameId: 'math_race',
                difficulty: 1,
                skillId: 'math.addition'),
            _level(
                id: 'mr-hard',
                gameId: 'math_race',
                difficulty: 4,
                skillId: 'math.addition'),
          ],
        },
        masteryBySkill: const {},
        recentAttempts: const [],
        locale: 'vi',
        ageBand: 'junior',
      );

      final math = worlds.firstWhere((w) => w.subjectId == 'math');
      expect(math.totalNodes, 2);

      final recommended = math.nodesInState(LevelProgressState.recommended);
      expect(recommended, hasLength(1));
      expect(
          recommended.single.level.id, 'mr-easy'); // guaranteed-success start
      expect(recommended.single.reasonCodes, contains('NEW_SKILL_EASY_START'));

      // The non-recommended node must not carry stale reason codes.
      final other = math.nodes.firstWhere((n) => n.level.id != 'mr-easy');
      expect(other.reasonCodes, isEmpty);
    });

    test('completionPercent reflects mastered-vs-total nodes for that world',
        () {
      final worlds = service.buildWorlds(
        taxonomy: _taxonomy(),
        resolver: resolver,
        levelsByGame: {
          'math_race': [
            _level(
                id: 'mr-1',
                gameId: 'math_race',
                difficulty: 1,
                skillId: 'math.addition'),
            _level(
                id: 'mr-2',
                gameId: 'math_race',
                difficulty: 2,
                skillId: 'math.addition'),
          ],
        },
        masteryBySkill: {
          'math.addition': MasteryState(
            childId: 'child-1',
            skillId: 'math.addition',
            masteryScore: 0.95,
            currentDifficulty: 2,
            evidenceCount: 6,
            status: MasteryStatus.mastered,
            nextReviewAt: DateTime.now().add(const Duration(days: 30)),
          ),
        },
        recentAttempts: const [],
        locale: 'vi',
        ageBand: 'junior',
      );

      final math = worlds.firstWhere((w) => w.subjectId == 'math');
      // mr-2 (difficulty matches currentDifficulty exactly) becomes the
      // recommended pick; mr-1 (difficulty 1 <= currentDifficulty 2)
      // falls through to mastered since it isn't the recommended one.
      expect(math.masteredCount, 1);
      expect(math.completionPercent, 0.5);
    });

    test('games in different real categories land in different worlds', () {
      final worlds = service.buildWorlds(
        taxonomy: _taxonomy(),
        resolver: resolver,
        levelsByGame: {
          'math_race': [
            _level(
                id: 'mr-1',
                gameId: 'math_race',
                difficulty: 1,
                skillId: 'math.addition'),
          ],
          'memory_cards': [
            _level(
                id: 'mc-1',
                gameId: 'memory_cards',
                difficulty: 1,
                skillId: 'logic.memory'),
          ],
        },
        masteryBySkill: const {},
        recentAttempts: const [],
        locale: 'vi',
        ageBand: 'junior',
      );

      expect(worlds.firstWhere((w) => w.subjectId == 'math').totalNodes, 1);
      expect(worlds.firstWhere((w) => w.subjectId == 'logic').totalNodes, 1);
    });

    test(
        'a game with no levels supplied contributes no nodes, not a '
        'crash', () {
      final worlds = service.buildWorlds(
        taxonomy: _taxonomy(),
        resolver: resolver,
        levelsByGame: const {},
        masteryBySkill: const {},
        recentAttempts: const [],
        locale: 'vi',
        ageBand: 'junior',
      );

      expect(worlds.every((w) => w.totalNodes == 0), isTrue);
    });
  });

  group('buildInsights', () {
    test(
        'aggregates mastered/review/weak/strong skills from real mastery '
        'data, with taxonomy display names attached', () {
      final insights = service.buildInsights(
        taxonomy: _taxonomy(),
        curriculum: _curriculum(),
        allMastery: [
          _mastery(
            skillId: 'math.addition',
            masteryScore: 0.95,
            nextReviewAt: DateTime.now().add(const Duration(days: 30)),
          ),
          _mastery(
            skillId: 'logic.memory',
            masteryScore: 0.2,
            nextReviewAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
        attempts: const [],
        unlockedRewards: const [],
        ageBand: 'junior',
      );

      expect(insights.masteredSkills.single.skillId, 'math.addition');
      expect(insights.masteredSkills.single.name['en'], 'Addition');

      expect(insights.skillsNeedingReview.single.skillId, 'logic.memory');
      expect(insights.weakSkills.first.skillId, 'logic.memory');
      expect(insights.strongSkills.first.skillId, 'math.addition');
    });

    test(
        'curriculumCompletionBySubject is null when the age band has no '
        'curriculum node for that subject, not a fabricated 0%', () {
      final insights = service.buildInsights(
        taxonomy: _taxonomy(),
        curriculum: _curriculum(), // only defines 'junior' nodes
        allMastery: const [],
        attempts: const [],
        unlockedRewards: const [],
        ageBand: 'explorer', // science's skill is 'explorer' but no node exists
      );

      expect(insights.curriculumCompletionBySubject['science'], isNull);
    });

    test(
        'curriculumCompletionBySubject reflects real mastered-skill '
        'fraction for a node that does exist', () {
      final insights = service.buildInsights(
        taxonomy: _taxonomy(),
        curriculum: _curriculum(),
        allMastery: [
          _mastery(
              skillId: 'math.addition', masteryScore: 0.9, evidenceCount: 5),
        ],
        attempts: const [],
        unlockedRewards: const [],
        ageBand: 'junior',
      );

      expect(insights.curriculumCompletionBySubject['math'], 1.0);
      expect(insights.curriculumCompletionBySubject['logic'], 0.0);
    });

    test(
        'overallAccuracy and totalTimeSpent aggregate real attempts, and '
        'default to zero-safe values with no history', () {
      final empty = service.buildInsights(
        taxonomy: _taxonomy(),
        curriculum: _curriculum(),
        allMastery: const [],
        attempts: const [],
        unlockedRewards: const [],
        ageBand: 'junior',
      );
      expect(empty.overallAccuracy, 0.0);
      expect(empty.totalTimeSpent, Duration.zero);
      expect(empty.streakDays, 0);

      final now = DateTime.now();
      final withHistory = service.buildInsights(
        taxonomy: _taxonomy(),
        curriculum: _curriculum(),
        allMastery: const [],
        attempts: [
          AttemptRecord(
            childId: 'child-1',
            gameId: 'math_race',
            levelId: 'mr-1',
            correct: true,
            attemptedAt: now,
            duration: const Duration(seconds: 40),
          ),
          AttemptRecord(
            childId: 'child-1',
            gameId: 'math_race',
            levelId: 'mr-2',
            correct: false,
            attemptedAt: now,
            duration: const Duration(seconds: 20),
          ),
        ],
        unlockedRewards: const [],
        ageBand: 'junior',
      );
      expect(withHistory.overallAccuracy, 0.5);
      expect(withHistory.totalTimeSpent, const Duration(seconds: 60));
      expect(withHistory.streakDays, 1);
    });

    test(
        'unlockedRewards passes through the caller-provided catalog '
        'as-is -- no fabricated recency ordering', () {
      const reward = RewardDefinition(
        id: 'first_completion',
        name: {'vi': 'x', 'en': 'x'},
        description: {'vi': 'x', 'en': 'x'},
        rule: RewardRule.firstCompletion(),
      );
      final insights = service.buildInsights(
        taxonomy: _taxonomy(),
        curriculum: _curriculum(),
        allMastery: const [],
        attempts: const [],
        unlockedRewards: const [reward],
        ageBand: 'junior',
      );
      expect(insights.unlockedRewards, [reward]);
    });
  });
}
