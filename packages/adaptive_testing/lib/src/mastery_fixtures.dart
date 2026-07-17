import 'package:mastery_core/mastery_core.dart';

/// Test fixtures for mastery engine evaluation.
class MasteryFixtures {
  MasteryFixtures._();

  /// Fresh state for a new child-skill pair.
  static MasteryState newChild() => MasteryState(
    childId: 'fixture-child-new',
    skillId: 'math.addition.within_10',
  );

  /// State with consistent success.
  static MasteryState consistentSuccess() => MasteryState(
    childId: 'fixture-child-success',
    skillId: 'math.addition.within_10',
    masteryScore: 0.65,
    evidenceCount: 10,
    confidence: 0.6,
    correctCount: 8,
    incorrectCount: 2,
    lastPracticedAt: DateTime.now().subtract(const Duration(days: 1)),
  );

  /// State with high mastery.
  static MasteryState mastered() => MasteryState(
    childId: 'fixture-child-mastered',
    skillId: 'math.addition.within_10',
    masteryScore: 0.85,
    evidenceCount: 20,
    confidence: 0.8,
    correctCount: 18,
    incorrectCount: 2,
    status: MasteryStatus.mastered,
  );

  /// State with low mastery (struggling).
  static MasteryState struggling() => MasteryState(
    childId: 'fixture-child-struggle',
    skillId: 'math.addition.within_10',
    masteryScore: 0.25,
    evidenceCount: 5,
    confidence: 0.3,
    correctCount: 2,
    incorrectCount: 3,
    status: MasteryStatus.developing,
  );

  /// A correct independent attempt at difficulty 1.
  static AttemptEvidence correctAttempt1({int difficulty = 1}) => AttemptEvidence(
    attemptedAt: DateTime.now(),
    correct: true,
    hintsUsed: 0,
    difficulty: difficulty,
  );

  /// A correct attempt with hints at difficulty 2.
  static AttemptEvidence correctWithHints({int difficulty = 2}) => AttemptEvidence(
    attemptedAt: DateTime.now(),
    correct: true,
    hintsUsed: 2,
    difficulty: difficulty,
  );

  /// An incorrect attempt at difficulty 2.
  static AttemptEvidence incorrectAttempt({int difficulty = 2}) => AttemptEvidence(
    attemptedAt: DateTime.now(),
    correct: false,
    hintsUsed: 1,
    difficulty: difficulty,
  );

  /// A correct attempt at high difficulty.
  static AttemptEvidence correctHighDifficulty() => AttemptEvidence(
    attemptedAt: DateTime.now(),
    correct: true,
    hintsUsed: 0,
    difficulty: 5,
  );

  /// State with no evidence.
  static MasteryState noEvidence() => MasteryState(
    childId: 'fixture-no-evidence',
    skillId: 'science.cause_effect',
    masteryScore: 0.0,
    evidenceCount: 0,
    confidence: 0.0,
  );

  /// State after long offline gap.
  static MasteryState longOfflineGap() => MasteryState(
    childId: 'fixture-offline-gap',
    skillId: 'letters.spelling',
    masteryScore: 0.70,
    evidenceCount: 8,
    confidence: 0.5,
    lastPracticedAt: DateTime.now().subtract(const Duration(days: 14)),
  );
}
