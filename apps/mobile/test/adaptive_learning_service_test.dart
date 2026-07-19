import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/services/adaptive_learning_service.dart';
import 'package:mi_game_core/mi_game_core.dart';

void main() {
  test(
    'maps game completion into mastery and recommendation shadow result',
    () {
      final result = MiCompletionResult(
        gameId: 'math_race',
        levelId: 'level_1',
        childProfileId: 'child-1',
        score: 90,
        maxScore: 100,
        attemptsUsed: 3,
        hintsUsed: 0,
        duration: const Duration(minutes: 4),
        completedAt: DateTime(2026, 7, 17, 9),
        newSkillsAcquired: const ['math.addition.basic'],
        perfectRun: true,
      );

      final shadow = const AdaptiveLearningService().evaluateCompletion(
        childProfileId: 'child-1',
        result: result,
        offlineMode: true,
      );

      expect(shadow.engineVersion, 'mastery-rule-v1');
      expect(shadow.mastery.childId, 'child-1');
      expect(shadow.mastery.skillId, 'math.addition.basic');
      expect(shadow.reasonCodes, contains('CORRECT_ANSWER'));
      expect(shadow.recommendation.engineVersion, 'recommendation-rule-v1');
      expect(shadow.recommendation.offlineMode, isTrue);
      expect(shadow.toJson()['shadow_mode'], isTrue);
    },
  );
}
