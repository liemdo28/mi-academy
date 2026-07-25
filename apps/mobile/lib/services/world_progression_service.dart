import 'package:mastery_core/mastery_core.dart';
import 'package:mi_game_content/mi_game_content.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_progress/mi_game_progress.dart';
import 'package:spaced_repetition/spaced_repetition.dart';

import 'game_registry.dart';
import 'level_selector.dart';

/// One playable node in a world's map -- one (game, level), already
/// classified by [LevelSelector]. [reasonCodes] is only populated when
/// [state] is [LevelProgressState.recommended] (the same reason codes
/// [LevelSelector.select] would return for it), so a UI can explain "why
/// this lesson appears" without re-deriving the scoring.
class JourneyNode {
  const JourneyNode({
    required this.level,
    required this.game,
    required this.mapping,
    required this.state,
    this.reasonCodes = const [],
  });

  final MiLevel level;
  final GameRegistryEntry game;
  final CanonicalActivityMapping mapping;
  final LevelProgressState state;
  final List<String> reasonCodes;
}

/// One subject's world: every [JourneyNode] that resolved to it, grouped
/// by [CanonicalActivityMapping.subjectId] (the taxonomy-resolved
/// subject, never the game's raw `category` string -- see
/// [CanonicalActivityMapping]'s own doc comment on why those can
/// disagree). [name] comes straight from [SubjectDefinition.name] in the
/// taxonomy -- never a second, hand-maintained display-name map.
///
/// A subject with zero registered games (e.g. 'science', 'creative' as of
/// this feature's build) still gets a [WorldProgress] entry with
/// [nodes] empty -- an honest "not built yet" world, not a fabricated one
/// with placeholder content.
class WorldProgress {
  const WorldProgress({
    required this.subjectId,
    required this.name,
    required this.nodes,
  });

  final String subjectId;
  final Map<String, String> name;
  final List<JourneyNode> nodes;

  int get totalNodes => nodes.length;

  int get masteredCount =>
      nodes.where((n) => n.state == LevelProgressState.mastered).length;

  /// 0.0 for a world with no content yet -- never divides by zero, never
  /// shows a fake percentage for content that doesn't exist.
  double get completionPercent =>
      totalNodes == 0 ? 0.0 : masteredCount / totalNodes;

  List<JourneyNode> nodesInState(LevelProgressState state) =>
      nodes.where((n) => n.state == state).toList(growable: false);
}

/// One skill's display identity plus its current mastery score, for the
/// weak/strong-skills and mastered/review lists -- pairs a stable ID with
/// its taxonomy display name so a UI never needs a second name lookup.
class SkillInsight {
  const SkillInsight({
    required this.skillId,
    required this.name,
    required this.masteryScore,
  });

  final String skillId;
  final Map<String, String> name;
  final double masteryScore;
}

/// Parent/child-facing learning summary, built entirely from data other
/// services already compute (mastery, attempts, rewards) -- no new
/// tracked concept invented here beyond aggregation.
///
/// Deliberately does NOT include XP, coins, or a "recent achievements"
/// feed sorted by unlock time: neither exists anywhere in this app's data
/// model today ([RewardStore] persists only a `Set<String>` of unlocked
/// IDs, with no unlock timestamp), and fabricating either would violate
/// the "no fake rewards" requirement. [unlockedRewards] is the same
/// honest, unordered "currently earned" list [GardenScreen] already
/// shows.
class LearningInsights {
  const LearningInsights({
    required this.masteredSkills,
    required this.skillsNeedingReview,
    required this.weakSkills,
    required this.strongSkills,
    required this.curriculumCompletionBySubject,
    required this.streakDays,
    required this.totalTimeSpent,
    required this.overallAccuracy,
    required this.unlockedRewards,
  });

  final List<SkillInsight> masteredSkills;
  final List<SkillInsight> skillsNeedingReview;

  /// Lowest-mastery skills with real evidence (evidenceCount > 0) --
  /// never a zero-evidence skill, which would just be "not started," not
  /// "weak."
  final List<SkillInsight> weakSkills;
  final List<SkillInsight> strongSkills;

  /// subjectId -> fraction of that (ageBand, subject) curriculum node's
  /// skills mastered, or null when that age band has no curriculum node
  /// for the subject yet (see [CurriculumMap.nodeFor]) -- distinct from
  /// 0.0, which would wrongly imply a child has made no progress on
  /// content that doesn't exist for them yet.
  final Map<String, double?> curriculumCompletionBySubject;

  final int streakDays;
  final Duration totalTimeSpent;

  /// 0.0 when there's no attempt history yet, not a divide-by-zero crash.
  final double overallAccuracy;

  final List<RewardDefinition> unlockedRewards;
}

/// Aggregates [LevelSelector], [ActivityMappingResolver], mastery, and
/// reward data into the "world map" and "learning journey" views --
/// itself holds no state and does no I/O; every input is data the caller
/// already loaded (typically once, from cached Riverpod providers -- see
/// `providers.dart`'s `worldProgressProvider`/`learningInsightsProvider`),
/// so calling this repeatedly costs list iteration, never re-parsing
/// content.
class WorldProgressionService {
  const WorldProgressionService({
    this.levelSelector = const LevelSelector(),
    this.scheduler = const SpacedRepetitionScheduler(),
  });

  final LevelSelector levelSelector;
  final SpacedRepetitionScheduler scheduler;

