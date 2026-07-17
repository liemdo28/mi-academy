/// Skill mastery tracking for adaptive learning.
///
/// Each skill has a mastery score (0.0-1.0) computed from game results.
/// Mastery increases with consistent correct answers and decreases
/// with incorrect answers or high hint usage.

/// Per-skill mastery record.
class SkillMastery {
  final String skillKey; // e.g. "math.addition.2digit"
  final double masteryScore; // 0.0 - 1.0
  final int currentDifficulty; // 1-5
  final int correctStreak;
  final int totalAttempts;
  final int totalCorrect;
  final DateTime? lastPlayedAt;
  final DateTime? reviewDueAt;

  const SkillMastery({
    required this.skillKey,
    this.masteryScore = 0.0,
    this.currentDifficulty = 1,
    this.correctStreak = 0,
    this.totalAttempts = 0,
    this.totalCorrect = 0,
    this.lastPlayedAt,
    this.reviewDueAt,
  });

  double get accuracyRate {
    if (totalAttempts == 0) return 0.0;
    return totalCorrect / totalAttempts;
  }

  /// Is this skill considered mastered?
  bool get isMastered => masteryScore >= 0.8;

  /// Is this skill developing (needs more practice)?
  bool get needsPractice => masteryScore < 0.5;

  SkillMastery copyWith({
    double? masteryScore,
    int? currentDifficulty,
    int? correctStreak,
    int? totalAttempts,
    int? totalCorrect,
    DateTime? lastPlayedAt,
    DateTime? reviewDueAt,
  }) {
    return SkillMastery(
      skillKey: skillKey,
      masteryScore: masteryScore ?? this.masteryScore,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      correctStreak: correctStreak ?? this.correctStreak,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      reviewDueAt: reviewDueAt ?? this.reviewDueAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'skill_key': skillKey,
        'mastery_score': masteryScore,
        'current_difficulty': currentDifficulty,
        'correct_streak': correctStreak,
        'total_attempts': totalAttempts,
        'total_correct': totalCorrect,
        'last_played_at': lastPlayedAt?.toIso8601String(),
        'review_due_at': reviewDueAt?.toIso8601String(),
      };

  factory SkillMastery.fromJson(Map<String, dynamic> json) {
    return SkillMastery(
      skillKey: json['skill_key'] as String,
      masteryScore: (json['mastery_score'] as num?)?.toDouble() ?? 0.0,
      currentDifficulty: json['current_difficulty'] as int? ?? 1,
      correctStreak: json['correct_streak'] as int? ?? 0,
      totalAttempts: json['total_attempts'] as int? ?? 0,
      totalCorrect: json['total_correct'] as int? ?? 0,
      lastPlayedAt: json['last_played_at'] != null
          ? DateTime.parse(json['last_played_at'] as String)
          : null,
      reviewDueAt: json['review_due_at'] != null
          ? DateTime.parse(json['review_due_at'] as String)
          : null,
    );
  }
}
