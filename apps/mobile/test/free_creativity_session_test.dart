import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/src/games/free_creativity/creative_artifact_store.dart';
import 'package:mi_academy/src/games/free_creativity/free_creativity_session.dart';
import 'package:mi_game_core/mi_game_core.dart';

void main() {
  test('completion is participation-based and has no answer evaluation', () {
    final session = FreeCreativitySession(
      level: _creativeLevel,
      childProfileId: 'child-a',
      locale: 'en',
    );

    expect(session.complete(), isNull);
    expect(session.feedbackState, CreativeFeedbackState.needsScene);

    session
      ..selectScene('scene-door')
      ..selectCharacter('character-mi')
      ..selectFeeling('feeling-curious')
      ..updateStoryText('MI opens the door and asks what is inside.');

    final completion = session.complete(now: DateTime.utc(2026, 7, 25));

    expect(completion, isNotNull);
    expect(session.feedbackState, CreativeFeedbackState.shared);
    expect(session.feedback, 'MI loved hearing your idea.');
    expect(completion!.artifact.storyText,
        'MI opens the door and asks what is inside.');
  });

  test('legacy answer flags do not change creative behavior', () {
    final original = FreeCreativitySession(
      level: _creativeLevel,
      childProfileId: 'child-a',
      locale: 'en',
    );
    final inverted = FreeCreativitySession(
      level: _creativeLevelWithLegacyFlags(invert: true),
      childProfileId: 'child-a',
      locale: 'en',
    );

    for (final session in [original, inverted]) {
      session
        ..selectScene('scene-door')
        ..selectCharacter('character-mi')
        ..selectFeeling('feeling-curious')
        ..updateStoryText('MI makes a story.');
      expect(session.complete(now: DateTime.utc(2026, 7, 25)), isNotNull);
      expect(session.feedbackState, CreativeFeedbackState.shared);
      expect(session.artifact!.sceneId, 'scene-door');
    }
  });

  test('empty and whitespace-only stories are guided, not saved', () {
    final session = FreeCreativitySession(
      level: _creativeLevel,
      childProfileId: 'child-a',
      locale: 'en',
    )
      ..selectScene('scene-door')
      ..selectCharacter('character-mi')
      ..selectFeeling('feeling-curious');

    expect(session.complete(), isNull);
    expect(session.feedbackState, CreativeFeedbackState.needsStory);

    session.updateStoryText('    ');

    expect(session.complete(), isNull);
    expect(session.artifact, isNull);
    expect(session.feedback, 'Add a short story idea.');
  });

  test('snapshots preserve creative composition by stable IDs', () {
    final session = FreeCreativitySession(
      level: _creativeLevel,
      childProfileId: 'child-a',
      locale: 'en',
    );

    session
      ..selectScene('scene-door')
      ..selectCharacter('character-friend')
      ..selectFeeling('feeling-happy')
      ..updateStoryText('They draw a map together.  ')
      ..showHint();

    final snapshot = session.saveSnapshot(now: DateTime.utc(2026, 7, 25));
    final restored = FreeCreativitySession(
      level: _creativeLevel,
      childProfileId: 'child-a',
      locale: 'en',
    )..restoreSnapshot(snapshot);

    expect(restored.sceneId, 'scene-door');
    expect(restored.scene, 'A tiny door');
    expect(restored.characterId, 'character-friend');
    expect(restored.feelingId, 'feeling-happy');
    expect(restored.storyText, 'They draw a map together.');
    expect(restored.hintsUsed, 1);
    expect(snapshot.score, 0);
    expect(snapshot.metadata['completionModel'], 'participation');
    expect(snapshot.metadata['assessmentModel'], 'ungraded');
  });

  test('restore rejects wrong child, game, and level without corrupting state',
      () {
    final session = FreeCreativitySession(
      level: _creativeLevel,
      childProfileId: 'child-a',
      locale: 'en',
    )..selectScene('scene-door');
    final snapshot = session.saveSnapshot();

    expect(
      () => FreeCreativitySession(
        level: _creativeLevel,
        childProfileId: 'child-b',
        locale: 'en',
      ).restoreSnapshot(snapshot),
      throwsArgumentError,
    );
    expect(
      () => FreeCreativitySession(
        level: _creativeLevel.copyWith(id: 'other-level'),
        childProfileId: 'child-a',
        locale: 'en',
      ).restoreSnapshot(snapshot),
      throwsArgumentError,
    );
  });

  test('legacy snapshots and removed options restore safely', () {
    final legacySnapshot = MiGameSnapshot(
      gameId: 'free_creativity',
      levelId: 'free-creativity-test',
      childProfileId: 'child-a',
      state: const {
        'scene': 'A tiny door',
        'character': 'MI',
        'feeling': 'curious',
        'storyText': '  A Vietnamese idea: Xin chào MI!  ',
        'status': 'complete',
      },
      createdAt: DateTime.utc(2026, 7, 25),
    );

    final restored = FreeCreativitySession(
      level: _creativeLevel,
      childProfileId: 'child-a',
      locale: 'en',
    )..restoreSnapshot(legacySnapshot);

    expect(restored.sceneId, 'scene-door');
    expect(restored.characterId, 'character-mi');
    expect(restored.feelingId, 'feeling-curious');
    expect(restored.feedbackState, CreativeFeedbackState.composing);
    expect(restored.storyText, '  A Vietnamese idea: Xin chào MI!  ');

    final changedLevel = _creativeLevelWithScenes(const [
      {'id': 'scene-garden', 'label': 'A garden'}
    ]);
    final changed = FreeCreativitySession(
      level: changedLevel,
      childProfileId: 'child-a',
      locale: 'en',
    )..restoreSnapshot(legacySnapshot);
    expect(changed.sceneId, isNull);
    expect(changed.storyText, isNotEmpty);
  });

  test('malformed snapshot values do not crash restore', () {
    final snapshot = MiGameSnapshot(
      gameId: 'free_creativity',
      levelId: 'free-creativity-test',
      childProfileId: 'child-a',
      state: const {
        'sceneId': 99,
        'characterId': ['character-mi'],
        'feelingId': {'id': 'feeling-curious'},
        'storyText': 1234,
        'feedback': 88,
        'feedbackState': 'not-a-state',
        'contentVersion': '1',
      },
      createdAt: DateTime.utc(2026, 7, 25),
      hintsUsed: 99,
    );

    final restored = FreeCreativitySession(
      level: _creativeLevel,
      childProfileId: 'child-a',
      locale: 'en',
    );

    expect(() => restored.restoreSnapshot(snapshot), returnsNormally);
    expect(restored.sceneId, isNull);
    expect(restored.characterId, isNull);
    expect(restored.feelingId, isNull);
    expect(restored.feedback, isNull);
    expect(restored.feedbackState, CreativeFeedbackState.composing);
    expect(restored.hintsUsed, 1);
  });

  test('artifact store saves, updates, lists, and isolates child data',
      () async {
    final store = InMemoryCreativeArtifactStore();
    final session = FreeCreativitySession(
      level: _creativeLevel,
      childProfileId: 'child-a',
      locale: 'vi',
    );

    session
      ..selectScene('scene-door')
      ..selectCharacter('character-mi')
      ..selectFeeling('feeling-curious')
      ..updateStoryText('  MI mở cửa và nói xin chào.  ');

    final first = session.complete(now: DateTime.utc(2026, 7, 25, 8))!;
    await store.save(first.artifact);
    session.updateStoryText('MI mở cửa và vẽ thêm một ngôi sao.');
    final second = session.complete(now: DateTime.utc(2026, 7, 25, 9))!;
    await store.save(second.artifact);

    expect(second.artifact.artifactId, first.artifact.artifactId);
    expect(second.artifact.revision, 2);
    expect(
      store
          .load(
            childProfileId: 'child-a',
            artifactId: first.artifact.artifactId,
          )!
          .storyText,
      'MI mở cửa và vẽ thêm một ngôi sao.',
    );
    expect(
        store.load(
            childProfileId: 'child-b', artifactId: first.artifact.artifactId),
        isNull);
    expect(store.listForChild('child-a'), hasLength(1));
  });

  test('maximum story length is enforced without breaking Vietnamese text', () {
    final session = FreeCreativitySession(
      level: _creativeLevelWithLimits(maximumStoryLength: 12),
      childProfileId: 'child-a',
      locale: 'vi',
    );

    session.updateStoryText('Xin chào MI đang sáng tạo rất dài');

    expect(session.storyText.runes.length, 12);
    expect(session.storyText, 'Xin chào MI ');
  });
}

