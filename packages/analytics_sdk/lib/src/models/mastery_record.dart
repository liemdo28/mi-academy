import 'package:json_annotation/json_annotation.dart';

part 'mastery_record.g.dart';

/// A record of a child's mastery level for a specific skill.
/// Contract: mi.analytics.mastery-record / v1
@JsonSerializable(explicitToJson: true)
class MasteryRecord {
  final String id;
  final String childProfileId;
  final String skillId;
  final double masteryLevel;
  final int totalAttempts;
  final int successfulAttempts;
  final DateTime firstAttemptedAt;
  final DateTime lastAttemptedAt;
  final String? sourceGameId;
  final String? sourceLessonId;

  const MasteryRecord({
    required this.id,
    required this.childProfileId,
    required this.skillId,
    required this.masteryLevel,
    this.totalAttempts = 0,
    this.successfulAttempts = 0,
    required this.firstAttemptedAt,
    required this.lastAttemptedAt,
    this.sourceGameId,
    this.sourceLessonId,
  });

  factory MasteryRecord.fromJson(Map<String, dynamic> json) =>
      _$MasteryRecordFromJson(json);

  Map<String, dynamic> toJson() => _$MasteryRecordToJson(this);

  double get successRate =>
      totalAttempts == 0 ? 0.0 : successfulAttempts / totalAttempts;

  /// Classification based on mastery level.
  String get masteryCategory {
    if (masteryLevel >= 0.9) return 'mastered';
    if (masteryLevel >= 0.7) return 'proficient';
    if (masteryLevel >= 0.4) return 'developing';
    return 'beginning';
  }

  List<String> validate() {
    final errors = <String>[];
    if (id.isEmpty) errors.add('id is required');
    if (childProfileId.isEmpty) errors.add('childProfileId is required');
    if (skillId.isEmpty) errors.add('skillId is required');
    if (masteryLevel < 0.0 || masteryLevel > 1.0) {
      errors.add('masteryLevel must be between 0.0 and 1.0');
    }
    return errors;
  }
}
