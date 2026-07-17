import 'dart:math' as math;
import 'mastery_config.dart';
import 'mastery_state.dart';
import 'mastery_status.dart';
import 'mastery_result.dart';

/// Rule-based mastery calculation engine.
///
/// This is the Tier 1 (Deterministic Rules) mastery engine.
/// It operates fully offline and is the source of truth for MVP.
///
/// Per blueprint §7: Mastery is not based solely on accuracy.
/// Components: accuracy, independence, difficulty, retention, consistency.
/// Safety: maximum single-attempt delta enforced.
class MasteryEngine {
  const MasteryEngine({this.config = MasteryConfig.defaultConfig});

  final MasteryConfig config;

  /// Evaluate a single attempt and update mastery state.
  ///
  /// [currentState] — existing state (or null for new skill)
  /// [attempt] — the new attempt evidence
  /// [accessibilityMode] — if true, timing-based penalties are suppressed
  MasteryResult evaluate({
    required MasteryState currentState,
    required AttemptEvidence attempt,
    bool accessibilityMode = false,
  }) {
    final now = DateTime.now();
    final reasonCodes = <String>[];
    final warningCodes = <String>[];

    // Start from previous state or fresh state
    final previousScore = currentState.masteryScore;
    final newEvidenceCount = currentState.evidenceCount + 1;

    // Build updated attempt history (max 20 entries)
    final newHistory = [attempt, ...currentState.attemptHistory];
    final trimmedHistory = newHistory.take(20).toList();

    // ── Score components ───────────────────────────────────────────────

    // Accuracy component: fraction correct across all attempts
    final newCorrect = currentState.correctCount + (attempt.correct ? 1 : 0);
    final newIncorrect = currentState.incorrectCount + (attempt.correct ? 0 : 1);
    final totalAttempts = newCorrect + newIncorrect;
    final accuracy = totalAttempts > 0 ? newCorrect / totalAttempts : 0.0;

    // Independence component: fraction of correct answers without hints
    final newIndependentCorrect = currentState.independentCorrectCount +
        (attempt.correct && attempt.hintsUsed == 0 ? 1 : 0);
    final totalCorrect = newCorrect;
    final independence = totalCorrect > 0
        ? newIndependentCorrect / totalCorrect
        : 0.0;

    // Difficulty bonus: higher difficulty → higher evidence value
    final normalizedDifficulty = (attempt.difficulty - 1) / 4.0; // 0.0 to 1.0
    final difficultyBonus =
        normalizedDifficulty * config.difficultyBonusMax * config.weights.difficulty;

    // Hint penalty: proportional to hint usage
    final newHintsUsed = currentState.totalHintsUsed + attempt.hintsUsed;
    final avgHintsPerAttempt =
        newEvidenceCount > 0 ? newHintsUsed / newEvidenceCount : 0.0;
    final hintPenalty =
        avgHintsPerAttempt * config.maxHintPenaltyRatio * config.weights.independence;

    // Retention component: practice spacing
    final daysSinceLast = currentState.lastPracticedAt != null
        ? now.difference(currentState.lastPracticedAt!).inDays
        : 999;
    final retentionDays = config.retentionPenaltyDays;
    double retentionBonus = 0.0;
    if (daysSinceLast <= retentionDays) {
      // Practiced recently — small positive retention bonus
      retentionBonus = config.weights.retention * 0.5;
    } else if (daysSinceLast <= retentionDays * 2) {
      // Practiced 1-2 retention cycles ago — reduced
      retentionBonus = config.weights.retention * 0.2;
    } else {
      // Long gap — no retention bonus (but also not a large penalty)
      retentionBonus = 0.0;
    }

    // Consistency component: based on recent attempt correctness
    double consistencyScore = 0.5; // default neutral
    if (trimmedHistory.length >= 2) {
      final recentCorrect = trimmedHistory
          .take(3)
          .where((a) => a.correct)
          .length;
      consistencyScore = recentCorrect / math.min(3, trimmedHistory.length);
    }
    final consistencyComponent = consistencyScore * config.weights.consistency;

    // ── Compute raw score ─────────────────────────────────────────────
    final rawScore = (config.weights.accuracy * accuracy) +
        (config.weights.independence * independence) +
        difficultyBonus +
        retentionBonus +
        consistencyComponent;

    // Apply hint penalty (reduces score but never below 0)
    final afterHintPenalty = (rawScore - hintPenalty).clamp(0.0, 1.0);

    // Enforce maximum single-attempt delta
    final candidateScore = afterHintPenalty;
    double finalScore;
    double delta;

    if (newEvidenceCount == 1) {
      // First attempt: initialize conservatively
      finalScore = (candidateScore * 0.5).clamp(0.0, 1.0);
      delta = finalScore - previousScore;
    } else {
      // Subsequent attempts: enforce delta limits
      final deltaCandidate = candidateScore - previousScore;
      delta = deltaCandidate.clamp(
        -config.maxSingleAttemptDecrease,
        config.maxSingleAttemptIncrease,
      );
      finalScore = (previousScore + delta).clamp(0.0, 1.0);
    }

    // Ensure score never drops below 0 or exceeds 1
    finalScore = finalScore.clamp(0.0, 1.0);

    // ── Confidence calculation ─────────────────────────────────────────
    // Confidence grows with evidence count and consistency
    final evidenceConfidence = math.min(newEvidenceCount / config.minEvidenceForConfidence, 1.0);
    double consistencyConfidence = 0.5;
    if (trimmedHistory.length >= 3) {
      final recentCorrect = trimmedHistory.take(3).where((a) => a.correct).length;
      consistencyConfidence = recentCorrect / 3.0;
    }
    final confidence = ((evidenceConfidence * 0.7) + (consistencyConfidence * 0.3)).clamp(0.0, 1.0);

    // ── Status determination ─────────────────────────────────────────
    final newStatus = _computeStatus(
      finalScore,
      confidence,
      trimmedHistory,
      currentState.status,
      now,
    );

    // ── Difficulty recommendation ────────────────────────────────────
    final newDifficulty = _computeDifficulty(finalScore, trimmedHistory);

    // ── Reason codes ────────────────────────────────────────────────
    if (attempt.correct) reasonCodes.add('CORRECT_ANSWER');
    if (attempt.hintsUsed == 0) reasonCodes.add('INDEPENDENT_COMPLETION');
    if (attempt.difficulty >= 3) reasonCodes.add('HIGH_DIFFICULTY');
    if (newEvidenceCount == 1) reasonCodes.add('FIRST_ATTEMPT');
    if (delta > 0) reasonCodes.add('SCORE_INCREASED');
    if (delta < 0) reasonCodes.add('SCORE_DECREASED');
    if (hintPenalty > 0.01) reasonCodes.add('HINT_PENALTY_APPLIED');
    if (daysSinceLast > config.retentionPenaltyDays) {
      reasonCodes.add('RETENTION_GAP');
    }
    if (consistencyScore > 0.7) reasonCodes.add('CONSISTENT_RECENT');

    // ── Warnings ────────────────────────────────────────────────────
    if (newEvidenceCount < 3 && finalScore > 0.7) {
      warningCodes.add('LOW_EVIDENCE_HIGH_SCORE');
    }
    if (newHintsUsed > newEvidenceCount * 2) {
      warningCodes.add('EXCESSIVE_HINTS');
    }

    // ── Build score components ───────────────────────────────────────
    final scoreComponents = ScoreComponents(
      accuracy: accuracy * config.weights.accuracy,
      independence: independence * config.weights.independence,
      difficulty: difficultyBonus,
      retention: retentionBonus,
      consistency: consistencyComponent,
      hintPenalty: hintPenalty,
      retentionPenalty: 0.0, // No penalty, only bonus
      rawTotal: rawScore,
      clampedTotal: finalScore,
    );

    final confidenceComponents = ConfidenceComponents(
      evidenceCountWeight: evidenceConfidence,
      consistencyWeight: consistencyConfidence,
      totalConfidence: confidence,
    );

    // ── Updated state ────────────────────────────────────────────────
    final updatedState = currentState.copyWith(
      masteryScore: finalScore,
      confidence: confidence,
      evidenceCount: newEvidenceCount,
      status: newStatus,
      lastPracticedAt: now,
      nextReviewAt: _computeNextReview(newStatus, finalScore, now),
      correctCount: newCorrect,
      incorrectCount: newIncorrect,
      independentCorrectCount: newIndependentCorrect,
      totalHintsUsed: newHintsUsed,
      lastPracticedDifficulty: attempt.difficulty,
      currentDifficulty: newDifficulty,
      attemptHistory: trimmedHistory,
    );

    return MasteryResult(
      updatedState: updatedState,
      scoreComponents: scoreComponents,
      confidenceComponents: confidenceComponents,
      reasonCodes: reasonCodes,
      engineVersion: 'mastery-rule-v1',
      delta: delta,
      warningCodes: warningCodes,
    );
  }

