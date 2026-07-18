import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/config/router.dart';
import 'package:mi_academy/providers/providers.dart';

/// Covers the redirect guard added in router.dart: `/parent` and
/// `/parent/settings` must not be reachable by direct navigation without a
/// verified parent PIN this session — previously nothing enforced that.
void main() {
  testWidgets(
      'direct navigation to /parent redirects to the PIN gate when unverified',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: routerProvider),
      ),
    );
    // Let SplashScreen's own async redirect (auth restore -> /login) finish
    // first, so it doesn't race with the explicit navigation below.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    routerProvider.go('/parent');
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Nhập mã PIN phụ huynh'), findsOneWidget);
  });

  testWidgets('/parent is reachable once the parent gate is verified',
      (tester) async {
    final container = ProviderContainer(
      overrides: [parentGateProvider.overrideWith((ref) => true)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: routerProvider),
      ),
    );
    // Let SplashScreen's own async redirect (auth restore -> /login) finish
    // first, so it doesn't race with the explicit navigation below.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    routerProvider.go('/parent');
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Bảng điều khiển phụ huynh'), findsOneWidget);
    expect(find.text('Nhập mã PIN phụ huynh'), findsNothing);
  });
}
