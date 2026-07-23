import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:mastery_core/mastery_core.dart';

/// Platform-owned persistence for each (child, skill) [MasteryState].
///
/// `AdaptiveLearningService.evaluateCompletion` (packages/mastery_core +
/// recommendation_core, wired since the Foundation Sprint) previously
/// recomputed mastery from a *fresh* `MasteryState` on every single game
/// completion -- evidenceCount, confidence, and attempt history never
/// accumulated, so the richer mastery model those packages already
/// implement had no memory across sessions. This store closes that gap the
/// same way `progress_store.dart`/`reward_store.dart` did for attempts and
/// rewards: [GameScreen] loads the previous state before evaluating, and
/// saves the updated one back after.
abstract class MasteryStateStore {
  MasteryState? load(String childProfileId, String skillId);

  Future<void> save(MasteryState state);

  /// Every skill this child has mastery evidence for -- the read side of
  /// the parent-dashboard data layer (Progress/Mastery/Learning gaps):
  /// raw [MasteryState] data, not shaped for any particular UI.
  List<MasteryState> loadAll(String childProfileId);
}

/// Real implementation, backed by the `mastery` Hive box (already opened
/// by `initHive()`, shared with `ProgressStore` -- keyed distinctly
/// (`mastery_state::child::skill`) so the two never collide).
class HiveMasteryStateStore implements MasteryStateStore {
  HiveMasteryStateStore(this._box);

  final Box _box;

  static String _key(String childProfileId, String skillId) =>
      'mastery_state::$childProfileId::$skillId';

  @override
  MasteryState? load(String childProfileId, String skillId) {
    final raw = _box.get(_key(childProfileId, skillId));
    if (raw is! String) return null;
    try {
      return MasteryState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(MasteryState state) async {
    await _box.put(
      _key(state.childId, state.skillId),
      jsonEncode(state.toJson()),
    );
  }

  @override
  List<MasteryState> loadAll(String childProfileId) {
    final prefix = 'mastery_state::$childProfileId::';
    final states = <MasteryState>[];
    for (final key in _box.keys) {
      if (key is! String || !key.startsWith(prefix)) continue;
      final raw = _box.get(key);
      if (raw is! String) continue;
      try {
        states.add(MasteryState.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        // Corrupted entry -- skip rather than fail the whole summary.
      }
    }
    return states;
  }
}

/// In-memory implementation for tests and any context where a real Hive
/// box isn't warranted.
class InMemoryMasteryStateStore implements MasteryStateStore {
  final Map<String, MasteryState> _store = {};

  @override
  MasteryState? load(String childProfileId, String skillId) =>
      _store['$childProfileId::$skillId'];

  @override
  Future<void> save(MasteryState state) async {
    _store['${state.childId}::${state.skillId}'] = state;
  }

  @override
  List<MasteryState> loadAll(String childProfileId) {
    final prefix = '$childProfileId::';
    return _store.entries
        .where((e) => e.key.startsWith(prefix))
        .map((e) => e.value)
        .toList();
  }
}
