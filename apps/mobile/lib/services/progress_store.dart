import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:mi_game_progress/mi_game_progress.dart';

/// Platform-owned persistence for each child's [ProgressTracker] -- the
/// attempt history and skill mastery that reward evaluation (see
/// `reward_store.dart`) and future adaptive-difficulty features read.
/// Games never touch this directly; [GameScreen] is the one call site.
abstract class ProgressStore {
  Future<void> save(ProgressTracker tracker);

  /// Loads the tracker for [childProfileId], or `null` if none exists yet
  /// or the stored data fails to parse -- callers must treat `null` as
  /// "start fresh," matching [SnapshotStore]'s restore policy.
  ProgressTracker? load(String childProfileId);
}

/// Real implementation, backed by the `mastery` Hive box (already opened
/// by `initHive()`, previously unused).
class HiveProgressStore implements ProgressStore {
  HiveProgressStore(this._box);

  final Box _box;

  @override
  Future<void> save(ProgressTracker tracker) async {
    await _box.put(tracker.childId, jsonEncode(tracker.toJson()));
  }

  @override
  ProgressTracker? load(String childProfileId) {
    final raw = _box.get(childProfileId);
    if (raw is! String) return null;
    try {
      return ProgressTracker.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}

/// In-memory implementation for tests and any context where a real Hive
/// box isn't warranted.
class InMemoryProgressStore implements ProgressStore {
  final Map<String, ProgressTracker> _store = {};

  @override
  Future<void> save(ProgressTracker tracker) async {
    _store[tracker.childId] = tracker;
  }

  @override
  ProgressTracker? load(String childProfileId) => _store[childProfileId];
}