const _creativeLevel = MiLevel(
  id: 'free-creativity-test',
  gameId: 'free_creativity',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {
      'prompt': 'Tạo câu chuyện tò mò.',
      'options': [
        {'id': 'a', 'text': 'Một cánh cửa nhỏ', 'correct': false},
        {'id': 'b', 'text': 'tiếng gõ nhẹ', 'correct': false},
        {'id': 'c', 'text': 'một câu hỏi mới', 'correct': true},
      ],
      'deepData': {
        'storyLabels': ['Bối cảnh', 'Cảm xúc', 'Chi tiết'],
        'scenes': [
          {'id': 'scene-door', 'label': 'Một cánh cửa nhỏ'}
        ],
        'characters': [
          {'id': 'character-mi', 'label': 'MI'},
          {'id': 'character-friend', 'label': 'một người bạn'}
        ],
        'feelings': [
          {'id': 'feeling-curious', 'label': 'tò mò'},
          {'id': 'feeling-happy', 'label': 'vui'}
        ],
        'storyStarters': [
          {'id': 'starter-question', 'label': 'MI tự hỏi...'}
        ],
        'minimumStoryLength': 1,
        'maximumStoryLength': 500,
      },
    },
    'en': {
      'prompt': 'Create a curious story.',
      'options': [
        {'id': 'a', 'text': 'A tiny door', 'correct': false},
        {'id': 'b', 'text': 'a gentle knock', 'correct': false},
        {'id': 'c', 'text': 'a new question', 'correct': true},
      ],
      'deepData': {
        'storyLabels': ['Setting', 'Feeling', 'Detail'],
        'scenes': [
          {'id': 'scene-door', 'label': 'A tiny door'}
        ],
        'characters': [
          {'id': 'character-mi', 'label': 'MI'},
          {'id': 'character-friend', 'label': 'a friend'}
        ],
        'feelings': [
          {'id': 'feeling-curious', 'label': 'curious'},
          {'id': 'feeling-happy', 'label': 'happy'}
        ],
        'storyStarters': [
          {'id': 'starter-question', 'label': 'MI wondered...'}
        ],
        'minimumStoryLength': 1,
        'maximumStoryLength': 500,
      },
    },
  },
  hints: [
    {
      'localizedText': {
        'en': 'Try one sentence about what happens next.',
      },
    },
  ],
  metadata: {
    'skillIds': ['creative.storytelling'],
    'deepData': {
      'engine': 'creative_story_lab',
      'completionModel': 'participation',
      'assessmentModel': 'ungraded',
    },
  },
);

