part of mi_game_core;

/// The interface through which games save progress.
///
/// The Platform provides three implementations:
/// 1. [MiLocalProgressGateway] — stores in Hive for offline play
/// 2. [MiRemoteProgressGateway] — calls the API when online
/// 3. [MiCachedProgressGateway] — local-first with background sync
///
/// Games use this interface exclusively. They MUST NOT:
/// - Call HTTP APIs directly
/// - Access the parent account
/// - Store access tokens
abstract interface class MiProgressGateway {
  /// Saves a game result. Idempotent by attemptId — submitting the same
  /// result twice is a no-op on the server side.
  ///
  /// This is the primary way the platform tracks learning progress.
  /// Call this exactly once per game session when the child finishes.
  Future<void> saveGameResult(MiGameResult result);

  /// Saves a game snapshot for resume capability.
  /// Call on pause, on app backgrounding, and periodically during play.
  Future<void> saveSnapshot(MiGameSnapshot snapshot);

  /// Loads the most recent snapshot for a child/game/level combination.
  /// Returns null if no snapshot exists.
  Future<MiGameSnapshot?> loadSnapshot({
    required String childProfileId,
    required String gameId,
    required String levelId,
  });
}

/// In-memory implementation for Dev 2 to build games without backend.
/// Deterministic, no persistence, thread-safe via zone.
class MiInMemoryProgressGateway implements MiProgressGateway {
  final Map<String, MiGameResult> _results = {};
  final Map<String, MiGameSnapshot> _snapshots = {};

  String _snapshotKey(String childId, String gameId, String levelId) =>
      '$childId/$gameId/$levelId';

  @override
  Future<void> saveGameResult(MiGameResult result) async {
    _results[result.attemptId] = result;
  }

  @override
  Future<void> saveSnapshot(MiGameSnapshot snapshot) async {
    final key = _snapshotKey(
      snapshot.childProfileId,
      snapshot.gameId,
      snapshot.levelId,
    );
    _snapshots[key] = snapshot;
  }

  @override
  Future<MiGameSnapshot?> loadSnapshot({
    required String childProfileId,
    required String gameId,
    required String levelId,
  }) async {
    final key = _snapshotKey(childProfileId, gameId, levelId);
    return _snapshots[key];
  }

  /// Get all saved results (for testing).
  List<MiGameResult> getAllResults() => _results.values.toList();
}
