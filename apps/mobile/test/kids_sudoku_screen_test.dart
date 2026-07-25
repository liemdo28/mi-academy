import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/src/games/kids_sudoku/kids_sudoku_screen.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

void main() {
  testWidgets('Kids Sudoku completes after filling and checking the grid',
      (tester) async {
    _usePhoneViewport(tester);
    MiCompletionResult? completed;

    await tester.pumpWidget(
      MaterialApp(
        home: KidsSudokuScreen(
          level: _sudokuLevel,
          allLevels: const [_sudokuLevel],
          locale: 'en',
          onComplete: (result) => completed = result,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Kids Sudoku'), findsOneWidget);
    expect(find.byKey(const ValueKey('kids-sudoku-grid')), findsOneWidget);
    expect(completed, isNull);

    await tester.tap(find.byKey(const ValueKey('kids-sudoku-symbol-C')));
    await tester.pump();
    await tester.tap(find.text('Check'));
    await tester.pump();

    expect(completed, isNotNull);
    expect(completed!.metadata['engine'], 'kids_sudoku_grid');
    expect(find.text('You solved the Sudoku grid!'), findsOneWidget);
  });

  testWidgets('Kids Sudoku supports retry, erase, hint, and Vietnamese text',
      (tester) async {
    _usePhoneViewport(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: KidsSudokuScreen(
          level: _sudokuLevel,
          allLevels: [_sudokuLevel],
          locale: 'vi',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sudoku trẻ em'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kids-sudoku-symbol-A')));
    await tester.pump();
    await tester.tap(find.text('Kiểm tra'));
    await tester.pump();
    expect(
      find.textContaining('bị lặp', skipOffstage: false),
      findsOneWidget,
    );

    await tester.tap(find.text('Xóa'));
    await tester.pump();
    expect(find.text('?', skipOffstage: false), findsOneWidget);

    await tester.tap(find.byType(HintButton));
    await tester.pump();
    expect(
      find.text('Nhìn hàng và cột.', skipOffstage: false),
      findsOneWidget,
    );
  });
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(480, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

const _sudokuLevel = MiLevel(
  id: 'kids-sudoku-test',
  gameId: 'kids_sudoku',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {'prompt': 'Điền ô trống.'},
    'en': {'prompt': 'Fill the empty square.'},
  },
  hints: [
    {
      'localizedText': {
        'vi': 'Nhìn hàng và cột.',
        'en': 'Check the row and column.',
      },
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
