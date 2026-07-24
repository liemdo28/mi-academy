import 'package:json_annotation/json_annotation.dart';

part 'game_result.g.dart';

/// Result of a completed game session.
/// Contract: mi.game.result / v2
@JsonSerializable(explicitToJson: true)
class GameResult {
  final String attemptId;
  final String childProfileId;
  final String gameId;
  final String levelId;
  final DateTime startedAt;
  final DateTime completedAt;
  final int correctCount;
  final int incorrectCount;
  final double? masteryEvidence;
  final List<SkillEvidence> skillEvidence;
  final String? completionStatus;
  final Map<String, dynamic>? metadata;

  const GameResult({
    required this.attemptId,
    required this.childProfileId,
    required this.gameId,
    required this.levelId,
    required this.startedAt,
    required this.completedAt,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.masteryEvidence,
    this.skillEvidence = const [],
    this.completionStatus,
    this.metadata,
  });

  factory GameResult.fromJson(Map<String, dynamic> json) =>
      _$GameResultFromJson(json);

  Map<String, dynamic> toJson() => _$GameResultToJson(this);

  /// Calculated accuracy as ratio of correct to total answers.
  double get accuracy {
    final total = correctCount + incorrectCount;
    return total == 0 ? 0.0 : correctCount / total;
  }

  /// Duration of the game session.
  Duration get duration => completedAt.difference(startedAt);

  /// Validates result against contract rules.
  List<String> validate() {
    final errors = <String>[];
    if (attemptId.isEmpty) errors.add('attemptId is required');
    if (childProfileId.isEmpty) errors.add('childProfileId is required');
    if (masteryEvidence != null &&
        (masteryEvidence! < 0.0 || masteryEvidence! > 1.0)) {
      errors.add('masteryEvidence must be between 0.0 and 1.0');
    }
    if (completedAt.isBefore(startedAt)) {
      errors.add('completedAt must be after startedAt');
    }
    if (completionStatus != null &&
        !['completed', 'abandoned', 'timeout'].contains(completionStatus)) {
      errors.add('completionStatus must be completed, abandoned, or timeout');
    }
    for (var i = 0; i < skillEvidence.length; i++) {
      final se = skillEvidence[i];
      if (se.skillId.isEmpty) {
        errors.add('skillEvidence[$i].skillId is required');
      }
      if (se.masteryLevel < 0.0 || se.masteryLevel > 1.0) {
        errors.add(
          'skillEvidence[$i].masteryLevel must be between 0.0 and 1.0',
        );
      }
    }
    return errors;
  }

  GameResult copyWith({
    String? attemptId,
    String? childProfileId,
    String? gameId,
    String? levelId,
    DateTime? startedAt,
    DateTime? completedAt,
    int? correctCount,
    int? incorrectCount,
    double? masteryEvidence,
    List<SkillEvidence>? skillEvidence,
    String? completionStatus,
    Map<String, dynamic>? metadata,
  }) {
    return GameResult(
      attemptId: attemptId ?? this.attemptId,
      childProfileId: childProfileId ?? this.childProfileId,
      gameId: gameId ?? this.gameId,
      levelId: levelId ?? this.levelId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      masteryEvidence: masteryEvidence ?? this.masteryEvidence,
      skillEvidence: skillEvidence ?? this.skillEvidence,
      completionStatus: completionStatus ?? this.completionStatus,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Evidence of skill mastery from a game session.
@JsonSerializable(explicitToJson: true)
class SkillEvidence {
  final String skillId;
  final double masteryLevel;
  final int attempts;
  final String? category;

  const SkillEvidence({
    required this.skillId,
    required this.masteryLevel,
    this.attempts = 1,
    this.category,
  });

  factory SkillEvidence.fromJson(Map<String, dynamic> json) =>
      _$SkillEvidenceFromJson(json);

  Map<String, dynamic> toJson() => _$SkillEvidenceToJson(this);
}
