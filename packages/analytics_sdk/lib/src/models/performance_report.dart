import 'package:json_annotation/json_annotation.dart';

part 'performance_report.g.dart';

/// Aggregated performance report for a child over a time period.
@JsonSerializable(explicitToJson: true)
class PerformanceReport {
  final String reportId;
  final String childProfileId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String periodType; // daily, weekly, monthly
  final List<SkillPerformance> skills;
  final double overallAccuracy;
  final double overallMastery;
  final int totalStudyTimeMinutes;
  final int totalGamesPlayed;
  final int totalLessonsCompleted;
  final int streakDays;
  final Map<String, dynamic>? metadata;

  static const String currentSchemaVersion = '1.0.0';
  static const validPeriodTypes = ['daily', 'weekly', 'monthly'];

  PerformanceReport({
    required this.reportId,
    required this.childProfileId,
    required this.periodStart,
    required this.periodEnd,
    required this.periodType,
    this.skills = const [],
    this.overallAccuracy = 0.0,
    this.overallMastery = 0.0,
    this.totalStudyTimeMinutes = 0,
    this.totalGamesPlayed = 0,
    this.totalLessonsCompleted = 0,
    this.streakDays = 0,
    this.metadata,
  });

  factory PerformanceReport.fromJson(Map<String, dynamic> json) =>
      _$PerformanceReportFromJson(json);
  Map<String, dynamic> toJson() => _$PerformanceReportToJson(this);

  /// Skills sorted by mastery level (lowest first — areas needing attention).
  List<SkillPerformance> get skillsNeedingAttention =>
      List.of(skills)..sort((a, b) => a.masteryLevel.compareTo(b.masteryLevel));

  /// Skills where mastery is above threshold (0.8).
  List<SkillPerformance> get masteredSkills =>
      skills.where((s) => s.masteryLevel >= 0.8).toList();

  /// Top 3 strongest skills.
  List<SkillPerformance> get topSkills =>
      List.of(skills)..sort((a, b) => b.masteryLevel.compareTo(a.masteryLevel));

  List<String> validate() {
    final errors = <String>[];
    if (reportId.isEmpty) errors.add('reportId required');
    if (childProfileId.isEmpty) errors.add('childProfileId required');
    if (!validPeriodTypes.contains(periodType)) {
      errors.add('periodType must be: ${validPeriodTypes.join(', ')}');
    }
    if (periodEnd.isBefore(periodStart)) {
      errors.add('periodEnd must be >= periodStart');
    }
    return errors;
  }
}

/// Performance metrics for a single skill.
@JsonSerializable(explicitToJson: true)
class SkillPerformance {
  final String skillId;
  final String skillName;
  final double accuracy;
  final double masteryLevel; // 0.0-1.0
  final int attemptsTotal;
  final int attemptsCorrect;
  final DateTime lastPracticed;
  final String? trend; // improving, stable, declining
  final int? recommendedPracticeMinutes;

  SkillPerformance({
    required this.skillId,
    required this.skillName,
    required this.accuracy,
    required this.masteryLevel,
    required this.attemptsTotal,
    required this.attemptsCorrect,
    required this.lastPracticed,
    this.trend,
    this.recommendedPracticeMinutes,
  });

  factory SkillPerformance.fromJson(Map<String, dynamic> json) =>
      _$SkillPerformanceFromJson(json);
  Map<String, dynamic> toJson() => _$SkillPerformanceToJson(this);

  bool get needsPractice => masteryLevel < 0.6;
  bool get isMastered => masteryLevel >= 0.8;
}
