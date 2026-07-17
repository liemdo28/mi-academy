/// MI Academy — Adaptive Core
///
/// Central adaptive learning orchestration: learning paths, hint recommendation,
/// difficulty calibration, student-state modeling.
///
/// Per blueprint:
/// - §9: Learning path generation
/// - §11: Difficulty calibration
/// - §13: Hint recommendation and escalation
/// - §15: Student-state modeling
/// - Offline-first: all core logic is deterministic
library adaptive_core;

export 'src/student_state.dart';
export 'src/learning_path.dart';
export 'src/hint_recommender.dart';
export 'src/difficulty_calibrator.dart';
export 'src/session_composer.dart';
