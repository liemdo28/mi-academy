import 'package:flutter/foundation.dart';

import 'game_state.dart';

/// Thrown when an illegal state transition is attempted.
class InvalidStateTransitionException implements Exception {
  InvalidStateTransitionException(this.from, this.to);

  final GameState from;
  final GameState to;

  @override
  String toString() =>
      'InvalidStateTransitionException: cannot go from $from to $to';
}

/// Manages the game lifecycle state machine.
///
/// Enforces valid transitions and notifies listeners of state changes.
/// Every game uses this to guarantee consistent lifecycle behavior and
/// guaranteed recovery after an error.
class GameLifecycle extends ChangeNotifier {
  GameLifecycle();

  GameState _state = GameState.created;

  /// The current state.
  GameState get state => _state;

  /// History of states, useful for recovery and debugging.
  final List<GameState> _history = [GameState.created];
  List<GameState> get history => List.unmodifiable(_history);

  /// The last stable (non-error) state, used for recovery.
  GameState _lastStableState = GameState.created;
  GameState get lastStableState => _lastStableState;

  /// Allowed transitions between states.
  static const Map<GameState, Set<GameState>> _allowed = {
    GameState.created: {GameState.initializing, GameState.loadFailed},
    GameState.initializing: {
      GameState.ready,
      GameState.loadFailed,
      GameState.assetMissing,
      GameState.invalidLevel,
    },
    GameState.ready: {
      GameState.playing,
      GameState.initializing,
      GameState.loadFailed,
    },
    GameState.playing: {
      GameState.paused,
      GameState.hintShown,
      GameState.retrying,
      GameState.completed,
      GameState.saveFailed,
      GameState.recoveryRequired,
    },
    GameState.paused: {
      GameState.playing,
      GameState.recoveryRequired,
    },
    GameState.hintShown: {
      GameState.playing,
      GameState.retrying,
    },
    GameState.retrying: {
      GameState.playing,
      GameState.hintShown,
      GameState.completed,
    },
    GameState.completed: {
      GameState.ready, // replay / next level
      GameState.initializing,
    },
    // Error states can all recover.
    GameState.loadFailed: {GameState.initializing, GameState.recoveryRequired},
    GameState.assetMissing: {
      GameState.initializing,
      GameState.recoveryRequired
    },
    GameState.invalidLevel: {GameState.recoveryRequired},
    GameState.saveFailed: {GameState.playing, GameState.recoveryRequired},
    GameState.recoveryRequired: {
      GameState.initializing,
      GameState.ready,
    },
  };

  /// Whether transitioning to [target] is currently allowed.
  bool canTransitionTo(GameState target) {
    return _allowed[_state]?.contains(target) ?? false;
  }

  /// Attempt to transition to [target].
  ///
  /// Throws [InvalidStateTransitionException] if not allowed.
  void transitionTo(GameState target) {
    if (!canTransitionTo(target)) {
      throw InvalidStateTransitionException(_state, target);
    }
    if (!_state.isError) {
      _lastStableState = _state;
    }
    _state = target;
    _history.add(target);
    notifyListeners();
  }

  /// Enter an error state (allowed from any state).
  ///
  /// Records the current stable state so [recover] can restore it.
  void enterError(GameState errorState) {
    assert(errorState.isError, 'enterError requires an error state');
    if (!_state.isError) {
      _lastStableState = _state;
    }
    _state = errorState;
    _history.add(errorState);
    notifyListeners();
  }

  /// Recover from an error to a stable state.
  ///
  /// Guarantees the game returns to a usable state after any error,
  /// per blueprint §3.1 ("Mọi game phải có khả năng trở lại trạng thái
  /// ổn định sau lỗi").
  void recover() {
    _state = GameState.recoveryRequired;
    _history.add(GameState.recoveryRequired);
    // Move to a safe restart point.
    _state = GameState.ready;
    _history.add(GameState.ready);
    notifyListeners();
  }

  /// Reset the machine to [GameState.created].
  void reset() {
    _state = GameState.created;
    _lastStableState = GameState.created;
    _history
      ..clear()
      ..add(GameState.created);
    notifyListeners();
  }
}
