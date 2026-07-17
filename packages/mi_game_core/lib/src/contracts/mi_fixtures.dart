part of mi_game_core;

/// Deterministic mock implementation of [MiProgressGateway] for Dev 2.
///
/// Use this when building games without backend connectivity.
/// All operations are thread-safe via zone isolation.
class InMemoryProgressGateway implements MiProgressGateway {
  final Map<String, MiGameResult> _results = {};
  final Map<String, MiGameSnapshot> _snapshots = {};

  String _snapshotKey(String childId, String gameId, String levelId) =>
      '$childId/$gameId/$levelId';

  @override
  Future<void> saveGameResult(MiGameResult result) async {
    _results[result.attemptId] = result;
  }

  @override
  Future<void> saveSnapshot(MiGameSnapshot snapshot) async {
    final key = _snapshotKey(
      snapshot.childProfileId,
      snapshot.gameId,
      snapshot.levelId,
    );
    _snapshots[key] = snapshot;
  }

  @override
  Future<MiGameSnapshot?> loadSnapshot({
    required String childProfileId,
    required String gameId,
    required String levelId,
  }) async {
    final key = _snapshotKey(childProfileId, gameId, levelId);
    return _snapshots[key];
  }

  /// Test helper: get all saved results.
  List<MiGameResult> getAllResults() => _results.values.toList();

  /// Test helper: clear all state.
  void reset() {
    _results.clear();
    _snapshots.clear();
  }
}

// ─── Fixtures for Dev 2 ───────────────────────────────────────────────────────

/// Standard fixtures for game development without backend.
abstract class MiFixtures {
  // ─── Child profile fixtures ──────────────────────────────────────────────

  /// Sample child profile IDs (deterministic).
  static const String childJunior = 'child_junior_001';
  static const String childExplorer = 'child_explorer_001';
  static const String childMaster = 'child_master_001';

  // ─── Game & level fixtures ───────────────────────────────────────────────

  static const List<String> mvpGames = [
    'word_builder',
    'sound_match',
    'math_race',
    'math_supermarket',
    'memory_cards',
    'robot_commands',
  ];

  /// Standard level IDs for MVP games.
  static List<String> levelIdsForGame(String gameId) {
    switch (gameId) {
      case 'word_builder':
        return ['level_1', 'level_2', 'level_3', 'level_4', 'level_5'];
      case 'sound_match':
        return ['level_1', 'level_2', 'level_3', 'level_4', 'level_5'];
      case 'math_race':
        return ['level_1', 'level_2', 'level_3', 'level_4', 'level_5'];
      case 'math_supermarket':
        return ['level_1', 'level_2', 'level_3', 'level_4', 'level_5'];
      case 'memory_cards':
        return ['level_1', 'level_2', 'level_3', 'level_4', 'level_5'];
      case 'robot_commands':
        return ['level_1', 'level_2', 'level_3', 'level_4', 'level_5'];
      default:
        return ['level_1'];
    }
  }

  /// Sample level content for a game (extend per game as needed).
  static Map<String, dynamic> levelContentFixture(
    String gameId,
    String levelId,
  ) {
    return {
      'game_id': gameId,
      'level_id': levelId,
      'version': 1,
      'word_bank': _wordBankForGame(gameId),
      'question_count': 10,
      'time_limit_seconds': 120,
    };
  }

  static List<String> _wordBankForGame(String gameId) {
    switch (gameId) {
      case 'word_builder':
      case 'sound_match':
        return ['mèo', 'cá', 'gà', 'bò', 'heo', 'dê', 'ngựa', 'vịt', 'chim', 'sóc'];
      case 'math_race':
      case 'math_supermarket':
        return ['1+1', '2+3', '5-2', '4+4', '6-1', '7+2', '8-3', '9-0', '5+5', '10-4'];
      case 'memory_cards':
        return ['🐱', '🐶', '🐰', '🐻', '🐼', '🦁', '🐯', '🐮', '🐷', '🐸'];
      case 'robot_commands':
        return ['forward', 'back', 'turn_left', 'turn_right', 'jump', 'pick', 'drop', 'repeat'];
      default:
        return [];
    }
  }

  // ─── Localization fixtures ──────────────────────────────────────────────

  static const Map<String, String> localizationVi = {
    'play': 'Chơi',
    'pause': 'Tạm dừng',
    'resume': 'Tiếp tục',
    'hint': 'Gợi ý',
    'next': 'Tiếp theo',
    'back': 'Quay lại',
    'correct': 'Đúng rồi!',
    'incorrect': 'Chưa đúng, thử lại nhé!',
    'great_job': 'Làm tốt lắm!',
    'try_again': 'Thử lại',
    'level_complete': 'Hoàn thành!',
    'stars_earned': 'Bạn nhận được {count} sao!',
  };

