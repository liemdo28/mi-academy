import 'package:equatable/equatable.dart';
import 'mastery_status.dart';

/// Skill mastery state for a single child-skill pair.
///
/// Per blueprint §6: this is the core mastery state that tracks
/// multiple evidence dimensions. It is NOT a label for the child.
class MasteryState extends Equatable {
  const MasteryState({
    required this.childId,
    required this.skillId,
    this.masteryScore = 0.0,
    this.confidence = 0.0,
    this.evidenceCount = 0,
    this.status = MasteryStatus.notStarted,
    this.lastPracticedAt,
    this.nextReviewAt,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.independentCorrectCount = 0,
    this.totalHintsUsed = 0,
    this.currentDifficulty = 1,
    this.lastPracticedDifficulty = 1,
    this.modelVersion = 'mastery-rule-v1',
    this.attemptHistory = const [],
  });

  /// Child identifier (internal pseudonym, not PII).
  final String childId;

  /// Skill identifier from skill taxonomy.
  final String skillId;

  /// Mastery score 0.0-1.0.
  final double masteryScore;

  /// Confidence in the mastery estimate 0.0-1.0.
  /// Low confidence means few or conflicting evidence.
  final double confidence;

  /// Number of independent attempts (excluding repeats of same question).
  final int evidenceCount;

  /// Current mastery status.
  final MasteryStatus status;

  /// When the skill was last practiced.
  final DateTime? lastPracticedAt;

  /// When the next spaced repetition review is due.
  final DateTime? nextReviewAt;

  /// Total correct answers across all attempts.
  final int correctCount;

  /// Total incorrect answers across all attempts.
  final int incorrectCount;

  /// Correct answers without using hints.
  final int independentCorrectCount;

  /// Total hints used across all attempts.
  final int totalHintsUsed;

  /// Current difficulty level (1-5) recommended for this skill.
  final int currentDifficulty;

  /// Difficulty level of the most recent attempt.
  final int lastPracticedDifficulty;

  /// Version of the mastery rule that produced this state.
  final String modelVersion;

  /// History of attempt evidence (most recent first, max 20 entries).
  final List<AttemptEvidence> attemptHistory;

  /// Accuracy rate (0.0-1.0).
  double get accuracyRate {
    final total = correctCount + incorrectCount;
    if (total == 0) return 0.0;
    return correctCount / total;
  }

  /// Independence rate: fraction of correct answers without hints.
  double get independenceRate {
    if (correctCount == 0) return 0.0;
    return independentCorrectCount / correctCount;
  }

  /// Average hints per attempt (0.0+).
  double get hintsPerAttempt {
    if (evidenceCount == 0) return 0.0;
    return totalHintsUsed / evidenceCount;
  }

  /// Days since last practice.
  int get daysSinceLastPractice {
    if (lastPracticedAt == null) return 999;
    return DateTime.now().difference(lastPracticedAt!).inDays;
  }

  MasteryState copyWith({
    String? childId,
    String? skillId,
    double? masteryScore,
    double? confidence,
    int? evidenceCount,
    MasteryStatus? status,
    DateTime? lastPracticedAt,
    DateTime? nextReviewAt,
    int? correctCount,
    int? incorrectCount,
    int? independentCorrectCount,
    int? totalHintsUsed,
    int? currentDifficulty,
    int? lastPracticedDifficulty,
    String? modelVersion,
    List<AttemptEvidence>? attemptHistory,
  }) {
    return MasteryState(
      childId: childId ?? this.childId,
      skillId: skillId ?? this.skillId,
      masteryScore: masteryScore ?? this.masteryScore,
      confidence: confidence ?? this.confidence,
      evidenceCount: evidenceCount ?? this.evidenceCount,
      status: status ?? this.status,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      independentCorrectCount:
          independentCorrectCount ?? this.independentCorrectCount,
      totalHintsUsed: totalHintsUsed ?? this.totalHintsUsed,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      lastPracticedDifficulty:
          lastPracticedDifficulty ?? this.lastPracticedDifficulty,
      modelVersion: modelVersion ?? this.modelVersion,
      attemptHistory: attemptHistory ?? this.attemptHistory,
    );
  }

