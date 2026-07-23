import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_content/mi_game_content.dart';
import 'package:mi_game_core/mi_game_core.dart';

SkillTaxonomy _taxonomy() {
  return SkillTaxonomy.fromJson({
    'version': '1.0.0',
    'masteryThreshold': 0.8,
    'reviewIntervalDays': 3,
    'spacedRecallDays': 2,
    'subjects': [
      {
        'subjectId': 'letters',
        'name': {'vi': 'x', 'en': 'x'},
        'skills': [
          {
            'skillId': 'letters.recognition.uppercase',
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
        'letters': {
          'skills': ['letters.recognition.uppercase'],
          'description': {'vi': 'x', 'en': 'x'},
        },
      },
      'dailyTimeMinutes': {'min': 15, 'max': 25},
      'lessonsPerDay': {'min': 1, 'max': 3},
    },
  ]);
}

MiLevel _level({
  String id = 'ae-lv001',
  String gameId = 'alphabet_explorer',
  int difficulty = 1,
  List<String>? skillIds,
  String? ageGroup = 'junior',
  Map<String, Map<String, dynamic>>? localizedContent,
}) {
  return MiLevel(
    id: id,
    gameId: gameId,
    levelNumber: 1,
    difficulty: difficulty,
    localizedContent: localizedContent ??
        const {
          'vi': {'prompt': 'x'},
          'en': {'prompt': 'x'},
        },
    hints: const [],
    metadata: {
      if (ageGroup != null) 'ageGroup': ageGroup,
      'skillIds': skillIds ?? ['letters.recognition.uppercase'],
    },
  );
}

const _game = GameDescriptor(
  gameId: 'alphabet_explorer',
  subjectId: 'letters',
  ageBands: ['junior', 'explorer'],
);

void main() {
  late ActivityMappingResolver resolver;

  setUp(() {
    resolver = ActivityMappingResolver(
      taxonomy: _taxonomy(),
      curriculum: _curriculum(),
    );
  });

  test('resolves a well-formed level with no errors', () {
    final result = resolver.resolve(game: _game, level: _level());

    expect(result.isValid, isTrue);
    expect(result.errors, isEmpty);
    final mapping = result.mapping!;
    expect(mapping.gameId, 'alphabet_explorer');
    expect(mapping.levelId, 'ae-lv001');
    expect(mapping.activityId, 'ae-lv001');
    expect(mapping.primarySkillId, 'letters.recognition.uppercase');
    expect(mapping.secondarySkillIds, isEmpty);
    expect(mapping.subjectId, 'letters');
    expect(mapping.curriculumNodeId, 'junior.letters');
    expect(mapping.difficulty, 1);
    expect(mapping.prerequisites, isEmpty);
    expect(mapping.supportedLocales, containsAll(['vi', 'en']));
    expect(mapping.contentPackId, 'alphabet_explorer');
  });

  test('a level with no skillIds fails fatally with NO_SKILL_MAPPING', () {
    final result = resolver.resolve(
      game: _game,
      level: _level(skillIds: []),
    );

    expect(result.isValid, isFalse);
    expect(result.hasFatalErrors, isTrue);
    expect(result.errors.single.code, 'NO_SKILL_MAPPING');
  });

  test('a skillId not in the taxonomy fails fatally with UNKNOWN_SKILL_ID',
      () {
    final result = resolver.resolve(
      game: _game,
      level: _level(skillIds: ['letters.not_a_real_skill']),
    );

    expect(result.isValid, isFalse);
    expect(
      result.errors.any((e) => e.code == 'UNKNOWN_SKILL_ID'),
      isTrue,
    );
  });

  test('a display-name-shaped skillId fails fatally, never silently used '
      'as an identity', () {
    final result = resolver.resolve(
      game: _game,
      level: _level(skillIds: ['Nhận biết chữ hoa']),
    );

    expect(result.isValid, isFalse);
    expect(
      result.errors.any((e) => e.code == 'SKILL_ID_LOOKS_LIKE_DISPLAY_NAME'),
      isTrue,
    );
  });

  test('warns (but still resolves) when the game category disagrees with '
      "the skill's taxonomy subject", () {
    const mismatchedGame = GameDescriptor(
      gameId: 'alphabet_explorer',
      subjectId: 'math', // wrong on purpose
      ageBands: ['junior'],
    );

    final result = resolver.resolve(game: mismatchedGame, level: _level());

    expect(result.isValid, isTrue);
    expect(
      result.warnings.any(
        (e) => e.code == 'GAME_CATEGORY_SKILL_SUBJECT_MISMATCH',
      ),
      isTrue,
    );
    // Taxonomy is authoritative, not the game's own category.
    expect(result.mapping!.subjectId, 'letters');
  });

  test('warns when no curriculum node exists for the resolved age/subject',
      () {
    final result = resolver.resolve(
      game: _game,
      level: _level(ageGroup: 'master'), // no 'master.letters' node defined
    );

    expect(result.isValid, isTrue);
    expect(result.mapping!.curriculumNodeId, isNull);
    expect(
      result.warnings.any((e) => e.code == 'NO_CURRICULUM_NODE'),
      isTrue,
    );
  });

  test('warns when level difficulty falls outside the taxonomy range', () {
    final result = resolver.resolve(
      game: _game,
      level: _level(difficulty: 5), // skill's range is 1-2
    );

    expect(result.isValid, isTrue);
    expect(
      result.warnings.any(
        (e) => e.code == 'DIFFICULTY_OUT_OF_TAXONOMY_RANGE',
      ),
      isTrue,
    );
  });

  test('findDuplicateActivityIds flags two different games sharing an ID',
      () {
    const a = CanonicalActivityMapping(
      gameId: 'game_a',
      levelId: 'shared-id',
      activityId: 'shared-id',
      primarySkillId: 'letters.recognition.uppercase',
      secondarySkillIds: [],
      subjectId: 'letters',
      curriculumNodeId: 'junior.letters',
      difficulty: 1,
      prerequisites: [],
      supportedLocales: ['vi'],
      contentPackId: 'game_a',
    );
    const b = CanonicalActivityMapping(
      gameId: 'game_b',
      levelId: 'shared-id',
      activityId: 'shared-id',
      primarySkillId: 'math.counting',
      secondarySkillIds: [],
      subjectId: 'math',
      curriculumNodeId: 'junior.math',
      difficulty: 1,
      prerequisites: [],
      supportedLocales: ['vi'],
      contentPackId: 'game_b',
    );

    final errors = ActivityMappingResolver.findDuplicateActivityIds([a, b]);
    expect(errors, hasLength(1));
    expect(errors.single.code, 'DUPLICATE_ACTIVITY_ID');
  });

  test('findOrphanSkills reports taxonomy skills no mapping covers', () {
    final richTaxonomy = SkillTaxonomy.fromJson({
      'version': '1.0.0',
      'masteryThreshold': 0.8,
      'reviewIntervalDays': 3,
      'spacedRecallDays': 2,
      'subjects': [
        {
          'subjectId': 'letters',
          'name': {'vi': 'x', 'en': 'x'},
          'skills': [
            {
              'skillId': 'letters.recognition.uppercase',
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
              'skillId': 'letters.never_covered',
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
          ],
        },
      ],
    });

    final result = ActivityMappingResolver(
      taxonomy: richTaxonomy,
      curriculum: _curriculum(),
    ).resolve(game: _game, level: _level());

    final orphans = ActivityMappingResolver.findOrphanSkills(
      richTaxonomy,
      [result.mapping!],
    );
    expect(orphans, ['letters.never_covered']);
  });
}
