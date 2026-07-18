import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/src/games/memory_cards/memory_cards_game.dart';
import 'package:mi_game_core/mi_game_core.dart';

import 'game_test_fixtures.dart';

void main() {
  test('Memory Cards restores an offline snapshot and can finish the level',
      () async {
    final game = MemoryCardsGame();
    await _startMemoryGame(game);

    final firstPair = _pairIndexes(game).values.first;
    await game.handleAction(
      MiGameAction(type: 'tap', targetId: firstPair[0].toString()),
    );
    final matchResult = await game.handleAction(
      MiGameAction(type: 'tap', targetId: firstPair[1].toString()),
    );
    expect(matchResult.correct, isTrue);
    expect(matchResult.isLevelComplete, isFalse);

    final snapshot = await game.saveSnapshot();
    expect(snapshot.gameId, 'memory_cards');
    expect(snapshot.levelId, memoryCardsLevel.id);
    expect(snapshot.childProfileId, 'offline-child');
    expect(snapshot.itemsCompleted, 1);
    expect(snapshot.totalItems, 2);
    expect(snapshot.inProgress, isTrue);
    expect(snapshot.progress, 0.5);

    final restoredSnapshot = MiGameSnapshot.fromJson(snapshot.toJson());
    final restoredGame = MemoryCardsGame();
    await _startMemoryGame(restoredGame);
    await restoredGame.restoreSnapshot(restoredSnapshot);

    expect(restoredGame.matchedPairs, 1);
    expect(restoredGame.cards.where((c) => c.state == CardState.matched),
        hasLength(2));

    final remainingPair = _pairIndexes(restoredGame).values.firstWhere(
          (indexes) =>
              restoredGame.cards[indexes[0]].state != CardState.matched,
        );
    await restoredGame.handleAction(
      MiGameAction(type: 'tap', targetId: remainingPair[0].toString()),
    );
    final finalResult = await restoredGame.handleAction(
      MiGameAction(type: 'tap', targetId: remainingPair[1].toString()),
    );

    expect(finalResult.correct, isTrue);
    expect(finalResult.isLevelComplete, isTrue);
    expect(restoredGame.currentState, GameState.completed);

    final completion = await restoredGame.complete();
    expect(completion.gameId, 'memory_cards');
    expect(completion.levelId, memoryCardsLevel.id);
    expect(completion.metadata['matchedPairs'], 2);
    expect(completion.metadata['totalPairs'], 2);

    await game.dispose();
    await restoredGame.dispose();
  });

  test('Memory Cards snapshot keeps state privacy-safe for offline persistence',
      () async {
    final game = MemoryCardsGame();
    await _startMemoryGame(game);

    final snapshot = await game.saveSnapshot();
    final json = snapshot.toJson();
    final encoded = json.toString().toLowerCase();

    expect(json['state'], isA<Map<String, dynamic>>());
    expect(encoded, isNot(contains('parent')));
    expect(encoded, isNot(contains('email')));
    expect(encoded, isNot(contains('token')));
    expect(encoded, isNot(contains('answer')));
    expect(snapshot.storageKey,
        'memory_cards_${memoryCardsLevel.id}_offline-child');

    await game.dispose();
  });
}

Future<void> _startMemoryGame(MemoryCardsGame game) async {
  await game.initialize(context: _offlineContext);
  await game.loadLevel(level: memoryCardsLevel);
  await game.start();
}

Map<String, List<int>> _pairIndexes(MemoryCardsGame game) {
  final pairs = <String, List<int>>{};
  for (var index = 0; index < game.cards.length; index++) {
    pairs.putIfAbsent(game.cards[index].pairId, () => []).add(index);
  }
  return pairs;
}

const _offlineContext = MiGameContext(
  childProfileId: 'offline-child',
  language: 'vi',
  ageGroup: '5-7',
  accessibility: AccessibilityPreferences(),
  audio: AudioPreferences(),
  services: MiGameServices(
    saveSnapshot: _noopSave,
    loadSnapshot: _noopLoad,
    logEvent: _noopLog,
    playAudio: _noopAudio,
    stopAudio: _noopStop,
  ),
);

Future<void> _noopSave(String key, Map<String, dynamic> data) async {}
Future<Map<String, dynamic>?> _noopLoad(String key) async => null;
Future<void> _noopLog(String event, Map<String, dynamic> data) async {}
Future<void> _noopAudio(String audioRef, {double? volume}) async {}
Future<void> _noopStop() async {}
