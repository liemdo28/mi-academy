import 'package:mi_game_core/mi_game_core.dart';

/// Fake game launcher for Dev 1 to build lesson flows.
///
/// Dev 1 uses this to build lesson flows and parent reports
/// WITHOUT needing real game implementations.
class FakeGameLauncher {
  Future<MiGameResult> launch(MiGameLaunchRequest request) async {
    switch (request.resultType) {
      case FakeResultType.success:
        return _successResult(request);
      case FakeResultType.incomplete:
        return _incompleteResult(request);
      case FakeResultType.paused:
        return _pausedResult(request);
      case FakeResultType.restored:
        return _restoredResult(request);
      case FakeResultType.error:
        return _errorResult(request);
      case FakeResultType.hintHeavy:
        return _hintHeavyResult(request);
      case FakeResultType.lowMastery:
        return _lowMasteryResult(request);
      case FakeResultType.highMastery:
        return _highMasteryResult(request);
    }
  }
  Future<MiGameResult> _successResult(MiGameLaunchRequest r) async {
    final startedAt = DateTime.now().subtract(const Duration(seconds: 120));
    final completedAt = DateTime.now();
    return MiGameResult(
      attemptId: 'fake_attempt_success_${r.levelId}',
      childProfileId: r.childProfileId, gameId: r.gameId, levelId: r.levelId,
      startedAt: startedAt, completedAt: completedAt, attemptCount: 10,
      correctCount: 8, incorrectCount: 2, hintCount: 0, durationSeconds: 120,
      completed: true, masteryEvidence: 0.82,
      skillEvidence: {'math': ['addition', 'number_recognition'], 'language': [r.language]},
      metadata: {'session_type': 'success', 'accuracy': 0.8},
    );
  }

  Future<MiGameResult> _incompleteResult(MiGameLaunchRequest r) async {
    final startedAt = DateTime.now().subtract(const Duration(seconds: 45));
    final completedAt = DateTime.now();
    return MiGameResult(
      attemptId: 'fake_attempt_incomplete_${r.levelId}',
      childProfileId: r.childProfileId, gameId: r.gameId, levelId: r.levelId,
      startedAt: startedAt, completedAt: completedAt, attemptCount: 4,
      correctCount: 3, incorrectCount: 1, hintCount: 0, durationSeconds: 45,
      completed: false, masteryEvidence: 0.35,
      skillEvidence: {'math': ['number_recognition'], 'language': [r.language]},
      metadata: {'session_type': 'incomplete', 'accuracy': 0.75, 'exit_reason': 'child_quit'},
    );
  }

  Future<MiGameResult> _pausedResult(MiGameLaunchRequest r) async {
    final startedAt = DateTime.now().subtract(const Duration(seconds: 60));
    final completedAt = DateTime.now();
    return MiGameResult(
      attemptId: 'fake_attempt_paused_${r.levelId}',
      childProfileId: r.childProfileId, gameId: r.gameId, levelId: r.levelId,
      startedAt: startedAt, completedAt: completedAt, attemptCount: 6,
      correctCount: 5, incorrectCount: 1, hintCount: 0, durationSeconds: 60,
      completed: false, masteryEvidence: 0.45,
      skillEvidence: {'math': ['addition'], 'language': [r.language]},
      metadata: {'session_type': 'paused', 'accuracy': 0.83, 'exit_reason': 'paused_and_abandoned'},
    );
  }
  Future<MiGameResult> _restoredResult(MiGameLaunchRequest r) async {
    final startedAt = DateTime.now().subtract(const Duration(seconds: 120));
    final completedAt = DateTime.now();
    return MiGameResult(
      attemptId: 'fake_attempt_restored_${r.levelId}',
      childProfileId: r.childProfileId, gameId: r.gameId, levelId: r.levelId,
      startedAt: startedAt, completedAt: completedAt, attemptCount: 10,
      correctCount: 7, incorrectCount: 3, hintCount: 1, durationSeconds: 120,
      completed: true, masteryEvidence: 0.74,
      skillEvidence: {'math': ['addition', 'subtraction'], 'language': [r.language]},
      metadata: {'session_type': 'restored', 'had_restored_state': true},
    );
  }

