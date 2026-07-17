/// MI Academy — Recommendation Core
///
/// Deterministic offline-first recommendation engine.
///
/// Features:
/// - Prerequisite-aware content selection
/// - Reason codes for every recommendation
/// - Subject diversity enforcement
/// - Session length compliance
/// - Offline availability filtering
/// - Parent time limit respect
/// - Full offline fallback
library recommendation_core;

export 'src/recommendation_types.dart';
export 'src/recommendation_engine.dart';
export 'src/session_planner.dart';
export 'src/prerequisite_checker.dart';
