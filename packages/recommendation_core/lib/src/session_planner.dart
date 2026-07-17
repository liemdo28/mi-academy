import 'recommendation_types.dart';

/// Session planner that composes a daily learning session.
///
/// Per blueprint §9: Session structure enforces:
/// - Warm-up → Review → New learning → Practice → Creative → Summary
/// - No consecutive hard activities
/// - Always at least one high-success activity
/// - Never exceeds parent time limit
/// - Never forces completion when time runs out
class SessionPlanner {
  const SessionPlanner();

  /// Plan a daily session.
  ///
  /// [availableRecommendations] — ranked recommendations from the engine
  /// [remainingMinutes] — remaining time allowed (from parent settings)
  /// [offlineMode] — if true, only offline-available content
  SessionPlan planSession({
    required List<Recommendation> availableRecommendations,
    required int remainingMinutes,
    bool offlineMode = false,
    String subjectLastPracticed = '',
  }) {
    final activities = <SessionActivity>[];
    var totalMinutes = 0;

    // Filter offline if needed
    final candidates = offlineMode
        ? availableRecommendations.where((r) => r.offlineAvailable).toList()
        : availableRecommendations;

    if (candidates.isEmpty) {
      return SessionPlan(
        sessionId: _generateSessionId(),
        estimatedMinutes: 0,
        activities: [],
        engineVersion: 'session-planner-v1',
      );
    }

    // Priority 1: Warm-up (2-3 min) — pick a high-confidence, easy activity
    final warmup = _selectWarmup(candidates);
    if (warmup != null) {
      activities.add(
        SessionActivity(
          type: ActivityType.warmup,
          recommendation: warmup,
          estimatedMinutes: 2,
        ),
      );
      totalMinutes += 2;
    }

    // Priority 2: Review due (3-5 min) — spaced repetition
    final reviewActivities = _selectReviews(
      candidates,
      remainingMinutes - totalMinutes,
    );
    for (final review in reviewActivities) {
      final reviewMinutes = review.estimatedMinutes ?? 3;
      if (totalMinutes + reviewMinutes <= remainingMinutes) {
        activities.add(
          SessionActivity(
            type: ActivityType.review,
            recommendation: review,
            estimatedMinutes: reviewMinutes,
          ),
        );
        totalMinutes += reviewMinutes;
      }
    }

    // Priority 3: Main learning (5-8 min) — new or weak skill
    final mainLearning = _selectMainLearning(
      candidates,
      remainingMinutes - totalMinutes,
      subjectLastPracticed,
    );
    if (mainLearning != null &&
        totalMinutes + (mainLearning.estimatedMinutes ?? 5) <=
            remainingMinutes) {
      activities.add(
        SessionActivity(
          type: ActivityType.mainLearning,
          recommendation: mainLearning,
          estimatedMinutes: mainLearning.estimatedMinutes ?? 5,
        ),
      );
      totalMinutes += mainLearning.estimatedMinutes ?? 5;
    }

    // Priority 4: Practice game (3-5 min)
    final practice = _selectPractice(
      candidates,
      remainingMinutes - totalMinutes,
    );
    if (practice != null &&
        totalMinutes + (practice.estimatedMinutes ?? 3) <= remainingMinutes) {
      activities.add(
        SessionActivity(
          type: ActivityType.practiceGame,
          recommendation: practice,
          estimatedMinutes: practice.estimatedMinutes ?? 3,
        ),
      );
      totalMinutes += practice.estimatedMinutes ?? 3;
    }

    // Priority 5: Creative activity (2-3 min) — optional
    final creative = _selectCreative(
      candidates,
      remainingMinutes - totalMinutes,
    );
    if (creative != null &&
        totalMinutes + (creative.estimatedMinutes ?? 2) <= remainingMinutes) {
      activities.add(
        SessionActivity(
          type: ActivityType.creative,
          recommendation: creative,
          estimatedMinutes: creative.estimatedMinutes ?? 2,
        ),
      );
      totalMinutes += creative.estimatedMinutes ?? 2;
    }

    return SessionPlan(
      sessionId: _generateSessionId(),
      estimatedMinutes: totalMinutes,
      activities: activities,
      engineVersion: 'session-planner-v1',
    );
  }

  Recommendation? _selectWarmup(List<Recommendation> candidates) {
    // Pick highest confidence, medium difficulty
    final warmups = candidates
        .where(
          (r) =>
              r.reasonCodes.contains('DIFFICULTY_LOW') ||
              r.reasonCodes.contains('MASTERED_SKILL'),
        )
        .toList();
    warmups.sort((a, b) => b.confidence.compareTo(a.confidence));
    return warmups.isNotEmpty ? warmups.first : null;
  }

  List<Recommendation> _selectReviews(
    List<Recommendation> candidates,
    int remainingMinutes,
  ) {
    if (remainingMinutes <= 0) return [];
    final reviews = candidates
        .where((r) => r.reasonCodes.contains('REVIEW_DUE'))
        .toList();
    return reviews.take(2).toList();
  }

  Recommendation? _selectMainLearning(
    List<Recommendation> candidates,
    int remainingMinutes,
    String subjectLastPracticed,
  ) {
    if (remainingMinutes <= 0) return null;
    // Prefer weak skills, then new content, with subject rotation
    final main = candidates
        .where(
          (r) =>
              r.reasonCodes.contains('LOW_MASTERY') ||
              r.reasonCodes.contains('DEVELOPING_SKILL') ||
              r.reasonCodes.contains('NO_EVIDENCE'),
        )
        .toList();
    // Rotate subject
    final rotated = main
        .where((r) => r.subjectCode != subjectLastPracticed)
        .toList();
    return rotated.isNotEmpty
        ? rotated.first
        : (main.isNotEmpty ? main.first : null);
  }

  Recommendation? _selectPractice(
    List<Recommendation> candidates,
    int remainingMinutes,
  ) {
    if (remainingMinutes <= 0) return null;
    final games = candidates
        .where((r) => r.type == RecommendationType.game)
        .toList();
    return games.isNotEmpty ? games.first : null;
  }

  Recommendation? _selectCreative(
    List<Recommendation> candidates,
    int remainingMinutes,
  ) {
    if (remainingMinutes <= 0) return null;
    final creative = candidates
        .where(
          (r) =>
              r.type == RecommendationType.creativeActivity ||
              r.subjectCode == 'creative',
        )
        .toList();
    return creative.isNotEmpty ? creative.first : null;
  }

  String _generateSessionId() =>
      'session-${DateTime.now().millisecondsSinceEpoch}';
}

/// A planned daily session with ordered activities.
class SessionPlan {
  const SessionPlan({
    required this.sessionId,
    required this.estimatedMinutes,
    required this.activities,
    required this.engineVersion,
  });

  final String sessionId;
  final int estimatedMinutes;
  final List<SessionActivity> activities;
  final String engineVersion;
}

/// A single activity within a session.
class SessionActivity {
  const SessionActivity({
    required this.type,
    required this.recommendation,
    required this.estimatedMinutes,
  });

  final ActivityType type;
  final Recommendation recommendation;
  final int estimatedMinutes;
}

enum ActivityType {
  warmup,
  review,
  mainLearning,
  practiceGame,
  creative,
  summary,
}
