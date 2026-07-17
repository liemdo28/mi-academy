import 'package:mastery_core/mastery_core.dart';
import 'spaced_repetition_config.dart';

/// Spaced repetition scheduler.
///
/// Per blueprint §10:
/// - Intervals based on mastery status
/// - When child forgets (score drops): shorten interval, reduce difficulty
/// - When child retains: extend interval
/// - Never display "you forgot" — neutral language
/// - Configurable intervals
class SpacedRepetitionScheduler {
  const SpacedRepetitionScheduler({
    this.config = SpacedRepetitionConfig.defaultConfig,
  });

  final SpacedRepetitionConfig config;

  /// Compute the next review date for a skill.
  DateTime computeNextReview(MasteryState mastery) {
    final interval = config.intervals.getInterval(mastery.status.value);
    final adjustedInterval = _adjustForRetention(
      baseInterval: interval,
      mastery: mastery,
    );
    return mastery.lastPracticedAt != null
        ? mastery.lastPracticedAt!.add(Duration(days: adjustedInterval))
        : DateTime.now().add(Duration(days: interval));
  }

  /// Adjust interval based on retention evidence.
  int _adjustForRetention({
    required int baseInterval,
    required MasteryState mastery,
  }) {
    // If child retained (did not forget significantly):
    // slightly increase interval
    if (mastery.masteryScore >= 0.7) {
      return (baseInterval * (1 + config.retentionBonus)).round();
    }
    // If struggling, reduce interval
    if (mastery.masteryScore < 0.4) {
      return (baseInterval * 0.5).round().clamp(1, baseInterval);
    }
    return baseInterval;
  }

  /// Check if a skill is due for review.
  bool isDue(MasteryState mastery) {
    if (mastery.nextReviewAt == null) return true;
    return DateTime.now().isAfter(mastery.nextReviewAt!);
  }

  /// Get all skills due for review.
  List<MasteryState> getDueSkills(List<MasteryState> allSkills) {
    return allSkills.where((m) => isDue(m) && m.evidenceCount > 0).toList();
  }

  /// Compute difficulty adjustment after a review.
  ///
  /// Per blueprint §11: reduce difficulty slightly if child forgot.
  /// Never show "you forgot" message to child.
  DifficultyAdjustment computeDifficultyAdjustment(MasteryState mastery) {
    if (mastery.nextReviewAt == null) {
      return const DifficultyAdjustment(
        changeDirection: DifficultyChangeDirection.none,
        newDifficulty: 1,
        reason: 'FIRST_REVIEW',
      );
    }

    final daysOverdue = DateTime.now().difference(mastery.nextReviewAt!).inDays;
    if (daysOverdue > config.forgettingCurveDays) {
      // Significant gap — likely forgot; reduce difficulty
      return DifficultyAdjustment(
        changeDirection: DifficultyChangeDirection.decrease,
        newDifficulty: (mastery.currentDifficulty - 1).clamp(1, 5),
        reason: 'RETENTION_GAP',
      );
    }

    if (mastery.masteryScore < 0.5) {
      return DifficultyAdjustment(
        changeDirection: DifficultyChangeDirection.decrease,
        newDifficulty: (mastery.currentDifficulty - 1).clamp(1, 5),
        reason: 'LOW_RETENTION',
      );
    }

    return DifficultyAdjustment(
      changeDirection: DifficultyChangeDirection.none,
      newDifficulty: mastery.currentDifficulty,
      reason: 'STABLE',
    );
  }

  /// Get recommended practice hint for parent.
  ///
  /// Per blueprint §12: Use neutral, helpful language.
  String getParentHint(MasteryState mastery, String language) {
    if (mastery.hintsPerAttempt > 1.5) {
      return language == 'vi'
          ? 'Trẻ sử dụng nhiều gợi ý ở kỹ năng này. Thử hoạt động trực quan hơn.'
          : 'The learner used many hints on this skill. Try a more visual activity.';
    }
    if (mastery.daysSinceLastPractice > 14) {
      return language == 'vi'
          ? 'Đã lâu không luyện kỹ năng này. Thử ôn lại.'
          : 'It has been a while since practicing this skill. Time for a review.';
    }
    if (mastery.confidence < 0.4) {
      return language == 'vi'
          ? 'Có thể cần luyện thêm kỹ năng này.'
          : 'This skill may benefit from more practice.';
    }
    return language == 'vi'
        ? 'Tiếp tục với kỹ năng này.'
        : 'Continue with this skill.';
  }
}

class DifficultyAdjustment {
  const DifficultyAdjustment({
    required this.changeDirection,
    required this.newDifficulty,
    required this.reason,
  });

  final DifficultyChangeDirection changeDirection;
  final int newDifficulty;
  final String reason;
}

enum DifficultyChangeDirection { increase, decrease, none }
