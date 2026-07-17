/// Mastery status enum.
///
/// Per blueprint §6: statuses are educational evidence categories,
/// NOT labels for the child. Never use "bad", "weak", "slow".
enum MasteryStatus {
  /// Skill has not been attempted yet.
  notStarted,

  /// Child has seen the skill but needs more evidence.
  introduced,

  /// Child is actively developing the skill with mixed results.
  developing,

  /// Child demonstrates consistent competence.
  proficient,

  /// Child shows strong, reliable mastery.
  mastered,

  /// Spaced repetition interval has passed; review recommended.
  reviewDue,
}

extension MasteryStatusExtension on MasteryStatus {
  String get value {
    switch (this) {
      case MasteryStatus.notStarted:
        return 'not_started';
      case MasteryStatus.introduced:
        return 'introduced';
      case MasteryStatus.developing:
        return 'developing';
      case MasteryStatus.proficient:
        return 'proficient';
      case MasteryStatus.mastered:
        return 'mastered';
      case MasteryStatus.reviewDue:
        return 'review_due';
    }
  }

  static MasteryStatus fromString(String value) {
    switch (value) {
      case 'not_started':
        return MasteryStatus.notStarted;
      case 'introduced':
        return MasteryStatus.introduced;
      case 'developing':
        return MasteryStatus.developing;
      case 'proficient':
        return MasteryStatus.proficient;
      case 'mastered':
        return MasteryStatus.mastered;
      case 'review_due':
        return MasteryStatus.reviewDue;
      default:
        return MasteryStatus.notStarted;
    }
  }

  /// Human-readable label (for parent-facing insights only).
  String label(String language) {
    switch (this) {
      case MasteryStatus.notStarted:
        return language == 'vi' ? 'Chưa bắt đầu' : 'Not started';
      case MasteryStatus.introduced:
        return language == 'vi' ? 'Đã giới thiệu' : 'Introduced';
      case MasteryStatus.developing:
        return language == 'vi' ? 'Đang phát triển' : 'Developing';
      case MasteryStatus.proficient:
        return language == 'vi' ? 'Thành thạo' : 'Proficient';
      case MasteryStatus.mastered:
        return language == 'vi' ? 'Đã thành thạo' : 'Mastered';
      case MasteryStatus.reviewDue:
        return language == 'vi' ? 'Cần ôn tập' : 'Review due';
    }
  }
}
