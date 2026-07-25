import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/src/games/logic_maze/logic_maze_screen.dart';
import 'package:mi_game_core/mi_game_core.dart';

void main() {
  testWidgets('Logic Maze completes only after running a valid movement path',
      (tester) async {
    _usePhoneViewport(tester);
    MiCompletionResult? completed;

    await tester.pumpWidget(
      MaterialApp(
        home: LogicMazeScreen(
          level: _mazeLevel,
          allLevels: const [_mazeLevel],
          locale: 'en',
          onComplete: (result) => completed = result,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Logic Maze'), findsOneWidget);
    expect(find.byKey(const ValueKey('logic-maze-grid')), findsOneWidget);
    expect(completed, isNull);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('logic-maze-command-up')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('logic-maze-command-up')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('logic-maze-command-up')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('logic-maze-command-right')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('logic-maze-command-right')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('logic-maze-command-right')));
    await tester.pump();
    await tester.tap(find.text('Run path'));
    await tester.pump();

    expect(completed, isNotNull);
    expect(completed!.metadata['engine'], 'logic_maze_movement');
    expect(find.text('You guided MI to the star!'), findsOneWidget);
  });

  testWidgets('Logic Maze supports retry, undo, reset, and Vietnamese text',
      (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: LogicMazeScreen(
          level: _mazeLevel,
          allLevels: [_mazeLevel],
          locale: 'vi',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Mê cung logic'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('logic-maze-command-right')));
    await tester.pump();
    await tester.tap(find.text('Chạy đường đi'));
    await tester.pump();

    expect(
        find.textContaining('ô bị chặn', skipOffstage: false), findsOneWidget);

    await tester.tap(find.byTooltip('Xóa bước cuối'));
    await tester.pump();
    expect(find.text('1. Phải'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('logic-maze-command-up')));
    await tester.pump();
    await tester.tap(find.byTooltip('Làm lại đường đi'));
    await tester.pump();

    expect(
      find.textContaining('Con thêm bước', skipOffstage: false),
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

const _mazeLevel = MiLevel(
  id: 'logic-maze-test',
  gameId: 'logic_maze',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {
      'prompt': 'Dẫn MI tới ngôi sao.',
    },
    'en': {
      'prompt': 'Guide MI to the star.',
    },
  },
  hints: [
    {
      'localizedText': {
        'vi': 'Đi vòng qua ô chặn.',
        'en': 'Move around the blocked square.',
      },
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
