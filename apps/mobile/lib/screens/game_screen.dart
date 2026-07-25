import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:mastery_core/mastery_core.dart';
import 'package:mi_game_content/mi_game_content.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_progress/mi_game_progress.dart';
import 'package:offline_sync/offline_sync.dart';
import 'package:uuid/uuid.dart';

import '../providers/providers.dart';
import '../services/adaptive_learning_service.dart';
import '../services/game_levels.dart';
import '../services/game_registry.dart';
import '../services/level_selector.dart';

/// Production game launcher — the real `/game/:gameId` destination.
///
/// Loads real level content for [gameType] and renders the matching game
/// engine (the same widgets the debug picker in `main.dart` uses), so the
/// production golden flow plays an actual game rather than a placeholder.
/// Every game reports completion via `onComplete(MiCompletionResult)`; this
/// screen — not the game itself — turns that into a `SaveGameResultRequest`
/// call with an offline-queue fallback, per the "games don't call the
/// backend directly" rule.
class GameScreen extends ConsumerStatefulWidget {
  final String childId;
  final String gameType;
  final String? lessonId;
  const GameScreen({
    super.key,
    required this.childId,
    required this.gameType,
    this.lessonId,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  List<MiLevel>? _levels;
  // The level to actually serve -- either one being resumed (an existing
  // snapshot always wins) or [LevelSelector]'s pick. Null only while
  // [_levels] is also null/empty; [build] falls back to levels.first in
  // that gap so a mid-load frame never crashes.
  MiLevel? _selectedLevel;
  String? _error;
  MiGameSnapshot? _initialSnapshot;
  bool _reduceMotion = false;
  // Was hardcoded to 'vi' everywhere a game reads locale-specific content
  // (every game session class, MiGameContext.language) regardless of the
  // parent's actual language setting -- confirmed during the 1.0 release
  // audit that ParentSettingsSnapshot.language was write-only, read by
  // nothing. Sourced from the same settings load as _reduceMotion.
  String _locale = 'vi';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLevels());
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameType != widget.gameType ||
        oldWidget.childId != widget.childId ||
        oldWidget.lessonId != widget.lessonId) {
      setState(() {
        _levels = null;
        _selectedLevel = null;
        _error = null;
        _initialSnapshot = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadLevels();
      });
    }
  }

  Future<void> _loadLevels() async {
    try {
      final settings = await ref.read(parentSettingsStoreProvider).load();
      if (!mounted) return;
      setState(() {
        _reduceMotion = settings.reduceMotion;
        _locale = settings.language;
      });
      final levels = await loadGameLevels(context, widget.gameType);
      if (!mounted) return;

      if (levels.isEmpty) {
        setState(() {
          _levels = levels;
          _selectedLevel = null;
          _initialSnapshot = null;
        });
        return;
      }

      // Resuming an in-progress level always wins over fresh selection --
      // a child mid-level must never be redirected to a different one just
      // because LevelSelector would otherwise pick something else.
      final snapshotStore = ref.read(snapshotStoreProvider);
      MiLevel? resumeLevel;
      MiGameSnapshot? resumeSnapshot;
      for (final level in levels) {
        final snapshot = snapshotStore.load(
          childProfileId: widget.childId,
          gameId: widget.gameType,
          levelId: level.id,
        );
        if (snapshot != null) {
          resumeLevel = level;
          resumeSnapshot = snapshot;
          break;
        }
      }

      final selectedLevel = resumeLevel ?? await _selectFreshLevel(levels);
      if (!mounted) return;
      setState(() {
        _levels = levels;
        _selectedLevel = selectedLevel;
        _initialSnapshot = resumeSnapshot;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  /// Picks which of [levels] to serve for a fresh (non-resumed) launch --
  /// replaces the old "always levels.first" behavior. See
  /// services/level_selector.dart for the actual scoring; this method's
  /// job is just gathering that selector's inputs from the providers this
  /// screen already has access to.
  ///
  /// Never throws: any failure (missing registry entry, resolver load
  /// failure) falls back to `levels.first`, same as before this feature
  /// existed, so a selection problem can never block play entirely.
  Future<MiLevel> _selectFreshLevel(List<MiLevel> levels) async {
    final entry = GameRegistry.find(widget.gameType);
    if (entry == null) return levels.first;

    try {
      final resolver = await ref.read(activityMappingResolverProvider.future);
      final masteryStore = ref.read(masteryStateStoreProvider);
      final progressTracker =
          ref.read(progressStoreProvider).load(widget.childId);

      // MasteryStateStore is keyed by (child, skillId); collect the
      // skillIds this game's own levels reference so we only look up
      // mastery this game could actually need, rather than every skill
      // the child has ever practiced.
      final skillIds = <String>{
        for (final level in levels) ...level.skillTags,
      };
      final masteryBySkill = <String, MasteryState>{};
      for (final skillId in skillIds) {
        final state = masteryStore.load(widget.childId, skillId);
        if (state != null) masteryBySkill[skillId] = state;
      }

      final result = const LevelSelector().select(
        levels: levels,
        game: GameDescriptor(
          gameId: entry.gameId,
          subjectId: entry.category,
          ageBands: entry.ageBands,
        ),
        resolver: resolver,
        masteryBySkill: masteryBySkill,
        recentAttempts: progressTracker?.attempts ?? const [],
        locale: _locale,
        // The game's own registered age bands, not yet the specific
        // child's -- GameScreen has no child-profile age lookup today.
        // LevelSelector treats a non-matching/unknown age band as
        // "don't over-filter," so this degrades gracefully rather than
        // silently excluding levels.
        ageBand: entry.ageBands.isNotEmpty ? entry.ageBands.first : null,
      );
      return result.level;
    } catch (_) {
      return levels.first;
    }
  }

  void _onSaveSnapshot(MiGameSnapshot snapshot) {
    // Child game screens can call this from their own dispose() (see
    // SnapshotLifecycleMixin), including during whole-widget-tree teardown
    // (app close, test teardown). `mounted` alone isn't enough here: during
    // a teardown pass Flutter deactivates a whole subtree before unmounting
    // it, and `State.mounted` stays true throughout deactivation -- only
    // `unmount()` (after `dispose()` returns) flips it. If GameScreen's own
    // element is deactivated in the same pass as the child that's saving,
    // ref.read()'s ancestor lookup throws even though `mounted` says true.
    // This save is always best-effort (the child screen already has the
    // snapshot in memory regardless), so swallow that failure rather than
    // crash the teardown.
    if (!mounted) return;
    try {
      ref.read(snapshotStoreProvider).save(snapshot);
    } catch (_) {}
  }

  Future<void> _saveResult(MiCompletionResult result) async {
    // The level is done (whether or not the backend save below succeeds) --
    // any in-progress snapshot for it is stale now, so it must not be
    // offered as "resume" on a future launch of the same level.
    await ref.read(snapshotStoreProvider).clear(
          childProfileId: widget.childId,
          gameId: widget.gameType,
          levelId: result.levelId,
        );

    final ungraded = _isUngradedCompletion(result);

    // Resolved once and threaded through both the local reward/progress
    // path and the adaptive-shadow path below, so a single completion
    // never reasons about two different skill identities depending on
    // which block happens to run.
    final mapping = ungraded ? null : await _resolveCanonicalMapping(result);

    // Local-only: progress tracking and reward unlocking need no network,
    // so this runs unconditionally (including for the 'offline-child' test
    // sentinel below) -- a child playing without connectivity must earn
    // rewards exactly as reliably as one online.
    await _recordProgressAndRewards(result, mapping);

    if (widget.childId == 'offline-child') return;

    List<Map<String, dynamic>> games;
    try {
      games = await ref.read(gamesCatalogProvider.future);
    } catch (_) {
      // Family/live web builds can run fully offline or without a reachable
      // backend catalog. Local progress/rewards are already recorded above,
      // so a backend lookup failure must not surface as an unhandled game
      // error after the child completes a level.
      return;
    }
    final game = games.firstWhere(
      (g) => g['game_type'] == widget.gameType,
      orElse: () => const {},
    );
    final dbGameId = game['id'] as String?;
    if (dbGameId == null) return; // Game not in backend catalog yet.

    final attemptId = const Uuid().v4();
    final startedAt = result.completedAt.subtract(result.duration).toUtc();
    final completedAt = result.completedAt.toUtc();
    final correctCount = ungraded
        ? 0
        : (result.perfectRun
            ? result.attemptsUsed
            : (result.attemptsUsed - 1).clamp(0, result.attemptsUsed));
    final incorrectCount = ungraded ? 0 : result.attemptsUsed - correctCount;
    Map<String, dynamic> adaptiveShadow;
    if (ungraded) {
      adaptiveShadow = {
        'shadow_mode': true,
        'skipped': true,
        'reason_codes': ['UNGRADED_PARTICIPATION'],
      };
    } else {
      try {
        // mastery_core's MasteryState carries evidenceCount/confidence/
        // attemptHistory that only mean anything if it accumulates across
        // completions -- load whatever this child already has for this
        // skill (mastery_state_store.dart) instead of always starting from
        // a fresh, zero-evidence state.
        final skillId =
            AdaptiveLearningService.resolvedSkillId(result, mapping: mapping);
        final masteryStore = ref.read(masteryStateStoreProvider);
        final previousMastery = masteryStore.load(widget.childId, skillId);

        final shadow = const AdaptiveLearningService().evaluateCompletion(
          childProfileId: widget.childId,
          result: result,
          offlineMode: !await ref.read(connectivityProvider.future),
          previousMastery: previousMastery,
          mapping: mapping,
        );
        await masteryStore.save(shadow.mastery);
        adaptiveShadow = shadow.toJson();
      } catch (_) {
        adaptiveShadow = {
          'shadow_mode': true,
          'used_fallback': true,
          'reason_codes': ['ADAPTIVE_EXCEPTION_FALLBACK'],
        };
      }
    }
    final body = {
      'attempt_id': attemptId,
      'child_profile_id': widget.childId,
      'game_id': dbGameId,
      'level_id': result.levelId,
      if (widget.lessonId != null) 'lesson_id': widget.lessonId,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt.toIso8601String(),
      'attempt_count': result.attemptsUsed,
      'correct_count': correctCount,
      'incorrect_count': incorrectCount,
      'hint_count': result.hintsUsed,
      'duration_seconds': result.duration.inSeconds,
      'completed': true,
      'mastery_evidence': !ungraded && result.maxScore > 0
          ? (result.score / result.maxScore).clamp(0.0, 1.0)
          : 0.0,
      'skill_evidence': {
        if (!ungraded)
          for (final skill in result.newSkillsAcquired) skill: true,
      },
      'metadata': {
        ...result.metadata,
        'adaptive_shadow': adaptiveShadow,
      },
    };

    try {
      final api = ref.read(apiServiceProvider);
      await api.submitGameResult(dbGameId, body);
    } catch (_) {
      // Offline, or the save didn't go through — queue it for later
      // instead of dropping the result on the floor.
      try {
        await ref.read(syncServiceProvider).enqueue(
              id: attemptId,
              childProfileId: widget.childId,
              type: SyncItemType.gameResult,
              payload: body,
            );
      } catch (_) {
        // Best-effort — nothing more we can do without a queue.
      }
    }
  }

  /// Resolves the canonical (gameId, levelId) -> (skillId, subjectId,
  /// curriculum node, prerequisites) mapping for this completion, against
  /// the real knowledge graph/curriculum content -- see
  /// mi_game_content's ActivityMappingResolver. Returns null (never
  /// throws) when the game isn't registered, the completed level can't be
  /// found in what's currently loaded, or the mapping fails validation
  /// (e.g. an unmapped or unknown skill) -- callers fall back to
  /// [AdaptiveLearningService]'s documented compatibility heuristics in
  /// that case, never crash on a resolution failure.
  Future<CanonicalActivityMapping?> _resolveCanonicalMapping(
    MiCompletionResult result,
  ) async {
    final entry = GameRegistry.find(widget.gameType);
    final levels = _levels;
    if (entry == null || levels == null) return null;

    MiLevel? level;
    for (final candidate in levels) {
      if (candidate.id == result.levelId) {
        level = candidate;
        break;
      }
    }
    if (level == null) return null;

    try {
      final resolver = await ref.read(activityMappingResolverProvider.future);
      final mappingResult = resolver.resolve(
        game: GameDescriptor(
          gameId: entry.gameId,
          subjectId: entry.category,
          ageBands: entry.ageBands,
        ),
        level: level,
      );
      return mappingResult.mapping;
    } catch (_) {
      return null;
    }
  }

  /// Records this completion into the child's local [ProgressTracker] and
  /// evaluates the reward catalog against the updated history. Every one
  /// of the 8 built games (and every future one, since they all launch
  /// through this same [GameScreen]) gets reward-unlock behavior for free
  /// — no per-game wiring needed. Newly-unlocked rewards are persisted
  /// locally (so [GardenScreen] reflects them immediately, offline) and
  /// best-effort queued for backend notification.
  ///
  /// [mapping] is the canonical mapping resolved for this exact level, if
  /// any (see [_resolveCanonicalMapping]) -- when present, its
  /// taxonomy-validated skill IDs replace the old
  /// `result.newSkillsAcquired`/generic-tag fallback.
  Future<void> _recordProgressAndRewards(
    MiCompletionResult result,
    CanonicalActivityMapping? mapping,
  ) async {
    final ungraded = _isUngradedCompletion(result);
    final progressStore = ref.read(progressStoreProvider);
    final tracker = progressStore.load(widget.childId) ??
        ProgressTracker(childId: widget.childId);

    if (ungraded) {
      tracker.recordParticipationCompletion(
        gameId: widget.gameType,
        levelId: result.levelId,
        duration: result.duration,
        hintsUsed: result.hintsUsed,
      );
    } else {
      tracker.recordCompletion(
        gameId: widget.gameType,
        levelId: result.levelId,
        correct: true,
        duration: result.duration,
        hintsUsed: result.hintsUsed,
        skillIds: mapping != null
            ? [mapping.primarySkillId, ...mapping.secondarySkillIds]
            : (result.newSkillsAcquired.isNotEmpty
                ? result.newSkillsAcquired
                : ['${widget.gameType}.general']),
      );
    }
    await progressStore.save(tracker);

    final rewardStore = ref.read(rewardStoreProvider);
    final alreadyUnlocked = rewardStore.unlockedIds(widget.childId);
    RewardCatalog catalog;
    try {
      catalog = await ref.read(rewardCatalogProvider.future);
    } catch (_) {
      return; // Catalog was unavailable -- try again on the next completion.
    }

    final newlyUnlocked = const RewardEngine().evaluate(
      catalog: catalog,
      attempts: tracker.attempts,
      gameCategories: {
        for (final entry in GameRegistry.all) entry.gameId: entry.category,
      },
      alreadyUnlocked: alreadyUnlocked,
    );

    for (final rewardId in newlyUnlocked) {
      await rewardStore.unlock(widget.childId, rewardId);
      try {
        await ref.read(syncServiceProvider).enqueue(
          id: '${widget.childId}_${rewardId}_${result.completedAt.microsecondsSinceEpoch}',
          childProfileId: widget.childId,
          type: SyncItemType.rewardUnlock,
          payload: {
            'reward_id': rewardId,
            'unlocked_at': DateTime.now().toUtc().toIso8601String(),
          },
        );
      } catch (_) {
        // Best-effort — the reward is already unlocked locally regardless.
      }
    }
  }

  bool _isUngradedCompletion(MiCompletionResult result) {
    return result.metadata['assessmentModel'] == 'ungraded' ||
        result.metadata['isMasteryScore'] == false;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
            leading: IconButton(
                icon: const Icon(Icons.close), onPressed: () => context.pop())),
        body: MiErrorState(
          title: _locale == 'en'
              ? 'This game could not be loaded'
              : 'Không thể tải trò chơi',
          retryLabel: _locale == 'en' ? 'Try again' : 'Thử lại',
          onRetry: () {
            setState(() => _error = null);
            _loadLevels();
          },
        ),
      );
    }

    final levels = _levels;
    if (levels == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (levels.isEmpty) {
      return Scaffold(
        appBar: AppBar(
            leading: IconButton(
                icon: const Icon(Icons.close), onPressed: () => context.pop())),
        body: Center(
          child: Text(
            _locale == 'en'
                ? 'No levels are available for this game yet'
                : 'Chưa có cấp độ nào cho trò chơi này',
          ),
        ),
      );
    }

    return _buildGame(_selectedLevel ?? levels.first, levels);
  }

  Widget _buildGame(MiLevel level, List<MiLevel> allLevels) {
    void onExit() => context.pop();

    final entry = GameRegistry.find(widget.gameType);
    if (entry == null || !entry.enabled) {
      // Unregistered game ID (typo, not-yet-built game, or a disabled
      // feature-flagged one) -- safe fallback, never a crash.
      return Scaffold(
        appBar: AppBar(
            leading:
                IconButton(icon: const Icon(Icons.close), onPressed: onExit)),
        body: Center(
          child: Text(
            _locale == 'en'
                ? 'Game "${widget.gameType}" is not supported yet'
                : 'Trò chơi "${widget.gameType}" chưa hỗ trợ',
          ),
        ),
      );
    }

    return entry.builder(
      level: level,
      allLevels: allLevels,
      onExit: onExit,
      onComplete: _saveResult,
      childProfileId: widget.childId,
      initialSnapshot: _initialSnapshot,
      onSaveSnapshot: _onSaveSnapshot,
      creativeArtifactStore: widget.gameType == 'free_creativity'
          ? ref.read(creativeArtifactStoreProvider)
          : null,
      reduceMotion: _reduceMotion,
      locale: _locale,
    );
  }
}
