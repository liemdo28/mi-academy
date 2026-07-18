import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_academy/providers/providers.dart';
import 'package:mi_academy/screens/locale_selection_screen.dart';
import 'package:mi_academy/screens/splash_screen.dart';
import 'package:mi_academy/services/parent_settings_store.dart';

/// Covers the first-launch language-selection requirement from the MI
/// Academy 1.0 audit: a fresh install (or a post-data-reset state) must not
/// silently default to Vietnamese -- it must ask, persist the answer, and
/// apply it immediately without an app restart.
void main() {
  group('startRouteFor', () {
    test('unconfirmed locale always routes to /locale-select first', () {
      expect(
        startRouteFor(
          isAuthenticated: true,
          hasSelectedChild: true,
          localeConfirmed: false,
        ),
        '/locale-select',
      );
      expect(
        startRouteFor(
          isAuthenticated: false,
          hasSelectedChild: false,
          localeConfirmed: false,
        ),
        '/locale-select',
      );
    });

    test('confirmed locale falls through to the normal auth-based routing', () {
      expect(
        startRouteFor(isAuthenticated: false, hasSelectedChild: false),
        '/login',
      );
    });
  });

  testWidgets('fresh install shows the locale-selection screen, not content',
      (tester) async {
    final store = MemoryParentSettingsStore();
    final container = ProviderContainer(
      overrides: [parentSettingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LocaleSelectionScreen()),
      ),
    );

    expect(find.text('Tiếng Việt'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  GoRouter buildTestRouter() => GoRouter(
        initialLocation: '/locale-select',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Text('post-selection destination')),
          ),
          GoRoute(
            path: '/locale-select',
            builder: (context, state) => const LocaleSelectionScreen(),
          ),
        ],
      );

  testWidgets(
      'selecting Vietnamese persists language and localeConfirmed, '
      'then navigates on', (tester) async {
    final store = MemoryParentSettingsStore();
    final container = ProviderContainer(
      overrides: [parentSettingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: buildTestRouter()),
      ),
    );

    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle();

    final saved = await store.load();
    expect(saved.language, 'vi');
    expect(saved.localeConfirmed, isTrue);
    expect(find.text('post-selection destination'), findsOneWidget);
  });

  testWidgets(
      'selecting English persists language and localeConfirmed, '
      'then navigates on', (tester) async {
    final store = MemoryParentSettingsStore();
    final container = ProviderContainer(
      overrides: [parentSettingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: buildTestRouter()),
      ),
    );

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    final saved = await store.load();
    expect(saved.language, 'en');
    expect(saved.localeConfirmed, isTrue);
    expect(find.text('post-selection destination'), findsOneWidget);
  });

  test('selection persists across a simulated restart (new store read)',
      () async {
    final store = MemoryParentSettingsStore();
    await store.save(
      const ParentSettingsSnapshot(language: 'en', localeConfirmed: true),
    );

    // A restart just re-reads the same underlying store/box; simulate that
    // by loading again rather than reusing any in-memory widget state.
    final reloaded = await store.load();
    expect(reloaded.language, 'en');
    expect(reloaded.localeConfirmed, isTrue);
  });

  test('changing language later (Parent Settings path) keeps localeConfirmed',
      () async {
    final store = MemoryParentSettingsStore();
    await store.save(
      const ParentSettingsSnapshot(language: 'vi', localeConfirmed: true),
    );

    final current = await store.load();
    await store.save(current.copyWith(language: 'en'));

    final updated = await store.load();
    expect(updated.language, 'en');
    expect(updated.localeConfirmed, isTrue,
        reason: 'Changing language later must not re-trigger first-launch '
            'selection.');
  });

  test('a full local-data reset clears localeConfirmed', () async {
    final store = MemoryParentSettingsStore();
    await store.save(
      const ParentSettingsSnapshot(language: 'en', localeConfirmed: true),
    );

    await store.deleteChildData();

    final afterReset = await store.load();
    expect(afterReset.localeConfirmed, isFalse,
        reason: 'SplashScreen must route back to /locale-select after a '
            'full local-data reset.');
  });
}
