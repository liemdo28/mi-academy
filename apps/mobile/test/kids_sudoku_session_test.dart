import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/src/games/kids_sudoku/kids_sudoku_session.dart';
import 'package:mi_game_core/mi_game_core.dart';

void main() {
  test('correct symbol completes the grid', () {
    final session = KidsSudokuSession(level: _sudokuLevel, locale: 'en');

    session.setSymbol('C');

    expect(session.check(), isTrue);
    expect(session.status, KidsSudokuStatus.complete);
    expect(session.stars, 3);
  });

  test('validates empty, row, column, and region conflicts', () {
    final session = KidsSudokuSession(level: _sudokuLevel, locale: 'en');

    expect(session.validate(), KidsSudokuStatus.empty);

    session.setSymbol('A');
    expect(session.validate(), KidsSudokuStatus.rowConflict);

    final columnSession = KidsSudokuSession(
      level: _columnConflictLevel,
      locale: 'en',
    )..setSymbol('A');
    expect(columnSession.validate(), KidsSudokuStatus.columnConflict);

    final regionSession = KidsSudokuSession(
      level: _regionConflictLevel,
      locale: 'en',
    )..setSymbol('A');
    expect(regionSession.validate(), KidsSudokuStatus.regionConflict);
  });

  test('erase, hints, and snapshots preserve in-progress state', () {
    final session = KidsSudokuSession(level: _sudokuLevel, locale: 'en');

    session
      ..setSymbol('C')
      ..showHint();

    final snapshot = session.saveSnapshot(now: DateTime.utc(2026, 7, 25));
    final restored = KidsSudokuSession(level: _sudokuLevel, locale: 'en')
      ..restoreSnapshot(snapshot);

    expect(restored.valueAt(restored.blankIndex), 'C');
    expect(restored.hintsUsed, 1);
    expect(restored.feedback, 'Check the row and column.');

    restored.erase();
    expect(restored.valueAt(restored.blankIndex), isNull);
  });

  test('level solvability validator accepts authored answer', () {
    expect(KidsSudokuSession.isLevelSolvable(_sudokuLevel), isTrue);
  });
}

const _sudokuLevel = MiLevel(
  id: 'kids-sudoku-test',
  gameId: 'kids_sudoku',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'en': {'prompt': 'Fill the empty square.'},
  },
  hints: [
    {
      'localizedText': {'en': 'Check the row and column.'},
    },
  ],
  metadata: {
    'skillIds': ['logic.conditions'],
    'deepData': {
      'gridSize': 3,
      'symbols': ['A', 'B', 'C'],
      'blankIndex': 3,
      'givens': {
        '0': 'B',
        '1': 'C',
        '2': 'A',
        '4': 'A',
        '5': 'B',
        '6': 'A',
        '7': 'B',
        '8': 'C',
      },
      'answer': 'C',
    },
  },
);

const _regionConflictLevel = MiLevel(
  id: 'kids-sudoku-region-test',
  gameId: 'kids_sudoku',
  levelNumber: 2,
  difficulty: 2,
  localizedContent: {
    'en': {'prompt': 'Fill the empty square.'},
  },
  hints: [],
  metadata: {
    'deepData': {
      'gridSize': 4,
      'symbols': ['A', 'B', 'C', 'D'],
      'blankIndex': 0,
      'givens': {
        '1': 'B',
        '2': 'C',
        '3': 'D',
        '4': 'C',
        '5': 'A',
        '6': 'D',
        '7': 'B',
        '8': 'B',
        '9': 'D',
        '10': 'A',
        '11': 'C',
        '12': 'C',
        '13': 'A',
        '14': 'B',
        '15': 'D',
      },
      'answer': 'D',
    },
  },
);

const _columnConflictLevel = MiLevel(
  id: 'kids-sudoku-column-test',
  gameId: 'kids_sudoku',
  levelNumber: 3,
  difficulty: 1,
  localizedContent: {
    'en': {'prompt': 'Fill the empty square.'},
  },
  hints: [],
  metadata: {
    'deepData': {
      'gridSize': 3,
      'symbols': ['A', 'B', 'C'],
      'blankIndex': 0,
      'givens': {
        '1': 'B',
        '2': 'C',
        '3': 'A',
        '4': 'C',
        '5': 'B',
        '6': 'B',
        '7': 'A',
        '8': 'C',
      },
      'answer': 'C',
    },
  },
);
