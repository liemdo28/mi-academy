import 'package:hive_flutter/hive_flutter.dart';

import 'sync_queue.dart';

/// Hive box names for MI Academy.
abstract class MiBoxes {
  static const String auth = 'auth';
  static const String profiles = 'profiles';
  static const String lessons = 'lessons';
  static const String levels = 'levels';
  static const String progress = 'progress';
  static const String attempts = 'attempts';
  static const String snapshots = 'snapshots';
  static const String creativeArtifacts = 'creative_artifacts';
  static const String rewards = 'rewards';
  static const String syncQueue = 'sync_queue';
  static const String settings = 'settings';
  static const String mastery = 'mastery';
}

/// Boxes that failed to open normally and were recovered by deleting the
/// corrupted file and recreating an empty box -- surfaced so a caller can
/// report this via diagnostics rather than it happening silently. Empty
/// until [initHive] runs.
final List<String> recoveredCorruptedBoxes = [];

/// Initialize all Hive boxes.
///
/// Only the sync-queue box has a typed adapter registered today; the rest
/// are opened untyped (`Box<dynamic>`) since their local-cache schemas
/// aren't finalized yet. Opening them here (rather than leaving them
/// commented out) is required for [SyncService]/[SyncQueue] to function —
/// `Hive.box()` throws if the box was never opened.
Future<void> initHive() async {
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(SyncQueueItemAdapter().typeId)) {
    Hive.registerAdapter(SyncQueueItemAdapter());
  }

  await openBoxWithCorruptionRecovery<SyncQueueItem>(MiBoxes.syncQueue);
  await openBoxWithCorruptionRecovery(MiBoxes.progress);
  await openBoxWithCorruptionRecovery(MiBoxes.attempts);
  await openBoxWithCorruptionRecovery(MiBoxes.lessons);
  await openBoxWithCorruptionRecovery(MiBoxes.levels);
  await openBoxWithCorruptionRecovery(MiBoxes.rewards);
  await openBoxWithCorruptionRecovery(MiBoxes.snapshots);
  await openBoxWithCorruptionRecovery(MiBoxes.creativeArtifacts);
  await openBoxWithCorruptionRecovery(MiBoxes.profiles);
  await openBoxWithCorruptionRecovery(MiBoxes.settings);
  await openBoxWithCorruptionRecovery(MiBoxes.auth);
  await openBoxWithCorruptionRecovery(MiBoxes.mastery);
}

/// Opens a box, recovering from a corrupted on-disk file instead of
/// letting the exception propagate out of [initHive] -- previously an
/// uncaught HiveError there (a corrupted box file, e.g. from an
/// interrupted write) meant `main()` never reached `runApp`, leaving the
/// app permanently blank/crashed with no recovery path.
///
/// Deleting-and-recreating a corrupted box does lose that box's cached
/// data, which matters most for [MiBoxes.syncQueue] (unsynced attempts).
/// This is still the right tradeoff: an unusable app loses everything,
/// while this loses only the one corrupted box's contents and the app
/// recovers. It's a last resort, only reached when the normal open fails.
Future<Box<T>> openBoxWithCorruptionRecovery<T>(String name) async {
  try {
    return await Hive.openBox<T>(name);
  } catch (_) {
    await Hive.deleteBoxFromDisk(name);
    final reopened = await Hive.openBox<T>(name);
    recoveredCorruptedBoxes.add(name);
    return reopened;
  }
}

/// Get a Hive box by name.
Box<T> box<T>(String name) => Hive.box<T>(name);
