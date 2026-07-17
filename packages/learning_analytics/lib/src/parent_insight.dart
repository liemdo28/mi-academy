import 'package:equatable/equatable.dart';

/// Parent-facing learning insight.
///
/// Per blueprint §17: Short, friendly, neutral language only.
/// Never: "below average", "slow", "failed", "needs to study more than other children".
class ParentInsight extends Equatable {
  const ParentInsight({
    required this.insightId,
    required this.childId,
    required this.insightType,
    required this.title,
    required this.summary,
    this.recommendedAction,
    this.skillId,
    this.generatedAt,
    this.language = 'vi',
  });

  final String insightId;
  final String childId;
  final ParentInsightType insightType;
  final LocalizedText title;
  final LocalizedText summary;
  final RecommendedAction? recommendedAction;
  final String? skillId;
  final DateTime generatedAt;
  final String language;

  @override
  List<Object?> get props => [
        insightId,
        childId,
        insightType,
        title,
        summary,
        recommendedAction,
        skillId,
        generatedAt,
        language,
      ];
}

class LocalizedText extends Equatable {
  const LocalizedText({required this.vi, required this.en});
  final String vi;
  final String en;

  String get(String language) => language == 'en' ? en : vi;

  @override
  List<Object?> get props => [vi, en];
}

class RecommendedAction extends Equatable {
  const RecommendedAction({
    required this.activityVi,
    required this.activityEn,
    this.gameId,
    this.levelId,
  });
  final String activityVi;
  final String activityEn;
  final String? gameId;
  final String? levelId;

  String activity(String language) => language == 'en' ? activityEn : activityVi;

  @override
  List<Object?> get props => [activityVi, activityEn, gameId, levelId];
}

enum ParentInsightType {
  practiceSuggestion,
  masteryProgress,
  newSkillDiscovered,
  reviewReminder,
  engagementNote,
  subjectBalance,
  difficultyNote,
}
