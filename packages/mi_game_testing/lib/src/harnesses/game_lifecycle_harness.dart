import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_core/mi_game_core.dart';

/// Test harness that drives a [MiGame] through its lifecycle states.
///
/// Use this to verify a game properly transitions through
/// CREATED → INITIALIZING → READY → PLAYING → COMPLETED.
class GameLifecycleHarness {
  GameLifecycleHarness({required this.game, this.timeout = const Duration(seconds: 5)});

  final MiGame game;
  final Duration timeout;

  /// Verify the game passes through every required state.
  Future<void> expectFullLifecycle() async {
    expect(game.state, MiGameState.created, reason: 'Should start in CREATED');

    await game.initialize();
    expect(game.state, MiGameState.ready, reason: 'Should reach READY after init');

    await game.start();
    expect(game.state, MiGameState.playing, reason: 'Should reach PLAYING after start');

    await game.pause();
    expect(game.state, MiGameState.paused, reason: 'Should reach PAUSED after pause');

    await game.resume();
    expect(game.state, MiGameState.playing, reason: 'Should return to PLAYING after resume');

    await game.complete();
    expect(game.state, MiGameState.completed, reason: 'Should reach COMPLETED after complete');
  }

  /// Verify the game handles errors gracefully.
  Future<MiGameResult> expectErrorHandled() async {
    final result = await game.startAndWaitForResult();
    expect(
      game.state,
      anyOf(
        equals(MiGameState.completed),
        equals(MiGameState.error),
      ),
      reason: 'Should terminate cleanly even on error',
    );
    return result;
  }
}
