/// Deterministic mock implementation of MiProgressGateway for Dev 2.
///
/// This gateway stores data in memory — no network, no database.
/// Use it to develop games without waiting for the backend.
library in_memory_progress_gateway;

import 'mi_progress_gateway.dart';
import 'shared_models.dart';

/// In-memory, deterministic mock gateway.
///
/// - Stores game results and snapshots in simple Maps.
/// - Guarantees idempotent saves (same attemptId → no duplicate).
/// - Works synchronously but returns Futures to match the interface.
class InMemoryProgressGateway implements MiProgressGateway {
  final Map<String, MiGameResult> _results = {};
  final Map<String, MiGameSnapshot> _snapshots = {};

  @override
  Future<void> saveGameResult(MiGameResult result) async {
    // Idempotent: ignore if we already have this attemptId
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

  // ─── Test helpers ────────────────────────────────────────────────────────

  /// All saved game results (for assertions in tests).
  List<MiGameResult> get allResults => List.unmodifiable(_results.values);

  /// All saved snapshots (for assertions in tests).
  List<MiGameSnapshot> get allSnapshots =>
      List.unmodifiable(_snapshots.values);

  /// Clear all stored data (useful for tests).
  void clear() {
    _results.clear();
    _snapshots.clear();
  }

  /// Find a saved result by attemptId.
  MiGameResult? resultById(String attemptId) => _results[attemptId];

  static String _snapshotKey(String childId, String gameId, String levelId) =>
      '$childId|$gameId|$levelId';
}
