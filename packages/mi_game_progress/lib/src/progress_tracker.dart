import 'attempt_record.dart';
import 'skill_mastery.dart';
import 'mastery_calculator.dart';

/// Tracks attempts and skill mastery for a child across all games.
///
/// Uses Hive for offline persistence; every session is recorded so
/// progress survives app interruption.
class ProgressTracker {
  ProgressTracker({
    required this.childId,
    MasteryCalculator? calculator,
  }) : _calculator = calculator ?? const MasteryCalculator();

  final String childId;
  final MasteryCalculator _calculator;

  final List<AttemptRecord> _attempts = [];
  final Map<String, SkillMastery> _skills = {};

  List<AttemptRecord> get attempts => List.unmodifiable(_attempts);
  Map<String, SkillMastery> get skills => Map.unmodifiable(_skills);

  /// Record a completed level attempt.
  void recordCompletion({
    required String gameId,
    required String levelId,
    required bool correct,
    required Duration duration,
    required List<String> skillIds,
    int hintsUsed = 0,
    int difficulty = 1,
  }) {
    final record = AttemptRecord(
      childId: childId,
      gameId: gameId,
      levelId: levelId,
      correct: correct,
      attemptedAt: DateTime.now(),
      duration: duration,
      hintsUsed: hintsUsed,
    );
    _attempts.add(record);

    for (final skillId in skillIds) {
      _skills.putIfAbsent(
          skillId,
          () => SkillMastery(
                skillId: skillId,
                childId: childId,
              ));
      _skills[skillId]!.recordAttempt(
        correct: correct,
        hintsUsed: hintsUsed,
        difficulty: difficulty,
      );
    }
  }

  /// Get mastery for a specific skill, or 0 if not practiced.
  double getMastery(String skillId) {
    return _skills[skillId]?.mastery ?? 0.0;
  }

  /// Recommend the next difficulty tier for a practiced skill.
  int recommendDifficulty(String skillId) {
    final skill = _skills[skillId];
    if (skill == null) return 1;
    return _calculator.recommendDifficulty(skill);
  }

  /// Get all mastered skills (mastery >= 0.8).
  List<String> get masteredSkills {
    return _skills.entries
        .where((e) => e.value.isMastered)
        .map((e) => e.key)
        .toList();
  }

  /// Get skills that need spaced recall.
  List<String> get skillsNeedingRecall {
    return _skills.entries
        .where((e) => e.value.needsRecall)
        .map((e) => e.key)
        .toList();
  }

  /// Serialize all progress data for persistence.
  Map<String, dynamic> toJson() => {
        'childId': childId,
        'attempts': _attempts.map((a) => a.toJson()).toList(),
        'skills': _skills.map((k, v) => MapEntry(k, v.toJson())),
      };

  /// Restore from persisted data.
  factory ProgressTracker.fromJson(Map<String, dynamic> json) {
    final tracker = ProgressTracker(childId: json['childId'] as String);
    final attempts = (json['attempts'] as List)
        .map((a) => AttemptRecord.fromJson(a as Map<String, dynamic>))
        .toList();
    tracker._attempts.addAll(attempts);
    final skills = (json['skills'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, SkillMastery.fromJson(v as Map<String, dynamic>)),
    );
    tracker._skills.addAll(skills);
    return tracker;
  }
}
