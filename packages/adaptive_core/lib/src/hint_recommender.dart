/// Hint recommendation and escalation system (§13).
///
/// Provides progressive hint strategies based on mastery level,
/// attempt history, and time-on-task. Escalates hints when
/// the student is struggling.
library;

import 'dart:math';

/// Enum representing the level of hint to provide.
enum HintLevel {
  /// No hint — student works independently.
  none,

  /// Subtle visual cue or framing hint.
  minimal,

  /// Conceptual guidance pointing toward the right approach.
  conceptual,

  /// Step-by-step worked example showing the method.
  workedExample,

  /// Full solution reveal (last resort).
  fullSolution,
}

/// A hint recommendation with metadata for auditability.
class HintRecommendation {
  const HintRecommendation({
    required this.level,
    required this.message,
    required this.reasonCode,
    this.escalatesFrom,
    required this.confidence,
    required this.modelVersion,
    required this.timestamp,
  });

  /// The recommended hint level.
  final HintLevel level;

  /// Localized hint message template (key for i18n lookup).
  final String message;

  /// Reason code for why this hint level was chosen.
  final String reasonCode;

  /// Previous hint level this escalates from, if any.
  final HintLevel? escalatesFrom;

  /// Confidence score [0.0–1.0] that this hint is appropriate.
  final double confidence;

  /// Model version that generated this recommendation.
  final String modelVersion;

  /// Timestamp of the recommendation.
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'message': message,
        'reasonCode': reasonCode,
        'escalatesFrom': escalatesFrom?.name,
        'confidence': confidence,
        'modelVersion': modelVersion,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Configuration for hint behavior thresholds.
class HintConfig {
  const HintConfig({
    this.minTimeBeforeFirstHint = const Duration(seconds: 30),
    this.minTimeBetweenHints = const Duration(seconds: 15),
    this.maxHintsPerQuestion = 4,
    this.autoEscalateAfterIncorrect = 2,
    this.forceRevealAfterMasteryBelow = 0.15,
    this.modelVersion = '1.0.0',
  });

  /// Minimum time before first hint can appear.
  final Duration minTimeBeforeFirstHint;

  /// Minimum time between hint escalations.
  final Duration minTimeBetweenHints;

  /// Maximum number of hints per question before forcing full reveal.
  final int maxHintsPerQuestion;

  /// Number of consecutive incorrect attempts before auto-escalation.
  final int autoEscalateAfterIncorrect;

  /// If mastery score is below this threshold, skip to worked example.
  final double forceRevealAfterMasteryBelow;

  /// Model version for auditability.
  final String modelVersion;
}

/// Context snapshot used to evaluate hint recommendations.
class HintContext {
  const HintContext({
    required this.childId,
    required this.skillId,
    required this.masteryScore,
    required this.currentHintLevel,
    required this.hintsUsedThisQuestion,
    required this.consecutiveIncorrectAttempts,
    required this.timeOnCurrentQuestion,
    required this.totalAttemptsThisQuestion,
    this.questionDifficulty = 0.5,
  });

  final String childId;
  final String skillId;
  final double masteryScore;
  final HintLevel currentHintLevel;
  final int hintsUsedThisQuestion;
  final int consecutiveIncorrectAttempts;
  final Duration timeOnCurrentQuestion;
  final int totalAttemptsThisQuestion;
  final double questionDifficulty;
}

/// §13 Hint Recommender.
///
/// Progressive hint system that recommends appropriate hint levels
/// based on student context. Follows escalation rules and enforces
/// per-question limits.
///
/// Rules:
/// - Never show a hint before [HintConfig.minTimeBeforeFirstHint].
/// - Escalate after [HintConfig.autoEscalateAfterIncorrect] consecutive incorrect.
/// - For very low mastery ([HintConfig.forceRevealAfterMasteryBelow]),
///   skip directly to workedExample.
/// - Max [HintConfig.maxHintsPerQuestion] hints; after that, fullSolution.
/// - Every recommendation carries a reason code for audit.
class HintRecommender {
  HintRecommender({HintConfig? config})
      : _config = config ?? const HintConfig();

  final HintConfig _config;

  /// Current model version for auditability.
  String get modelVersion => _config.modelVersion;

  /// Evaluate the hint level for the given context.
  HintRecommendation evaluate(HintContext context) {
    final now = DateTime.now();

    // Rule: max hints reached → full solution
    if (context.hintsUsedThisQuestion >= _config.maxHintsPerQuestion) {
      return HintRecommendation(
        level: HintLevel.fullSolution,
        message: 'hint.full_solution',
        reasonCode: 'MAX_HINTS_REACHED',
        escalatesFrom: context.currentHintLevel,
        confidence: 1.0,
        modelVersion: modelVersion,
        timestamp: now,
      );
    }

    // Rule: no hint if not enough time has passed
    if (context.hintsUsedThisQuestion == 0 &&
        context.timeOnCurrentQuestion < _config.minTimeBeforeFirstHint) {
      return HintRecommendation(
        level: HintLevel.none,
        message: '',
        reasonCode: 'TOO_EARLY',
        confidence: 1.0,
        modelVersion: modelVersion,
        timestamp: now,
      );
    }

    // Rule: very low mastery → jump to worked example
    if (context.masteryScore < _config.forceRevealAfterMasteryBelow &&
        context.currentHintLevel.index < HintLevel.workedExample.index) {
      return HintRecommendation(
        level: HintLevel.workedExample,
        message: 'hint.worked_example',
        reasonCode: 'LOW_MASTERY_SKIP',
        escalatesFrom: context.currentHintLevel,
        confidence: 0.9,
        modelVersion: modelVersion,
        timestamp: now,
      );
    }

    // Rule: consecutive incorrect → escalate
    if (context.consecutiveIncorrectAttempts >=
        _config.autoEscalateAfterIncorrect) {
      final nextLevel = _escalate(context.currentHintLevel);
      return HintRecommendation(
        level: nextLevel,
        message: _messageKey(nextLevel),
        reasonCode: 'CONSECUTIVE_INCORRECT',
        escalatesFrom: context.currentHintLevel,
        confidence: 0.85,
        modelVersion: modelVersion,
        timestamp: now,
      );
    }

    // Default: provide minimal hint if student has been working a while
    if (context.timeOnCurrentQuestion >= _config.minTimeBeforeFirstHint &&
        context.currentHintLevel == HintLevel.none) {
      return HintRecommendation(
        level: HintLevel.minimal,
        message: 'hint.minimal',
        reasonCode: 'TIME_ON_TASK',
        escalatesFrom: null,
        confidence: 0.7,
        modelVersion: modelVersion,
        timestamp: now,
      );
    }

    // No escalation needed — stay at current level
    return HintRecommendation(
      level: HintLevel.none,
      message: '',
      reasonCode: 'NO_ACTION',
      confidence: 1.0,
      modelVersion: modelVersion,
      timestamp: now,
    );
  }

  /// Get the next hint level in the escalation chain.
  HintLevel _escalate(HintLevel current) {
    final levels = HintLevel.values;
    final idx = current.index;
    // Skip 'none' when escalating
    final nextIdx = idx == 0 ? 1 : min(idx + 1, levels.length - 1);
    return levels[nextIdx];
  }

  /// Map hint level to message key.
  String _messageKey(HintLevel level) {
    switch (level) {
      case HintLevel.minimal:
        return 'hint.minimal';
      case HintLevel.conceptual:
        return 'hint.conceptual';
      case HintLevel.workedExample:
        return 'hint.worked_example';
      case HintLevel.fullSolution:
        return 'hint.full_solution';
      case HintLevel.none:
        return '';
    }
  }
}