  Future<MiGameResult> _errorResult(MiGameLaunchRequest r) async {
    final startedAt = DateTime.now().subtract(const Duration(seconds: 30));
    final completedAt = DateTime.now();
    return MiGameResult(
      attemptId: 'fake_attempt_error_${r.levelId}',
      childProfileId: r.childProfileId, gameId: r.gameId, levelId: r.levelId,
      startedAt: startedAt, completedAt: completedAt, attemptCount: 3,
      correctCount: 2, incorrectCount: 1, hintCount: 0, durationSeconds: 30,
      completed: false, masteryEvidence: 0.15,
      skillEvidence: {'math': [], 'language': [r.language]},
      metadata: {'session_type': 'error', 'error_code': 'asset_missing'},
    );
  }
  Future<MiGameResult> _hintHeavyResult(MiGameLaunchRequest r) async {
    final startedAt = DateTime.now().subtract(const Duration(seconds: 180));
    final completedAt = DateTime.now();
    return MiGameResult(
      attemptId: 'fake_attempt_hint_heavy_${r.levelId}',
      childProfileId: r.childProfileId, gameId: r.gameId, levelId: r.levelId,
      startedAt: startedAt, completedAt: completedAt, attemptCount: 10,
      correctCount: 6, incorrectCount: 4, hintCount: 6, durationSeconds: 180,
      completed: true, masteryEvidence: 0.40,
      skillEvidence: {'math': ['addition'], 'language': [r.language]},
      metadata: {'session_type': 'hint_heavy', 'struggling_detected': true},
    );
  }
  Future<MiGameResult> _lowMasteryResult(MiGameLaunchRequest r) async {
    final startedAt = DateTime.now().subtract(const Duration(seconds: 150));
    final completedAt = DateTime.now();
    return MiGameResult(
      attemptId: 'fake_attempt_low_mastery_${r.levelId}',
      childProfileId: r.childProfileId, gameId: r.gameId, levelId: r.levelId,
      startedAt: startedAt, completedAt: completedAt, attemptCount: 10,
      correctCount: 3, incorrectCount: 7, hintCount: 2, durationSeconds: 150,
      completed: true, masteryEvidence: 0.22,
      skillEvidence: {'math': ['addition'], 'language': [r.language]},
      metadata: {'session_type': 'low_mastery', 'recommended_replay': true},
    );
  }
  Future<MiGameResult> _highMasteryResult(MiGameLaunchRequest r) async {
    final startedAt = DateTime.now().subtract(const Duration(seconds: 90));
    final completedAt = DateTime.now();
    return MiGameResult(
      attemptId: 'fake_attempt_high_mastery_${r.levelId}',
      childProfileId: r.childProfileId, gameId: r.gameId, levelId: r.levelId,
      startedAt: startedAt, completedAt: completedAt, attemptCount: 10,
      correctCount: 10, incorrectCount: 0, hintCount: 0, durationSeconds: 90,
      completed: true, masteryEvidence: 1.0,
      skillEvidence: {'math': ['addition', 'subtraction', 'number_order'], 'language': [r.language]},
      metadata: {'session_type': 'high_mastery', 'perfect_run': true, 'bonus_stars': 3},
    );
  }
}

enum FakeResultType {
  success, incomplete, paused, restored, error, hintHeavy, lowMastery, highMastery,
}

class MiGameLaunchRequest {
  final int schemaVersion;
  final String childProfileId;
  final String gameId;
  final String levelId;
  final String language;
  final String ageGroup;
  final AccessibilityPreferences accessibility;
  final AudioPreferences audioPreferences;
  final Map<String, dynamic> levelContent;
  final Map<String, dynamic>? restoredState;
  final FakeResultType resultType;

  const MiGameLaunchRequest({
    this.schemaVersion = 1,
    required this.childProfileId,
    required this.gameId,
    required this.levelId,
    required this.language,
    required this.ageGroup,
    required this.accessibility,
    required this.audioPreferences,
    required this.levelContent,
    this.restoredState,
    this.resultType = FakeResultType.success,
  });

  MiGameLaunchRequest copyWith({FakeResultType? resultType}) {
    return MiGameLaunchRequest(
      schemaVersion: schemaVersion,
      childProfileId: childProfileId, gameId: gameId,
      levelId: levelId, language: language, ageGroup: ageGroup,
      accessibility: accessibility, audioPreferences: audioPreferences,
      levelContent: levelContent, restoredState: restoredState,
      resultType: resultType ?? this.resultType,
    );
  }
}
