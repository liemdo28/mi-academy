import 'package:flutter_test/flutter_test.dart';
import 'package:mastery_core/mastery_core.dart';

void main() {
  group('MasteryEngine', () {
    late MasteryEngine engine;
    setUp(() => engine = const MasteryEngine());

    test('first correct attempt initializes mastery conservatively', () {
      final state =
          MasteryState(childId: 'c1', skillId: 'math.addition.within_10');
      final attempt = AttemptEvidence(
        attemptedAt: DateTime.now(),
        correct: true,
        hintsUsed: 0,
        difficulty: 1,
      );
      final result = engine.evaluate(currentState: state, attempt: attempt);
      expect(result.updatedState.evidenceCount, 1);
      expect(result.updatedState.masteryScore, greaterThan(0));
      expect(result.updatedState.masteryScore, lessThan(0.31));
      expect(result.reasonCodes, contains('FIRST_ATTEMPT'));
      expect(result.reasonCodes, contains('CORRECT_ANSWER'));
    });

    test('single incorrect attempt does not collapse mastery', () {
      final state = MasteryState(
        childId: 'c1',
        skillId: 'math.addition.within_10',
        masteryScore: 0.72,
        evidenceCount: 12,
        confidence: 0.65,
        correctCount: 10,
        incorrectCount: 2,
      );
      final attempt = AttemptEvidence(
        attemptedAt: DateTime.now(),
        correct: false,
        hintsUsed: 2,
        difficulty: 2,
      );
      final result = engine.evaluate(currentState: state, attempt: attempt);
      expect(
        state.masteryScore - result.updatedState.masteryScore,
        lessThanOrEqualTo(0.041),
      );
      expect(result.updatedState.masteryScore, greaterThanOrEqualTo(0.679));
      expect(result.reasonCodes, contains('SCORE_DECREASED'));
    });

    test('high difficulty success gives difficulty bonus', () {
      final state = MasteryState(
        childId: 'c1',
        skillId: 'math.multiplication.tables',
        masteryScore: 0.65,
        evidenceCount: 8,
        confidence: 0.5,
      );
      final attempt = AttemptEvidence(
        attemptedAt: DateTime.now(),
        correct: true,
        hintsUsed: 0,
        difficulty: 5,
      );
      final result = engine.evaluate(currentState: state, attempt: attempt);
      expect(result.updatedState.masteryScore, greaterThan(0.62));
      expect(result.reasonCodes, contains('HIGH_DIFFICULTY'));
    });

    test('hint usage reduces mastery but is not treated as failure', () {
      final state = MasteryState(
        childId: 'c1',
        skillId: 'math.subtraction.within_10',
        masteryScore: 0.6,
        evidenceCount: 4,
        confidence: 0.35,
      );
      final attempt = AttemptEvidence(
        attemptedAt: DateTime.now(),
        correct: true,
        hintsUsed: 3,
        difficulty: 2,
      );
      final result = engine.evaluate(currentState: state, attempt: attempt);
      expect(result.reasonCodes, contains('HINT_PENALTY_APPLIED'));
      expect(result.updatedState.masteryScore, greaterThan(0.5));
      expect(result.updatedState.masteryScore, lessThan(0.68));
    });

    test('maximum single-attempt increase is enforced', () {
      final state = MasteryState(
        childId: 'c1',
        skillId: 'math.addition.within_20',
        masteryScore: 0.70,
        evidenceCount: 8,
        confidence: 0.55,
      );
      final attempt = AttemptEvidence(
        attemptedAt: DateTime.now(),
        correct: true,
        hintsUsed: 0,
        difficulty: 5,
      );
      final result = engine.evaluate(currentState: state, attempt: attempt);
      expect(result.delta, lessThanOrEqualTo(0.08));
    });

    test('reason codes are always non-empty', () {
      final state = MasteryState(childId: 'c1', skillId: 'logic.memory');
      final attempt = AttemptEvidence(
        attemptedAt: DateTime.now(),
        correct: true,
        hintsUsed: 0,
        difficulty: 1,
      );
      final result = engine.evaluate(currentState: state, attempt: attempt);
      expect(result.reasonCodes, isNotEmpty);
    });

    test('engine version is always present in output', () {
      final state = MasteryState(childId: 'c1', skillId: 'letters.recognition');
      final attempt = AttemptEvidence(
        attemptedAt: DateTime.now(),
        correct: false,
        hintsUsed: 1,
        difficulty: 1,
      );
      final result = engine.evaluate(currentState: state, attempt: attempt);
      expect(result.engineVersion, equals('mastery-rule-v1'));
    });
  });

  group('MasteryConfig', () {
    test('default values are sensible', () {
      const config = MasteryConfig.defaultConfig;
      expect(config.masteryThreshold, 0.80);
      expect(config.maxSingleAttemptIncrease, 0.08);
      expect(config.maxSingleAttemptDecrease, 0.04);
      expect(config.weights.total, closeTo(1.0, 0.000001));
    });

    test('JSON roundtrip works', () {
      const config = MasteryConfig.defaultConfig;
      final json = config.toJson();
      final restored = MasteryConfig.fromJson(json);
      expect(restored.masteryThreshold, config.masteryThreshold);
      expect(
          restored.maxSingleAttemptIncrease, config.maxSingleAttemptIncrease);
    });
  });

  group('MasteryStatus', () {
    test('status values match expected strings', () {
      expect(MasteryStatus.notStarted.value, 'not_started');
      expect(MasteryStatus.introduced.value, 'introduced');
      expect(MasteryStatus.developing.value, 'developing');
      expect(MasteryStatus.proficient.value, 'proficient');
      expect(MasteryStatus.mastered.value, 'mastered');
      expect(MasteryStatus.reviewDue.value, 'review_due');
    });

    test('labels are localized', () {
      expect(MasteryStatus.mastered.label('vi'), 'Đã thành thạo');
      expect(MasteryStatus.mastered.label('en'), 'Mastered');
    });
  });

  group('MasteryState', () {
    test('accuracy rate computed correctly', () {
      final state = MasteryState(
        childId: 'c1',
        skillId: 'math.addition',
        correctCount: 7,
        incorrectCount: 3,
      );
      expect(state.accuracyRate, 0.7);
    });

    test('accuracy rate is 0 when no attempts', () {
      final state = MasteryState(childId: 'c1', skillId: 'math.addition');
      expect(state.accuracyRate, 0.0);
    });

    test('JSON roundtrip preserves all fields', () {
      final state = MasteryState(
        childId: 'c1',
        skillId: 'math.addition.within_10',
        masteryScore: 0.75,
        confidence: 0.6,
        evidenceCount: 5,
        status: MasteryStatus.proficient,
        correctCount: 4,
        incorrectCount: 1,
      );
      final json = state.toJson();
      final restored = MasteryState.fromJson(json);
      expect(restored.masteryScore, state.masteryScore);
      expect(restored.confidence, state.confidence);
      expect(restored.evidenceCount, state.evidenceCount);
      expect(restored.status, state.status);
    });
  });
}
