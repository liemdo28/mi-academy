import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Platform-owned local persistence of which reward IDs a child has
/// unlocked. This is the offline source of truth [GardenScreen] reads --
/// unlike the backend `ChildReward` table, it never needs connectivity to
/// be accurate, matching this app's offline-first default (no embedded
/// backend URL; see docs/RELEASE_READINESS_BASELINE.md).
abstract class RewardStore {
  /// Reward IDs (stable slugs from the bundled reward catalog) already
  /// unlocked for [childProfileId].
  Set<String> unlockedIds(String childProfileId);

  /// Marks [rewardId] unlocked for [childProfileId]. Idempotent.
  Future<void> unlock(String childProfileId, String rewardId);
}

/// Real implementation, backed by the `rewards` Hive box (already opened
/// by `initHive()`, previously unused).
class HiveRewardStore implements RewardStore {
  HiveRewardStore(this._box);

  final Box _box;

  @override
  Set<String> unlockedIds(String childProfileId) {
    final raw = _box.get(childProfileId);
    if (raw is! String) return {};
    try {
      return Set<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> unlock(String childProfileId, String rewardId) async {
    final current = unlockedIds(childProfileId);
    if (current.contains(rewardId)) return;
    await _box.put(
      childProfileId,
      jsonEncode([...current, rewardId]),
    );
  }
}

/// In-memory implementation for tests and any context where a real Hive
/// box isn't warranted.
class InMemoryRewardStore implements RewardStore {
  final Map<String, Set<String>> _store = {};

  @override
  Set<String> unlockedIds(String childProfileId) =>
      Set.unmodifiable(_store[childProfileId] ?? const {});

  @override
  Future<void> unlock(String childProfileId, String rewardId) async {
    _store.putIfAbsent(childProfileId, () => {}).add(rewardId);
  }
}