  /// One [WorldProgress] per taxonomy subject -- every real subject in
  /// `content/skills/skill_taxonomy.json`, whether or not any game
  /// currently has content for it.
  List<WorldProgress> buildWorlds({
    required SkillTaxonomy taxonomy,
    required ActivityMappingResolver resolver,

    /// Already-loaded levels per game (e.g. via `loadGameLevels`), keyed
    /// by `GameRegistryEntry.gameId`. A game with no entry here (or an
    /// empty list) simply contributes no nodes -- never a fabricated one.
    required Map<String, List<MiLevel>> levelsByGame,
    required Map<String, MasteryState> masteryBySkill,
    required List<AttemptRecord> recentAttempts,
    required String locale,
    required String? ageBand,
  }) {
    final nodesBySubject = <String, List<JourneyNode>>{};

    for (final entry in GameRegistry.all) {
      final levels = levelsByGame[entry.gameId];
      if (levels == null || levels.isEmpty) continue;

      final game = GameDescriptor(
        gameId: entry.gameId,
        subjectId: entry.category,
        ageBands: entry.ageBands,
      );

      final classified = levelSelector.classifyAll(
        levels: levels,
        game: game,
        resolver: resolver,
        masteryBySkill: masteryBySkill,
        recentAttempts: recentAttempts,
        locale: locale,
        ageBand: ageBand,
      );

      LevelSelectionResult? selection;
      try {
        selection = levelSelector.select(
          levels: levels,
          game: game,
          resolver: resolver,
          masteryBySkill: masteryBySkill,
          recentAttempts: recentAttempts,
          locale: locale,
          ageBand: ageBand,
        );
      } catch (_) {
        selection = null; // Same defensive posture as classifyAll's caller.
      }

      for (final progression in classified) {
        final mapping =
            resolver.resolve(game: game, level: progression.level).mapping;
        // No canonical mapping -- this level can't be placed in any
        // world honestly, so it's excluded rather than guessed into one.
        if (mapping == null) continue;

        final reasonCodes =
            progression.state == LevelProgressState.recommended &&
                    selection != null &&
                    selection.level.id == progression.level.id
                ? selection.reasonCodes
                : const <String>[];

        nodesBySubject.putIfAbsent(mapping.subjectId, () => []).add(
              JourneyNode(
                level: progression.level,
                game: entry,
                mapping: mapping,
                state: progression.state,
                reasonCodes: reasonCodes,
              ),
            );
      }
    }

    return [
      for (final subject in taxonomy.subjects)
        WorldProgress(
          subjectId: subject.subjectId,
          name: subject.name,
          nodes: nodesBySubject[subject.subjectId] ?? const [],
        ),
    ];
  }

  /// Parent/child learning summary -- see [LearningInsights] for what is
  /// deliberately left out and why.
  LearningInsights buildInsights({
    required SkillTaxonomy taxonomy,
    required CurriculumMap curriculum,
    required List<MasteryState> allMastery,
    required List<AttemptRecord> attempts,
    required List<RewardDefinition> unlockedRewards,
    required String? ageBand,
  }) {
    final evidenced = allMastery.where((m) => m.evidenceCount > 0).toList();
    final mastered =
        evidenced.where((m) => m.masteryScore >= taxonomy.masteryThreshold);
    final due = scheduler.getDueSkills(allMastery);

    final sortedByMastery = [...evidenced]
      ..sort((a, b) => a.masteryScore.compareTo(b.masteryScore));

    final gradedAttempts = attempts.where((a) => a.isGraded).toList();
    final correctCount = gradedAttempts.where((a) => a.isCorrect).length;
    final totalTime = attempts.fold<Duration>(
      Duration.zero,
      (sum, a) => sum + a.duration,
    );

    return LearningInsights(
      masteredSkills: [for (final m in mastered) _named(m, taxonomy)],
      skillsNeedingReview: [for (final m in due) _named(m, taxonomy)],
      weakSkills: [
        for (final m in sortedByMastery.take(3)) _named(m, taxonomy)
      ],
      strongSkills: [
        for (final m in sortedByMastery.reversed.take(3)) _named(m, taxonomy),
      ],
      curriculumCompletionBySubject: {
        for (final subject in taxonomy.subjects)
          subject.subjectId: _curriculumCompletionFor(
            subject.subjectId,
            ageBand,
            curriculum,
            allMastery,
            taxonomy,
          ),
      },
      streakDays: StreakCalculator.currentStreakDays(attempts),
      totalTimeSpent: totalTime,
      overallAccuracy:
          gradedAttempts.isEmpty ? 0.0 : correctCount / gradedAttempts.length,
      unlockedRewards: unlockedRewards,
    );
  }

  SkillInsight _named(MasteryState mastery, SkillTaxonomy taxonomy) {
    final skill = taxonomy.skill(mastery.skillId);
    return SkillInsight(
      skillId: mastery.skillId,
      // Falls back to the raw ID (never a blank string) if a mastery
      // record somehow references a skill the current taxonomy no
      // longer has -- visibly wrong rather than silently missing.
      name: skill?.name ?? {'vi': mastery.skillId, 'en': mastery.skillId},
      masteryScore: mastery.masteryScore,
    );
  }

  double? _curriculumCompletionFor(
    String subjectId,
    String? ageBand,
    CurriculumMap curriculum,
    List<MasteryState> allMastery,
    SkillTaxonomy taxonomy,
  ) {
    if (ageBand == null) return null;
    final node = curriculum.nodeFor(ageGroup: ageBand, subjectId: subjectId);
    if (node == null || node.skillIds.isEmpty) return null;

    final masteryBySkill = {for (final m in allMastery) m.skillId: m};
    final masteredCount = node.skillIds.where((skillId) {
      final mastery = masteryBySkill[skillId];
      return mastery != null &&
          mastery.masteryScore >= taxonomy.masteryThreshold;
    }).length;
    return masteredCount / node.skillIds.length;
  }
}
