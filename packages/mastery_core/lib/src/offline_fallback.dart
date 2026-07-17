import 'package:mastery_core/mastery_core.dart';
import 'package:recommendation_core/recommendation_core.dart';

/// Offline fallback — child is never blocked from learning.
class OfflineFallbackEngine {
  const OfflineFallbackEngine();

  RecommendationResult getFallbackRecommendations({
    required String childProfileId,
    required Map<String, MasteryState> masteries,
    required List<ContentItem> availableContent,
    required int remainingMinutes,
  }) {
    final candidates = availableContent.where((c) =>
        c.offlineDownloaded && c.isPublished &&
        c.qualityWarnings.isEmpty &&
        c.estimatedMinutes <= remainingMinutes).toList();

    if (candidates.isEmpty) {
      return RecommendationResult(
        recommendations: const [],
        engineVersion: 'offline-fallback-v1',
        offlineMode: true,
        usedFallback: true,
        fallbackReason: 'NO_OFFLINE_CONTENT',
      );
    }

    final recs = <Recommendation>[];

    // P1: spaced repetition due
    final dueIds = masteries.values
        .where((m) =>
            m.nextReviewAt != null &&
            m.nextReviewAt!.isBefore(DateTime.now()))
        .map((m) => m.skillId).toSet();
    final review = candidates
        .where((c) => c.skillIds.any((s) => dueIds.contains(s))).toList();
    for (final c in review.take(2)) {
      recs.add(_makeRec(
        childProfileId, c, RecommendationType.review,
        RecommendationPriority.review, 0.9, 0.8,
        const ['REVIEW_DUE', 'OFFLINE_FALLBACK'],
      ));
    }

    // P2: recently practiced
    final recent = masteries.values
        .where((m) => m.lastPracticedAt != null).toList()
      ..sort((a, b) =>
          b.lastPracticedAt!.compareTo(a.lastPracticedAt!));
    final recentIds = recent.take(5).map((m) => m.skillId).toSet();
    final practice = candidates
        .where((c) =>
            c.skillIds.any((s) => recentIds.contains(s)) &&
            !review.contains(c)).toList();
    for (final c in practice.take(2)) {
      recs.add(_makeRec(
        childProfileId, c, RecommendationType.review,
        RecommendationPriority.newContent, 0.7, 0.6,
        const ['RECENTLY_PRACTICED', 'OFFLINE_FALLBACK'],
      ));
    }

    // P3: any approved
    if (recs.length < 3) {
      final any = candidates
          .where((c) =>
              !recs.any((r) => r.targetId == c.id))
          .take(3 - recs.length).toList();
      for (final c in any) {
        recs.add(_makeRec(
          childProfileId, c, RecommendationType.game,
          RecommendationPriority.enrichment, 0.5, 0.3,
          const ['OFFLINE_FALLBACK', 'AVAILABLE_CONTENT'],
        ));
      }
    }

    return RecommendationResult(
      recommendations: recs,
      engineVersion: 'offline-fallback-v1',
      offlineMode: true,
      usedFallback: true,
      fallbackReason: 'AI_SERVICE_UNAVAILABLE',
    );
  }

  Recommendation _makeRec(
    String childId,
    ContentItem c,
    RecommendationType type,
    RecommendationPriority priority,
    double score,
    double confidence,
    List<String> reasons,
  ) {
    return Recommendation(
      recommendationId: 'fb-${c.id}',
      childProfileId: childId,
      type: type,
      targetId: c.id,
      priority: priority,
      score: score,
      confidence: confidence,
      reasonCodes: reasons,
      engineVersion: 'offline-fallback-v1',
      offlineAvailable: true,
    );
  }

  MasteryResult getFallbackMasteryUpdate({
    required MasteryState currentState,
    required AttemptEvidence attempt,
  }) {
    const engine = MasteryEngine();
    return engine.evaluate(currentState: currentState, attempt: attempt);
  }
}
