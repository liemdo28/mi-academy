import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'providers.dart';

/// Active lesson state.
class ActiveLessonState {
  final String? lessonId;
  final Map<String, dynamic>? lesson;
  final bool isLoading;
  final int currentPhaseIndex;
  final bool isComplete;
  final String? error;

  const ActiveLessonState({
    this.lessonId,
    this.lesson,
    this.isLoading = false,
    this.currentPhaseIndex = 0,
    this.isComplete = false,
    this.error,
  });

  ActiveLessonState copyWith({
    String? lessonId,
    Map<String, dynamic>? lesson,
    bool? isLoading,
    int? currentPhaseIndex,
    bool? isComplete,
    String? error,
  }) {
    return ActiveLessonState(
      lessonId: lessonId ?? this.lessonId,
      lesson: lesson ?? this.lesson,
      isLoading: isLoading ?? this.isLoading,
      currentPhaseIndex: currentPhaseIndex ?? this.currentPhaseIndex,
      isComplete: isComplete ?? this.isComplete,
      error: error,
    );
  }

  /// Total phases in the current lesson.
  int get totalPhases {
    if (lesson == null) return 0;
    final phases = lesson!['phases'] as List<dynamic>? ?? [];
    return phases.length;
  }

  /// Current phase data.
  Map<String, dynamic>? get currentPhase {
    if (lesson == null) return null;
    final phases = lesson!['phases'] as List<dynamic>? ?? [];
    if (currentPhaseIndex >= phases.length) return null;
    return phases[currentPhaseIndex] as Map<String, dynamic>?;
  }

  /// Progress as 0.0-1.0.
  double get progress {
    if (totalPhases == 0) return 0.0;
    return (currentPhaseIndex + 1) / totalPhases;
  }
}

class ActiveLessonNotifier extends Notifier<ActiveLessonState> {
  late final ApiService _api;

  @override
  ActiveLessonState build() {
    _api = ref.read(apiServiceProvider);
    return const ActiveLessonState();
  }

  /// Load and start a lesson.
  Future<void> startLesson(String lessonId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.getLesson(lessonId);
      state = state.copyWith(
        lessonId: lessonId,
        lesson: data,
        isLoading: false,
        currentPhaseIndex: 0,
        isComplete: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Advance to the next phase.
  void nextPhase() {
    if (state.isComplete) return;
    final newIndex = state.currentPhaseIndex + 1;
    if (newIndex >= state.totalPhases) {
      state = state.copyWith(isComplete: true, currentPhaseIndex: newIndex);
    } else {
      state = state.copyWith(currentPhaseIndex: newIndex);
    }
  }

  /// Go back to the previous phase.
  void previousPhase() {
    if (state.currentPhaseIndex > 0) {
      state = state.copyWith(
        currentPhaseIndex: state.currentPhaseIndex - 1,
      );
    }
  }

  /// Reset the lesson to start over.
  void reset() {
    state = state.copyWith(
      currentPhaseIndex: 0,
      isComplete: false,
    );
  }

  /// End the lesson.
  void end() {
    state = const ActiveLessonState();
  }
}
