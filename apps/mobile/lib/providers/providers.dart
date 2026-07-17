import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'child_provider.dart';

/// API service provider — singleton, initialized once.
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Parent PIN verifier.
///
/// Kept as a provider seam so the parent gate can be tested without network.
final parentPinVerifierProvider =
    Provider<Future<bool> Function(String)>((ref) {
  return (pin) async {
    final api = ref.read(apiServiceProvider);
    await api.verifyPin(pin);
    return true;
  };
});

/// Auth state provider.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);

/// Active child profile provider.
final activeChildProvider =
    NotifierProvider<ActiveChildNotifier, ActiveChildState>(
  () => ActiveChildNotifier(),
);

/// Lesson catalog provider.
final lessonCatalogProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final child = ref.watch(activeChildProvider);
  final ageGroup = child.child?['age_group'];
  final result = await api.getLessons(ageGroup: ageGroup);
  return result.cast<Map<String, dynamic>>();
});

/// Daily plan provider.
final dailyPlanProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final child = ref.watch(activeChildProvider);
  if (child.childId == null) return [];
  final result = await api.getDailyPlan(child.childId!);
  return result.cast<Map<String, dynamic>>();
});

/// Rewards provider.
final rewardsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final child = ref.watch(activeChildProvider);
  if (child.childId == null) return [];
  final result = await api.getChildRewards(child.childId!);
  return result.cast<Map<String, dynamic>>();
});

/// Parent report provider.
final reportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final result = await api.getReports();
  final reports = result['reports'];
  if (reports is List) return reports.cast<Map<String, dynamic>>();
  return [result];
});

/// Connectivity status provider.
final connectivityProvider = FutureProvider<bool>((ref) async {
  // TODO: Use connectivity_plus for real checks
  return true;
});
