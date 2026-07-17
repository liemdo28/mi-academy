import 'package:json_annotation/json_annotation.dart';

part 'session_summary.g.dart';

/// Summarizes a child's learning session for analytics reporting.
///
/// A session encompasses one or more events within a time window,
/// aggregated for dashboard and reporting purposes.
@JsonSerializable(explicitToJson: true)
class SessionSummary {
  final String sessionId;
  final String childProfileId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int totalEvents;
  final int gamesPlayed;
  final int lessonsViewed;
  final int assessmentsCompleted;
  final double overallAccuracy;
  final Duration totalDuration;
  final Map<String, int> skillsTouched;
  final Map<String, dynamic>? metadata;

  static const String currentSchemaVersion = '1.0.0';

  SessionSummary({
    required this.sessionId,
    required this.childProfileId,
    required this.startedAt,
    required this.endedAt,
    this.totalEvents = 0,
    this.gamesPlayed = 0,
    this.lessonsViewed = 0,
    this.assessmentsCompleted = 0,
    this.overallAccuracy = 0.0,
    Duration? totalDuration,
    this.skillsTouched = const {},
    this.metadata,
  }) : totalDuration = totalDuration ?? Duration.zero;

  factory SessionSummary.fromJson(Map<String, dynamic> json) =>
      _$SessionSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$SessionSummaryToJson(this);

  /// Effective learning duration in minutes.
  double get effectiveDurationMinutes => totalDuration.inMinutes.toDouble();

  /// Engagement score: 0-100 based on activity density and variety.
  double get engagementScore {
    if (totalDuration.inSeconds == 0) return 0.0;
    final activityDensity = totalEvents / totalDuration.inMinutes.clamp(1, 60);
    final varietyBonus = (skillsTouched.length * 5.0).clamp(0, 25);
    final completionBonus =
        ((gamesPlayed + lessonsViewed) * 3.0).clamp(0, 25);
    final raw = (activityDensity * 50).clamp(0, 50) + varietyBonus + completionBonus;
    return raw.clamp(0, 100);
  }

  /// Whether this session meets minimum meaningful activity thresholds.
  bool get isMeaningful =>
      totalDuration.inMinutes >= 5 && totalEvents >= 3;

  List<String> validate() {
    final errors = <String>[];
    if (sessionId.isEmpty) errors.add('sessionId required');
    if (childProfileId.isEmpty) errors.add('childProfileId required');
    if (endedAt.isBefore(startedAt)) {
      errors.add('endedAt must be >= startedAt');
    }
    if (overallAccuracy < 0 || overallAccuracy > 1) {
      errors.add('overallAccuracy must be 0.0-1.0');
    }
    return errors;
  }
}
