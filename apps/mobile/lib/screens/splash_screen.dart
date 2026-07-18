import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';

/// Decides where the app lands after cold start, based on restored auth
/// state — not a fixed delay to `/login`.
///
/// - No stored/valid token (unauthenticated, storage failure, or API
///   unavailable while restoring — `AuthNotifier.initialize()` degrades to
///   `isAuthenticated: false` on any error) -> `/login`.
/// - Authenticated with at least one child profile -> `/home` (the child
///   that gets auto-selected follows the existing single-child rule in
///   `ActiveChildNotifier.loadChildren`; with multiple children the parent
///   picks one from `/select-child`... but since the API returned children
///   and none is auto-selected for >1, route there instead).
/// - Authenticated with zero children -> `/select-child` (its "add child"
///   card covers first-run child creation).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashState();
}

/// Pure routing decision, factored out of [SplashScreen] so it's testable
/// without mocking secure storage / network — see `test/splash_routing_test.dart`.
String startRouteFor({
  required bool isAuthenticated,
  required bool hasSelectedChild,
}) {
  if (!isAuthenticated) return '/login';
  return hasSelectedChild ? '/home' : '/select-child';
}

class _SplashState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveStartRoute());
  }

  Future<void> _resolveStartRoute() async {
    await ref.read(authProvider.notifier).initialize();
    if (!mounted) return;

    final isAuthenticated = ref.read(authProvider).isAuthenticated;
    if (isAuthenticated) {
      await ref.read(activeChildProvider.notifier).loadChildren();
      if (!mounted) return;
    }

    final hasSelectedChild = ref.read(activeChildProvider).childId != null;
    context.go(startRouteFor(
      isAuthenticated: isAuthenticated,
      hasSelectedChild: hasSelectedChild,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20)
                ],
              ),
              child: const Icon(Icons.smart_toy,
                  size: 72, color: MiColors.primary),
            ),
            const SizedBox(height: 24),
            const Text('MI Academy',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Học vui, chơi hay',
                style: TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
