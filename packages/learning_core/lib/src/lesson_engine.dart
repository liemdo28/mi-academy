import 'lesson_phase.dart';

/// Lesson engine — drives the 7-phase lesson flow.
///
/// Usage:
/// ```dart
/// final engine = LessonEngine();
/// final phase = engine.startLesson(lessonData);
/// engine.nextPhase();
/// engine.previousPhase();
/// ```
class LessonEngine {
  LessonProgressState _state = const LessonProgressState();

  LessonProgressState get state => _state;

  /// Start a lesson from content data.
  LessonPhase startLesson(Map<String, dynamic> lessonData) {
    final phases = _parsePhases(lessonData);
    if (phases.isEmpty) {
      throw ArgumentError('Lesson must have at least one phase');
    }
    _state = const LessonProgressState(currentPhaseIndex: 0);
    return phases.first;
  }

  /// Advance to the next phase. Returns the new phase or null if complete.
  LessonPhase? nextPhase(List<LessonPhase> phases) {
    if (_state.completed) return null;
    _state = _state.nextPhase();
    if (_state.completed) return null;
    return _currentPhase(phases);
  }

  /// Go back to the previous phase.
  LessonPhase? previousPhase(List<LessonPhase> phases) {
    _state = _state.previousPhase();
    return _currentPhase(phases);
  }

  /// Get the current phase data.
  LessonPhase? _currentPhase(List<LessonPhase> phases) {
    if (_state.currentPhaseIndex >= phases.length) return null;
    return phases[_state.currentPhaseIndex];
  }

  /// Parse lesson content JSON into phases.
  List<LessonPhase> _parsePhases(Map<String, dynamic> data) {
    final rawPhases = data['phases'] as List<dynamic>? ?? [];
    return rawPhases.map((p) {
      final phaseMap = p as Map<String, dynamic>;
      final typeStr = phaseMap['type'] as String;
      return LessonPhase(
        type: LessonPhaseType.values.firstWhere(
          (e) => e.name == typeStr,
          orElse: () => LessonPhaseType.introduction,
        ),
        content: phaseMap['content'] as Map<String, dynamic>? ?? {},
        durationSeconds: phaseMap['duration_seconds'] as int?,
      );
    }).toList();
  }

  /// Reset the lesson engine to its initial state.
  void reset() {
    _state = const LessonProgressState();
  }
}
