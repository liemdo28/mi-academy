import 'skill_mastery.dart';

/// Calculates mastery score and recommends difficulty.
///
/// Blueprint §3.4: "Không coi một câu đúng là thành thạo."
class MasteryCalculator {
  const MasteryCalculator();

  /// Calculate mastery from a list of attempts for the same skill.
  ///
  /// [attempts] — list of (correct, hintsUsed) tuples
  /// [difficulty] — current level difficulty tier
  double calculate({
    required List<({bool correct, int hintsUsed})> attempts,
    required int difficulty,
  }) {
    if (attempts.isEmpty) return 0.0;

    final correctCount = attempts.where((a) => a.correct).length;
    final accuracy = correctCount / attempts.length;
    final totalHints = attempts.fold<int>(0, (s, a) => s + a.hintsUsed);
    final hintPenalty = totalHints > 0
        ? (totalHints / (attempts.length + 1)).clamp(0.0, 0.5)
        : 0.0;
    final difficultyBonus = (difficulty * 0.05).clamp(0.0, 0.2);

    return (accuracy - hintPenalty + difficultyBonus).clamp(0.0, 1.0);
  }

  /// Recommend next difficulty based on current mastery.
  ///
  /// Returns the recommended difficulty tier (1-5).
  int recommendDifficulty(SkillMastery mastery) {
    if (mastery.mastery < 0.4) return 1;
    if (mastery.mastery < 0.6) return 2;
    if (mastery.mastery < 0.75) return 3;
    if (mastery.mastery < 0.9) return 4;
    return 5;
  }
}
