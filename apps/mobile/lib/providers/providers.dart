import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mastery_core/mastery_core.dart';
import 'package:mi_game_content/mi_game_content.dart';
import 'package:mi_game_progress/mi_game_progress.dart';
import 'package:offline_sync/offline_sync.dart';
import 'package:mi_game_core/mi_game_core.dart';
import '../config/router.dart';
import '../services/api_service.dart';
import '../services/api_sync_processor.dart';
import '../services/game_levels.dart';
import '../services/game_registry.dart';
import '../services/mastery_state_store.dart';
import '../services/parent_settings_store.dart';
import '../services/progress_store.dart';
import '../services/reward_catalog_loader.dart';
import '../services/reward_store.dart';
import '../services/skill_taxonomy_loader.dart';
import '../services/snapshot_store.dart';
import '../services/world_progression_service.dart';
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
final dailyPlanProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final child = ref.watch(activeChildProvider);
  if (child.childId == null) return [];
  final result = await api.getDailyPlan(child.childId!);
  return result.cast<Map<String, dynamic>>();
});

/// Platform-owned per-child mastery/attempt persistence -- reads the
/// `mastery` Hive box opened by `initHive()`, same constraint as
/// [syncServiceProvider]. [GameScreen] records every completion here so
/// reward evaluation ([localRewardsProvider]) always sees full history.
final progressStoreProvider = Provider<ProgressStore>((ref) {
  return HiveProgressStore(box(MiBoxes.mastery));
});

/// Platform-owned local reward-unlock persistence -- reads the `rewards`
/// Hive box opened by `initHive()`. This, not the backend, is the source
/// of truth [GardenScreen] displays: a child playing offline must see
/// earned badges immediately, with no dependency on connectivity.
final rewardStoreProvider = Provider<RewardStore>((ref) {
  return HiveRewardStore(box(MiBoxes.rewards));
});

/// Platform-owned per-(child, skill) mastery persistence -- reads the same
/// `mastery` Hive box as [progressStoreProvider] under a distinct key
/// prefix. [GameScreen] loads the previous state before calling
/// `AdaptiveLearningService.evaluateCompletion` and saves the updated one
/// back, so mastery_core's confidence/status/reasonCodes model actually
/// accumulates across completions instead of recomputing from scratch.
final masteryStateStoreProvider = Provider<MasteryStateStore>((ref) {
  return HiveMasteryStateStore(box(MiBoxes.mastery));
});

/// Parent-dashboard data layer (Progress/Mastery/Learning gaps/Strengths) --
/// raw [MasteryState] per skill for the active child, fully offline. Not
/// shaped for any particular UI; a future dashboard redesign consumes this
/// rather than reading `reportsProvider`'s backend-only shadow-mode data.
final childMasteryStatesProvider = Provider<List<MasteryState>>((ref) {
  final child = ref.watch(activeChildProvider);
  if (child.childId == null) return [];
  return ref.watch(masteryStateStoreProvider).loadAll(child.childId!);
});

/// The canonical (gameId, levelId) -> (skillId, subjectId, curriculum
/// node, prerequisites) resolver -- built once from the real knowledge
/// graph/curriculum content (content/skills/skill_taxonomy.json,
/// content/curriculum/age_*.json), not from game-name heuristics. See
/// skill_taxonomy_loader.dart.
final activityMappingResolverProvider =
    FutureProvider<ActivityMappingResolver>((ref) {
  return loadActivityMappingResolver();
});

/// The bundled bilingual reward catalog content pack (rule definitions +
/// vi/en copy) -- same "content pack, not hardcoded" loading pattern as
/// game levels.
final rewardCatalogProvider = FutureProvider<RewardCatalog>((ref) {
  return loadRewardCatalog();
});

