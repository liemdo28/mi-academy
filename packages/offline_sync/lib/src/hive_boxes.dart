import 'package:hive_flutter/hive_flutter.dart';

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
Future<void> initHive() async {
  await Hive.initFlutter();

  // Register adapters
  // await Hive.openBox('sync_queue');
  // await Hive.openBox('progress');
  // await Hive.openBox('attempts');
  // await Hive.openBox('lessons');
  // await Hive.openBox('levels');
  // await Hive.openBox('rewards');
  // await Hive.openBox('snapshots');
  // await Hive.openBox('profiles');
  // await Hive.openBox('settings');
  // await Hive.openBox('auth');
  // await Hive.openBox('mastery');
}

/// Get a Hive box by name.
Box<T> box<T>(String name) => Hive.box<T>(name);
