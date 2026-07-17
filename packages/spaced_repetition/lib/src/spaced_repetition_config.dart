import 'package:equatable/equatable.dart';

/// Configuration for spaced repetition intervals.
///
/// Per blueprint §10: Intervals must be configurable.
class SpacedRepetitionConfig extends Equatable {
  const SpacedRepetitionConfig({
    this.intervals = const SpacedRepetitionIntervals(),
    this.retentionBonus = 0.05,
    this.forgettingCurveDays = 7,
  });

  /// Interval definitions per mastery status.
  final SpacedRepetitionIntervals intervals;

  /// Bonus to next interval when retention is confirmed.
  final double retentionBonus;

  /// Number of days after which forgetting curve applies.
  final int forgettingCurveDays;

  @override
  List<Object?> get props => [intervals, retentionBonus, forgettingCurveDays];

  Map<String, dynamic> toJson() => {
        'intervals': intervals.toJson(),
        'retentionBonus': retentionBonus,
        'forgettingCurveDays': forgettingCurveDays,
      };

  factory SpacedRepetitionConfig.fromJson(Map<String, dynamic> json) {
    final intervalsJson = json['intervals'] as Map<String, dynamic>?;
    return SpacedRepetitionConfig(
      intervals: intervalsJson != null
          ? SpacedRepetitionIntervals.fromJson(intervalsJson)
          : const SpacedRepetitionIntervals(),
      retentionBonus: (json['retentionBonus'] as num?)?.toDouble() ?? 0.05,
      forgettingCurveDays: json['forgettingCurveDays'] as int? ?? 7,
    );
  }

  static const SpacedRepetitionConfig defaultConfig = SpacedRepetitionConfig();
}

/// Interval definitions for each mastery status.
class SpacedRepetitionIntervals extends Equatable {
  const SpacedRepetitionIntervals({
    this.notStarted = 1,
    this.introduced = 2,
    this.developing = 3,
    this.proficient = 7,
    this.mastered = 21,
    this.reviewDue = 1,
  });

  /// Interval in days for each status.
  final int notStarted;
  final int introduced;
  final int developing;
  final int proficient;
  final int mastered;
  final int reviewDue;

  @override
  List<Object?> get props => [
        notStarted,
        introduced,
        developing,
        proficient,
        mastered,
        reviewDue,
      ];

  Map<String, dynamic> toJson() => {
        'notStarted': notStarted,
        'introduced': introduced,
        'developing': developing,
        'proficient': proficient,
        'mastered': mastered,
        'reviewDue': reviewDue,
      };

  factory SpacedRepetitionIntervals.fromJson(Map<String, dynamic> json) {
    return SpacedRepetitionIntervals(
      notStarted: json['notStarted'] as int? ?? 1,
      introduced: json['introduced'] as int? ?? 2,
      developing: json['developing'] as int? ?? 3,
      proficient: json['proficient'] as int? ?? 7,
      mastered: json['mastered'] as int? ?? 21,
      reviewDue: json['reviewDue'] as int? ?? 1,
    );
  }

  int getInterval(String status) {
    switch (status) {
      case 'not_started':
        return notStarted;
      case 'introduced':
        return introduced;
      case 'developing':
        return developing;
      case 'proficient':
        return proficient;
      case 'mastered':
        return mastered;
      case 'review_due':
        return reviewDue;
      default:
        return notStarted;
    }
  }
}