  static const Map<String, String> localizationEn = {
    'play': 'Play',
    'pause': 'Pause',
    'resume': 'Resume',
    'hint': 'Hint',
    'next': 'Next',
    'back': 'Back',
    'correct': 'Correct!',
    'incorrect': 'Not quite, try again!',
    'great_job': 'Great job!',
    'try_again': 'Try again',
    'level_complete': 'Complete!',
    'stars_earned': 'You earned {count} stars!',
  };

  /// Build a [MiGameLaunchRequest] for a given game/level with sensible defaults.
  static MiGameLaunchRequest buildLaunchRequest({
    String childProfileId = childJunior,
    String gameId = 'word_builder',
    String levelId = 'level_1',
    String language = 'vi',
    String ageGroup = 'junior',
    MiAccessibilityPreferences accessibility = const MiAccessibilityPreferences(),
    MiAudioPreferences audioPreferences = const MiAudioPreferences(),
    Map<String, dynamic>? restoredState,
  }) {
    return MiGameLaunchRequest(
      childProfileId: childProfileId,
      gameId: gameId,
      levelId: levelId,
      language: language,
      ageGroup: ageGroup,
      accessibility: accessibility,
      audioPreferences: audioPreferences,
      levelContent: levelContentFixture(gameId, levelId),
      restoredState: restoredState,
    );
  }

  /// Build a sample [MiGameResult].
  static MiGameResult buildGameResult({
    String? attemptId,
    String childProfileId = childJunior,
    String gameId = 'word_builder',
    String levelId = 'level_1',
    int attemptCount = 10,
    int correctCount = 8,
    int incorrectCount = 2,
    int hintCount = 1,
    int durationSeconds = 90,
    bool completed = true,
    double masteryEvidence = 0.8,
    Map<String, dynamic>? skillEvidence,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return MiGameResult(
      attemptId: attemptId ?? 'attempt_${now.millisecondsSinceEpoch}',
      childProfileId: childProfileId,
      gameId: gameId,
      levelId: levelId,
      startedAt: now.subtract(Duration(seconds: durationSeconds)),
      completedAt: now,
      attemptCount: attemptCount,
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      hintCount: hintCount,
      durationSeconds: durationSeconds,
      completed: completed,
      masteryEvidence: masteryEvidence,
      skillEvidence: skillEvidence ?? {'game': gameId, 'level': levelId},
      metadata: metadata ?? const {},
    );
  }

  /// Build a sample [MiGameSnapshot].
  static MiGameSnapshot buildSnapshot({
    String gameId = 'word_builder',
    String levelId = 'level_1',
    String childProfileId = childJunior,
    Map<String, dynamic>? state,
  }) {
    return MiGameSnapshot(
      gameId: gameId,
      levelId: levelId,
      childProfileId: childProfileId,
      createdAt: DateTime.now(),
      state: state ?? {'progress': 0.5, 'current_question': 5},
    );
  }

  // ─── Accessibility fixtures ─────────────────────────────────────────────

  static const MiAccessibilityPreferences accessibilityDefault =
      MiAccessibilityPreferences();
  static const MiAccessibilityPreferences accessibilityHighContrast =
      MiAccessibilityPreferences(highContrast: true);
  static const MiAccessibilityPreferences accessibilityLargeText =
      MiAccessibilityPreferences(largeText: true, fontSize: 1.3);
  static const MiAccessibilityPreferences accessibilityReduceMotion =
      MiAccessibilityPreferences(reduceMotion: true);
  static const MiAccessibilityPreferences accessibilityScreenReader =
      MiAccessibilityPreferences(screenReader: true);

  // ─── Audio preference fixtures ───────────────────────────────────────────

  static const MiAudioPreferences audioDefault = MiAudioPreferences();
  static const MiAudioPreferences audioQuiet =
      MiAudioPreferences(musicVolume: 0.3, sfxVolume: 0.5);
  static const MiAudioPreferences audioMuted = MiAudioPreferences(
    musicVolume: 0.0,
    sfxVolume: 0.0,
  );
  static const MiAudioPreferences audioLoud = MiAudioPreferences(
    musicVolume: 1.0,
    sfxVolume: 1.0,
  );
  static const MiAudioPreferences audioNoSpeech =
      MiAudioPreferences(speechEnabled: false);

  // ─── Age group fixtures ──────────────────────────────────────────────────

  static const List<String> ageGroups = ['junior', 'explorer', 'master'];

  static String ageGroupFromAge(int age) {
    if (age <= 7) return 'junior';
    if (age <= 10) return 'explorer';
    return 'master';
  }
}
