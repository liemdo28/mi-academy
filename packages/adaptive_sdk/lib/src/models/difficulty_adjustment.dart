import 'dart:math';
import 'package:json_annotation/json_annotation.dart';

part 'difficulty_adjustment.g.dart';

/// Represents a difficulty adjustment decision made by the adaptive engine.
///
/// The engine analyzes recent performance and recommends whether to
/// increase, decrease, or maintain the current difficulty level.
@JsonSerializable(explicitToJson: true)
class DifficultyAdjustment {
  final String adjustmentId;
  final String childProfileId;
  final String gameId;
  final String levelId;
  final String currentDifficulty; // easy, medium, hard, adaptive
  final String recommendedDifficulty;
  final double confidence; // 0.0-1.0
  final String direction; // up, down, maintain
  final List<String> reasons;
  final Map<String, dynamic>? performanceContext;
  final DateTime decidedAt;
  final String schemaVersion;

  static const String currentSchemaVersion = '1.0.0';
  static const validDifficulties = ['easy', 'medium', 'hard', 'adaptive'];
  static const validDirections = ['up', 'down', 'maintain'];

  DifficultyAdjustment({
    required this.adjustmentId,
    required this.childProfileId,
    required this.gameId,
    required this.levelId,
    required this.currentDifficulty,
    required this.recommendedDifficulty,
    required this.confidence,
    required this.direction,
    this.reasons = const [],
    this.performanceContext,
    DateTime? decidedAt,
    this.schemaVersion = currentSchemaVersion,
  }) : decidedAt = decidedAt ?? DateTime.now();

  factory DifficultyAdjustment.fromJson(Map<String, dynamic> json) =>
      _$DifficultyAdjustmentFromJson(json);
  Map<String, dynamic> toJson() => _$DifficultyAdjustmentToJson(this);

  /// Whether the confidence level is high enough to act on.
  bool get isConfident => confidence >= 0.7;

  /// Whether this adjustment actually changes difficulty.
  bool get isChange => direction != 'maintain';

  /// Compute difficulty adjustment from recent performance.
  ///
  /// Uses a simple heuristic based on accuracy thresholds:
  /// - accuracy >= 0.9 → increase
  /// - accuracy >= 0.6 → maintain
  /// - accuracy < 0.6 → decrease
  static DifficultyAdjustment computeFromPerformance({
    required String childProfileId,
    required String gameId,
    required String levelId,
    required String currentDifficulty,
    required double recentAccuracy,
    required int sampleSize,
  }) {
    final currentIndex = validDifficulties.indexOf(currentDifficulty);
    final newDifficulty = _computeNewDifficulty(
      currentIndex: currentIndex,
      accuracy: recentAccuracy,
      sampleSize: sampleSize,
    );
    final newIndex = validDifficulties.indexOf(newDifficulty);

    String direction;
    if (newIndex > currentIndex) {
      direction = 'up';
    } else if (newIndex < currentIndex) {
      direction = 'down';
    } else {
      direction = 'maintain';
    }

    final confidence = (min(sampleSize / 5.0, 1.0) *
            (1.0 - (recentAccuracy - 0.5).abs() * 0.5))
        .clamp(0.0, 1.0);

    final reasons = <String>[];
    if (direction == 'up') reasons.add('High accuracy performance detected');
    if (direction == 'down') reasons.add('Struggling with current difficulty');
    if (sampleSize < 5) reasons.add('Low sample size — low confidence');

    return DifficultyAdjustment(
      adjustmentId: '',
      childProfileId: childProfileId,
      gameId: gameId,
      levelId: levelId,
      currentDifficulty: currentDifficulty,
      recommendedDifficulty: newDifficulty,
      confidence: confidence,
      direction: direction,
      reasons: reasons,
      performanceContext: {
        'recent_accuracy': recentAccuracy,
        'sample_size': sampleSize,
      },
    );
  }

  static String _computeNewDifficulty({
    required int currentIndex,
    required double accuracy,
    required int sampleSize,
  }) {
    if (sampleSize < 3) return validDifficulties[currentIndex];
    if (accuracy >= 0.9) {
      return validDifficulties[min(currentIndex + 1, validDifficulties.length - 1)];
    }
    if (accuracy < 0.6) {
      return validDifficulties[max(currentIndex - 1, 0)];
    }
    return validDifficulties[currentIndex];
  }

  List<String> validate() {
    final errors = <String>[];
    if (adjustmentId.isEmpty) errors.add('adjustmentId required');
    if (!validDifficulties.contains(currentDifficulty)) {
      errors.add('Invalid currentDifficulty: $currentDifficulty');
    }
    if (!validDifficulties.contains(recommendedDifficulty)) {
      errors.add('Invalid recommendedDifficulty: $recommendedDifficulty');
    }
    if (!validDirections.contains(direction)) {
      errors.add('Invalid direction: $direction');
    }
    if (confidence < 0 || confidence > 1) {
      errors.add('confidence must be 0.0-1.0');
    }
    return errors;
  }
}
