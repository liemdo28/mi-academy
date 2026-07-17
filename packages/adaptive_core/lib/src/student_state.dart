import 'package:equatable/equatable.dart';
import 'package:mastery_core/mastery_core.dart';

/// Student state model for a single child.
///
/// Per blueprint §15: Aggregates all mastery states into a holistic
/// student profile. Does NOT label children — only tracks evidence.
/// No IQ, no psychological profile, no fixed traits.
class StudentState extends Equatable {
  const StudentState({
    required this.childId,
    this.masteries = const {},
    this.sessionCount = 0,
    this.totalTimeMinutes = 0,
    this.lastActiveAt,
    this.createdAt,
    this.modelVersion = 'student-state-v1',
  });

  final String childId;
  final Map<String, MasteryState> masteries;
  final int sessionCount;
  final int totalTimeMinutes;
  final DateTime? lastActiveAt;
  final DateTime? createdAt;
  final String modelVersion;

  /// Number of skills with at least one attempt.
  int get practicedSkillCount =>
      masteries.values.where((m) => m.evidenceCount > 0).length;

  /// Number of skills at proficient level or above.
  int get proficientSkillCount => masteries.values
      .where((m) =>
          m.status == MasteryStatus.proficient ||
          m.status == MasteryStatus.mastered)
      .length;

  /// Average mastery across all practiced skills.
  double get averageMastery {
    final practiced = masteries.values
        .where((m) => m.evidenceCount > 0)
        .toList();
    if (practiced.isEmpty) return 0.0;
    return practiced.map((m) => m.masteryScore).reduce((a, b) => a + b) /
        practiced.length;
  }

  /// Skills due for review.
  List<MasteryState> get reviewDueSkills => masteries.values
      .where((m) =>
          m.nextReviewAt != null &&
          m.nextReviewAt!.isBefore(DateTime.now()))
      .toList();

  /// Skills that are not yet started.
  List<String> get notStartedSkills => masteries.entries
      .where((e) => e.value.status == MasteryStatus.notStarted)
      .map((e) => e.key)
      .toList();

  /// Update a single skill mastery.
  StudentState updateMastery(String skillId, MasteryState newMastery) {
    return StudentState(
      childId: childId,
      masteries: {...masteries, skillId: newMastery},
      sessionCount: sessionCount,
      totalTimeMinutes: totalTimeMinutes,
      lastActiveAt: DateTime.now(),
      createdAt: createdAt,
      modelVersion: modelVersion,
    );
  }

  /// Record a completed session.
  StudentState recordSession(int additionalMinutes) {
    return StudentState(
      childId: childId,
      masteries: masteries,
      sessionCount: sessionCount + 1,
      totalTimeMinutes: totalTimeMinutes + additionalMinutes,
      lastActiveAt: DateTime.now(),
      createdAt: createdAt,
      modelVersion: modelVersion,
    );
  }

  /// Average daily session time.
  double get averageDailyMinutes {
    if (sessionCount == 0) return 0.0;
    return totalTimeMinutes / sessionCount.toDouble();
  }

  @override
  List<Object?> get props => [
        childId,
        masteries,
        sessionCount,
        totalTimeMinutes,
        lastActiveAt,
        createdAt,
        modelVersion,
      ];

  Map<String, dynamic> toJson() => {
        'childId': childId,
        'masteries': {for (var k in masteries.keys) k: masteries[k]!.toJson()},
        'sessionCount': sessionCount,
        'totalTimeMinutes': totalTimeMinutes,
        'lastActiveAt': lastActiveAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        'modelVersion': modelVersion,
      };

  factory StudentState.fromJson(Map<String, dynamic> json) {
    final masteriesJson = json['masteries'] as Map<String, dynamic>? ?? {};
    return StudentState(
      childId: json['childId'] as String,
      masteries: masteriesJson.map((k, v) =>
          MapEntry(k, MasteryState.fromJson(v as Map<String, dynamic>))),
      sessionCount: json['sessionCount'] as int? ?? 0,
      totalTimeMinutes: json['totalTimeMinutes'] as int? ?? 0,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      modelVersion: json['modelVersion'] as String? ?? 'student-state-v1',
    );
  }
}
