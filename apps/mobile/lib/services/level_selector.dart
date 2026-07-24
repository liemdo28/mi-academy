import 'package:equatable/equatable.dart';
import 'package:mastery_core/mastery_core.dart';
import 'package:mi_game_content/mi_game_content.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_progress/mi_game_progress.dart';
import 'package:spaced_repetition/spaced_repetition.dart';

/// Where one level sits in a child's progression through a game's level
/// list -- for a future level-map UI (see `WorldMapScreen`'s own comment:
/// "the locked/available/in-progress/completed state machine are a later
/// production wave... Dev 1 owns the navigation data"). Distinct from
/// [MasteryStatus], which is a per-*skill* evidence category; this is a
/// per-*level* playability/priority classification derived from it.
enum LevelProgressState {
  /// A prerequisite skill has not been introduced yet -- not playable.
  locked,

  /// The single level [LevelSelector.select] would pick right now.
  recommended,

  /// This level's skill is due for spaced-repetition review.
  review,

  /// This skill is already mastered at or above this level's difficulty.
  mastered,

  /// Author-flagged optional content (`metadata['bonus'] == true`) --
  /// never required for progression.
  bonus,

  /// Meaningfully harder than the child's current mastery -- available to
  /// attempt, but not the guaranteed-success path.
  challenge,

  /// Playable, ordinary next-in-line content.
  available,
}

/// One level's classification, for rendering a level list/map with
/// badges (locked padlock, "recommended" star, review reminder, etc.)
/// without re-deriving [LevelSelector]'s scoring logic per widget.
class LevelProgression extends Equatable {
  const LevelProgression({required this.level, required this.state});

  final MiLevel level;
  final LevelProgressState state;

  @override
  List<Object?> get props => [level, state];
}

/// Which level [LevelSelector] picked, and why -- reason codes exist for
/// the same reason `recommendation_core`'s `Recommendation.reasonCodes`
/// does: a selection nobody can explain isn't trustworthy, and a widget
/// test asserting on reason codes is far more meaningful than one
/// asserting on a scoring number that means nothing on its own.
class LevelSelectionResult {
  const LevelSelectionResult({required this.level, required this.reasonCodes});

  final MiLevel level;
  final List<String> reasonCodes;
}

/// Picks the best next level from a game's level list -- replacing the
/// previous `levels.first` behavior (see `GameScreen`'s old comment: "Only
/// ever the first level today... there's no per-level launch selection").
///
/// Scoped to *within one already-chosen game*: `GameScreen` is launched
/// with a specific `gameType`, so this selector decides which of that
/// game's levels to serve, not which game to play. Deciding *which game*
/// (and how much time to spend on it) is `recommendation_core`'s
/// `SessionPlanner`'s job, operating across a child's whole daily plan --
/// a separate, larger feature this does not attempt to replace or
/// duplicate.
///
/// Fully offline: every input is already-loaded local data, no network.
class LevelSelector {
  const LevelSelector({
    this.scheduler = const SpacedRepetitionScheduler(),
    // Below this, a prerequisite is considered "not yet introduced" --
    // matches skill_taxonomy.json's own `introducedThreshold` (0.15),
    // duplicated here as a default rather than imported since this
    // package has no dependency on the taxonomy's raw JSON structure,
    // only on already-resolved CanonicalActivityMapping/MasteryState data.
    this.prerequisiteIntroducedThreshold = 0.15,
  });

  final SpacedRepetitionScheduler scheduler;
  final double prerequisiteIntroducedThreshold;