  /// Determine mastery status from score and evidence.
  MasteryStatus _computeStatus(
    double score,
    double confidence,
    List<AttemptEvidence> history,
    MasteryStatus previousStatus,
    DateTime now,
  ) {
    // Check for review due first
    if (previousStatus == MasteryStatus.mastered ||
        previousStatus == MasteryStatus.proficient) {
      // These statuses need spaced repetition check
      // Review due is set via nextReviewAt field
    }

    if (score >= config.masteryThreshold && confidence >= 0.5) {
      return MasteryStatus.mastered;
    }
    if (score >= config.proficientThreshold) {
      return MasteryStatus.proficient;
    }
    if (score >= config.introducedThreshold) {
      return MasteryStatus.developing;
    }
    if (score > 0.0) {
      return MasteryStatus.introduced;
    }
    return MasteryStatus.notStarted;
  }

  /// Recommend difficulty level based on mastery score and history.
  int _computeDifficulty(double score, List<AttemptEvidence> history) {
    if (history.isEmpty) return 1;
    // Look at recent attempts to detect if difficulty should change
    final recentDifficulties = history.take(5).map((e) => e.difficulty).toList();
    final avgRecentDifficulty = recentDifficulties.reduce((a, b) => a + b) / recentDifficulties.length;

    // If mastery is high and recent attempts are consistently correct, suggest higher
    if (score >= 0.75 && recentDifficulties.take(3).every((d) => d >= 3)) {
      return (avgRecentDifficulty + 0.5).round().clamp(1, 5);
    }
    // If mastery is low and recent attempts had errors, suggest lower
    if (score < 0.4) {
      return (avgRecentDifficulty - 0.5).round().clamp(1, 5);
    }
    return avgRecentDifficulty.round().clamp(1, 5);
  }

  /// Compute next review date based on status and score.
  DateTime _computeNextReview(MasteryStatus status, double score, DateTime now) {
    int intervalDays;
    switch (status) {
      case MasteryStatus.notStarted:
      case MasteryStatus.introduced:
        intervalDays = 1;
        break;
      case MasteryStatus.developing:
        intervalDays = 2;
        break;
      case MasteryStatus.proficient:
        intervalDays = 7;
        break;
      case MasteryStatus.mastered:
        intervalDays = 21;
        break;
      case MasteryStatus.reviewDue:
        intervalDays = 1;
        break;
    }
    return now.add(Duration(days: intervalDays));
  }
}
