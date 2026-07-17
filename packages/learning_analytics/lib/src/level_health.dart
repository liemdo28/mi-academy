import 'package:equatable/equatable.dart';

/// Level health report for content quality analytics.
///
/// Per blueprint §15: Detects levels with anomalous performance data.
/// Does NOT auto-fix or publish levels. Sends review requests to Dev 3.
class LevelHealth extends Equatable {
  const LevelHealth({
    required this.levelId,
    required this.gameId,
    this.sampleSize = 0,
    this.completionRate,
    this.expectedCompletionRate = 0.78,
    this.medianAttempts,
    this.hintRate,
    this.abandonRate,
    this.medianDurationSeconds,
    this.status = LevelHealthStatus.healthy,
    this.reasonCodes = const [],
    this.reviewRecommended = false,
  });

  final String levelId;
  final String gameId;
  final int sampleSize;
  final double? completionRate;
  final double expectedCompletionRate;
  final double? medianAttempts;
  final double? hintRate;
  final double? abandonRate;
  final double? medianDurationSeconds;
  final LevelHealthStatus status;
  final List<String> reasonCodes;
  final bool reviewRecommended;

  @override
  List<Object?> get props => [
        levelId,
        gameId,
        sampleSize,
        completionRate,
        expectedCompletionRate,
        medianAttempts,
        hintRate,
        abandonRate,
        medianDurationSeconds,
        status,
        reasonCodes,
        reviewRecommended,
      ];

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'gameId': gameId,
        'sampleSize': sampleSize,
        'completionRate': completionRate,
        'expectedCompletionRate': expectedCompletionRate,
        'medianAttempts': medianAttempts,
        'hintRate': hintRate,
        'abandonRate': abandonRate,
        'medianDurationSeconds': medianDurationSeconds,
        'status': status.value,
        'reasonCodes': reasonCodes,
        'reviewRecommended': reviewRecommended,
      };
}

enum LevelHealthStatus {
  healthy,
  needsAttention,
  reviewRequired,
  qualityWarning,
}

extension LevelHealthStatusExtension on LevelHealthStatus {
  String get value {
    switch (this) {
      case LevelHealthStatus.healthy:
        return 'healthy';
      case LevelHealthStatus.needsAttention:
        return 'needs_attention';
      case LevelHealthStatus.reviewRequired:
        return 'review_required';
      case LevelHealthStatus.qualityWarning:
        return 'quality_warning';
    }
  }
}
