import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:mi_game_core/mi_game_core.dart';

/// Platform-owned snapshot save/load — per Phase 10, games only produce a
/// game-specific [MiGameSnapshot] payload; the platform owns persistence,
/// version/checksum validation, and child isolation. No game reads or
/// writes Hive directly.
///
/// Abstract so tests can supply a plain in-memory implementation instead of
/// standing up a real Hive box (which needs either `Hive.initFlutter()` --
/// a platform channel unavailable in plain `flutter test` -- or file I/O
/// via `Hive.init(path)`, which is unnecessary ceremony for a widget test
/// that never asserts on persistence itself).
abstract class SnapshotStore {
  Future<void> save(MiGameSnapshot snapshot);

  /// Loads the snapshot for this exact (child, game, level), or `null` if
  /// none exists, it belongs to a different child/game/level, it fails
  /// checksum/schema validation, or it's simply not parseable. Callers must
  /// treat `null` as "start fresh" — never surface a technical error to
  /// the child (Phase 10's restore policy).
  MiGameSnapshot? load({
    required String childProfileId,
    required String gameId,
    required String levelId,
    int maxSupportedSchemaVersion = 2,
  });

  Future<void> clear({
    required String childProfileId,
    required String gameId,
    required String levelId,
  });

  static String keyFor({
    required String childProfileId,
    required String gameId,
    required String levelId,
  }) =>
      '${gameId}_${levelId}_$childProfileId';
}

/// Real implementation, backed by the `snapshots` Hive box.
///
/// Stored as JSON strings (not raw [MiGameSnapshot] Hive objects) so a
/// snapshot with an unknown/future schema still deserializes as a plain
/// map — [MiGameSnapshot.fromJson] can then reject it gracefully instead
/// of a Hive type-adapter failure taking down the whole box.
class HiveSnapshotStore implements SnapshotStore {
  HiveSnapshotStore(this._box);

  final Box _box;

  @override
  Future<void> save(MiGameSnapshot snapshot) async {
    await _box.put(snapshot.storageKey, jsonEncode(snapshot.toJson()));
  }

  @override
  MiGameSnapshot? load({
    required String childProfileId,
    required String gameId,
    required String levelId,
    int maxSupportedSchemaVersion = 2,
  }) {
    final raw = _box.get(
      SnapshotStore.keyFor(
        childProfileId: childProfileId,
        gameId: gameId,
        levelId: levelId,
      ),
    );
    if (raw is! String) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final snapshot = MiGameSnapshot.fromJson(json);
      final valid = snapshot.canRestoreFor(
        childProfileId: childProfileId,
        gameId: gameId,
        levelId: levelId,
        maxSupportedSchemaVersion: maxSupportedSchemaVersion,
      );
      return valid ? snapshot : null;
    } catch (_) {
      // Truncated write, invalid JSON, missing required field, etc. --
      // treat exactly like "no snapshot," not a crash.
      return null;
    }
  }

  @override
  Future<void> clear({
    required String childProfileId,
    required String gameId,
    required String levelId,
  }) async {
    await _box.delete(
      SnapshotStore.keyFor(
        childProfileId: childProfileId,
        gameId: gameId,
        levelId: levelId,
      ),
    );
  }
}

/// In-memory implementation for tests and any context where a real Hive
/// box isn't warranted.
class InMemorySnapshotStore implements SnapshotStore {
  final Map<String, MiGameSnapshot> _store = {};

  @override
  Future<void> save(MiGameSnapshot snapshot) async {
    _store[snapshot.storageKey] = snapshot;
  }

  @override
  MiGameSnapshot? load({
    required String childProfileId,
    required String gameId,
    required String levelId,
    int maxSupportedSchemaVersion = 2,
  }) {
    final snapshot = _store[
        SnapshotStore.keyFor(childProfileId: childProfileId, gameId: gameId, levelId: levelId)];
    if (snapshot == null) return null;
    final valid = snapshot.canRestoreFor(
      childProfileId: childProfileId,
      gameId: gameId,
      levelId: levelId,
      maxSupportedSchemaVersion: maxSupportedSchemaVersion,
    );
    return valid ? snapshot : null;
  }

  @override
  Future<void> clear({
    required String childProfileId,
    required String gameId,
    required String levelId,
  }) async {
    _store.remove(
      SnapshotStore.keyFor(childProfileId: childProfileId, gameId: gameId, levelId: levelId),
    );
  }
}
