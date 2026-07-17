import 'package:mastery_core/mastery_core.dart';
import 'package:spaced_repetition/spaced_repetition.dart';
import 'parent_insight.dart';

/// Generates parent-facing insights from mastery data.
///
/// Per blueprint §17: Neutral, encouraging language only.
/// Examples of prohibited language:
/// - "Con bạn dưới trung bình"
/// - "Con bạn chậm"
/// - "Con bạn thất bại"
/// - "Cần học nhiều hơn trẻ khác"
class ParentInsightGenerator {
  const ParentInsightGenerator();

  /// Generate weekly insights for a child.
  ///
  /// [masteries] — all skill masteries for the child
  /// [weekStart] — start of the week
  /// [weekEnd] — end of the week
  /// [language] — preferred language for insight text
  List<ParentInsight> generateWeeklyInsights({
    required String childId,
    required Map<String, MasteryState> masteries,
    required DateTime weekStart,
    required DateTime weekEnd,
    String language = 'vi',
  }) {
    final insights = <ParentInsight>[];

    // Skill progress insight
    final practicedSkills = masteries.values
        .where((m) =>
            m.lastPracticedAt != null &&
            m.lastPracticedAt!.isAfter(weekStart) &&
            m.lastPracticedAt!.isBefore(weekEnd))
        .toList();

    if (practicedSkills.isNotEmpty) {
      insights.add(_buildPracticeSummary(
        childId: childId,
        practicedSkills: practicedSkills,
        language: language,
      ));
    }

    // Review due insight
    final dueSkills = masteries.values
        .where((m) => m.nextReviewAt != null && m.nextReviewAt!.isBefore(DateTime.now()))
        .toList();
    if (dueSkills.isNotEmpty) {
      insights.add(_buildReviewReminder(
        childId: childId,
        dueSkills: dueSkills,
        language: language,
      ));
    }

    // New mastery achieved
    final masteredSkills = masteries.values.where((m) => m.status == MasteryStatus.mastered).toList();
    if (masteredSkills.isNotEmpty) {
      insights.add(_buildMasteryProgress(
        childId: childId,
        masteredSkills: masteredSkills,
        language: language,
      ));
    }

    // Subject balance
    final subjectBalance = _analyzeSubjectBalance(masteries);
    if (subjectBalance != null) {
      insights.add(subjectBalance);
    }

    return insights;
  }

  ParentInsight _buildPracticeSummary({
    required String childId,
    required List<MasteryState> practicedSkills,
    required String language,
  }) {
    final skillCount = practicedSkills.length;
    final improvingSkills = practicedSkills.where((m) => m.delta > 0).length;

    return ParentInsight(
      insightId: 'insight-${DateTime.now().millisecondsSinceEpoch}',
      childId: childId,
      insightType: ParentInsightType.practiceSuggestion,
      title: LocalizedText(
        vi: 'Tuần này ${skillCount > 1 ? "các kỹ năng" : "kỹ năng"} được luyện tập',
        en: 'Skills practiced this week',
      ),
      summary: LocalizedText(
        vi: 'Trẻ đã luyện tập $skillCount kỹ năng trong tuần. Có $improvingSkills kỹ năng đang tiến bộ.',
        en: 'The learner practiced $skillCount skills this week. $improvingSkills skills are improving.',
      ),
      generatedAt: DateTime.now(),
      language: language,
    );
  }

  ParentInsight _buildReviewReminder({
    required String childId,
    required List<MasteryState> dueSkills,
    required String language,
  }) {
    return ParentInsight(
      insightId: 'insight-${DateTime.now().millisecondsSinceEpoch}-review',
      childId: childId,
      insightType: ParentInsightType.reviewReminder,
      title: LocalizedText(
        vi: 'Một số kỹ năng có thể cần ôn tập',
        en: 'Some skills may benefit from a review',
      ),
      summary: LocalizedText(
        vi: 'Có ${dueSkills.length} kỹ năng có thể cần ôn lại để giữ vững kiến thức.',
        en: '${dueSkills.length} skills may benefit from a quick review to reinforce learning.',
      ),
      recommendedAction: RecommendedAction(
        activityVi: 'Thử 5 phút ôn tập với game nhẹ nhàng.',
        activityEn: 'Try five minutes of light review with a game.',
      ),
      generatedAt: DateTime.now(),
      language: language,
    );
  }

  ParentInsight _buildMasteryProgress({
    required String childId,
    required List<MasteryState> masteredSkills,
    required String language,
  }) {
    return ParentInsight(
      insightId: 'insight-${DateTime.now().millisecondsSinceEpoch}-mastery',
      childId: childId,
      insightType: ParentInsightType.masteryProgress,
      title: LocalizedText(
        vi: 'Kỹ năng mới thành thạo!',
        en: 'New skills mastered!',
      ),
      summary: LocalizedText(
        vi: 'Trẻ đã thành thạo ${masteredSkills.length} kỹ năng mới. Thật tuyệt vời!',
        en: 'The learner has mastered ${masteredSkills.length} new skills. Wonderful progress!',
      ),
      generatedAt: DateTime.now(),
      language: language,
    );
  }

  ParentInsight? _analyzeSubjectBalance(Map<String, MasteryState> masteries) {
    // Analyze which subjects have been practiced
    final subjectPracticed = <String, int>{};
    for (final m in masteries.values) {
      if (m.evidenceCount > 0) {
        final subject = m.skillId.split('.').first;
        subjectPracticed[subject] = (subjectPracticed[subject] ?? 0) + 1;
      }
    }
    if (subjectPracticed.length <= 1) return null;

    return ParentInsight(
      insightId: 'insight-${DateTime.now().millisecondsSinceEpoch}-balance',
      childId: masteries.values.first.childId,
      insightType: ParentInsightType.subjectBalance,
      title: LocalizedText(
        vi: 'Cân bằng các môn học',
        en: 'Subject balance',
      ),
      summary: LocalizedText(
        vi: 'Trẻ đang học đều các môn. Điều này giúp phát triển toàn diện.',
        en: 'The learner is practicing across subjects. This supports well-rounded development.',
      ),
      generatedAt: DateTime.now(),
      language: 'vi',
    );
  }
}