  LevelSelectionResult select({
    required List<MiLevel> levels,
    required GameDescriptor game,
    required ActivityMappingResolver resolver,

    /// This child's persisted mastery, keyed by skillId. Empty for a
    /// brand-new child -- every level then falls back to the
    /// guaranteed-success path (lowest difficulty, no-prerequisite skills
    /// win).
    required Map<String, MasteryState> masteryBySkill,

    /// This child's attempt history, any game -- only this [game]'s
    /// entries are used, to avoid repeating the exact level just played.
    required List<AttemptRecord> recentAttempts,
    required String locale,
    required String? ageBand,
  }) {
    if (levels.isEmpty) {
      throw ArgumentError.value(levels, 'levels', 'must not be empty');
    }

    final candidates = <_Candidate>[];
    for (final level in levels) {
      final resolved = resolver.resolve(game: game, level: level);
      if (resolved.mapping != null) {
        candidates.add(_Candidate(level, resolved.mapping!));
      }
    }

    // No level in this game resolved a canonical mapping at all (content
    // data problem, or a game not properly registered) -- degrade to the
    // old behavior rather than leave the child with no game to play.
    if (candidates.isEmpty) {
      return LevelSelectionResult(
        level: levels.first,
        reasonCodes: const ['NO_CANONICAL_MAPPING_FALLBACK'],
      );
    }

    var pool = candidates
        .where((c) => c.level.ageBand == null || c.level.ageBand == ageBand)
        .toList();
    if (pool.isEmpty) pool = candidates; // don't over-filter into nothing

    final localePool = pool
        .where((c) => c.level.localizedContent.containsKey(locale))
        .toList();
    if (localePool.isNotEmpty) pool = localePool;

    final mostRecentLevelId = recentAttempts
        .where((a) => a.gameId == game.gameId)
        .fold<AttemptRecord?>(null, (latest, a) {
      if (latest == null || a.attemptedAt.isAfter(latest.attemptedAt)) {
        return a;
      }
      return latest;
    })?.levelId;

    _Candidate? best;
    var bestScore = double.negativeInfinity;
    var bestReasons = const <String>[];

    for (final candidate in pool) {
      final mapping = candidate.mapping;
      final mastery = masteryBySkill[mapping.primarySkillId];
      final reasons = <String>[];
      var score = 0.0;

      final unmetPrerequisites = mapping.prerequisites.where((prereqSkillId) {
        final prereqMastery = masteryBySkill[prereqSkillId];
        return prereqMastery == null ||
            prereqMastery.masteryScore < prerequisiteIntroducedThreshold;
      });
      if (unmetPrerequisites.isEmpty) {
        score += 10;
        reasons.add('PREREQUISITES_MET');
      } else {
        score -= 20;
        reasons.add('PREREQUISITES_UNMET');
      }

      if (mastery != null && scheduler.isDue(mastery)) {
        score += 15;
        reasons.add('REVIEW_DUE');
      }

      if (mastery == null) {
        // Guaranteed-success path: no evidence yet for this skill --
        // prefer the easiest available level so a brand-new child's first
        // attempt is winnable.
        score += (5 - candidate.level.difficulty).toDouble();
        reasons.add('NEW_SKILL_EASY_START');
      } else {
        final difficultyGap =
            (candidate.level.difficulty - mastery.currentDifficulty).abs();
        score += (5 - difficultyGap).clamp(-10, 5).toDouble();
        if (difficultyGap == 0) reasons.add('DIFFICULTY_MATCH');
      }

      if (candidate.level.id == mostRecentLevelId && pool.length > 1) {
        score -= 8;
        reasons.add('AVOID_IMMEDIATE_REPEAT');
      }

      if (score > bestScore) {
        bestScore = score;
        best = candidate;
        bestReasons = reasons;
      }
    }

    return LevelSelectionResult(level: best!.level, reasonCodes: bestReasons);
  }

  /// Classifies every level in [levels] into a [LevelProgressState], for a
  /// level-map/list UI. Calls [select] once internally to find the single
  /// "recommended" pick rather than re-deriving its scoring -- one source
  /// of truth for "what's next" either way.
  List<LevelProgression> classifyAll({
    required List<MiLevel> levels,
    required GameDescriptor game,
    required ActivityMappingResolver resolver,
    required Map<String, MasteryState> masteryBySkill,
    required List<AttemptRecord> recentAttempts,
    required String locale,
    required String? ageBand,
  }) {
    if (levels.isEmpty) return const [];

    final recommendedLevelId = select(
      levels: levels,
      game: game,
      resolver: resolver,
      masteryBySkill: masteryBySkill,
      recentAttempts: recentAttempts,
      locale: locale,
      ageBand: ageBand,
    ).level.id;

    return [
      for (final level in levels)
        _classify(level, game, resolver, masteryBySkill, recommendedLevelId),
    ];
  }

  LevelProgression _classify(
    MiLevel level,
    GameDescriptor game,
    ActivityMappingResolver resolver,
    Map<String, MasteryState> masteryBySkill,
    String recommendedLevelId,
  ) {
    final mapping = resolver.resolve(game: game, level: level).mapping;

    // No canonical mapping resolved for this level -- degrade to plain
    // availability rather than guess a state from nothing, mirroring
    // select()'s own NO_CANONICAL_MAPPING_FALLBACK behavior.
    if (mapping == null) {
      return LevelProgression(
          level: level, state: LevelProgressState.available);
    }

    final unmetPrerequisites = mapping.prerequisites.where((prereqSkillId) {
      final prereqMastery = masteryBySkill[prereqSkillId];
      return prereqMastery == null ||
          prereqMastery.masteryScore < prerequisiteIntroducedThreshold;
    });
    if (unmetPrerequisites.isNotEmpty) {
      return LevelProgression(level: level, state: LevelProgressState.locked);
    }

    if (level.id == recommendedLevelId) {
      return LevelProgression(
          level: level, state: LevelProgressState.recommended);
    }

    final mastery = masteryBySkill[mapping.primarySkillId];
    if (mastery != null && scheduler.isDue(mastery)) {
      return LevelProgression(level: level, state: LevelProgressState.review);
    }

    if (mastery != null &&
        mastery.status == MasteryStatus.mastered &&
        level.difficulty <= mastery.currentDifficulty) {
      return LevelProgression(level: level, state: LevelProgressState.mastered);
    }

    if (level.metadata['bonus'] == true) {
      return LevelProgression(level: level, state: LevelProgressState.bonus);
    }

    final baselineDifficulty = mastery?.currentDifficulty ?? 1;
    if (level.difficulty - baselineDifficulty >= 2) {
      return LevelProgression(
          level: level, state: LevelProgressState.challenge);
    }

    return LevelProgression(level: level, state: LevelProgressState.available);
  }
}

class _Candidate {
  const _Candidate(this.level, this.mapping);

  final MiLevel level;
  final CanonicalActivityMapping mapping;
}
