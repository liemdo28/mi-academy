import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mi_academy/app.dart';
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
Future<void> launchApp(WidgetTester tester) async {
  final parentSettingsStore = await HiveParentSettingsStore.open();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        parentSettingsStoreProvider.overrideWithValue(parentSettingsStore),
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
  const boxNames = [
    HiveParentSettingsStore.boxName,
    MiBoxes.auth,
    MiBoxes.profiles,
    MiBoxes.lessons,
    MiBoxes.levels,
    MiBoxes.progress,
    MiBoxes.attempts,
    MiBoxes.snapshots,
    MiBoxes.rewards,
    MiBoxes.syncQueue,
    MiBoxes.settings,
    MiBoxes.mastery,
  ];
  for (final boxName in boxNames) {
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
