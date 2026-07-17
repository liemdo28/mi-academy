import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/lessons_screen.dart';
import '../screens/questions_screen.dart';
import '../screens/games_screen.dart';
import '../screens/localization_screen.dart';

final adminRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    // TODO: Check auth state from secure storage
    final isLoggedIn = _isLoggedIn(); // Replace with actual auth check
    final isLogin = state.matchedLocation == '/login';
    if (!isLoggedIn && !isLogin) return '/login';
    if (isLoggedIn && isLogin) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
        GoRoute(path: '/lessons', builder: (context, state) => const LessonsScreen()),
        GoRoute(path: '/questions', builder: (context, state) => const QuestionsScreen()),
        GoRoute(path: '/games', builder: (context, state) => const GamesScreen()),
        GoRoute(path: '/localization', builder: (context, state) => const LocalizationScreen()),
      ],
    ),
  ],
);

bool _isLoggedIn() => false;

/// Admin layout shell with navigation sidebar.
class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex(context),
            onDestinationSelected: (i) => _navigate(context, i),
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('MI Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: Text('Lessons'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.quiz_outlined),
                selectedIcon: Icon(Icons.quiz),
                label: Text('Questions'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.games_outlined),
                selectedIcon: Icon(Icons.games),
                label: Text('Games'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.translate_outlined),
                selectedIcon: Icon(Icons.translate),
                label: Text('i18n'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc == '/') return 0;
    if (loc.startsWith('/lessons')) return 1;
    if (loc.startsWith('/questions')) return 2;
    if (loc.startsWith('/games')) return 3;
    if (loc.startsWith('/localization')) return 4;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/'); break;
      case 1: context.go('/lessons'); break;
      case 2: context.go('/questions'); break;
      case 3: context.go('/games'); break;
      case 4: context.go('/localization'); break;
    }
  }
}
