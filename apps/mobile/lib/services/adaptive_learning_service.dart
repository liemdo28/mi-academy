import 'package:mastery_core/mastery_core.dart';
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

  AdaptiveShadowResult evaluateCompletion({
    required String childProfileId,
    required MiCompletionResult result,
    bool offlineMode = false,
  }) {
    final skillId = result.newSkillsAcquired.isNotEmpty
        ? result.newSkillsAcquired.first
        : '${result.gameId}.${result.levelId}';
    final maxScore = result.maxScore <= 0 ? 1 : result.maxScore;
    final correct = result.score / maxScore >= 0.7;
    final current = MasteryState(childId: childProfileId, skillId: skillId);
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
      subjectCode: _subjectForGame(result.gameId),
      ageGroup: 'junior',
      difficulty: mastery.updatedState.currentDifficulty,
      gameId: result.gameId,
      levelIndex: 1,
      skillIds: [skillId],
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

  String _subjectForGame(String gameId) {
    if (gameId.startsWith('math')) return 'math';
    if (gameId == 'robot_commands') return 'logic';
    return 'language';
  }
}
