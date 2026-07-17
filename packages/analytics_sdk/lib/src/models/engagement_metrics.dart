import 'package:json_annotation/json_annotation.dart';

part 'engagement_metrics.g.dart';

/// Engagement metrics capturing how actively a child uses the platform.
@JsonSerializable(explicitToJson: true)
class EngagementMetrics {
  final String childProfileId;
  final DateTime measuredAt;
  final int daysActive; // last 30 days
  final int sessionsCompleted;
  final double averageSessionDurationMinutes;
  final double retentionRate; // 0.0-1.0 over period
  final int streakCurrent;
  final int streakBest;
  final Map<String, int> featureUsage; // feature -> count
  final String? engagementTier; // highly_active, active, moderate, at_risk, inactive

  static const String currentSchemaVersion = '1.0.0';

  EngagementMetrics({
    required this.childProfileId,
    required this.measuredAt,
    this.daysActive = 0,
    this.sessionsCompleted = 0,
    this.averageSessionDurationMinutes = 0.0,
    this.retentionRate = 0.0,
    this.streakCurrent = 0,
    this.streakBest = 0,
    this.featureUsage = const {},
    this.engagementTier,
  });

  factory EngagementMetrics.fromJson(Map<String, dynamic> json) =>
      _$EngagementMetricsFromJson(json);
  Map<String, dynamic> toJson() => _$EngagementMetricsToJson(this);

  /// Computes engagement tier based on activity thresholds.
  String computeTier() {
    if (daysActive >= 20 && retentionRate >= 0.8) return 'highly_active';
    if (daysActive >= 12 && retentionRate >= 0.5) return 'active';
    if (daysActive >= 6) return 'moderate';
    if (daysActive >= 2) return 'at_risk';
    return 'inactive';
  }

  /// Whether the child is at risk of disengagement.
  bool get isAtRisk {
    final tier = engagementTier ?? computeTier();
    return tier == 'at_risk' || tier == 'inactive';
  }

  List<String> validate() {
    final errors = <String>[];
    if (childProfileId.isEmpty) errors.add('childProfileId required');
    if (retentionRate < 0 || retentionRate > 1) {
      errors.add('retentionRate must be 0.0-1.0');
    }
    if (averageSessionDurationMinutes < 0) {
      errors.add('averageSessionDurationMinutes must be >= 0');
    }
    return errors;
  }
}
