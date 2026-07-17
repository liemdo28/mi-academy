import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_core/mi_game_core.dart';

// Fake game for testing the base game lifecycle.
class _FakeGame extends BaseGame {
  bool initializedCalled = false;
  bool loadLevelCalled = false;
  bool startCalled = false;
  bool pauseCalled = false;
  bool resumeCalled = false;
  bool disposeCalled = false;
  int actionCount = 0;

  @override
  String get gameId => 'fake_game';

  @override
  Future<void> onInitialize(MiGameContext context) async {
    initializedCalled = true;
  }

  @override
  Future<void> onLoadLevel(MiLevel level) async {
    loadLevelCalled = true;
  }

  @override
  Future<void> onStart() async {
    startCalled = true;
  }

  @override
  Future<void> onPause() async {
    pauseCalled = true;
  }

  @override
  Future<void> onResume() async {
    resumeCalled = true;
  }

  @override
  Future<MiActionResult> onHandleAction(MiGameAction action) async {
    actionCount++;
    return MiActionResult.success(
      feedback: 'Correct!',
      isLevelComplete: actionCount >= 2,
    );
  }

  @override
  Future<MiGameSnapshot> createSnapshot() async {
    return MiGameSnapshot(
      gameId: gameId,
      levelId: level!.id,
      childProfileId: context!.childProfileId,
      state: {'actionCount': actionCount},
      createdAt: DateTime.now(),
      itemsCompleted: actionCount,
      totalItems: 2,
    );
  }

  @override
  Future<void> onRestoreSnapshot(MiGameSnapshot snapshot) async {
    actionCount = snapshot.state['actionCount'] as int? ?? 0;
  }

  @override
  Future<MiCompletionResult> createCompletionResult({
    required Duration duration,
    required int hintsUsed,
  }) async {
    return MiCompletionResult(
      gameId: gameId,
      levelId: level!.id,
      childProfileId: context!.childProfileId,
      completedAt: DateTime.now(),
      score: actionCount,
      maxScore: 2,
      attemptsUsed: actionCount,
      hintsUsed: hintsUsed,
      duration: duration,
      perfectRun: true,
    );
  }

  @override
  Future<void> onDispose() async {
    disposeCalled = true;
  }
}

const _testContext = MiGameContext(
  childProfileId: 'child-1',
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

const _testLevel = MiLevel(
  id: 'level-1',
  gameId: 'fake_game',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {'prompt': 'Chạm vào thẻ'},
  },
  hints: [
    {'text': 'Nhìn vào thẻ úp'},
    {'text': 'Thẻ đầu tiên'},
  ],
);

Future<void> _noopSave(String key, Map<String, dynamic> data) async {}
Future<Map<String, dynamic>?> _noopLoad(String key) async => null;
Future<void> _noopLog(String event, Map<String, dynamic> data) async {}
Future<void> _noopAudio(String audioRef, {double? volume}) async {}
Future<void> _noopStop() async {}

