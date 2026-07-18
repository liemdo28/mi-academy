import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mi_academy/services/parent_settings_store.dart';

import 'helpers/app_launch.dart';

/// Real on-device integration coverage for the first-launch language
/// selection flow (Milestone 1 WS2, Suite A/E/H subset).
///
/// Scope note: this covers the part of Suite A/E/H that does not require a
/// backend (splash -> locale selection -> persistence -> reset). The
/// parts of Suite A/B/C/D/F/G that require an authenticated parent session
/// (PIN creation, child profiles, game completion, time limits) are not
/// covered by this file -- they need either a real or mocked backend
/// reachable from the test device, which was not stood up in this pass.
/// See docs/testing.md's integration-test section for the honest current
/// scope and what remains.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetLocalState();
  });

  testWidgets('fresh install shows language selection before any content',
      (tester) async {
    await launchApp(tester);

    expect(find.text('Tiếng Việt'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets(
      'selecting Vietnamese persists and is not asked again on relaunch',
      (tester) async {
    await launchApp(tester);
    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Relaunch (new widget tree, same on-device Hive storage) --
    // simulates an app restart without an actual process kill, which
    // `flutter test integration_test` cannot perform mid-test.
    await launchApp(tester);
    expect(find.text('Tiếng Việt'), findsNothing);
    expect(find.text('English'), findsNothing);

    final settings = await (await HiveParentSettingsStore.open()).load();
    expect(settings.language, 'vi');
    expect(settings.localeConfirmed, isTrue);
  });

  testWidgets('selecting English persists and is not asked again on relaunch',
      (tester) async {
    await launchApp(tester);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await launchApp(tester);
    expect(find.text('Tiếng Việt'), findsNothing);
    expect(find.text('English'), findsNothing);

    final settings = await (await HiveParentSettingsStore.open()).load();
    expect(settings.language, 'en');
    expect(settings.localeConfirmed, isTrue);
  });

  testWidgets(
      'a full local-data reset returns the app to language selection on next launch',
      (tester) async {
    await launchApp(tester);
    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final store = await HiveParentSettingsStore.open();
    await store.deleteChildData();

    await launchApp(tester);
    expect(find.text('Tiếng Việt'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });
}
