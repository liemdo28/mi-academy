import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_content/mi_game_content.dart';

void main() {
  group('ContentValidator.validateLevel', () {
    test('accepts a complete localized level', () {
      final errors = const ContentValidator().validateLevel(_level());

      expect(errors, isEmpty);
    });

    test('requires a non-empty string id', () {
      final missing =
          const ContentValidator().validateLevel(_level()..remove('id'));
      final empty = const ContentValidator().validateLevel(_level(id: ''));
      final wrongType = const ContentValidator().validateLevel(_level(id: 42));

      expect(missing, contains('Field "id" is required and must not be empty'));
      expect(empty, contains('Field "id" is required and must not be empty'));
      expect(
        wrongType,
        contains('Field "id" is required and must not be empty'),
      );
    });

    test('requires positive integer level number', () {
      final missing = const ContentValidator()
          .validateLevel(_level()..remove('levelNumber'));
      final zero =
          const ContentValidator().validateLevel(_level(levelNumber: 0));
      final text =
          const ContentValidator().validateLevel(_level(levelNumber: 'one'));

      expect(missing, contains('Field "levelNumber" is required'));
      expect(
        zero,
        contains('Field "levelNumber" must be a positive integer'),
      );
      expect(
        text,
        contains('Field "levelNumber" must be a positive integer'),
      );
    });

    test('requires difficulty from one to five', () {
      final missing = const ContentValidator()
          .validateLevel(_level()..remove('difficulty'));
      final tooLow =
          const ContentValidator().validateLevel(_level(difficulty: 0));
      final tooHigh =
          const ContentValidator().validateLevel(_level(difficulty: 6));
      final text =
          const ContentValidator().validateLevel(_level(difficulty: 'easy'));

      expect(missing, contains('Field "difficulty" is required'));
      for (final errors in [tooLow, tooHigh, text]) {
        expect(
          errors,
          contains('Field "difficulty" must be an integer between 1 and 5'),
        );
      }
    });

    test('requires Vietnamese localized content map', () {
      final missing = const ContentValidator()
          .validateLevel(_level()..remove('localizedContent'));
      final notMap = const ContentValidator()
          .validateLevel(_level(localizedContent: 'hello'));
      final noVi = const ContentValidator().validateLevel(
        _level(localizedContent: {
          'en': {'prompt': 'Build a word'},
        }),
      );

      expect(missing, contains('Field "localizedContent" is required'));
      expect(notMap, contains('Field "localizedContent" must be a Map'));
      expect(noVi, contains('Vietnamese (vi) localization is required'));
    });

    test('requires hints to be maps with text', () {
      final notList =
          const ContentValidator().validateLevel(_level(hints: 'hint'));
      final notMap =
          const ContentValidator().validateLevel(_level(hints: ['hint']));
      final missingText = const ContentValidator().validateLevel(
        _level(hints: [
          {'voice': 'Try the first letter'},
        ]),
      );
      final emptyText = const ContentValidator().validateLevel(
        _level(hints: [
          {'text': ''},
        ]),
      );

      expect(notList, contains('Field "hints" must be a list'));
      expect(notMap, contains('Hint[0] must be a map'));
      expect(
          missingText, contains('Hint[0] must have a non-empty "text" field'));
      expect(emptyText, contains('Hint[0] must have a non-empty "text" field'));
    });
  });

  group(
      'ContentValidator schema fields (contentVersion/publicationState/estimatedSeconds)',
      () {
    test('accepts a level with all new schema fields present and valid', () {
      final data = _level()
        ..addAll({
          'contentVersion': 2,
          'publicationState': 'published',
          'estimatedSeconds': 90,
        });
      expect(const ContentValidator().validateLevel(data), isEmpty);
    });

    test('rejects an invalid publicationState', () {
      final data = _level()..addAll({'publicationState': 'in_review'});
      final errors = const ContentValidator().validateLevel(data);
      expect(
        errors,
        contains(
          'Field "publicationState" must be one of {draft, published, archived}, got in_review',
        ),
      );
    });

    test('rejects a non-positive estimatedSeconds', () {
      final zero = const ContentValidator()
          .validateLevel(_level()..addAll({'estimatedSeconds': 0}));
      final negative = const ContentValidator()
          .validateLevel(_level()..addAll({'estimatedSeconds': -5}));
      for (final errors in [zero, negative]) {
        expect(
          errors,
          contains('Field "estimatedSeconds" must be a positive integer'),
        );
      }
    });

    test('rejects a non-positive contentVersion', () {
      final errors = const ContentValidator()
          .validateLevel(_level()..addAll({'contentVersion': 0}));
      expect(
        errors,
        contains('Field "contentVersion" must be a positive integer'),
      );
    });
  });

  group('ContentValidator.validateGameLevels', () {
    test('counts valid levels and total levels', () {
      final result = const ContentValidator().validateGameLevels([
        _level(id: 'level-1', levelNumber: 1),
        _level(id: 'level-2', levelNumber: 2),
      ]);

      expect(result.isValid, isTrue);
      expect(result.validLevelCount, 2);
      expect(result.totalLevelCount, 2);
      expect(result.toString(), 'Valid (2/2 levels)');
    });

    test('prefixes per-level errors for invalid entries', () {
      final result = const ContentValidator().validateGameLevels([
        _level(levelNumber: 0),
      ]);

      expect(result.isValid, isFalse);
      expect(
        result.errors,
        contains('Level 1: Field "levelNumber" must be a positive integer'),
      );
      expect(result.validLevelCount, 0);
    });

    test('reports duplicate level IDs without rejecting non-string IDs by cast',
        () {
      final result = const ContentValidator().validateGameLevels([
        _level(id: 'same', levelNumber: 1),
        _level(id: 'same', levelNumber: 2),
        _level(id: 42, levelNumber: 3),
      ]);

      expect(result.isValid, isFalse);
      expect(result.errors, contains('Duplicate level ID: same'));
      expect(
        result.errors,
        contains('Level 3: Field "id" is required and must not be empty'),
      );
    });
  });

  group('ContentLoader', () {
    test('parses a level with explicit game id and optional fields', () {
      final level = ContentLoader.parseLevel(
        _level(
          gameId: 'word_builder',
          learningObjective: 'Build a word',
          metadata: {'skill': 'language.word_building'},
          assetRefs: ['assets/audio/word_meo.wav'],
        ),
        gameId: 'fallback_game',
      );

      expect(level.id, 'level-1');
      expect(level.gameId, 'word_builder');
      expect(level.learningObjective, 'Build a word');
      expect(level.localizedContent['vi']?['prompt'], 'Ghép từ');
      expect(level.hints.single['text'], 'Bắt đầu bằng chữ m');
      expect(level.metadata['skill'], 'language.word_building');
      expect(level.assetRefs, ['assets/audio/word_meo.wav']);
    });

    test('uses supplied game id when level JSON omits gameId', () {
      final level = ContentLoader.parseLevel(_level(), gameId: 'sound_match');

      expect(level.gameId, 'sound_match');
    });

    test('throws ContentLoadException for missing required field', () {
      expect(
        () => ContentLoader.parseLevel(_level()..remove('difficulty'),
            gameId: 'word_builder'),
        throwsA(isA<ContentLoadException>()),
      );
    });

    test('parses new schema fields with their documented defaults', () {
      final withDefaults =
          ContentLoader.parseLevel(_level(), gameId: 'word_builder');
      expect(withDefaults.contentVersion, 1);
      expect(withDefaults.estimatedSeconds, 60);
      expect(withDefaults.publicationState, 'published');

      final explicit = ContentLoader.parseLevel(
        _level()
          ..addAll({
            'contentVersion': 3,
            'estimatedSeconds': 120,
            'publicationState': 'draft',
            'metadata': {
              'ageGroup': 'explorer',
              'skillIds': ['letters.word_building'],
            },
          }),
        gameId: 'word_builder',
      );
      expect(explicit.contentVersion, 3);
      expect(explicit.estimatedSeconds, 120);
      expect(explicit.publicationState, 'draft');
      expect(explicit.ageBand, 'explorer');
      expect(explicit.skillTags, ['letters.word_building']);
    });

    test('throws ContentLoadException for an invalid publicationState', () {
      expect(
        () => ContentLoader.parseLevel(
          _level()..addAll({'publicationState': 'in_review'}),
          gameId: 'word_builder',
        ),
        throwsA(isA<ContentLoadException>()),
      );
    });

    test('throws ContentLoadException for out-of-range difficulty', () {
      expect(
        () => ContentLoader.parseLevel(
          _level(difficulty: 9),
          gameId: 'word_builder',
        ),
        throwsA(isA<ContentLoadException>()),
      );
    });

    test('ageBand and skillTags default safely when metadata omits them', () {
      final level = ContentLoader.parseLevel(_level(), gameId: 'word_builder');
      expect(level.ageBand, isNull);
      expect(level.skillTags, isEmpty);
    });

    test('parses multiple levels in order', () {
      final levels = ContentLoader.parseLevels(
        [
          _level(id: 'level-1', levelNumber: 1),
          _level(id: 'level-2', levelNumber: 2),
        ],
        gameId: 'memory_cards',
      );

      expect(levels.map((level) => level.levelNumber), [1, 2]);
    });
  });

  group('GameContentProvider', () {
    test('loads valid levels and caches them by game', () async {
      final provider = GameContentProvider();

      final levels = await provider.loadLevels(
        [
          _level(id: 'level-1', levelNumber: 1),
          _level(id: 'level-2', levelNumber: 2),
        ],
        gameId: 'robot_commands',
      );

      expect(levels.length, 2);
      expect(provider.getLevels('robot_commands'), levels);
      expect(provider.getLevel('robot_commands', 2)?.id, 'level-2');
      expect(provider.getLevel('robot_commands', 99), isNull);
    });

    test('rejects invalid content before caching', () async {
      final provider = GameContentProvider();

      await expectLater(
        provider.loadLevels([_level(difficulty: 8)], gameId: 'math_race'),
        throwsA(isA<ContentLoadException>()),
      );

      expect(provider.getLevels('math_race'), isEmpty);
    });

    test('clears one game cache or all cached levels', () async {
      final provider = GameContentProvider();
      await provider.loadLevels([_level()], gameId: 'word_builder');
      await provider.loadLevels([_level(id: 'math-1')], gameId: 'math_race');

      provider.clearCache('word_builder');
      expect(provider.getLevels('word_builder'), isEmpty);
      expect(provider.getLevels('math_race'), isNotEmpty);

      provider.clearCache();
      expect(provider.getLevels('math_race'), isEmpty);
    });
  });
}

Map<String, dynamic> _level({
  Object? id = 'level-1',
  Object? gameId,
  Object? levelNumber = 1,
  Object? difficulty = 1,
  Object? localizedContent = const {
    'vi': {'prompt': 'Ghép từ'},
    'en': {'prompt': 'Build a word'},
  },
  Object? hints = const [
    {'text': 'Bắt đầu bằng chữ m'},
  ],
  Object? learningObjective,
  Object? metadata = const <String, dynamic>{},
  Object? assetRefs = const <String>[],
}) {
  return {
    'id': id,
    if (gameId != null) 'gameId': gameId,
    'levelNumber': levelNumber,
    'difficulty': difficulty,
    if (learningObjective != null) 'learningObjective': learningObjective,
    'localizedContent': localizedContent,
    'hints': hints,
    'metadata': metadata,
    'assetRefs': assetRefs,
  };
}
