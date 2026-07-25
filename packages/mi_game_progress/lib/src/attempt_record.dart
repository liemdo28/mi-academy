import 'package:equatable/equatable.dart';

enum AttemptAssessmentType {
  graded,
  participation,
}

enum AttemptCompletionModel {
  correctness,
  participation,
}

/// A single attempt at a level.
class AttemptRecord extends Equatable {
  const AttemptRecord({
    required this.childId,
    required this.gameId,
    required this.levelId,
    required this.correct,
    required this.attemptedAt,
    required this.duration,
    this.assessmentType = AttemptAssessmentType.graded,
    this.completionModel = AttemptCompletionModel.correctness,
    this.completed = true,
    this.hintsUsed = 0,
  }) : assert(
          assessmentType == AttemptAssessmentType.graded || correct == null,
        );

  final String childId;
  final String gameId;
  final String levelId;
  final bool? correct;
  final DateTime attemptedAt;
  final Duration duration;
  final AttemptAssessmentType assessmentType;
  final AttemptCompletionModel completionModel;
  final bool completed;
  final int hintsUsed;

  bool get isGraded => assessmentType == AttemptAssessmentType.graded;
  bool get isParticipation =>
      assessmentType == AttemptAssessmentType.participation;
  bool get isCorrect => isGraded && correct == true;
  bool get isIncorrect => isGraded && correct == false;

  Map<String, dynamic> toJson() => {
        'childId': childId,
        'gameId': gameId,
        'levelId': levelId,
        'correct': correct,
        'assessmentType': assessmentType.name,
        'completionModel': completionModel.name,
        'completed': completed,
        'attemptedAt': attemptedAt.toIso8601String(),
        'durationMs': duration.inMilliseconds,
        'hintsUsed': hintsUsed,
      };

  factory AttemptRecord.fromJson(Map<String, dynamic> json) {
    final assessmentType = _assessmentTypeFromJson(json['assessmentType']);
    final completionModel = _completionModelFromJson(json['completionModel']);
    final rawCorrect = json['correct'];
    return AttemptRecord(
      childId: json['childId'] as String,
      gameId: json['gameId'] as String,
      levelId: json['levelId'] as String,
      correct: assessmentType == AttemptAssessmentType.participation
          ? null
          : rawCorrect as bool? ?? false,
      attemptedAt: DateTime.parse(json['attemptedAt'] as String),
      duration: Duration(milliseconds: json['durationMs'] as int),
      assessmentType: assessmentType,
      completionModel: completionModel,
      completed: json['completed'] as bool? ?? true,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        childId,
        gameId,
        levelId,
        correct,
        attemptedAt,
        duration,
        assessmentType,
        completionModel,
        completed,
        hintsUsed,
      ];

  static AttemptAssessmentType _assessmentTypeFromJson(Object? value) {
    return AttemptAssessmentType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => AttemptAssessmentType.graded,
    );
  }

  static AttemptCompletionModel _completionModelFromJson(Object? value) {
    return AttemptCompletionModel.values.firstWhere(
      (model) => model.name == value,
      orElse: () => AttemptCompletionModel.correctness,
    );
  }
}
