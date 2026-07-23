import 'package:mastery_core/mastery_core.dart';
import 'package:mi_game_content/mi_game_content.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:recommendation_core/recommendation_core.dart';

class AdaptiveShadowResult {
  const AdaptiveShadowResult({
    required this.engineVersion,
    required this.mastery,
    required this.recommendation,
    required this.reasonCodes,
    required this.usedFallback,
  });

  final String engineVersion;
  final MasteryState mastery;
  final RecommendationResult recommendation;
  final List<String> reasonCodes;
  final bool usedFallback;

  Map<String, dynamic> toJson() => {
        'engine_version': engineVersion,
        'mastery': mastery.toJson(),
        'recommendation_count': recommendation.recommendations.length,
        'recommendation_engine_version': recommendation.engineVersion,
        'reason_codes': reasonCodes,
        'used_fallback': usedFallback,
        'shadow_mode': true,
      };
}

class AdaptiveLearningService {
  const AdaptiveLearningService({
    this.masteryEngine = const MasteryEngine(),
    this.recommendationEngine = const RecommendationEngine(),
  });

  final MasteryEngine masteryEngine;
  final RecommendationEngine recommendationEngine;

  /// Compatibility fallback only -- used when no [CanonicalActivityMapping]
  /// could be resolved for this completion (mapping/content load failure,
  /// or a level with no `metadata.skillIds` at all). Guesses a skill
  /// identity from the raw `MiCompletionResult`, the same way this method
  /// always worked before `mi_game_content`'s `ActivityMappingResolver`
  /// existed. Kept, tested, and clearly named as a fallback rather than
  /// removed outright, since a resolution failure must never crash
  /// mastery tracking -- see [resolvedSkillId].
  static String skillIdFor(MiCompletionResult result) {
    return result.newSkillsAcquired.isNotEmpty
        ? result.newSkillsAcquired.first
        : '${result.gameId}.${result.levelId}';
  }

  /// The skill this completion provides evidence for. Prefers the
  /// canonical, taxonomy-validated [mapping] when one was resolved;
  /// only falls back to [skillIdFor]'s heuristic when it wasn't. Exposed
  /// so callers (GameScreen) can look up the right [MasteryState] to pass
  /// as [previousMastery] *before* calling [evaluateCompletion], without
  /// duplicating this derivation logic.
  static String resolvedSkillId(
    MiCompletionResult result, {
    CanonicalActivityMapping? mapping,
  }) {
    return mapping?.primarySkillId ?? skillIdFor(result);
  }

  AdaptiveShadowResult evaluateCompletion({
    required String childProfileId,
    required MiCompletionResult result,
    bool offlineMode = false,
    // Previously computed state for this child+skill, so mastery
    // accumulates across completions instead of recomputing from scratch
    // every time. Defaults to a fresh skill (evidenceCount 0) when the
    // caller has none yet -- preserves prior behavior for existing callers.
    MasteryState? previousMastery,
    // The canonical mapping resolved for this exact (gameId, levelId), if
    // any -- see mi_game_content's ActivityMappingResolver. When present,
    // this replaces every heuristic below (subject-from-game-name-prefix,
    // hardcoded 'junior' age group) with real taxonomy/curriculum data.
    CanonicalActivityMapping? mapping,
  }) {
    final skillId = resolvedSkillId(result, mapping: mapping);
    final maxScore = result.maxScore <= 0 ? 1 : result.maxScore;
    final correct = result.score / maxScore >= 0.7;
    final current =
        previousMastery ?? MasteryState(childId: childProfileId, skillId: skillId);
    final mastery = masteryEngine.evaluate(
      currentState: current,
      attempt: AttemptEvidence(
        attemptedAt: result.completedAt,
        correct: correct,
        hintsUsed: result.hintsUsed,
        difficulty: _difficultyFromScore(result.score / maxScore),
        durationSeconds: result.duration.inSeconds,
      ),
    );
    final content = ContentItem(
      id: result.levelId,
      type: ContentType.game,
      subjectCode: mapping?.subjectId ?? _legacySubjectGuess(result.gameId),
      ageGroup: _ageGroupFrom(mapping) ?? 'junior',
      difficulty: mastery.updatedState.currentDifficulty,
      gameId: result.gameId,
      levelIndex: 1,
      skillIds: mapping != null
          ? [mapping.primarySkillId, ...mapping.secondarySkillIds]
          : [skillId],
      estimatedMinutes: result.duration.inMinutes.clamp(1, 15),
      offlineDownloaded: true,
    );
    final recommendation = recommendationEngine.getRecommendations(
      childProfileId: childProfileId,
      masteries: {skillId: mastery.updatedState},
      availableContent: [content],
      remainingMinutes: 15,
      offlineMode: offlineMode,
      maxRecommendations: 3,
    );

    return AdaptiveShadowResult(
      engineVersion: mastery.engineVersion,
      mastery: mastery.updatedState,
      recommendation: recommendation,
      reasonCodes: mastery.reasonCodes,
      usedFallback: recommendation.usedFallback,
    );
  }

  int _difficultyFromScore(double ratio) {
    if (ratio >= 0.9) return 4;
    if (ratio >= 0.7) return 3;
    if (ratio >= 0.4) return 2;
    return 1;
  }

  /// [CanonicalActivityMapping.curriculumNodeId] is `'$ageGroup.$subjectId'`
  /// (see mi_game_content's CurriculumNode) -- subjectId never contains a
  /// dot, so splitting on the first one reliably recovers ageGroup without
  /// needing a separate field on the mapping.
  String? _ageGroupFrom(CanonicalActivityMapping? mapping) {
    final nodeId = mapping?.curriculumNodeId;
    if (nodeId == null) return null;
    return nodeId.split('.').first;
  }

  /// Compatibility fallback only, paired with [skillIdFor] -- used when no
  /// [CanonicalActivityMapping] was resolved. Real subject identity always
  /// comes from the taxonomy (`mapping.subjectId`) when available.
  String _legacySubjectGuess(String gameId) {
    if (gameId.startsWith('math')) return 'math';
    if (gameId == 'robot_commands') return 'logic';
    return 'letters';
  }
}
