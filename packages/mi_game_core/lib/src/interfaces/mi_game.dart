import '../context/mi_game_context.dart';
import '../lifecycle/game_state.dart';
import '../models/models.dart';

/// The official interface every MI Academy game must implement.
///
/// This is the contract between the game shell (app) and individual games.
/// Games receive only what they need via [MiGameContext] — never auth tokens,
/// parent data, or payment information.
abstract interface class MiGame {
  /// Unique identifier for this game type (e.g., "memory_cards", "word_builder").
  String get gameId;

  /// Current lifecycle state.
  GameState get currentState;

  /// Initialize the game with context.
  ///
  /// Called once when the game screen is opened.
  /// Must transition to [GameState.ready] on success.
  Future<void> initialize({required MiGameContext context});

  /// Load a specific level.
  ///
  /// Called after [initialize] and before [start].
  /// Populates the game board with level data.
  Future<void> loadLevel({required MiLevel level});

  /// Begin gameplay.
  ///
  /// Transitions from [GameState.ready] to [GameState.playing].
  Future<void> start();

  /// Pause the game.
  ///
  /// Game should freeze animations, stop timers, and save state if needed.
  Future<void> pause();

  /// Resume from pause.
  Future<void> resume();

  /// Process an action from the child.
  ///
  /// Returns [MiActionResult] with feedback.
  Future<MiActionResult> handleAction(MiGameAction action);

  /// Request a hint for the current state.
  ///
  /// Returns the next hint in the progressive hint ladder.
  /// Games must never auto-complete via hints.
  Future<MiHint> requestHint();

  /// Save current game state for later restoration.
  ///
  /// Must be callable at any point during gameplay.
  Future<MiGameSnapshot> saveSnapshot();

  /// Restore game state from a snapshot.
  ///
  /// Called when returning to a previously-saved game.
  Future<void> restoreSnapshot(MiGameSnapshot snapshot);

  /// Mark the game as complete and return results.
  ///
  /// Called automatically when [handleAction] returns
  /// [MiActionResult.isLevelComplete] = true, or explicitly by the UI.
  Future<MiCompletionResult> complete();

  /// Clean up all resources.
  ///
  /// Called when leaving the game screen entirely.
  Future<void> dispose();
}