/// Rewards the active child has actually earned, resolved against the
/// local catalog -- fully offline, no backend dependency. [GardenScreen]
/// reads this instead of hitting the network.
final localRewardsProvider = FutureProvider<List<RewardDefinition>>((ref) async {
  final child = ref.watch(activeChildProvider);
  if (child.childId == null) return [];
  final catalog = await ref.watch(rewardCatalogProvider.future);
  final unlockedIds = ref.watch(rewardStoreProvider).unlockedIds(child.childId!);
  return catalog.rewards.where((r) => unlockedIds.contains(r.id)).toList();
});

/// Parent report provider.
final reportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final result = await api.getReports();
  final reports = result['reports'];
  if (reports is List) return reports.cast<Map<String, dynamic>>();
  return [result];
});

/// Games catalog provider — used to resolve a game_type (e.g.
/// "memory_cards") to the backend's DB game id (a UUID), since
/// SaveGameResultRequest / POST /games/{game_id}/result key on the DB id.
final gamesCatalogProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
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

/// Every registered game's level content, loaded once per app session
/// and cached by Riverpod — [worldProgressProvider] depends on this
/// rather than each rebuild re-reading and re-parsing every game's level
/// JSON. A game whose asset fails to load contributes no nodes to the
/// world map rather than failing the whole provider.
final allGameLevelsProvider =
    FutureProvider<Map<String, List<MiLevel>>>((ref) async {
  final result = <String, List<MiLevel>>{};
  for (final entry in GameRegistry.all) {
    try {
      result[entry.gameId] = await loadGameLevelsFromRootBundle(entry.gameId);
    } catch (_) {
      // Missing/broken content for one game must not block the rest of
      // the world map from rendering.
    }
  }
  return result;
});

/// This child's full attempt history — the same data reward evaluation
/// already reads in `GameScreen`, reused here for streak/accuracy/time
/// aggregation rather than a second attempt log.
final childAttemptsProvider = Provider<List<AttemptRecord>>((ref) {
  final child = ref.watch(activeChildProvider);
  if (child.childId == null) return const [];
  final tracker = ref.watch(progressStoreProvider).load(child.childId!);
  return tracker?.attempts ?? const [];
});

/// The World Map / Learning Journey data — every taxonomy subject's
/// [WorldProgress], built from already-cached mapping/level/mastery data
/// (see [WorldProgressionService]). Never re-parses the taxonomy or
/// curriculum itself; [activityMappingResolverProvider] does that once.
final worldProgressProvider = FutureProvider<List<WorldProgress>>((ref) async {
  final resolver = await ref.watch(activityMappingResolverProvider.future);
  final levelsByGame = await ref.watch(allGameLevelsProvider.future);
  final masteryStates = ref.watch(childMasteryStatesProvider);
  final settings = await ref.watch(parentSettingsProvider.future);
  final child = ref.watch(activeChildProvider);
  final attempts = ref.watch(childAttemptsProvider);

  const service = WorldProgressionService();
  return service.buildWorlds(
    taxonomy: resolver.taxonomy,
    resolver: resolver,
    levelsByGame: levelsByGame,
    masteryBySkill: {for (final m in masteryStates) m.skillId: m},
    recentAttempts: attempts,
    locale: settings.language,
    ageBand: child.child?['age_group'] as String?,
  );
});

/// Parent/child-facing learning summary (mastered/weak/strong skills,
/// review queue, streak, time spent, accuracy, earned rewards) — see
/// [LearningInsights] for exactly what this does and doesn't include.
final learningInsightsProvider = FutureProvider<LearningInsights>((ref) async {
  final resolver = await ref.watch(activityMappingResolverProvider.future);
  final masteryStates = ref.watch(childMasteryStatesProvider);
  final attempts = ref.watch(childAttemptsProvider);
  final unlockedRewards = await ref.watch(localRewardsProvider.future);
  final child = ref.watch(activeChildProvider);

  const service = WorldProgressionService();
  return service.buildInsights(
    taxonomy: resolver.taxonomy,
    curriculum: resolver.curriculum,
    allMastery: masteryStates,
    attempts: attempts,
    unlockedRewards: unlockedRewards,
    ageBand: child.child?['age_group'] as String?,
  );
});
