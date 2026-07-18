import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mi_academy/app.dart';
import 'package:mi_academy/config/router.dart';
import 'package:mi_academy/providers/providers.dart';
import 'package:mi_academy/services/parent_settings_store.dart';
import 'package:offline_sync/offline_sync.dart';

/// Reusable app-launch helper for integration tests.
///
/// Boots the real widget tree (the same `MiAcademyApp` `main.dart` uses)
/// against real, on-device Hive storage -- not a mocked provider tree --
/// so these tests exercise actual persistence, not a test double of it.
/// Only [parentSettingsStoreProvider] is overridden, and only because
/// `main()` itself does the same override (it opens the store before
/// `runApp` so it's available synchronously); every other provider is the
/// real production one.
///
/// `config/router.dart`'s `routerProvider` is a top-level `GoRouter`
/// singleton, not something scoped per [ProviderScope] -- re-pumping
/// `MiAcademyApp` to simulate a relaunch (this test binary can't actually
/// kill and restart the OS process) reattaches to that *same* GoRouter
/// instance, which still remembers whatever route the previous simulated
/// launch navigated to. Forcing it back to `/` first is what makes each
/// [launchApp] call actually re-run `SplashScreen`'s cold-start redirect
/// logic, instead of silently resuming wherever the last call left off.
Future<void> launchApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  final parentSettingsStore = await HiveParentSettingsStore.open();
  routerProvider.go('/');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        parentSettingsStoreProvider.overrideWithValue(parentSettingsStore),
        ...overrides,
      ],
      child: const MiAcademyApp(),
    ),
  );
  // One real frame plus settle covers the splash screen's
  // addPostFrameCallback-triggered async routing decision -- no arbitrary
  // fixed-duration sleep.
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

/// Clears all local app state (Hive boxes) so each test scenario starts
/// from a true fresh-install state, independent of any other test that
/// ran before it in the same process.
Future<void> resetLocalState() async {
  await initHive();
  // sync_queue is the one box opened with a typed adapter
  // (Box<SyncQueueItem> -- see initHive); Hive.box(name) (implicitly
  // Box<dynamic>) throws HiveError on a box that's already open with a
  // different type parameter, so it needs its own correctly-typed clear.
  if (Hive.isBoxOpen(MiBoxes.syncQueue)) {
    await Hive.box<SyncQueueItem>(MiBoxes.syncQueue).clear();
  }
  const untypedBoxNames = [
    HiveParentSettingsStore.boxName,
    MiBoxes.auth,
    MiBoxes.profiles,
    MiBoxes.lessons,
    MiBoxes.levels,
    MiBoxes.progress,
    MiBoxes.attempts,
    MiBoxes.snapshots,
    MiBoxes.rewards,
    MiBoxes.settings,
    MiBoxes.mastery,
  ];
  for (final boxName in untypedBoxNames) {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).clear();
    }
  }
}

/// Deterministic test IDs -- avoids relying on real UUID generation (which
/// would make assertions on "the profile I just created" awkward) while
/// still exercising the real profile-creation code paths.
class TestIds {
  static const childA = 'test-child-aaaaaaaa';
  static const childB = 'test-child-bbbbbbbb';
}
