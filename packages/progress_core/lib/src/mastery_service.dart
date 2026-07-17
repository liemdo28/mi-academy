import 'skill_mastery.dart';

/// Service for computing mastery scores from game results.
///
/// Uses a weighted average of:
/// - Session accuracy (60% weight)
/// - Session completion (20% weight)
/// - Hint efficiency (20% weight)
///
/// Hint penalty: hints reduce the mastery evidence but do not
/// cause a fail state for the child.
class MasteryService {
  /// Compute the updated mastery score given the current score and a game result.
  ///
  /// [currentScore] — existing mastery score (0.0-1.0)
  /// [masteryEvidence] — game's mastery evidence for this session (0.0-1.0)
  /// [hintCount] — number of hints used in this session
  /// [totalQuestions] — total questions in the session
  double computeUpdatedScore({
    required double currentScore,
    required double masteryEvidence,
    required int hintCount,
    required int totalQuestions,
  }) {
    if (totalQuestions == 0) return currentScore;

    // Hint penalty: reduce evidence by up to 20% if many hints used
    final hintRatio = hintCount / totalQuestions;
    final hintPenalty = hintRatio * 0.2;
    final adjustedEvidence = (masteryEvidence - hintPenalty).clamp(0.0, 1.0);

    // Weighted update: new evidence contributes 40%, current score 60%
    final newScore = currentScore * 0.6 + adjustedEvidence * 0.4;
    return newScore.clamp(0.0, 1.0);
  }

  /// Derive difficulty level from mastery score.
  /// Returns 1-5 where 1=easiest, 5=hardest.
  int difficultyFromMastery(double masteryScore) {
    if (masteryScore >= 0.9) return 5;
    if (masteryScore >= 0.7) return 4;
    if (masteryScore >= 0.5) return 3;
    if (masteryScore >= 0.3) return 2;
    return 1;
  }

  /// Update a skill mastery record with new session data.
  SkillMastery updateSkillMastery(
    SkillMastery current,
    double masteryEvidence,
    int hintCount,
    int totalQuestions,
    bool wasCorrect,
  ) {
    final newScore = computeUpdatedScore(
      currentScore: current.masteryScore,
      masteryEvidence: masteryEvidence,
      hintCount: hintCount,
      totalQuestions: totalQuestions,
    );

    final now = DateTime.now();
    return current.copyWith(
      masteryScore: newScore,
      totalAttempts: current.totalAttempts + 1,
      totalCorrect: wasCorrect ? current.totalCorrect + 1 : current.totalCorrect,
      correctStreak: wasCorrect ? current.correctStreak + 1 : 0,
      lastPlayedAt: now,
      reviewDueAt: _computeReviewDue(newScore),
    );
  }

  /// Compute when the next review should happen (spaced repetition).
  /// Higher mastery = longer interval.
  DateTime _computeReviewDue(double masteryScore) {
    final daysUntilReview = (masteryScore * 7).round().clamp(1, 7);
    return DateTime.now().add(Duration(days: daysUntilReview));
  }

  /// Check if a reward should be unlocked based on mastery milestones.
  RewardCheck checkRewardEligibility({
    required double masteryScore,
    required int lessonsCompleted,
    required int gamesCompleted,
    required List<String> existingRewardIds,
  }) {
    final newRewards = <String>[];

    if (lessonsCompleted >= 1 && !existingRewardIds.contains('badge_first_lesson')) {
      newRewards.add('badge_first_lesson');
    }
    if (lessonsCompleted >= 5 && !existingRewardIds.contains('badge_diligent')) {
      newRewards.add('badge_diligent');
    }
    if (lessonsCompleted >= 10 && !existingRewardIds.contains('badge_scholar')) {
      newRewards.add('badge_scholar');
    }
    if (masteryScore >= 0.8 && !existingRewardIds.contains('badge_master')) {
      newRewards.add('badge_master');
    }

    return RewardCheck(
      newlyUnlocked: newRewards,
      starAwarded: lessonsCompleted > 0 ? 1 : 0,
    );
  }
}

class RewardCheck {
  final List<String> newlyUnlocked;
  final int starAwarded;

  const RewardCheck({
    required this.newlyUnlocked,
    required this.starAwarded,
  });
}
