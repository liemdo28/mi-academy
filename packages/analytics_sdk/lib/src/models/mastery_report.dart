import 'package:json_annotation/json_annotation.dart';

part 'mastery_report.g.dart';

/// Mastery report — skill mastery levels for a child.
/// Contract ID: mi.analytics.mastery_report, schemaVersion: 1
@JsonSerializable()
class MasteryReport {
  static const int schemaVersion = 1;

  final String childProfileId;
  final DateTime generatedAt;
  final Map<String, SkillMastery> skills;
  final double overallMastery;
  final List<String> recommendedNext;

  const MasteryReport({
    required this.childProfileId,
    required this.generatedAt,
    this.skills = const {},
    this.overallMastery = 0.0,
    this.recommendedNext = const [],
  });

  factory MasteryReport.fromJson(Map<String, dynamic> json) =>
      _$MasteryReportFromJson(json);

  Map<String, dynamic> toJson() => _$MasteryReportToJson(this);

  List<String> validate() {
    final errors = <String>[];
    if (childProfileId.isEmpty) errors.add('childProfileId is required');
    if (overallMastery < 0 || overallMastery > 1.0) {
      errors.add('overallMastery must be 0-1');
    }
    return errors;
  }
}

@JsonSerializable()
class SkillMastery {
  final String skillId;
  final double level;
  final int totalAttempts;
  final int successfulAttempts;
  final double trend; // -1 declining, 0 stable, 1 improving

  const SkillMastery({
    required this.skillId,
    this.level = 0.0,
    this.totalAttempts = 0,
    this.successfulAttempts = 0,
    this.trend = 0.0,
  });

  factory SkillMastery.fromJson(Map<String, dynamic> json) =>
      _$SkillMasteryFromJson(json);

  Map<String, dynamic> toJson() => _$SkillMasteryToJson(this);

  String get classification {
    if (level >= 0.8) return 'mastered';
    if (level >= 0.6) return 'proficient';
    if (level >= 0.3) return 'developing';
    return 'emerging';
  }
}
