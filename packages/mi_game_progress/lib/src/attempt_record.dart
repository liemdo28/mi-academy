import 'package:equatable/equatable.dart';

/// A single attempt at a level.
class AttemptRecord extends Equatable {
  const AttemptRecord({
    required this.childId,
    required this.gameId,
    required this.levelId,
    required this.correct,
    required this.attemptedAt,
    required this.duration,
    this.hintsUsed = 0,
  });

  final String childId;
  final String gameId;
  final String levelId;
  final bool correct;
  final DateTime attemptedAt;
  final Duration duration;
  final int hintsUsed;

  Map<String, dynamic> toJson() => {
        'childId': childId,
        'gameId': gameId,
        'levelId': levelId,
        'correct': correct,
        'attemptedAt': attemptedAt.toIso8601String(),
        'durationMs': duration.inMilliseconds,
        'hintsUsed': hintsUsed,
      };

  factory AttemptRecord.fromJson(Map<String, dynamic> json) {
    return AttemptRecord(
      childId: json['childId'] as String,
      gameId: json['gameId'] as String,
      levelId: json['levelId'] as String,
      correct: json['correct'] as bool,
      attemptedAt: DateTime.parse(json['attemptedAt'] as String),
      duration: Duration(milliseconds: json['durationMs'] as int),
      hintsUsed: json['hintsUsed'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [childId, gameId, levelId, correct, attemptedAt, duration, hintsUsed];
}
