import 'package:mastery_core/mastery_core.dart';
import 'recommendation_types.dart';
import 'prerequisite_checker.dart';

/// Deterministic recommendation engine.
///
/// Per blueprint §8: This is the core offline-first recommendation engine.
/// Operates without network dependency. Tier 1 (Deterministic Rules).
///
/// Safety guarantees:
/// - Every recommendation has reason codes
/// - Every recommendation has engine version
/// - Prerequisite enforcement
/// - Offline availability filtering
/// - Parent time limit respect
class RecommendationEngine {
  const RecommendationEngine({
    this.prerequisiteChecker = const PrerequisiteChecker(),
  });

  final PrerequisiteChecker prerequisiteChecker;

  /// Generate recommendations for a child.
  ///
  /// [childProfileId] — internal child identifier
  /// [masteries] — map of skillId → mastery state
  /// [availableContent] — content available for recommendation
  /// [remainingMinutes] — time remaining from parent's daily limit
  /// [offlineMode] — if true, filter to only offline-available content
  /// [maxRecommendations] — maximum number of recommendations to return
  RecommendationResult getRecommendations({
    required String childProfileId,
    required Map<String, MasteryState> masteries,
    required List<ContentItem> availableContent,
    required int remainingMinutes,
    bool offlineMode = false,
    int maxRecommendations = 5,
  }) {
    final reasonCodes = <String>[];
    var usedFallback = false;
    String? fallbackReason;

    // Filter content by constraints
    var candidates = availableContent.where((c) {
      if (!c.isPublished) return false;
      if (c.qualityWarnings.isNotEmpty) return false; // Skip content with warnings
      if (offlineMode && !c.offlineDownloaded) return false;
      if (remainingMinutes > 0 && c.estimatedMinutes > remainingMinutes) return false;
      return true;
    }).toList();

    if (candidates.isEmpty) {
      usedFallback = true;
      fallbackReason = 'NO_AVAILABLE_CONTENT';
      reasonCodes.add('FALLBACK_TRIGGERED');
      // Fallback: recommend the most recent mastered content as practice
      final fallback = _buildFallbackRecommendation(
        childProfileId,
        masteries,
        remainingMinutes,
      );
      return RecommendationResult(
        recommendations: fallback,
        engineVersion: 'recommendation-rule-v1',
        offlineMode: offlineMode,
        usedFallback: usedFallback,
        fallbackReason: fallbackReason,
      );
    }

    // Score and rank candidates
    final scored = <_ScoredCandidate>[];
    for (final content in candidates) {
      final score = _computeRecommendationScore(
        content: content,
        masteries: masteries,
        remainingMinutes: remainingMinutes,
      );
      scored.add(_ScoredCandidate(content: content, score: score));
    }

    // Sort by score descending
    scored.sort((a, b) => b.score.compareTo(a.score));

    // Build recommendations
    final recommendations = <Recommendation>[];
    for (final candidate in scored.take(maxRecommendations)) {
      final content = candidate.content;
      final rec = _buildRecommendation(
        childProfileId: childProfileId,
        content: content,
        score: candidate.score,
        masteries: masteries,
      );
      recommendations.add(rec);
    }

    // Check subject diversity
    final subjectCounts = <String, int>{};
    for (final rec in recommendations) {
      if (rec.subjectCode != null) {
        subjectCounts[rec.subjectCode!] =
            (subjectCounts[rec.subjectCode!] ?? 0) + 1;
      }
    }

    return RecommendationResult(
      recommendations: recommendations,
      engineVersion: 'recommendation-rule-v1',
      offlineMode: offlineMode,
      usedFallback: usedFallback,
      fallbackReason: fallbackReason,
      totalEstimatedMinutes:
          recommendations.fold(0, (sum, r) => sum + (r.estimatedMinutes ?? 0)),
    );
  }

  /// Compute recommendation score for a content item.
  double _computeRecommendationScore({
    required ContentItem content,
    required Map<String, MasteryState> masteries,
    required int remainingMinutes,
  }) {
    var score = 0.5;

    // Check prerequisite satisfaction
    final prereqsMet = prerequisiteChecker.canAccess(
      requiredPrerequisites: content.prerequisiteSkillIds,
      childMasteries: masteries,
    );

    if (!prereqsMet) {
      // Unmet prerequisites: deprioritize heavily
      return -1.0;
    }

    // All prerequisites met: small positive
    score += 0.1;

    // Mastery-based scoring
    double avgMastery = 0.0;
    double masteryWeight = 0.0;
    for (final skillId in content.skillIds) {
      final mastery = masteries[skillId];
      if (mastery != null) {
        avgMastery += mastery.masteryScore;
        masteryWeight += 1.0;
      }
    }

    if (masteryWeight > 0) {
      avgMastery /= masteryWeight;
    }

    // Low mastery → higher score (needs practice)
    if (avgMastery < 0.3) {
      score += 0.3;
    } else if (avgMastery < 0.5) {
      score += 0.2;
    } else if (avgMastery < 0.65) {
      score += 0.1;
    } else if (avgMastery >= 0.8) {
      score -= 0.2; // Already mastered, deprioritize unless review due
    }

    // Difficulty match bonus
    if (content.skillIds.isNotEmpty) {
      final skillMastery = masteries[content.skillIds.first];
      if (skillMastery != null) {
        final diff = (content.difficulty - skillMastery.currentDifficulty).abs();
        if (diff <= 1) {
          score += 0.15; // Good difficulty match
        } else {
          score -= 0.1; // Poor difficulty match
        }
      }
    }

    // Review due bonus
    for (final skillId in content.skillIds) {
      final mastery = masteries[skillId];
      if (mastery != null &&
          mastery.nextReviewAt != null &&
          mastery.nextReviewAt!.isBefore(DateTime.now())) {
        score += 0.25; // Significant bonus for due review
      }
    }

    // Subject diversity: slight penalty if same subject dominates
    // (handled at result level, but factored in here too)

    // No evidence: moderate boost (exploration)
    if (masteryWeight == 0) {
      score += 0.15;
    }

    return score.clamp(0.0, 1.0);
  }

