import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_progress/mi_game_progress.dart';

void main() {
  group('AttemptRecord', () {
    test('round-trips attempt data for offline persistence', () {
      final attemptedAt = DateTime.utc(2026, 7, 17, 8, 30);
      final record = AttemptRecord(
        childId: 'child-1',
        gameId: 'word_builder',
        levelId: 'level-1',
        correct: true,
        attemptedAt: attemptedAt,
        duration: const Duration(seconds: 42),
        hintsUsed: 1,
      );

      final restored = AttemptRecord.fromJson(record.toJson());

      expect(restored, record);
      expect(restored.toJson()['durationMs'], 42000);
    });

    test('defaults missing hintsUsed to zero when restoring old data', () {
      final restored = AttemptRecord.fromJson({
        'childId': 'child-1',
        'gameId': 'math_race',
        'levelId': 'level-2',
        'correct': false,
        'attemptedAt': DateTime.utc(2026, 7, 17).toIso8601String(),
        'durationMs': 12000,
      });

      expect(restored.hintsUsed, 0);
    });
  });

  group('MasteryCalculator', () {
    test('returns zero mastery when there are no attempts', () {
      final mastery = const MasteryCalculator().calculate(
        attempts: const [],
        difficulty: 3,
      );

      expect(mastery, 0.0);
    });

    test('rewards accuracy and difficulty while clamping to one', () {
      final mastery = const MasteryCalculator().calculate(
        attempts: const [
          (correct: true, hintsUsed: 0),
          (correct: true, hintsUsed: 0),
          (correct: true, hintsUsed: 0),
        ],
        difficulty: 5,
      );

      expect(mastery, 1.0);
    });

    test('penalizes hint-heavy attempts without going below zero', () {
      final mastery = const MasteryCalculator().calculate(
        attempts: const [
          (correct: false, hintsUsed: 4),
          (correct: false, hintsUsed: 4),
        ],
        difficulty: 1,
      );

      expect(mastery, 0.0);
    });

    test('maps mastery bands to recommended difficulty tiers', () {
      const calculator = MasteryCalculator();

      expect(calculator.recommendDifficulty(_mastery(0.39)), 1);
      expect(calculator.recommendDifficulty(_mastery(0.4)), 2);
      expect(calculator.recommendDifficulty(_mastery(0.6)), 3);
      expect(calculator.recommendDifficulty(_mastery(0.75)), 4);
      expect(calculator.recommendDifficulty(_mastery(0.9)), 5);
    });
  });

  group('SkillMastery', () {
    test('records attempts and updates mastery counters', () {
      final skill = SkillMastery(skillId: 'math.addition', childId: 'child-1');

      skill.recordAttempt(correct: true, hintsUsed: 0, difficulty: 2);
      skill.recordAttempt(correct: false, hintsUsed: 1, difficulty: 2);

      expect(skill.totalAttempts, 2);
      expect(skill.correctAttempts, 1);
      expect(skill.totalHintsUsed, 1);
      expect(skill.mastery, closeTo(0.266, 0.01));
      expect(skill.lastAttemptedAt, isNotNull);
      expect(skill.lastSpacedRecallAt, isNotNull);
    });

    test('marks high mastery as mastered', () {
      final skill = SkillMastery(
        skillId: 'language.word_builder',
        childId: 'child-1',
        mastery: 0.8,
      );

      expect(skill.isMastered, isTrue);
    });

    test('flags skills that need spaced recall after two days', () {
      final skill = SkillMastery(
        skillId: 'logic.memory',
        childId: 'child-1',
        lastSpacedRecallAt: DateTime.now().subtract(const Duration(days: 3)),
      );

      expect(skill.needsRecall, isTrue);
    });

    test('round-trips mastery state to JSON', () {
      final skill = SkillMastery(
        skillId: 'math.money',
        childId: 'child-1',
        mastery: 0.72,
        totalAttempts: 5,
        correctAttempts: 4,
        totalHintsUsed: 2,
        lastAttemptedAt: DateTime.utc(2026, 7, 17, 9),
        lastSpacedRecallAt: DateTime.utc(2026, 7, 16, 9),
      );

      final restored = SkillMastery.fromJson(skill.toJson());

      expect(restored, skill);
    });
  });

  group('ProgressTracker', () {
    test('records completion attempt and updates each skill', () {
      final tracker = ProgressTracker(childId: 'child-1');

      tracker.recordCompletion(
        gameId: 'math_supermarket',
        levelId: 'level-1',
        correct: true,
        duration: const Duration(seconds: 30),
        skillIds: ['math.money', 'math.addition'],
        difficulty: 2,
      );

      expect(tracker.attempts, hasLength(1));
      expect(tracker.attempts.single.childId, 'child-1');
      expect(tracker.skills.keys, containsAll(['math.money', 'math.addition']));
      expect(tracker.getMastery('math.money'), greaterThan(0.0));
    });

    test('returns conservative defaults for unpracticed skills', () {
      final tracker = ProgressTracker(childId: 'child-1');

      expect(tracker.getMastery('unknown'), 0.0);
      expect(tracker.recommendDifficulty('unknown'), 1);
      expect(tracker.masteredSkills, isEmpty);
    });

    test('lists mastered skills but not skills below threshold', () {
      final tracker = ProgressTracker(childId: 'child-1');
      for (var i = 0; i < 3; i++) {
        tracker.recordCompletion(
          gameId: 'word_builder',
          levelId: 'level-$i',
          correct: true,
          duration: const Duration(seconds: 20),
          skillIds: ['language.word_builder'],
          difficulty: 4,
        );
      }
      tracker.recordCompletion(
        gameId: 'word_builder',
        levelId: 'level-miss',
        correct: false,
        duration: const Duration(seconds: 20),
        skillIds: ['language.spelling'],
        hintsUsed: 2,
        difficulty: 1,
      );

      expect(tracker.masteredSkills, contains('language.word_builder'));
      expect(tracker.masteredSkills, isNot(contains('language.spelling')));
    });

    test('lists skills needing recall after restore', () {
      final tracker = ProgressTracker.fromJson({
        'childId': 'child-1',
        'attempts': const [],
        'skills': {
          'logic.memory': SkillMastery(
            skillId: 'logic.memory',
            childId: 'child-1',
            mastery: 0.85,
            totalAttempts: 3,
            correctAttempts: 3,
            totalHintsUsed: 0,
            lastSpacedRecallAt:
                DateTime.now().subtract(const Duration(days: 4)),
          ).toJson(),
        },
      });

      expect(tracker.skillsNeedingRecall, ['logic.memory']);
    });

    test('round-trips attempts and skills for persistence', () {
      final tracker = ProgressTracker(childId: 'child-1');
      tracker.recordCompletion(
        gameId: 'robot_commands',
        levelId: 'level-1',
        correct: true,
        duration: const Duration(seconds: 55),
        skillIds: ['logic.sequence'],
        hintsUsed: 0,
        difficulty: 3,
      );

      final restored = ProgressTracker.fromJson(tracker.toJson());

      expect(restored.childId, 'child-1');
      expect(restored.attempts, tracker.attempts);
      expect(restored.skills.keys, tracker.skills.keys);
      expect(restored.getMastery('logic.sequence'), greaterThan(0.0));
    });
  });
}

SkillMastery _mastery(double value) {
  return SkillMastery(skillId: 'skill', childId: 'child', mastery: value);
}
