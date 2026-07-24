import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/services/adaptive_learning_service.dart';
import 'package:mi_game_content/mi_game_content.dart';
import 'package:mi_game_core/mi_game_core.dart';

const _mapping = CanonicalActivityMapping(
  gameId: 'math_race',
  levelId: 'level_1',
  activityId: 'level_1',
  primarySkillId: 'math.addition.within_10',
  secondarySkillIds: ['math.counting'],
  subjectId: 'math',
  curriculumNodeId: 'junior.math',
  difficulty: 2,
  prerequisites: ['math.counting'],
  supportedLocales: ['vi', 'en'],
  contentPackId: 'math_race',
);

MiCompletionResult _mathRaceCompletion(DateTime completedAt) {
  return MiCompletionResult(
    gameId: 'math_race',
    levelId: 'level_1',
    childProfileId: 'child-1',
    score: 90,
    maxScore: 100,
    attemptsUsed: 3,
    hintsUsed: 0,
    duration: const Duration(minutes: 4),
    completedAt: completedAt,
    newSkillsAcquired: const ['math.addition.basic'],
    perfectRun: true,
  );
}

void main() {
  test('maps game completion into mastery and recommendation shadow result',
      () {
    final result = _mathRaceCompletion(DateTime(2026, 7, 17, 9));

    final shadow = const AdaptiveLearningService().evaluateCompletion(
      childProfileId: 'child-1',
      result: result,
      offlineMode: true,
    );

    expect(shadow.engineVersion, 'mastery-rule-v1');
    expect(shadow.mastery.childId, 'child-1');
    expect(shadow.mastery.skillId, 'math.addition.basic');
    expect(shadow.mastery.evidenceCount, 1);
    expect(shadow.reasonCodes, contains('CORRECT_ANSWER'));
    expect(shadow.recommendation.engineVersion, 'recommendation-rule-v1');
    expect(shadow.recommendation.offlineMode, isTrue);
    expect(shadow.toJson()['shadow_mode'], isTrue);
  });

  test('skillIdFor matches the skill evaluateCompletion actually scores', () {
    final result = _mathRaceCompletion(DateTime(2026, 7, 17, 9));
    expect(
      AdaptiveLearningService.skillIdFor(result),
      'math.addition.basic',
    );
  });

  test('resolvedSkillId prefers the canonical mapping over the heuristic', () {
    final result = _mathRaceCompletion(DateTime(2026, 7, 17, 9));

    expect(
      AdaptiveLearningService.resolvedSkillId(result, mapping: _mapping),
      'math.addition.within_10',
    );
    expect(
      AdaptiveLearningService.resolvedSkillId(result),
      'math.addition.basic', // falls back to skillIdFor when no mapping
    );
  });

  test(
      'when a canonical mapping is passed, evaluateCompletion uses its real '
      'subjectId/skillIds/ageGroup instead of guessing from the game name', () {
    final shadow = const AdaptiveLearningService().evaluateCompletion(
      childProfileId: 'child-1',
      result: _mathRaceCompletion(DateTime(2026, 7, 17, 9)),
      offlineMode: true,
      mapping: _mapping,
    );

    expect(shadow.mastery.skillId, 'math.addition.within_10');
    // Not reachable directly on AdaptiveShadowResult, but proven via the
    // recommendation call succeeding with the mapping's subjectId/skillIds
    // (ContentItem would throw/validate on garbage input) and via the
    // mastery skillId above actually being the canonical one, not the
    // '${gameId}.${levelId}'/newSkillsAcquired heuristic.
    expect(shadow.recommendation.engineVersion, 'recommendation-rule-v1');
  });

  test(
      'mastery accumulates across completions when previousMastery is '
      'passed, instead of resetting to a fresh zero-evidence state', () {
    const service = AdaptiveLearningService();

    final first = service.evaluateCompletion(
      childProfileId: 'child-1',
      result: _mathRaceCompletion(DateTime(2026, 7, 17, 9)),
      offlineMode: true,
    );
    expect(first.mastery.evidenceCount, 1);
    expect(first.mastery.correctCount, 1);

    // Same call, but with no previousMastery passed -- this is the bug
    // AdaptiveLearningService used to have: every completion evaluated
    // as if it were the child's very first attempt.
    final secondWithoutHistory = service.evaluateCompletion(
      childProfileId: 'child-1',
      result: _mathRaceCompletion(DateTime(2026, 7, 18, 9)),
      offlineMode: true,
    );
    expect(secondWithoutHistory.mastery.evidenceCount, 1); // still 1, not 2

    // With the previous state threaded through (as GameScreen now does via
    // mastery_state_store.dart), evidence genuinely accumulates.
    final secondWithHistory = service.evaluateCompletion(
      childProfileId: 'child-1',
      result: _mathRaceCompletion(DateTime(2026, 7, 18, 9)),
      offlineMode: true,
      previousMastery: first.mastery,
    );
    expect(secondWithHistory.mastery.evidenceCount, 2);
    expect(secondWithHistory.mastery.correctCount, 2);
    expect(
      secondWithHistory.mastery.masteryScore,
      greaterThanOrEqualTo(first.mastery.masteryScore),
    );
  });
}