  Map<String, dynamic> toJson() => {
        'childId': childId,
        'skillId': skillId,
        'masteryScore': masteryScore,
        'confidence': confidence,
        'evidenceCount': evidenceCount,
        'status': status.value,
        'lastPracticedAt': lastPracticedAt?.toIso8601String(),
        'nextReviewAt': nextReviewAt?.toIso8601String(),
        'correctCount': correctCount,
        'incorrectCount': incorrectCount,
        'independentCorrectCount': independentCorrectCount,
        'totalHintsUsed': totalHintsUsed,
        'currentDifficulty': currentDifficulty,
        'lastPracticedDifficulty': lastPracticedDifficulty,
        'modelVersion': modelVersion,
        'attemptHistory': attemptHistory.map((e) => e.toJson()).toList(),
      };

  factory MasteryState.fromJson(Map<String, dynamic> json) {
    final historyList = (json['attemptHistory'] as List?)
        ?.map((e) => AttemptEvidence.fromJson(e as Map<String, dynamic>))
        .toList();
    return MasteryState(
      childId: json['childId'] as String,
      skillId: json['skillId'] as String,
      masteryScore: (json['masteryScore'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      evidenceCount: json['evidenceCount'] as int? ?? 0,
      status: MasteryStatusExtension.fromString(
          json['status'] as String? ?? 'not_started'),
      lastPracticedAt: json['lastPracticedAt'] != null
          ? DateTime.parse(json['lastPracticedAt'] as String)
          : null,
      nextReviewAt: json['nextReviewAt'] != null
          ? DateTime.parse(json['nextReviewAt'] as String)
          : null,
      correctCount: json['correctCount'] as int? ?? 0,
      incorrectCount: json['incorrectCount'] as int? ?? 0,
      independentCorrectCount: json['independentCorrectCount'] as int? ?? 0,
      totalHintsUsed: json['totalHintsUsed'] as int? ?? 0,
      currentDifficulty: json['currentDifficulty'] as int? ?? 1,
      lastPracticedDifficulty:
          json['lastPracticedDifficulty'] as int? ?? 1,
      modelVersion: json['modelVersion'] as String? ?? 'mastery-rule-v1',
      attemptHistory: historyList ?? const [],
    );
  }

  @override
  List<Object?> get props => [
        childId,
        skillId,
        masteryScore,
        confidence,
        evidenceCount,
        status,
        lastPracticedAt,
        nextReviewAt,
        correctCount,
        incorrectCount,
        independentCorrectCount,
        totalHintsUsed,
        currentDifficulty,
        lastPracticedDifficulty,
        modelVersion,
      ];
}

/// Evidence from a single attempt.
class AttemptEvidence extends Equatable {
  const AttemptEvidence({
    required this.attemptedAt,
    required this.correct,
    required this.hintsUsed,
    required this.difficulty,
    this.durationSeconds,
    this.accessibilityMode = false,
  });

  final DateTime attemptedAt;
  final bool correct;
  final int hintsUsed;
  final int difficulty;
  final int? durationSeconds;
  final bool accessibilityMode;

  Map<String, dynamic> toJson() => {
        'attemptedAt': attemptedAt.toIso8601String(),
        'correct': correct,
        'hintsUsed': hintsUsed,
        'difficulty': difficulty,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        'accessibilityMode': accessibilityMode,
      };

  factory AttemptEvidence.fromJson(Map<String, dynamic> json) {
    return AttemptEvidence(
      attemptedAt: DateTime.parse(json['attemptedAt'] as String),
      correct: json['correct'] as bool,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      difficulty: json['difficulty'] as int? ?? 1,
      durationSeconds: json['durationSeconds'] as int?,
      accessibilityMode: json['accessibilityMode'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [attemptedAt, correct, hintsUsed, difficulty, durationSeconds];
}