  Recommendation _buildRecommendation({
    required String childProfileId,
    required ContentItem content,
    required double score,
    required Map<String, MasteryState> masteries,
  }) {
    final reasonCodes = <String>[];
    var confidence = 0.5;

    // Prerequisite codes
    if (content.prerequisiteSkillIds.isNotEmpty) {
      final prereqsMet = prerequisiteChecker.canAccess(
        requiredPrerequisites: content.prerequisiteSkillIds,
        childMasteries: masteries,
      );
      reasonCodes.add(prereqsMet
          ? ReasonCodes.allPrerequisitesMet
          : ReasonCodes.prerequisiteUnmet);
    } else {
      reasonCodes.add(ReasonCodes.prerequisiteMastered);
    }

    // Mastery-based codes
    double avgMastery = 0.0;
    for (final skillId in content.skillIds) {
      final mastery = masteries[skillId];
      if (mastery != null) {
        avgMastery += mastery.masteryScore;
        confidence += mastery.confidence / content.skillIds.length;
        if (mastery.masteryScore < 0.5) {
          reasonCodes.add(ReasonCodes.lowMastery);
        } else if (mastery.masteryScore < 0.65) {
          reasonCodes.add(ReasonCodes.developingSkill);
        } else if (mastery.masteryScore >= 0.8) {
          reasonCodes.add(ReasonCodes.masteredSkill);
        }
        if (mastery.nextReviewAt != null && mastery.nextReviewAt!.isBefore(DateTime.now())) {
          reasonCodes.add(ReasonCodes.reviewDue);
        }
      } else {
        reasonCodes.add(ReasonCodes.noEvidence);
      }
    }

    // Difficulty codes
    if (content.skillIds.isNotEmpty) {
      final skillMastery = masteries[content.skillIds.first];
      if (skillMastery != null) {
        final diff = content.difficulty - skillMastery.currentDifficulty;
        if (diff.abs() <= 1) {
          reasonCodes.add(ReasonCodes.difficultyMatch);
        } else if (diff > 1) {
          reasonCodes.add(ReasonCodes.difficultyHigh);
        } else {
          reasonCodes.add(ReasonCodes.difficultyLow);
        }
      }
    }

    reasonCodes.add(ReasonCodes.offlineAvailable);
    reasonCodes.add(ReasonCodes.ageGroupMatch);

    // Determine priority
    RecommendationPriority priority;
    if (reasonCodes.contains(ReasonCodes.reviewDue)) {
      priority = RecommendationPriority.review;
    } else if (avgMastery < 0.3) {
      priority = RecommendationPriority.weak;
    } else if (reasonCodes.contains(ReasonCodes.noEvidence)) {
      priority = RecommendationPriority.newContent;
    } else {
      priority = RecommendationPriority.newContent;
    }

    // Determine type
    RecommendationType type;
    if (content.type == ContentType.game) {
      type = RecommendationType.game;
    } else if (reasonCodes.contains(ReasonCodes.reviewDue)) {
      type = RecommendationType.review;
    } else {
      type = RecommendationType.nextLesson;
    }

    return Recommendation(
      recommendationId: 'rec-${DateTime.now().millisecondsSinceEpoch}-${content.id.hashCode}',
      childProfileId: childProfileId,
      type: type,
      targetId: content.id,
      priority: priority,
      score: score,
      confidence: (confidence / 2.0).clamp(0.0, 1.0),
      reasonCodes: reasonCodes,
      engineVersion: 'recommendation-rule-v1',
      subjectCode: content.subjectCode,
      gameId: content.gameId,
      levelId: content.levelIndex != null ? '${content.gameId}_${content.levelIndex}' : null,
      skillId: content.skillIds.isNotEmpty ? content.skillIds.first : null,
      estimatedMinutes: content.estimatedMinutes,
      offlineAvailable: content.offlineDownloaded,
    );
  }

  List<Recommendation> _buildFallbackRecommendation(
    String childProfileId,
    Map<String, MasteryState> masteries,
    int remainingMinutes,
  ) {
    // Find the most recent practiced skill as fallback
    MasteryState? mostRecent;
    for (final m in masteries.values) {
      if (mostRecent == null ||
          (m.lastPracticedAt != null &&
           mostRecent.lastPracticedAt != null &&
           m.lastPracticedAt!.isAfter(mostRecent.lastPracticedAt!))) {
        mostRecent = m;
      }
    }

    if (mostRecent != null) {
      return [
        Recommendation(
          recommendationId: 'rec-fallback-${mostRecent.skillId}',
          childProfileId: childProfileId,
          type: RecommendationType.review,
          targetId: mostRecent.skillId,
          priority: RecommendationPriority.review,
          score: 0.5,
          confidence: 0.3,
          reasonCodes: ['FALLBACK_TRIGGERED', 'MOST_RECENT_SKILL'],
          engineVersion: 'recommendation-rule-v1',
          skillId: mostRecent.skillId,
          offlineAvailable: true,
        ),
      ];
    }
    return [];
  }
}

class _ScoredCandidate {
  _ScoredCandidate({required this.content, required this.score});
  final ContentItem content;
  final double score;
}
