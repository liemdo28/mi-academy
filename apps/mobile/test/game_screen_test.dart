import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/screens/game_screen.dart';

/// Covers the production `/game/:gameId` launcher: it must render the real
/// per-game engine (loaded from the bundled level assets), not the old
/// hardcoded demo. childId is 'offline-child' throughout so the save path
/// (which needs network) is never exercised — see api_sync_processor_test
/// and test_api_game_result.py (backend) for that.
Future<void> _pumpAndSettleLoad(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp(home: child)),
  );
  // Level content loads via an async asset read; pump until it resolves.
  for (var i = 0; i < 10 && tester.any(find.byType(CircularProgressIndicator)); i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('renders the real Word Builder game for gameType word_builder',
      (tester) async {
    await _pumpAndSettleLoad(
      tester,
      const GameScreen(childId: 'offline-child', gameType: 'word_builder'),
    );

    expect(find.text('Ghép chữ thành từ!'), findsOneWidget);
  });

  testWidgets('renders the real Memory Cards game for gameType memory_cards',
      (tester) async {
    await _pumpAndSettleLoad(
      tester,
      const GameScreen(childId: 'offline-child', gameType: 'memory_cards'),
    );

    expect(find.text('Memory Cards'), findsWidgets);
    // MemoryCardsScreen's tutorial dismiss uses no timer, but flush any
    // stray animation/frame callbacks before teardown to avoid a pending
    // timer assertion.
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('shows an error state (with retry) for an unknown game type',
      (tester) async {
    await _pumpAndSettleLoad(
      tester,
      const GameScreen(childId: 'offline-child', gameType: 'not_a_real_game'),
    );

    expect(find.text('Không thể tải trò chơi'), findsOneWidget);
  });
}
