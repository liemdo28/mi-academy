part of mi_game_core;

// ─── Game Result ──────────────────────────────────────────────────────────────

/// The canonical result produced by a game at session end.
///
/// Games MUST produce exactly one MiGameResult per session (attemptId is
/// the idempotency key). The platform uses this to update mastery,
/// unlock rewards, and generate parent reports.
///
/// NO PII is included. All fields are child-safe.
class MiGameResult {
  /// Schema version. Currently always 1.
  final int schemaVersion;

  /// Unique attempt ID — UUID v4. Used as idempotency key so the
  /// same result submitted twice is ignored by the platform.
  final String attemptId;

  /// Child profile ID (not parent ID, not user ID).
  final String childProfileId;

  /// Game identifier, e.g. "word_builder".
  final String gameId;

  /// Level identifier, e.g. "level_3".
  final String levelId;

  /// When the game session started.
  final DateTime startedAt;

  /// When the game session ended.
  final DateTime completedAt;

  /// Total number of attempts within this session.
  /// For math_race: number of questions answered.
  final int attemptCount;

  /// Number of correct attempts within this session.
  final int correctCount;

  /// Number of incorrect attempts within this session.
  final int incorrectCount;

  /// Number of hints used during this session.
  final int hintCount;

  /// Session duration in seconds (wall-clock, not play-time only).
  final int durationSeconds;

  /// Whether the game session was fully completed.
  /// If false, the child may have quit early.
  final bool completed;

  /// Game-provided mastery evidence for this session: 0.0 to 1.0.
  /// 0.0 = no mastery. 1.0 = perfect mastery.
  /// Used by the platform to update the child's skill mastery score.
  final double masteryEvidence;

  /// Game-provided skill evidence: which specific skills were practiced.
  /// Example: {"math": ["addition", "subtraction"], "vocabulary": ["vi"]}
  /// The platform parses these keys to update per-skill mastery.
  final Map<String, dynamic> skillEvidence;

  /// Any additional metadata the game wants to record.
  /// Stored but not processed by the platform.
  final Map<String, dynamic> metadata;

  const MiGameResult({
    this.schemaVersion = 1,
    required this.attemptId,
    required this.childProfileId,
    required this.gameId,
    required this.levelId,
    required this.startedAt,
    required this.completedAt,
    required this.attemptCount,
    required this.correctCount,
    required this.incorrectCount,
    this.hintCount = 0,
    required this.durationSeconds,
    this.completed = false,
    this.masteryEvidence = 0.0,
    this.skillEvidence = const {},
    this.metadata = const {},
  });

  /// Derived: correct rate for this session (0.0 to 1.0).
  double get correctRate {
    if (attemptCount == 0) return 0.0;
    return correctCount / attemptCount;
  }

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'attempt_id': attemptId,
        'child_profile_id': childProfileId,
        'game_id': gameId,
        'level_id': levelId,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt.toIso8601String(),
        'attempt_count': attemptCount,
        'correct_count': correctCount,
        'incorrect_count': incorrectCount,
        'hint_count': hintCount,
        'duration_seconds': durationSeconds,
        'completed': completed,
        'mastery_evidence': masteryEvidence,
        'skill_evidence': skillEvidence,
        'metadata': metadata,
      };

  factory MiGameResult.fromJson(Map<String, dynamic> json) {
    return MiGameResult(
      schemaVersion: json['schema_version'] as int? ?? 1,
      attemptId: json['attempt_id'] as String,
      childProfileId: json['child_profile_id'] as String,
      gameId: json['game_id'] as String,
      levelId: json['level_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: DateTime.parse(json['completed_at'] as String),
      attemptCount: json['attempt_count'] as int,
      correctCount: json['correct_count'] as int,
      incorrectCount: json['incorrect_count'] as int,
      hintCount: json['hint_count'] as int? ?? 0,
      durationSeconds: json['duration_seconds'] as int,
      completed: json['completed'] as bool? ?? false,
      masteryEvidence: (json['mastery_evidence'] as num?)?.toDouble() ?? 0.0,
      skillEvidence: json['skill_evidence'] as Map<String, dynamic>? ?? {},
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}
