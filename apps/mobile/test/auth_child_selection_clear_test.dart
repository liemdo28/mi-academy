import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/providers/providers.dart';
import 'package:mi_academy/services/api_service.dart';

/// Regression test for a real shared-device bug found during the PR #4
/// final audit: ActiveChildNotifier.loadChildren() preserves the previous
/// childId across a refresh via copyWith (correct for the same parent's
/// own session), but neither logout() nor forceLogout() ever cleared
/// activeChildProvider at all. On a shared device, a second parent logging
/// in after a first parent's logout would inherit the first parent's
/// stale childId until the backend's ownership check rejected it with
/// 403s -- a broken flow, though not an actual cross-family data leak
/// since the backend already validates ownership server-side.
void main() {
  test('logout() clears the previously-selected child', () async {
    final container = ProviderContainer(overrides: [
      apiServiceProvider.overrideWithValue(
        ApiService(
            baseUrl: 'http://test.local', tokenStore: InMemoryTokenStore()),
      ),
    ]);
    addTearDown(container.dispose);

    // Simulate a prior parent having selected a child.
    await container
        .read(activeChildProvider.notifier)
        .selectChild({'id': 'child-from-parent-a', 'nickname': 'A kid'});
    expect(container.read(activeChildProvider).childId, 'child-from-parent-a');

    await container.read(authProvider.notifier).logout();

    final state = container.read(activeChildProvider);
    expect(state.childId, isNull);
    expect(state.child, isNull);
    expect(state.children, isEmpty);
  });

  test('forceLogout() clears the previously-selected child', () async {
    final container = ProviderContainer(overrides: [
      apiServiceProvider.overrideWithValue(
        ApiService(
            baseUrl: 'http://test.local', tokenStore: InMemoryTokenStore()),
      ),
    ]);
    addTearDown(container.dispose);

    await container
        .read(activeChildProvider.notifier)
        .selectChild({'id': 'child-from-parent-a', 'nickname': 'A kid'});

    container.read(authProvider.notifier).forceLogout();

    expect(container.read(activeChildProvider).childId, isNull);
  });
}