MiLevel _creativeLevelWithScenes(List<Map<String, String>> scenes) {
  final content = Map<String, Map<String, dynamic>>.from(
    _creativeLevel.localizedContent,
  );
  final en = Map<String, dynamic>.from(content['en']!);
  final deepData = Map<String, dynamic>.from(en['deepData'] as Map);
  deepData['scenes'] = scenes;
  en['deepData'] = deepData;
  content['en'] = en;
  return _creativeLevel.copyWith(localizedContent: content);
}

MiLevel _creativeLevelWithLimits({required int maximumStoryLength}) {
  final content = Map<String, Map<String, dynamic>>.from(
    _creativeLevel.localizedContent,
  );
  final vi = Map<String, dynamic>.from(content['vi']!);
  final deepData = Map<String, dynamic>.from(vi['deepData'] as Map);
  deepData['maximumStoryLength'] = maximumStoryLength;
  vi['deepData'] = deepData;
  content['vi'] = vi;
  return _creativeLevel.copyWith(localizedContent: content);
}

MiLevel _creativeLevelWithLegacyFlags({required bool invert}) {
  final content = Map<String, Map<String, dynamic>>.from(
    _creativeLevel.localizedContent,
  );
  for (final locale in ['vi', 'en']) {
    final localeContent = Map<String, dynamic>.from(content[locale]!);
    localeContent['options'] = [
      for (final option in localeContent['options'] as List)
        {
          ...Map<String, dynamic>.from(option as Map),
          'correct': invert
              ? !(Map<String, dynamic>.from(option)['correct'] as bool)
              : Map<String, dynamic>.from(option)['correct'],
        },
    ];
    content[locale] = localeContent;
  }
  return _creativeLevel.copyWith(localizedContent: content);
}

extension on MiLevel {
  MiLevel copyWith({
    String? id,
    Map<String, Map<String, dynamic>>? localizedContent,
  }) {
    return MiLevel(
      id: id ?? this.id,
      gameId: gameId,
      levelNumber: levelNumber,
      difficulty: difficulty,
      learningObjective: learningObjective,
      localizedContent: localizedContent ?? this.localizedContent,
      hints: hints,
      metadata: metadata,
      assetRefs: assetRefs,
      accessibilityOverrides: accessibilityOverrides,
      contentVersion: contentVersion,
      estimatedSeconds: estimatedSeconds,
      publicationState: publicationState,
    );
  }
}
