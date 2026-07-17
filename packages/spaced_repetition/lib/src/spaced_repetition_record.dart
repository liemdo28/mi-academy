import 'package:equatable/equatable.dart';

/// Record of a spaced repetition review event.
class SpacedRepetitionRecord extends Equatable {
  const SpacedRepetitionRecord({
    required this.skillId,
    required this.childId,
    required this.scheduledAt,
    required this.completedAt,
    required this.masteryAtSchedule,
    required this.masteryAtCompletion,
    required this.retained,
    required this.intervalDays,
    required this.reviewNumber,
  });

  final String skillId;
  final String childId;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final double masteryAtSchedule;
  final double masteryAtCompletion;
  final bool retained; // true if score was maintained or improved
  final int intervalDays;
  final int reviewNumber;

  Map<String, dynamic> toJson() => {
        'skillId': skillId,
        'childId': childId,
        'scheduledAt': scheduledAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'masteryAtSchedule': masteryAtSchedule,
        'masteryAtCompletion': masteryAtCompletion,
        'retained': retained,
        'intervalDays': intervalDays,
        'reviewNumber': reviewNumber,
      };

  factory SpacedRepetitionRecord.fromJson(Map<String, dynamic> json) {
    return SpacedRepetitionRecord(
      skillId: json['skillId'] as String,
      childId: json['childId'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      masteryAtSchedule: (json['masteryAtSchedule'] as num).toDouble(),
      masteryAtCompletion: (json['masteryAtCompletion'] as num).toDouble(),
      retained: json['retained'] as bool,
      intervalDays: json['intervalDays'] as int,
      reviewNumber: json['reviewNumber'] as int,
    );
  }

  @override
  List<Object?> get props => [
        skillId,
        childId,
        scheduledAt,
        completedAt,
        masteryAtSchedule,
        masteryAtCompletion,
        retained,
        intervalDays,
        reviewNumber,
      ];
}
