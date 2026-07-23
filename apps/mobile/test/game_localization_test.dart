import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/services/game_registry.dart';
import 'package:mi_academy/src/games/memory_cards/memory_cards_game.dart';
import 'package:mi_academy/src/games/memory_cards/memory_cards_screen.dart';
import 'package:mi_game_core/mi_game_core.dart';

import 'game_test_fixtures.dart';

void main() {
  testWidgets('choice games use English shell, hints, and completion labels',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GameRegistry.find('math_race')!.builder(
          level: mathRaceLevel,
          allLevels: const [mathRaceLevel],
          onExit: () {},
          onComplete: (_) {},
          childProfileId: 'child-test',
          locale: 'en',
        ),
      ),
    );

    expect(find.text('Math Race'), findsOneWidget);
    expect(find.text('MI moves forward when you choose correctly.'),
        findsOneWidget);

    await tester.tap(find.byIcon(Icons.lightbulb_outline_rounded));
    await tester.pump();
    expect(
      find.text('Hint 1: Look closely and try one step at a time.'),
      findsOneWidget,
    );

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    expect(find.text('Score: 95'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Play again'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('memory cards localizes tutorial and pause overlay to English',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MemoryCardsScreen(
          game: MemoryCardsGame(),
          level: memoryCardsLevel,
          onComplete: (MiCompletionResult result) {},
          onExit: () {},
          locale: 'en',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Memory Cards'), findsWidgets);
    expect(find.textContaining('Tap a card to flip it.'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Play again'), findsOneWidget);
    expect(find.text('Exit'), findsOneWidget);
  });
}
