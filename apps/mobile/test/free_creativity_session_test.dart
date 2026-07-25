import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/src/games/free_creativity/free_creativity_session.dart';
import 'package:mi_game_core/mi_game_core.dart';

void main() {
  test('completion is participation-based and has no correct answer check', () {
    final session = FreeCreativitySession(level: _creativeLevel, locale: 'en');

    expect(session.complete(), isFalse);
    expect(session.status, FreeCreativityStatus.needsScene);

    session
      ..selectScene('A tiny door')
      ..selectCharacter('MI')
      ..selectFeeling('curious')
      ..updateStoryText('MI opens the door and asks what is inside.');

    expect(session.complete(), isTrue);
    expect(session.status, FreeCreativityStatus.complete);
    expect(session.feedback, 'MI loved hearing your idea.');
  });

  test('hints and snapshots preserve creative composition locally', () {
    final session = FreeCreativitySession(level: _creativeLevel, locale: 'en');

    session
      ..selectScene('A tiny door')
      ..selectCharacter('a friend')
      ..selectFeeling('happy')
      ..updateStoryText('They draw a map together.')
      ..showHint();

    final snapshot = session.saveSnapshot(now: DateTime.utc(2026, 7, 25));
    final restored = FreeCreativitySession(level: _creativeLevel, locale: 'en')
      ..restoreSnapshot(snapshot);

    expect(restored.scene, 'A tiny door');
    expect(restored.character, 'a friend');
    expect(restored.feeling, 'happy');
    expect(restored.storyText, 'They draw a map together.');
    expect(restored.hintsUsed, 1);
    expect(snapshot.metadata['completionModel'], 'participation');
  });
}

const _creativeLevel = MiLevel(
  id: 'free-creativity-test',
  gameId: 'free_creativity',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'en': {
      'prompt': 'Create a curious story.',
      'options': [
        {'id': 'a', 'text': 'A tiny door', 'correct': false},
        {'id': 'b', 'text': 'a gentle knock', 'correct': false},
        {'id': 'c', 'text': 'a new question', 'correct': true},
      ],
      'deepData': {
        'storyLabels': ['Setting', 'Feeling', 'Detail'],
        'storyCards': ['A tiny door', 'a gentle knock', 'a new question'],
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
      'scene': 'creative',
      'targetFeeling': 'curious',
    },
  },
);
