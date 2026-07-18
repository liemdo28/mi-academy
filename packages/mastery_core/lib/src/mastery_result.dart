import 'package:equatable/equatable.dart';
import 'mastery_state.dart';

/// Result of a mastery evaluation.
///
/// Every mastery evaluation MUST return this with complete reason evidence.
class MasteryResult extends Equatable {
  const MasteryResult({
    required this.updatedState,
    required this.scoreComponents,
    required this.confidenceComponents,
    required this.reasonCodes,
    required this.engineVersion,
    this.delta = 0.0,
    this.warningCodes = const [],
  });

  /// The updated mastery state.
  final MasteryState updatedState;

  /// Breakdown of the score into components.
  final ScoreComponents scoreComponents;

  /// Breakdown of the confidence into components.
  final ConfidenceComponents confidenceComponents;

  /// Reason codes explaining what drove the mastery update.
  /// Always non-empty. Used for audit and explanation.
  final List<String> reasonCodes;

  /// Version of the engine used.
  final String engineVersion;

  /// Change in mastery score from previous state.
  final double delta;

  /// Warning codes (non-blocking issues).
  final List<String> warningCodes;

  @override
  List<Object?> get props => [
        updatedState,
        scoreComponents,
        confidenceComponents,
        reasonCodes,
        engineVersion,
        delta,
        warningCodes,
      ];

  Map<String, dynamic> toJson() => {
        'updatedState': updatedState.toJson(),
        'scoreComponents': scoreComponents.toJson(),
        'confidenceComponents': confidenceComponents.toJson(),
        'reasonCodes': reasonCodes,
        'engineVersion': engineVersion,
        'delta': delta,
        'warningCodes': warningCodes,
      };
}

/// Breakdown of the mastery score into components.
class ScoreComponents extends Equatable {
  const ScoreComponents({
    required this.accuracy,
    required this.independence,
    required this.difficulty,
    required this.retention,
    required this.consistency,
    required this.hintPenalty,
    required this.retentionPenalty,
    required this.rawTotal,
    required this.clampedTotal,
  });

  final double accuracy;
  final double independence;
  final double difficulty;
  final double retention;
  final double consistency;
  final double hintPenalty;
  final double retentionPenalty;
  final double rawTotal;
  final double clampedTotal;

  @override
  List<Object?> get props => [
        accuracy,
        independence,
        difficulty,
        retention,
        consistency,
        hintPenalty,
        retentionPenalty,
        rawTotal,
        clampedTotal,
      ];

  Map<String, dynamic> toJson() => {
        'accuracy': accuracy,
        'independence': independence,
        'difficulty': difficulty,
        'retention': retention,
        'consistency': consistency,
        'hintPenalty': hintPenalty,
        'retentionPenalty': retentionPenalty,
        'rawTotal': rawTotal,
        'clampedTotal': clampedTotal,
      };
}

/// Breakdown of confidence into components.
class ConfidenceComponents extends Equatable {
  const ConfidenceComponents({
    required this.evidenceCountWeight,
    required this.consistencyWeight,
    required this.totalConfidence,
  });

  /// How much evidence count contributes to confidence.
  final double evidenceCountWeight;

  /// How much consistency of evidence contributes to confidence.
  final double consistencyWeight;

  /// Total confidence estimate.
  final double totalConfidence;

  @override
  List<Object?> get props =>
      [evidenceCountWeight, consistencyWeight, totalConfidence];

  Map<String, dynamic> toJson() => {
        'evidenceCountWeight': evidenceCountWeight,
        'consistencyWeight': consistencyWeight,
        'totalConfidence': totalConfidence,
      };
}
