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
  static const String rewards = 'rewards';
  static const String syncQueue = 'sync_queue';
  static const String settings = 'settings';
  static const String mastery = 'mastery';
}

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

  await Hive.openBox<SyncQueueItem>(MiBoxes.syncQueue);
  await Hive.openBox(MiBoxes.progress);
  await Hive.openBox(MiBoxes.attempts);
  await Hive.openBox(MiBoxes.lessons);
  await Hive.openBox(MiBoxes.levels);
  await Hive.openBox(MiBoxes.rewards);
  await Hive.openBox(MiBoxes.snapshots);
  await Hive.openBox(MiBoxes.profiles);
  await Hive.openBox(MiBoxes.settings);
  await Hive.openBox(MiBoxes.auth);
  await Hive.openBox(MiBoxes.mastery);
}

/// Get a Hive box by name.
Box<T> box<T>(String name) => Hive.box<T>(name);