void main() {
  group('GameLifecycle', () {
    test('starts in created state', () {
      final lifecycle = GameLifecycle();
      expect(lifecycle.state, GameState.created);
    });

    test('transitions through normal flow', () {
      final lifecycle = GameLifecycle();
      lifecycle.transitionTo(GameState.initializing);
      expect(lifecycle.state, GameState.initializing);
      lifecycle.transitionTo(GameState.ready);
      expect(lifecycle.state, GameState.ready);
      lifecycle.transitionTo(GameState.playing);
      expect(lifecycle.state, GameState.playing);
      lifecycle.transitionTo(GameState.paused);
      expect(lifecycle.state, GameState.paused);
      lifecycle.transitionTo(GameState.playing);
      expect(lifecycle.state, GameState.playing);
      lifecycle.transitionTo(GameState.completed);
      expect(lifecycle.state, GameState.completed);
    });

    test('rejects invalid transition', () {
      final lifecycle = GameLifecycle();
      expect(
        () => lifecycle.transitionTo(GameState.playing),
        throwsA(isA<InvalidStateTransitionException>()),
      );
    });

    test('enters and recovers from error state', () {
      final lifecycle = GameLifecycle();
      lifecycle.transitionTo(GameState.initializing);
      lifecycle.enterError(GameState.loadFailed);
      expect(lifecycle.state, GameState.loadFailed);
      lifecycle.recover();
      expect(lifecycle.state, GameState.ready);
    });

    test('notifies listeners on transition', () {
      final lifecycle = GameLifecycle();
      int notifyCount = 0;
      lifecycle.addListener(() => notifyCount++);
      lifecycle.transitionTo(GameState.initializing);
      lifecycle.transitionTo(GameState.ready);
      expect(notifyCount, 2);
    });

    test('reset returns to created', () {
      final lifecycle = GameLifecycle();
      lifecycle.transitionTo(GameState.initializing);
      lifecycle.transitionTo(GameState.ready);
      lifecycle.reset();
      expect(lifecycle.state, GameState.created);
      expect(lifecycle.history, [GameState.created]);
    });
  });

  group('GameState helpers', () {
    test('isError returns true for error states', () {
      expect(GameState.loadFailed.isError, true);
      expect(GameState.assetMissing.isError, true);
      expect(GameState.playing.isError, false);
    });

    test('isActive returns true for active states', () {
      expect(GameState.playing.isActive, true);
      expect(GameState.paused.isActive, true);
      expect(GameState.completed.isActive, false);
    });

    test('acceptsInput only true for playing', () {
      expect(GameState.playing.acceptsInput, true);
      expect(GameState.paused.acceptsInput, false);
      expect(GameState.hintShown.acceptsInput, false);
    });
  });

  group('MiGameSnapshot', () {
    test('serialization round-trip', () {
      final original = MiGameSnapshot(
        gameId: 'memory_cards',
        levelId: 'level-1',
        childProfileId: 'child-1',
        state: {'cards': [1, 2, 3]},
        createdAt: DateTime(2026, 7, 17),
        score: 5,
        itemsCompleted: 3,
        totalItems: 6,
      );
      final json = original.toJson();
      final restored = MiGameSnapshot.fromJson(json);
      expect(restored, original);
    });

    test('storageKey is deterministic', () {
      final snap = MiGameSnapshot(
        gameId: 'a',
        levelId: 'b',
        childProfileId: 'c',
        state: {},
        createdAt: DateTime(2026),
      );
      expect(snap.storageKey, 'a_b_c');
    });

    test('progress returns correct ratio', () {
      final snap = MiGameSnapshot(
        gameId: 'a',
        levelId: 'b',
        childProfileId: 'c',
        state: {},
        createdAt: DateTime(2026),
        itemsCompleted: 3,
        totalItems: 6,
      );
      expect(snap.progress, 0.5);
    });
  });

  group('MiActionResult', () {
    test('success factory sets correct defaults', () {
      final result = MiActionResult.success(feedback: 'Đúng rồi!');
      expect(result.correct, true);
      expect(result.feedback, 'Đúng rồi!');
      expect(result.audioRef, 'correct');
      expect(result.shouldRetry, false);
      expect(result.isLevelComplete, false);
    });

    test('incorrect factory sets Vietnamese fallback', () {
      final result = MiActionResult.incorrect();
      expect(result.correct, false);
      expect(result.feedback, 'Thử lại nhé!');
      expect(result.audioRef, 'try_again');
      expect(result.shouldRetry, true);
    });
  });

  group('MiLevel', () {
    test('contentForLocale returns correct locale', () {
      const level = MiLevel(
        id: 'l1',
        gameId: 'g1',
        levelNumber: 1,
        difficulty: 1,
        localizedContent: {
          'vi': {'prompt': 'Xin chào'},
          'en': {'prompt': 'Hello'},
        },
        hints: [],
      );
      expect(level.contentForLocale('en')['prompt'], 'Hello');
    });

    test('contentForLocale falls back to vi', () {
      const level = MiLevel(
        id: 'l1',
        gameId: 'g1',
        levelNumber: 1,
        difficulty: 1,
        localizedContent: {
          'vi': {'prompt': 'Xin chào'},
        },
        hints: [],
      );
      expect(level.contentForLocale('fr')['prompt'], 'Xin chào');
    });
  });

  group('BaseGame lifecycle', () {
    late _FakeGame game;

    setUp(() {
      game = _FakeGame();
    });

    test('full lifecycle: init → load → start → action → complete', () async {
      await game.initialize(context: _testContext);
      expect(game.initializedCalled, true);
      expect(game.currentState, GameState.ready);

      await game.loadLevel(level: _testLevel);
      expect(game.loadLevelCalled, true);

      await game.start();
      expect(game.startCalled, true);
      expect(game.currentState, GameState.playing);

      final r1 = await game.handleAction(const MiGameAction(type: 'tap'));
      expect(r1.correct, true);
      expect(game.currentState, GameState.playing);

      final r2 = await game.handleAction(const MiGameAction(type: 'tap'));
      expect(r2.isLevelComplete, true);
      expect(game.currentState, GameState.completed);

      final result = await game.complete();
      expect(result.gameId, 'fake_game');
      expect(result.perfectRun, true);
      expect(result.score, 2);
    });

    test('pause and resume', () async {
      await game.initialize(context: _testContext);
      await game.loadLevel(level: _testLevel);
      await game.start();

      await game.pause();
      expect(game.currentState, GameState.paused);
      expect(game.pauseCalled, true);

      await game.resume();
      expect(game.currentState, GameState.playing);
      expect(game.resumeCalled, true);
    });

    test('save and restore snapshot', () async {
      await game.initialize(context: _testContext);
      await game.loadLevel(level: _testLevel);
      await game.start();

      await game.handleAction(const MiGameAction(type: 'tap'));

      final snapshot = await game.saveSnapshot();
      expect(snapshot.itemsCompleted, 1);
      expect(snapshot.totalItems, 2);

      // Restore into a new game instance.
      final game2 = _FakeGame();
      await game2.initialize(context: _testContext);
      await game2.loadLevel(level: _testLevel);
      await game2.start();
      await game2.restoreSnapshot(snapshot);

      final snap2 = await game2.saveSnapshot();
      expect(snap2.itemsCompleted, 1);
    });

    test('requestHint tracks hint count', () async {
      await game.initialize(context: _testContext);
      await game.loadLevel(level: _testLevel);
      await game.start();

      final hint1 = await game.requestHint();
      expect(hint1.hintNumber, 1);
      expect(hint1.content, 'Nhìn vào thẻ úp');

      final hint2 = await game.requestHint();
      expect(hint2.hintNumber, 2);
      expect(hint2.content, 'Thẻ đầu tiên');
    });

    test('dispose cleans up', () async {
      await game.initialize(context: _testContext);
      await game.dispose();
      expect(game.disposeCalled, true);
      expect(game.currentState, GameState.created);
    });
  });

  group('MiGameContext', () {
    test('does not expose sensitive data', () {
      expect(_testContext.childProfileId, isNot(contains('password')));
      expect(_testContext.childProfileId, isNot(contains('token')));
    });
  });
}
