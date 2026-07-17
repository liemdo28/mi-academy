import 'package:flutter_test/flutter_test.dart';
import 'package:mastery_core/mastery_core.dart';
import 'package:recommendation_core/recommendation_core.dart';

void main() {
  test(
    'content item defaults are valid and recommendation has reason codes',
    () {
      const content = ContentItem(
        id: 'level-1',
        type: ContentType.game,
        subjectCode: 'math',
        ageGroup: 'junior',
        difficulty: 2,
        offlineDownloaded: true,
      );

      final result = const RecommendationEngine().getRecommendations(
        childProfileId: 'child-1',
        masteries: {
          'math.addition.basic': const MasteryState(
            childId: 'child-1',
            skillId: 'math.addition.basic',
            masteryScore: 0.2,
          ),
        },
        availableContent: [content],
        remainingMinutes: 10,
        offlineMode: true,
      );

      expect(result.engineVersion, 'recommendation-rule-v1');
      expect(result.recommendations, hasLength(1));
      expect(result.recommendations.first.reasonCodes, isNotEmpty);
      expect(result.totalEstimatedMinutes, greaterThan(0));
    },
  );

  test('session planner handles nullable recommendation minutes safely', () {
    const recommendation = Recommendation(
      recommendationId: 'rec-1',
      childProfileId: 'child-1',
      type: RecommendationType.review,
      targetId: 'skill-1',
      priority: RecommendationPriority.review,
      score: 0.5,
      confidence: 0.5,
      reasonCodes: ['REVIEW_DUE'],
      engineVersion: 'recommendation-rule-v1',
    );

    final plan = const SessionPlanner().planSession(
      availableRecommendations: const [recommendation],
      remainingMinutes: 10,
      offlineMode: true,
    );

    expect(plan.engineVersion, 'session-planner-v1');
    expect(plan.estimatedMinutes, lessThanOrEqualTo(10));
  });
}
