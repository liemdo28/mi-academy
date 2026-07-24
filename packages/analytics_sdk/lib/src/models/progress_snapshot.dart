import 'package:json_annotation/json_annotation.dart';

part 'progress_snapshot.g.dart';

/// A snapshot of a child's overall progress.
/// Contract: mi.analytics.progress-snapshot / v1
@JsonSerializable(explicitToJson: true)
class ProgressSnapshot {
  final String childProfileId;
  final DateTime measuredAt;
  final Map<String, double> skillMastery;
  final int totalLessonsCompleted;
  final int totalGamesPlayed;
  final double overallAccuracy;
  final int currentStreakDays;
  final String? lastActiveGameId;
  final String? lastActiveLessonId;
  final Map<String, dynamic> metadata;

  const ProgressSnapshot({
    required this.childProfileId,
    required this.measuredAt,
    this.skillMastery = const {},
    this.totalLessonsCompleted = 0,
    this.totalGamesPlayed = 0,
    this.overallAccuracy = 0.0,
    this.currentStreakDays = 0,
    this.lastActiveGameId,
    this.lastActiveLessonId,
    this.metadata = const {},
  });

  factory ProgressSnapshot.fromJson(Map<String, dynamic> json) =>
      _$ProgressSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressSnapshotToJson(this);

  List<String> validate() {
    final errors = <String>[];
    if (childProfileId.isEmpty) errors.add('childProfileId is required');
    if (overallAccuracy < 0.0 || overallAccuracy > 1.0) {
      errors.add('overallAccuracy must be between 0.0 and 1.0');
    }
    for (final entry in skillMastery.entries) {
      if (entry.value < 0.0 || entry.value > 1.0) {
        errors.add('skillMastery.${entry.key} must be between 0.0 and 1.0');
      }
    }
    return errors;
  }

  ProgressSnapshot copyWith({
    String? childProfileId,
    DateTime? measuredAt,
    Map<String, double>? skillMastery,
    int? totalLessonsCompleted,
    int? totalGamesPlayed,
    double? overallAccuracy,
    int? currentStreakDays,
    String? lastActiveGameId,
    String? lastActiveLessonId,
    Map<String, dynamic>? metadata,
  }) {
    return ProgressSnapshot(
      childProfileId: childProfileId ?? this.childProfileId,
      measuredAt: measuredAt ?? this.measuredAt,
      skillMastery: skillMastery ?? this.skillMastery,
      totalLessonsCompleted:
          totalLessonsCompleted ?? this.totalLessonsCompleted,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      overallAccuracy: overallAccuracy ?? this.overallAccuracy,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      lastActiveGameId: lastActiveGameId ?? this.lastActiveGameId,
      lastActiveLessonId: lastActiveLessonId ?? this.lastActiveLessonId,
      metadata: metadata ?? this.metadata,
    );
  }
}
