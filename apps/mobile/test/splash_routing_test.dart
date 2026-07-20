import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/screens/splash_screen.dart';

/// Covers the cold-start routing decision documented on [SplashScreen]:
/// unauthenticated (including storage-failure/API-unavailable, which
/// AuthNotifier.initialize() degrades to isAuthenticated: false) always
/// lands on /login; authenticated users go to /home if a child is already
/// selected (single-child auto-select happens upstream in
/// ActiveChildNotifier.loadChildren) or /select-child otherwise.
void main() {
  test('unauthenticated always goes to /login, regardless of child state', () {
    expect(
      startRouteFor(isAuthenticated: false, hasSelectedChild: false),
      '/login',
    );
    expect(
      startRouteFor(isAuthenticated: false, hasSelectedChild: true),
      '/login',
    );
  });

  test('authenticated with a selected child goes to /home', () {
    expect(
      startRouteFor(isAuthenticated: true, hasSelectedChild: true),
      '/home',
    );
  });

  test('authenticated with no selected child goes to /select-child', () {
    expect(
      startRouteFor(isAuthenticated: true, hasSelectedChild: false),
      '/select-child',
    );
  });

  test('family mode without backend starts from local profile flow', () {
    expect(
      startRouteFor(
        isAuthenticated: false,
        hasSelectedChild: false,
        backendConfigured: false,
      ),
      '/select-child',
    );
    expect(
      startRouteFor(
        isAuthenticated: false,
        hasSelectedChild: true,
        backendConfigured: false,
      ),
      '/home',
    );
  });
}
