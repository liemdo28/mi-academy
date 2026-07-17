/// The 7 phases of a lesson in MI Academy.
///
/// Every lesson follows this sequence:
/// 1. Introduction — warm greeting, set expectations
/// 2. Explanation — teach the concept
/// 3. Example — demonstrate with examples
/// 4. Practice — guided practice
/// 5. Game — interactive game activity
/// 6. Feedback — review and correct
/// 7. Summary — recap what was learned
enum LessonPhaseType {
  introduction,
  explanation,
  example,
  practice,
  game,
  feedback,
  summary,
}

/// A single phase within a lesson.
class LessonPhase {
  final LessonPhaseType type;
  final Map<String, dynamic> content;
  final int? durationSeconds;

  const LessonPhase({
    required this.type,
    required this.content,
    this.durationSeconds,
  });

  /// Display name in Vietnamese.
  String get displayNameVi {
    switch (type) {
      case LessonPhaseType.introduction:
        return 'Giới thiệu';
      case LessonPhaseType.explanation:
        return 'Hướng dẫn';
      case LessonPhaseType.example:
        return 'Ví dụ';
      case LessonPhaseType.practice:
        return 'Luyện tập';
      case LessonPhaseType.game:
        return 'Trò chơi';
      case LessonPhaseType.feedback:
        return 'Nhận xét';
      case LessonPhaseType.summary:
        return 'Tóm tắt';
    }
  }

  /// Display name in English.
  String get displayNameEn {
    switch (type) {
      case LessonPhaseType.introduction:
        return 'Introduction';
      case LessonPhaseType.explanation:
        return 'Explanation';
      case LessonPhaseType.example:
        return 'Example';
      case LessonPhaseType.practice:
        return 'Practice';
      case LessonPhaseType.game:
        return 'Game';
      case LessonPhaseType.feedback:
        return 'Feedback';
      case LessonPhaseType.summary:
        return 'Summary';
    }
  }

  /// Get localized display name.
  String displayName(String language) =>
      language == 'vi' ? displayNameVi : displayNameEn;

  /// Phase index in sequence (0-based).
  int get phaseIndex => LessonPhaseType.values.indexOf(type);

  /// Total phases in a lesson.
  static const int totalPhases = 7;
}

/// Current state of a lesson being played.
class LessonProgressState {
  final int currentPhaseIndex;
  final Map<String, dynamic> phaseData;
  final bool completed;

  const LessonProgressState({
    this.currentPhaseIndex = 0,
    this.phaseData = const {},
    this.completed = false,
  });

  LessonProgressState nextPhase() {
    if (currentPhaseIndex >= LessonPhase.totalPhases - 1) {
      return copyWith(completed: true);
    }
    return LessonProgressState(
      currentPhaseIndex: currentPhaseIndex + 1,
      phaseData: phaseData,
    );
  }

  LessonProgressState previousPhase() {
    if (currentPhaseIndex <= 0) {
      return this;
    }
    return LessonProgressState(
      currentPhaseIndex: currentPhaseIndex - 1,
      phaseData: phaseData,
    );
  }

  double get progress => (currentPhaseIndex + 1) / LessonPhase.totalPhases;

  LessonProgressState copyWith({
    int? currentPhaseIndex,
    Map<String, dynamic>? phaseData,
    bool? completed,
  }) {
    return LessonProgressState(
      currentPhaseIndex: currentPhaseIndex ?? this.currentPhaseIndex,
      phaseData: phaseData ?? this.phaseData,
      completed: completed ?? this.completed,
    );
  }
}
