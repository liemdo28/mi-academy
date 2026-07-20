import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:offline_sync/offline_sync.dart';
import 'package:uuid/uuid.dart';
import 'package:localization/localization.dart';

import '../providers/providers.dart';
import '../services/adaptive_learning_service.dart';
import '../services/game_levels.dart';
import '../services/game_registry.dart';

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
      // Only ever the first level today (see _buildGame) -- resuming a
      // snapshot for a level the child isn't currently being shown isn't
      // meaningful yet, since there's no per-level launch selection.
      final firstLevel = levels.isNotEmpty ? levels.first : null;
      final snapshot = firstLevel == null
          ? null
          : ref.read(snapshotStoreProvider).load(
                childProfileId: widget.childId,
                gameId: widget.gameType,
                levelId: firstLevel.id,
              );
      setState(() {
        _levels = levels;
        _initialSnapshot = snapshot;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
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

    if (widget.childId == 'offline-child') return;

    final games = await ref.read(gamesCatalogProvider.future);
    final game = games.firstWhere(
      (g) => g['game_type'] == widget.gameType,
      orElse: () => const {},
    );
    final dbGameId = game['id'] as String?;
    if (dbGameId == null) return; // Game not in backend catalog yet.

    final attemptId = const Uuid().v4();
    final startedAt = result.completedAt.subtract(result.duration).toUtc();
    final completedAt = result.completedAt.toUtc();
    final correctCount = result.perfectRun
        ? result.attemptsUsed
        : (result.attemptsUsed - 1).clamp(0, result.attemptsUsed);
    final incorrectCount = result.attemptsUsed - correctCount;
    Map<String, dynamic> adaptiveShadow;
    try {
      adaptiveShadow = const AdaptiveLearningService()
          .evaluateCompletion(
            childProfileId: widget.childId,
            result: result,
            offlineMode: !await ref.read(connectivityProvider.future),
          )
          .toJson();
    } catch (_) {
      adaptiveShadow = {
        'shadow_mode': true,
        'used_fallback': true,
        'reason_codes': ['ADAPTIVE_EXCEPTION_FALLBACK'],
      };
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
      'mastery_evidence': result.maxScore > 0
          ? (result.score / result.maxScore).clamp(0.0, 1.0)
          : 0.0,
      'skill_evidence': {
        for (final skill in result.newSkillsAcquired) skill: true,
      },
      'metadata': {...result.metadata, 'adaptive_shadow': adaptiveShadow},
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

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: MiErrorState(
          title: _locale == 'en'
              ? 'This game could not be loaded'
              : MiMobileStrings.m068,
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
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            _locale == 'en'
                ? 'No levels are available for this game yet'
                : MiMobileStrings.m069,
          ),
        ),
      );
    }

    return _buildGame(levels.first, levels);
  }

  Widget _buildGame(MiLevel level, List<MiLevel> allLevels) {
    void onExit() => context.pop();

    final entry = GameRegistry.find(widget.gameType);
    if (entry == null || !entry.enabled) {
      // Unregistered game ID (typo, not-yet-built game, or a disabled
      // feature-flagged one) -- safe fallback, never a crash.
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.close), onPressed: onExit),
        ),
        body: Center(
          child: Text(
            _locale == 'en'
                ? 'Game "${widget.gameType}" is not supported yet'
                : MiMobileStrings.text('m070', {'p0': widget.gameType}),
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
      reduceMotion: _reduceMotion,
      locale: _locale,
    );
  }
}
