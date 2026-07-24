import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/src/games/deep_logic/deep_logic_game_screen.dart';
import 'package:mi_game_core/mi_game_core.dart';

void main() {
  for (final fixture in _fixtures) {
    testWidgets('renders ${fixture.title} as a bespoke deep scene',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DeepLogicGameScreen(
            title: fixture.title,
            worldLabel: fixture.worldLabel,
            level: fixture.level,
            allLevels: [fixture.level],
            scene: fixture.scene,
            primaryColor: fixture.color,
            onExit: () {},
            onComplete: (_) {},
            locale: 'en',
          ),
        ),
      );
      await tester.pump();

      expect(find.text(fixture.title), findsOneWidget);
      expect(find.text(fixture.sceneLabel), findsOneWidget);
      await tester.dragUntilVisible(
        find.text(fixture.prompt),
        find.byType(ListView),
        const Offset(0, -260),
      );
      expect(find.text(fixture.prompt), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('Correct answer'),
        find.byType(ListView),
        const Offset(0, -180),
      );
      expect(find.text('Correct answer'), findsAtLeastNWidgets(1));
    });
  }

  testWidgets('completes a deep logic scene with score metadata',
      (tester) async {
    MiCompletionResult? completed;
    final fixture = _fixtures.first;
    await tester.pumpWidget(
      MaterialApp(
        home: DeepLogicGameScreen(
          title: fixture.title,
          worldLabel: fixture.worldLabel,
          level: fixture.level,
          allLevels: [fixture.level],
          scene: fixture.scene,
          primaryColor: fixture.color,
          onExit: () {},
          onComplete: (result) => completed = result,
          locale: 'en',
        ),
      ),
    );
    await tester.pump();

    await tester.dragUntilVisible(
      find.text('Correct answer'),
      find.byType(ListView),
      const Offset(0, -180),
    );
    await tester.tap(find.text('Correct answer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(completed, isNotNull);
    expect(completed!.gameId, fixture.level.gameId);
    expect(completed!.metadata['deepLogicScene'], fixture.scene.name);
    expect(completed!.metadata['stars'], 3);
  });
}

const _fixtures = [
  _Fixture(
    title: 'Logic Maze',
    worldLabel: 'MI plans a path through the maze.',
    sceneLabel: 'Path planner',
    scene: DeepLogicScene.maze,
    color: Color(0xFF8E6BFF),
    level: _mazeLevel,
  ),
  _Fixture(
    title: 'Kids Sudoku',
    worldLabel: 'MI solves small grids with clues.',
    sceneLabel: 'Mini grid',
    scene: DeepLogicScene.sudoku,
    color: Color(0xFF8E6BFF),
    level: _sudokuLevel,
  ),
  _Fixture(
    title: 'Reasoning Detective',
    worldLabel: 'MI follows clues step by step.',
    sceneLabel: 'Clue board',
    scene: DeepLogicScene.detective,
    color: Color(0xFF8E6BFF),
    level: _detectiveLevel,
  ),
  _Fixture(
    title: 'Free Creativity',
    worldLabel: 'MI helps turn ideas into a story.',
    sceneLabel: 'Story lab',
    scene: DeepLogicScene.creative,
    color: Color(0xFFFF8A00),
    level: _creativeLevel,
  ),
  _Fixture(
    title: 'Story Comprehension',
    worldLabel: 'MI reads short stories with you.',
    sceneLabel: 'Story lens',
    scene: DeepLogicScene.reading,
    color: Color(0xFF4A90E2),
    level: _readingLevel,
  ),
];

class _Fixture {
  const _Fixture({
    required this.title,
    required this.worldLabel,
    required this.sceneLabel,
    required this.scene,
    required this.color,
    required this.level,
  });

  final String title;
  final String worldLabel;
  final String sceneLabel;
  final DeepLogicScene scene;
  final Color color;
  final MiLevel level;

  String get prompt => level.localizedContent['en']!['prompt'] as String;
}

const _mazeLevel = MiLevel(
  id: 'logic-maze-test',
  gameId: 'logic_maze',
  levelNumber: 3,
  difficulty: 2,
  localizedContent: {
    'en': {
      'prompt': 'MI needs four steps to the star.',
      'options': [
        {'id': 'a', 'text': 'Wrong answer', 'correct': false},
        {'id': 'b', 'text': 'Correct answer', 'correct': true},
        {'id': 'c', 'text': 'Try later', 'correct': false},
      ],
    },
  },
  hints: [
    {'text': 'Count each square in the path.'},
  ],
  metadata: {
    'skillIds': ['logic.maze'],
  },
);

const _sudokuLevel = MiLevel(
  id: 'kids-sudoku-test',
  gameId: 'kids_sudoku',
  levelNumber: 4,
  difficulty: 3,
  localizedContent: {
    'en': {
      'prompt': 'Choose the symbol missing from the row.',
      'options': [
        {'id': 'a', 'text': 'A', 'correct': false},
        {'id': 'b', 'text': 'Correct answer', 'correct': true},
        {'id': 'c', 'text': 'C', 'correct': false},
      ],
    },
  },
  hints: [
    {'text': 'Scan the row before the column.'},
  ],
  metadata: {
    'skillIds': ['logic.conditions'],
  },
);

const _detectiveLevel = MiLevel(
  id: 'reasoning-detective-test',
  gameId: 'reasoning_detective',
  levelNumber: 5,
  difficulty: 3,
  localizedContent: {
    'en': {
      'prompt': 'Who stands first?',
      'options': [
        {'id': 'a', 'text': 'B', 'correct': false},
        {'id': 'b', 'text': 'Correct answer', 'correct': true},
        {'id': 'c', 'text': 'C', 'correct': false},
      ],
    },
  },
  hints: [
    {'text': 'Follow the order clues from left to right.'},
  ],
  metadata: {
    'skillIds': ['logic.strategy'],
  },
);

const _creativeLevel = MiLevel(
  id: 'free-creativity-test',
  gameId: 'free_creativity',
  levelNumber: 6,
  difficulty: 2,
  localizedContent: {
    'en': {
      'prompt': 'Choose the detail that makes the story feel kind.',
      'options': [
        {'id': 'a', 'text': 'locked door', 'correct': false},
        {'id': 'b', 'text': 'Correct answer', 'correct': true},
        {'id': 'c', 'text': 'dark sky', 'correct': false},
      ],
    },
  },
  hints: [
    {'text': 'Pick the detail that helps the character.'},
  ],
  metadata: {
    'skillIds': ['creative.storytelling'],
  },
);

const _readingLevel = MiLevel(
  id: 'story-comprehension-test',
  gameId: 'story_comprehension',
  levelNumber: 7,
  difficulty: 2,
  localizedContent: {
    'en': {
      'prompt': 'Lan read four pages. How many pages did Lan read?',
      'options': [
        {'id': 'a', 'text': '3', 'correct': false},
        {'id': 'b', 'text': 'Correct answer', 'correct': true},
        {'id': 'c', 'text': '5', 'correct': false},
      ],
    },
  },
  hints: [
    {'text': 'Look for the number in the sentence.'},
  ],
  metadata: {
    'skillIds': ['letters.reading_comprehension'],
  },
);
