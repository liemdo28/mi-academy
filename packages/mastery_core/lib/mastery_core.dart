/// MI Academy — Mastery Core
///
/// Rule-based skill mastery engine with confidence, status, and evidence tracking.
///
/// Per blueprint requirements:
/// - Mastery is not just "got one right"
/// - Multiple evidence dimensions: accuracy, independence, difficulty, retention
/// - Confidence distinguishes certain vs. uncertain mastery
/// - Mastery status: not_started/developing/proficient/mastered/review_due
/// - Maximum single-attempt delta enforced
/// - Offline-first: pure computation, no network dependency
library mastery_core;

export 'src/mastery_config.dart';
export 'src/mastery_status.dart';
export 'src/mastery_state.dart';
export 'src/mastery_engine.dart';
export 'src/mastery_result.dart';
