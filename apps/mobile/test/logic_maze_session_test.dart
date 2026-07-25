import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/src/games/logic_maze/logic_maze_session.dart';
import 'package:mi_game_core/mi_game_core.dart';

void main() {
  test('valid command queue reaches the goal and scores a perfect run', () {
    final session = LogicMazeSession(level: _mazeLevel, locale: 'en');

    for (final command in ['up', 'up', 'right', 'right']) {
      session.addCommand(command);
    }

    expect(session.runProgram(), isTrue);
    expect(session.status, LogicMazeRunStatus.reachedGoal);
    expect(session.currentIndex, 2);
    expect(session.attempts, 1);
    expect(session.stars, 3);
  });

  test('movement simulation rejects obstacle collisions and out of bounds', () {
    final session = LogicMazeSession(level: _mazeLevel, locale: 'en');

    expect(
      session.simulate(const ['right']).status,
      LogicMazeRunStatus.hitObstacle,
    );
    expect(
      session.simulate(const ['left']).status,
      LogicMazeRunStatus.outOfBounds,
    );
  });

  test('undo, reset, hints, and snapshots preserve in-progress work', () {
    final session = LogicMazeSession(level: _mazeLevel, locale: 'en');

    session
      ..addCommand('up')
      ..addCommand('right')
      ..removeLast()
      ..showHint();

    expect(session.program, ['up']);
    expect(session.hintsUsed, 1);

    final snapshot = session.saveSnapshot(now: DateTime.utc(2026, 7, 25));
    final restored = LogicMazeSession(level: _mazeLevel, locale: 'en')
      ..restoreSnapshot(snapshot);

    expect(restored.program, ['up']);
    expect(restored.hintsUsed, 1);
    expect(restored.feedback, 'Move around the blocked square.');

    restored.resetProgram();
    expect(restored.program, isEmpty);
    expect(restored.currentIndex, restored.startIndex);
  });

  test('level reachability validator catches blocked goals', () {
    expect(LogicMazeSession.isLevelReachable(_mazeLevel), isTrue);
    expect(LogicMazeSession.isLevelReachable(_blockedMazeLevel), isFalse);
  });
}

const _mazeLevel = MiLevel(
  id: 'logic-maze-test',
  gameId: 'logic_maze',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'en': {
      'prompt': 'Guide MI to the star.',
      'deepData': {
        'pathSummary': '4 safe moves',
      },
    },
  },
  hints: [
    {
      'localizedText': {'en': 'Move around the blocked square.'},
    },
  ],
  metadata: {
    'skillIds': ['logic.maze'],
    'deepData': {
      'gridSize': 3,
      'startIndex': 6,
      'goalIndex': 2,
      'obstacles': [7],
      'commands': ['up', 'up', 'right', 'right'],
    },
  },
);

const _blockedMazeLevel = MiLevel(
  id: 'logic-maze-blocked',
  gameId: 'logic_maze',
  levelNumber: 2,
  difficulty: 1,
  localizedContent: {
    'en': {'prompt': 'Blocked'},
  },
  hints: [],
  metadata: {
    'deepData': {
      'gridSize': 3,
      'startIndex': 6,
      'goalIndex': 2,
      'obstacles': [3, 4, 5, 7],
    },
  },
);
