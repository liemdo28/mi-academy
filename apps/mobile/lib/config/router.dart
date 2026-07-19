import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../screens/splash_screen.dart';
import '../screens/locale_selection_screen.dart';
import '../screens/login_screen.dart';
import '../screens/child_home_screen.dart';
import '../screens/game_screen.dart';
import '../screens/parent_dashboard_screen.dart';
import '../screens/parent_settings_screen.dart';
import '../screens/parent_pin_screen.dart';
import '../screens/child_selector_screen.dart';
import '../screens/world_map_screen.dart';
import '../screens/garden_screen.dart';

/// MI Academy app router using go_router.
///
/// Route structure:
/// - /                → SplashScreen
/// - /locale-select   → LocaleSelectionScreen (first-launch only)
/// - /login           → LoginScreen
/// - /select-child    → ChildSelectorScreen
/// - /home            → ChildHomeScreen
/// - /world           → WorldMapScreen
/// - /garden          → GardenScreen
/// - /game/:id        → GameScreen
/// - /parent          → ParentDashboardScreen (PIN-protected via /parent-pin)
/// - /parent-pin      → ParentPinScreen
/// - /parent/settings → ParentSettingsScreen
/// Parent routes that require a verified PIN this session. Enforced below
/// via `redirect` — without this, `/parent` and `/parent/settings` were
/// reachable by direct navigation, bypassing ParentPinScreen entirely.
const _parentGatedPaths = {'/parent', '/parent/settings'};

final routerProvider = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    if (!_parentGatedPaths.contains(state.matchedLocation)) return null;
    final verified = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(parentGateProvider);
    return verified ? null : '/parent-pin';
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/locale-select',
      builder: (context, state) => const LocaleSelectionScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/select-child',
      builder: (context, state) => const ChildSelectorScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const ChildHomeScreen(),
    ),
    GoRoute(
      path: '/world',
      builder: (context, state) => const WorldMapScreen(),
    ),
    GoRoute(path: '/garden', builder: (context, state) => const GardenScreen()),
    GoRoute(
      path: '/game/:gameId',
      builder: (context, state) {
        final gameId = state.pathParameters['gameId']!;
        final childId = state.uri.queryParameters['childId'] ?? 'offline-child';
        final lessonId = state.uri.queryParameters['lessonId'];
        return GameScreen(
          childId: childId,
          gameType: gameId,
          lessonId: lessonId,
        );
      },
    ),
    GoRoute(
      path: '/parent-pin',
      builder: (context, state) => const ParentPinScreen(),
    ),
    GoRoute(
      path: '/parent',
      builder: (context, state) => const ParentDashboardScreen(),
    ),
    GoRoute(
      path: '/parent/settings',
      builder: (context, state) => ParentSettingsScreen(
        store: ProviderScope.containerOf(
          context,
          listen: false,
        ).read(parentSettingsStoreProvider),
      ),
    ),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
);
