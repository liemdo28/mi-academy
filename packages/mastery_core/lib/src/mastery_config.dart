import 'package:equatable/equatable.dart';

/// Configuration for the mastery calculation engine.
///
/// All weights are externally configurable so rules can be tuned
/// without code changes. Loaded from JSON configuration.
class MasteryConfig extends Equatable {
  const MasteryConfig({
    this.weights = const MasteryWeights(),
    this.maxSingleAttemptIncrease = 0.08,
    this.maxSingleAttemptDecrease = 0.04,
    this.masteryThreshold = 0.80,
    this.proficientThreshold = 0.65,
    this.introducedThreshold = 0.15,
    this.minEvidenceForConfidence = 3,
    this.maxHintPenaltyRatio = 0.30,
    this.difficultyBonusMax = 0.15,
    this.retentionPenaltyDays = 7,
  });

  /// Component weights for mastery score calculation.
  final MasteryWeights weights;

  /// Maximum increase in mastery score from a single attempt.
  final double maxSingleAttemptIncrease;

  /// Maximum decrease in mastery score from a single attempt.
  final double maxSingleAttemptDecrease;

  /// Threshold above which a skill is considered "mastered".
  final double masteryThreshold;

  /// Threshold above which a skill is considered "proficient".
  final double proficientThreshold;

  /// Threshold above which a skill moves from "introduced" to "developing".
  final double introducedThreshold;

  /// Minimum independent evidence count needed before confidence > 0.3.
  final int minEvidenceForConfidence;

  /// Maximum hint penalty as a ratio of score (0.30 = 30% penalty max).
  final double maxHintPenaltyRatio;

  /// Maximum difficulty bonus as an absolute score value.
  final double difficultyBonusMax;

  /// After this many days without practice, retention penalty applies.
  final int retentionPenaltyDays;

  @override
  List<Object?> get props => [
        weights,
        maxSingleAttemptIncrease,
        maxSingleAttemptDecrease,
        masteryThreshold,
        proficientThreshold,
        introducedThreshold,
        minEvidenceForConfidence,
        maxHintPenaltyRatio,
        difficultyBonusMax,
        retentionPenaltyDays,
      ];

  /// Default configuration for MVP.
  static const MasteryConfig defaultConfig = MasteryConfig();

  Map<String, dynamic> toJson() => {
        'weights': weights.toJson(),
        'maxSingleAttemptIncrease': maxSingleAttemptIncrease,
        'maxSingleAttemptDecrease': maxSingleAttemptDecrease,
        'masteryThreshold': masteryThreshold,
        'proficientThreshold': proficientThreshold,
        'introducedThreshold': introducedThreshold,
        'minEvidenceForConfidence': minEvidenceForConfidence,
        'maxHintPenaltyRatio': maxHintPenaltyRatio,
        'difficultyBonusMax': difficultyBonusMax,
        'retentionPenaltyDays': retentionPenaltyDays,
      };

  factory MasteryConfig.fromJson(Map<String, dynamic> json) {
    final weightsJson = json['weights'] as Map<String, dynamic>?;
    return MasteryConfig(
      weights: weightsJson != null
          ? MasteryWeights.fromJson(weightsJson)
          : const MasteryWeights(),
      maxSingleAttemptIncrease:
          (json['maxSingleAttemptIncrease'] as num?)?.toDouble() ?? 0.08,
      maxSingleAttemptDecrease:
          (json['maxSingleAttemptDecrease'] as num?)?.toDouble() ?? 0.04,
      masteryThreshold: (json['masteryThreshold'] as num?)?.toDouble() ?? 0.80,
      proficientThreshold:
          (json['proficientThreshold'] as num?)?.toDouble() ?? 0.65,
      introducedThreshold:
          (json['introducedThreshold'] as num?)?.toDouble() ?? 0.15,
      minEvidenceForConfidence: json['minEvidenceForConfidence'] as int? ?? 3,
      maxHintPenaltyRatio:
          (json['maxHintPenaltyRatio'] as num?)?.toDouble() ?? 0.30,
      difficultyBonusMax:
          (json['difficultyBonusMax'] as num?)?.toDouble() ?? 0.15,
      retentionPenaltyDays: json['retentionPenaltyDays'] as int? ?? 7,
    );
  }
}

/// Weights for each component of the mastery score.
class MasteryWeights extends Equatable {
  const MasteryWeights({
    this.accuracy = 0.35,
    this.independence = 0.20,
    this.difficulty = 0.15,
    this.retention = 0.20,
    this.consistency = 0.10,
  });

  /// Weight for raw accuracy (correct / total attempts).
  final double accuracy;

  /// Weight for independence (correct without hints / correct total).
  final double independence;

  /// Weight for difficulty of content mastered.
  final double difficulty;

  /// Weight for retention (spacing between sessions).
  final double retention;

  /// Weight for consistency (streak and variance).
  final double consistency;

  /// Sum of all weights; should equal 1.0.
  double get total =>
      accuracy + independence + difficulty + retention + consistency;

  @override
  List<Object?> get props =>
      [accuracy, independence, difficulty, retention, consistency];

  Map<String, dynamic> toJson() => {
        'accuracy': accuracy,
        'independence': independence,
        'difficulty': difficulty,
        'retention': retention,
        'consistency': consistency,
      };

  factory MasteryWeights.fromJson(Map<String, dynamic> json) {
    return MasteryWeights(
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.35,
      independence: (json['independence'] as num?)?.toDouble() ?? 0.20,
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0.15,
      retention: (json['retention'] as num?)?.toDouble() ?? 0.20,
      consistency: (json['consistency'] as num?)?.toDouble() ?? 0.10,
    );
  }
}
