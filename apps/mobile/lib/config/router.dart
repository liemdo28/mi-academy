import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
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
/// - /login           → LoginScreen
/// - /select-child    → ChildSelectorScreen
/// - /home            → ChildHomeScreen
/// - /world           → WorldMapScreen
/// - /garden          → GardenScreen
/// - /game/:id        → GameScreen
/// - /parent          → ParentDashboardScreen (PIN-protected via /parent-pin)
/// - /parent-pin      → ParentPinScreen
/// - /parent/settings → ParentSettingsScreen
final routerProvider = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
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
    GoRoute(
      path: '/garden',
      builder: (context, state) => const GardenScreen(),
    ),
    GoRoute(
      path: '/game/:gameId',
      builder: (context, state) {
        final gameId = state.pathParameters['gameId']!;
        final childId = state.uri.queryParameters['childId'] ?? 'offline-child';
        final lessonId = state.uri.queryParameters['lessonId'];
        return GameScreen(childId: childId, gameType: gameId, lessonId: lessonId);
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
      builder: (context, state) => ParentSettingsScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri}'),
    ),
  ),
);
