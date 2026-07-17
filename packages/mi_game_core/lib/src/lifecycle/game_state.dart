/// The lifecycle states a game can be in.
///
/// Normal flow:
/// ```
/// created → initializing → ready → playing → completed
/// ```
///
/// From [playing], a game may temporarily enter [paused],
/// [hintShown], or [retrying], then return to [playing].
///
/// Error states can be entered from any point and must always
/// be recoverable back to a stable state.
enum GameState {
  /// Instance created but not yet initialized.
  created,

  /// Loading resources and setting up.
  initializing,

  /// Ready to start (level loaded, resources ready).
  ready,

  /// Active gameplay.
  playing,

  /// Temporarily paused.
  paused,

  /// A hint is currently displayed.
  hintShown,

  /// Child is retrying after an incorrect attempt.
  retrying,

  /// Level completed successfully.
  completed,

  // --- Error states ---

  /// Level data or resources failed to load.
  loadFailed,

  /// A required asset is missing.
  assetMissing,

  /// The level definition is invalid.
  invalidLevel,

  /// Saving the snapshot failed.
  saveFailed,

  /// The game needs to recover to a stable state.
  recoveryRequired;

  /// Whether this is an error state.
  bool get isError => const {
        GameState.loadFailed,
        GameState.assetMissing,
        GameState.invalidLevel,
        GameState.saveFailed,
        GameState.recoveryRequired,
      }.contains(this);

  /// Whether gameplay is active or temporarily suspended.
  bool get isActive => const {
        GameState.playing,
        GameState.paused,
        GameState.hintShown,
        GameState.retrying,
      }.contains(this);

  /// Whether the game can accept player actions right now.
  bool get acceptsInput => this == GameState.playing;
}
