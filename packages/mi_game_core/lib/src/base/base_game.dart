import 'package:flutter/foundation.dart';

import '../context/mi_game_context.dart';
import '../interfaces/mi_game.dart';
import '../lifecycle/game_lifecycle.dart';
import '../lifecycle/game_state.dart';
import '../models/models.dart';

/// Base class that implements [MiGame] lifecycle boilerplate.
///
/// Concrete games extend this and implement only the game-specific logic.
/// All lifecycle state management, hint tracking, and timing is handled here.
abstract class BaseGame implements MiGame {
  final GameLifecycle _lifecycle = GameLifecycle();

  MiGameContext? _context;
  MiLevel? _level;

  /// Timer to track duration for completion metrics.
  final Stopwatch _stopwatch = Stopwatch();
  int _hintCount = 0;

  @override
  String get gameId;

  @override
  GameState get currentState => _lifecycle.state;

  /// Current context, available after [initialize].
  @protected
  MiGameContext? get context => _context;

  /// Current level, available after [loadLevel].
  @protected
  MiLevel? get level => _level;

  /// Available hints from current level definition.
  @protected
  List<Map<String, dynamic>> get levelHints => _level?.hints ?? [];

  @override
  Future<void> initialize({required MiGameContext context}) async {
    _lifecycle.transitionTo(GameState.initializing);
    _context = context;
    try {
      await onInitialize(context);
      _lifecycle.transitionTo(GameState.ready);
    } catch (e) {
      _lifecycle.enterError(GameState.loadFailed);
      rethrow;
    }
  }

  @override
  Future<void> loadLevel({required MiLevel level}) async {
    _assertState(GameState.ready);
    _level = level;
    try {
      await onLoadLevel(level);
    } catch (e) {
      _lifecycle.enterError(GameState.invalidLevel);
      rethrow;
    }
  }

  @override
  Future<void> start() async {
    _assertState(GameState.ready);
    _lifecycle.transitionTo(GameState.playing);
    _stopwatch.start();
    _hintCount = 0;
    await onStart();
  }

  @override
  Future<void> pause() async {
    _assertState(GameState.playing);
    _lifecycle.transitionTo(GameState.paused);
    _stopwatch.stop();
    await onPause();
  }

  @override
  Future<void> resume() async {
    _assertState(GameState.paused);
    _lifecycle.transitionTo(GameState.playing);
    _stopwatch.start();
    await onResume();
  }

  @override
  Future<MiActionResult> handleAction(MiGameAction action) async {
    _assertState(GameState.playing);
    final result = await onHandleAction(action);
    if (result.isLevelComplete) {
      _stopwatch.stop();
      _lifecycle.transitionTo(GameState.completed);
    }
    return result;
  }

  @override
  Future<MiHint> requestHint() async {
    _assertState(GameState.playing);
    _lifecycle.transitionTo(GameState.hintShown);
    _hintCount++;

    final hintIndex = (_hintCount - 1).clamp(0, levelHints.length - 1);
    final hintData = levelHints[hintIndex];

    final hint = MiHint(
      hintNumber: _hintCount,
      content: hintData['text'] as String? ?? '',
      mediaRef: hintData['media'] as String?,
      highlightTarget: hintData['highlight'] as String?,
      action: hintData['action'] as Map<String, dynamic>?,
    );

    await onHintShown(hint);

    // Return to playing after hint is dismissed.
    if (_lifecycle.state == GameState.hintShown) {
      _lifecycle.transitionTo(GameState.playing);
    }

    return hint;
  }

  @override
  Future<MiGameSnapshot> saveSnapshot() async {
    final snapshot = await createSnapshot();
    return snapshot;
  }

  @override
  Future<void> restoreSnapshot(MiGameSnapshot snapshot) async {
    _hintCount = snapshot.hintsUsed;
    _stopwatch.start();
    await onRestoreSnapshot(snapshot);
  }

  @override
  Future<MiCompletionResult> complete() async {
    _assertState(GameState.completed);
    _stopwatch.stop();

    final result = await createCompletionResult(
      duration: _stopwatch.elapsed,
      hintsUsed: _hintCount,
    );

    return result;
  }

  @override
  Future<void> dispose() async {
    _stopwatch.stop();
    _lifecycle.reset();
    await onDispose();
  }

  // --- Protected hooks for subclasses ---

  /// Called during [initialize] — set up resources here.
  Future<void> onInitialize(MiGameContext context) async {}

  /// Called during [loadLevel] — parse level data here.
  Future<void> onLoadLevel(MiLevel level) async {}

  /// Called when gameplay begins.
  Future<void> onStart() async {}

  /// Called when game is paused.
  Future<void> onPause() async {}

  /// Called when game resumes.
  Future<void> onResume() async {}

  /// Implement your game's action logic here.
  Future<MiActionResult> onHandleAction(MiGameAction action);

  /// Called when a hint is shown (optional override for UI feedback).
  Future<void> onHintShown(MiHint hint) async {}

  /// Create a snapshot of current game state.
  Future<MiGameSnapshot> createSnapshot();

  /// Restore game state from a snapshot.
  Future<void> onRestoreSnapshot(MiGameSnapshot snapshot) async {}

  /// Build the completion result from accumulated metrics.
  Future<MiCompletionResult> createCompletionResult({
    required Duration duration,
    required int hintsUsed,
  });

  /// Clean up game-specific resources.
  Future<void> onDispose() async {}

  // --- Helpers ---

  void _assertState(GameState requiredState) {
    if (_lifecycle.state != requiredState) {
      throw InvalidStateTransitionException(_lifecycle.state, requiredState);
    }
  }
}
