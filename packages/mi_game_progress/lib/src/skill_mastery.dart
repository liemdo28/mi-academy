import 'package:equatable/equatable.dart';

/// Tracks mastery of a specific skill across multiple attempts and days.
///
/// Per blueprint §3.4, mastery requires more than "got one right":
/// accuracy, attempts, hints, spacing between sessions,
/// ability to answer again after a few days, and difficulty of content.
// ignore: must_be_immutable
class SkillMastery extends Equatable {
  SkillMastery({
    required this.skillId,
    required this.childId,
    double mastery = 0.0,
    int totalAttempts = 0,
    int correctAttempts = 0,
    int totalHintsUsed = 0,
    DateTime? lastAttemptedAt,
    DateTime? lastSpacedRecallAt,
  })  : _mastery = mastery,
        _totalAttempts = totalAttempts,
        _correctAttempts = correctAttempts,
        _totalHintsUsed = totalHintsUsed,
        _lastAttemptedAt = lastAttemptedAt,
        _lastSpacedRecallAt = lastSpacedRecallAt;

  final String skillId;
  final String childId;
  double _mastery;
  int _totalAttempts;
  int _correctAttempts;
  int _totalHintsUsed;
  DateTime? _lastAttemptedAt;
  DateTime? _lastSpacedRecallAt;

  double get mastery => _mastery;
  int get totalAttempts => _totalAttempts;
  int get correctAttempts => _correctAttempts;
  int get totalHintsUsed => _totalHintsUsed;
  DateTime? get lastAttemptedAt => _lastAttemptedAt;
  DateTime? get lastSpacedRecallAt => _lastSpacedRecallAt;

  /// Whether mastery is high enough to consider the skill learned (>= 0.8).
  bool get isMastered => _mastery >= 0.8;

  /// Whether spaced recall is due (> 2 days since last recall).
  bool get needsRecall {
    if (_lastSpacedRecallAt == null) return false;
    return DateTime.now().difference(_lastSpacedRecallAt!).inDays > 2;
  }

  /// Record a new attempt and update mastery.
  void recordAttempt({
    required bool correct,
    required int hintsUsed,
    required int difficulty,
  }) {
    _totalAttempts++;
    if (correct) _correctAttempts++;
    _totalHintsUsed += hintsUsed;
    _lastAttemptedAt = DateTime.now();
    if (correct && hintsUsed == 0) {
      _lastSpacedRecallAt = DateTime.now();
    }
    _recalculateMastery(difficulty: difficulty);
  }

  void _recalculateMastery({required int difficulty}) {
    if (_totalAttempts == 0) {
      _mastery = 0.0;
      return;
    }
    final accuracy = _correctAttempts / _totalAttempts;
    final hintPenalty = _totalHintsUsed > 0
        ? (_totalHintsUsed / (_totalAttempts + 1)).clamp(0.0, 0.5)
        : 0.0;
    final difficultyBonus = (difficulty * 0.05).clamp(0.0, 0.2);
    final spacingBonus = needsRecall ? -0.1 : 0.0;

    _mastery =
        (accuracy - hintPenalty + difficultyBonus + spacingBonus).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'skillId': skillId,
        'childId': childId,
        'mastery': _mastery,
        'totalAttempts': _totalAttempts,
        'correctAttempts': _correctAttempts,
        'totalHintsUsed': _totalHintsUsed,
        'lastAttemptedAt': _lastAttemptedAt?.toIso8601String(),
        'lastSpacedRecallAt': _lastSpacedRecallAt?.toIso8601String(),
      };

  factory SkillMastery.fromJson(Map<String, dynamic> json) {
    return SkillMastery(
      skillId: json['skillId'] as String,
      childId: json['childId'] as String,
      mastery: (json['mastery'] as num).toDouble(),
      totalAttempts: json['totalAttempts'] as int,
      correctAttempts: json['correctAttempts'] as int,
      totalHintsUsed: json['totalHintsUsed'] as int,
      lastAttemptedAt: json['lastAttemptedAt'] != null
          ? DateTime.parse(json['lastAttemptedAt'] as String)
          : null,
      lastSpacedRecallAt: json['lastSpacedRecallAt'] != null
          ? DateTime.parse(json['lastSpacedRecallAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        skillId,
        childId,
        _mastery,
        _totalAttempts,
        _correctAttempts,
        _totalHintsUsed,
        _lastAttemptedAt,
        _lastSpacedRecallAt,
      ];
}
