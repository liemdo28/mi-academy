import 'skill_mastery.dart';

/// Adaptive learning engine.
///
/// Adjusts content difficulty based on child performance.
/// Key principles:
/// - Silent difficulty reduction (child never sees "you went down")
/// - No speed pressure
/// - No streak punishment
/// - Spaced repetition via review scheduling
class AdaptiveEngine {
  /// Adjust difficulty based on recent performance.
  ///
  /// Returns a [DifficultyRecommendation] that the platform uses
  /// to select appropriate content.
  DifficultyRecommendation adjustDifficulty(SkillMastery skill) {
    final attempts = skill.totalAttempts;
    final correctRate = skill.accuracyRate;
    final difficulty = skill.currentDifficulty;

    if (attempts >= 3 && correctRate >= 0.85) {
      // Child is consistently correct — increase difficulty (silent)
      return DifficultyRecommendation(
        suggestedDifficulty: (difficulty + 1).clamp(1, 5),
        reason: 'consistent_success',
        urgent: false,
      );
    }

    if (attempts >= 2 && correctRate <= 0.5) {
      // Child is struggling — decrease difficulty (silent)
      return DifficultyRecommendation(
        suggestedDifficulty: (difficulty - 1).clamp(1, 5),
        reason: 'struggling',
        urgent: false,
      );
    }

    // No change needed
    return DifficultyRecommendation(
      suggestedDifficulty: difficulty,
      reason: 'stable',
      urgent: false,
    );
  }

  /// Recommend the next lesson for a child based on:
  /// - Skills needing practice (low mastery)
  /// - Upcoming reviews (spaced repetition)
  /// - Age-appropriate difficulty
  List<LessonRecommendation> recommendLessons({
    required List<SkillMastery> skills,
    required int maxItems,
  }) {
    final recommendations = <LessonRecommendation>[];

    // Priority 1: Skills needing practice (mastery < 0.5)
    final weakSkills = skills.where((s) => s.masteryScore < 0.5).toList()
      ..sort((a, b) => a.masteryScore.compareTo(b.masteryScore));
    for (final skill in weakSkills.take(2)) {
      recommendations.add(LessonRecommendation(
        lessonId: skill.skillKey,
        reason: LessonRecommendationReason.needsPractice,
        priority: 1,
      ));
    }

    // Priority 2: Spaced repetition due
    final now = DateTime.now();
    final dueForReview = skills.where((s) {
      return s.reviewDueAt != null && s.reviewDueAt!.isBefore(now);
    }).toList();
    for (final skill in dueForReview.take(2)) {
      recommendations.add(LessonRecommendation(
        lessonId: skill.skillKey,
        reason: LessonRecommendationReason.spacedRepetition,
        priority: 2,
      ));
    }

    // Priority 3: New or not started skills
    final newSkills = skills.where((s) => s.totalAttempts == 0).toList();
    for (final skill in newSkills.take(maxItems - recommendations.length)) {
      recommendations.add(LessonRecommendation(
        lessonId: skill.skillKey,
        reason: LessonRecommendationReason.newContent,
        priority: 3,
      ));
    }

    return recommendations.take(maxItems).toList();
  }
}

class DifficultyRecommendation {
  final int suggestedDifficulty;
  final String reason;
  final bool urgent;

  const DifficultyRecommendation({
    required this.suggestedDifficulty,
    required this.reason,
    required this.urgent,
  });
}

enum LessonRecommendationReason {
  needsPractice,
  spacedRepetition,
  newContent,
  masteryComplete,
}

class LessonRecommendation {
  final String lessonId;
  final LessonRecommendationReason reason;
  final int priority;

  const LessonRecommendation({
    required this.lessonId,
    required this.reason,
    required this.priority,
  });
}
