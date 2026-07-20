import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_sync/offline_sync.dart';
import '../config/router.dart';
import '../services/api_service.dart';
import '../services/api_sync_processor.dart';
import '../services/child_profile_store.dart';
import '../services/parent_settings_store.dart';
import '../services/snapshot_store.dart';
import 'auth_provider.dart';
import 'child_provider.dart';

/// Parent settings store — defaults to an in-memory store (e.g. for tests
/// and the debug game picker); `main()` overrides this with a Hive-backed
/// store for the real app so settings persist across launches.
final parentSettingsStoreProvider = Provider<ParentSettingsStore>((ref) {
  return MemoryParentSettingsStore();
});

/// The parent's saved settings (language, accessibility, etc.), loaded from
/// [parentSettingsStoreProvider]. Consumers that need to react to a settings
/// change (e.g. MiAcademyApp's locale) should watch this and callers that
/// change settings (ParentSettingsScreen) must `ref.invalidate` it after
/// saving, since the underlying store has no change-notification of its own.
final parentSettingsProvider = FutureProvider<ParentSettingsSnapshot>((ref) {
  final store = ref.watch(parentSettingsStoreProvider);
  return store.load();
});

/// API service provider — singleton, initialized once.
///
/// Wires `onSessionExpired` so a mid-session unrecoverable 401 (refresh
/// token itself expired/rejected) doesn't just error out the screen that
/// happened to be making the request -- it resets auth state and sends the
/// whole app back to /login, same as an explicit logout would.
final apiServiceProvider = Provider<ApiService>((ref) {
  final api = ApiService();
  api.onSessionExpired = () {
    ref.read(authProvider.notifier).forceLogout();
    routerProvider.go('/login');
  };
  return api;
});

final childProfileStoreProvider = Provider<ChildProfileStore>((ref) {
  if (!HiveChildProfileStore.isReady) return MemoryChildProfileStore();
  return HiveChildProfileStore();
});

/// Parent PIN verifier.
///
/// Kept as a provider seam so the parent gate can be tested without network.
final parentPinVerifierProvider = Provider<Future<bool> Function(String)>((
  ref,
) {
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

/// Whether the parent has verified their PIN (or biometric/adult-challenge
/// fallback) *this app session*. Gates `/parent` and `/parent/settings` via
/// `router.dart`'s redirect — without this, either route was reachable by
/// direct navigation without ever going through `ParentPinScreen`. Reset on
/// logout so a fresh sign-in re-locks the parent area.
final parentGateProvider = StateProvider<bool>((ref) => false);

/// Active child profile provider.
final activeChildProvider =
    NotifierProvider<ActiveChildNotifier, ActiveChildState>(
  () => ActiveChildNotifier(),
);

/// Daily plan provider.
final dailyPlanProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final api = ref.read(apiServiceProvider);
  final child = ref.watch(activeChildProvider);
  if (child.childId == null) return [];
  if (!api.hasConfiguredBackend) return [];
  final result = await api.getDailyPlan(child.childId!);
  return result.cast<Map<String, dynamic>>();
});

/// Rewards provider.
final rewardsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final child = ref.watch(activeChildProvider);
  if (child.childId == null) return [];
  if (!api.hasConfiguredBackend) return [];
  final result = await api.getChildRewards(child.childId!);
  return result.cast<Map<String, dynamic>>();
});

/// Parent report provider.
final reportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  if (!api.hasConfiguredBackend) return [];
  final result = await api.getReports();
  final reports = result['reports'];
  if (reports is List) return reports.cast<Map<String, dynamic>>();
  return [result];
});

/// Games catalog provider — used to resolve a game_type (e.g.
/// "memory_cards") to the backend's DB game id (a UUID), since
/// SaveGameResultRequest / POST /games/{game_id}/result key on the DB id.
final gamesCatalogProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final api = ref.read(apiServiceProvider);
  if (!api.hasConfiguredBackend) return [];
  final result = await api.getGames();
  return result.cast<Map<String, dynamic>>();
});

/// Connectivity status provider — backed by connectivity_plus.
final connectivityProvider = FutureProvider<bool>((ref) async {
  final results = await Connectivity().checkConnectivity();
  return results.any((r) => r != ConnectivityResult.none);
});

/// Offline sync service — owns the local sync queue and drains it against
/// the backend when connectivity is available. Constructing this reads the
/// Hive boxes opened by `initHive()` in main(), so it must not be read
/// before that has run.
final syncServiceProvider = Provider<SyncService>((ref) {
  final api = ref.read(apiServiceProvider);
  final processor = ApiSyncProcessor(ApiServiceSyncClient(api));
  final service = SyncService(
    queueBox: box<SyncQueueItem>(MiBoxes.syncQueue),
    progressBox: box(MiBoxes.progress),
    attemptBox: box(MiBoxes.attempts),
    processor: processor.call,
  );
  service.start();
  ref.onDispose(service.stop);
  return service;
});

/// Platform-owned snapshot save/load (Phase 10) — reads the `snapshots`
/// Hive box opened by `initHive()`, same constraint as [syncServiceProvider].
final snapshotStoreProvider = Provider<SnapshotStore>((ref) {
  return HiveSnapshotStore(box(MiBoxes.snapshots));
});
