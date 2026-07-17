import 'package:equatable/equatable.dart';

/// Result when a level/game is completed.
///
/// Contains all metrics needed for progress tracking,
/// mastery calculation, and reward triggering.
class MiCompletionResult extends Equatable {
  const MiCompletionResult({
    required this.gameId,
    required this.levelId,
    required this.childProfileId,
    required this.completedAt,
    this.score = 0,
    this.maxScore = 0,
    this.attemptsUsed = 1,
    this.hintsUsed = 0,
    this.duration = Duration.zero,
    this.perfectRun = false,
    this.newSkillsAcquired = const [],
    this.metadata = const {},
  });

  final String gameId;
  final String levelId;
  final String childProfileId;

  /// Score achieved.
  final int score;

  /// Maximum possible score.
  final int maxScore;

  /// Total attempts used (including retries).
  final int attemptsUsed;

  /// Hints used during this playthrough.
  final int hintsUsed;

  /// Time spent on the level.
  final Duration duration;

  /// Whether the child completed the level without any incorrect attempts.
  final bool perfectRun;

  /// When the level was completed.
  final DateTime completedAt;

  /// New skills/concepts demonstrated.
  final List<String> newSkillsAcquired;

  /// Additional game-specific completion data.
  final Map<String, dynamic> metadata;

  /// Accuracy ratio (0.0 to 1.0).
  double get accuracy => maxScore > 0 ? score / maxScore : 0.0;

  @override
  List<Object?> get props => [
        gameId,
        levelId,
        childProfileId,
        score,
        maxScore,
        attemptsUsed,
        hintsUsed,
        duration,
        perfectRun,
        completedAt,
        newSkillsAcquired,
        metadata,
      ];
}
