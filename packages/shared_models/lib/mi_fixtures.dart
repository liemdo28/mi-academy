/// Fixtures for Dev 2 to build games without waiting for backend/data.
///
/// Provides deterministic sample data:
/// - Child profile fixtures
/// - Level fixtures
/// - Localization fixtures
/// - Accessibility fixtures
/// - Audio preference fixtures
/// - Snapshot fixtures
library mi_fixtures;

import 'mi_progress_gateway.dart';
import 'shared_models.dart';

/// Child profile fixtures — no PII, only IDs and preferences.
class MiFixtures {
  // ─── Child profiles ───────────────────────────────────────────────────────
  static const String childId1 = 'child-0001';
  static const String childId2 = 'child-0002';

  static const String gameIdWordBuilder = 'game-word-builder';
  static const String gameIdSoundMatch = 'game-sound-match';

  /// Level content fixture for word builder game.
  static const Map<String, dynamic> levelContentWordBuilder = {
    'words': [
      {'text': 'mèo', 'image': 'assets/cat.png'},
      {'text': 'chó', 'image': 'assets/dog.png'},
      {'text': 'cá', 'image': 'assets/fish.png'},
    ],
    'maxAttempts': 3,
  };

  // ─── Accessibility ────────────────────────────────────────────────────────
  static const defaultAccessibility = AccessibilityPreferences();
  static const highContrastAccessibility = AccessibilityPreferences(
    highContrast: true,
    largeText: true,
    fontSize: 1.3,
  );

  // ─── Audio preferences ────────────────────────────────────────────────────
  static const defaultAudio = AudioPreferences();
  static const silentAudio = AudioPreferences(
    musicVolume: 0.0,
    sfxVolume: 0.0,
    speechEnabled: false,
  );

  // ─── Launch request ───────────────────────────────────────────────────────
  static MiGameLaunchRequest sampleLaunchRequest({String? childId}) =>
      MiGameLaunchRequest(
        childProfileId: childId ?? childId1,
        gameId: gameIdWordBuilder,
        levelId: 'level-01',
        language: 'vi',
        ageGroup: 'explorer',
        accessibility: defaultAccessibility,
        audioPreferences: defaultAudio,
        levelContent: levelContentWordBuilder,
      );

  // ─── Game result ──────────────────────────────────────────────────────────
  static MiGameResult sampleGameResult({String? attemptId, String? childId}) {
    final now = DateTime.now();
    return MiGameResult(
      attemptId: attemptId ?? 'attempt-0001',
      childProfileId: childId ?? childId1,
      gameId: gameIdWordBuilder,
      levelId: 'level-01',
      startedAt: now.subtract(const Duration(minutes: 2)),
      completedAt: now,
      attemptCount: 3,
      correctCount: 3,
      incorrectCount: 0,
      hintCount: 1,
      durationSeconds: 120,
      completed: true,
      masteryEvidence: 0.85,
      skillEvidence: {'letter_recognition': 0.9, 'spelling': 0.8},
    );
  }

  // ─── Snapshot ─────────────────────────────────────────────────────────────
  static MiGameSnapshot sampleSnapshot({String? childId}) =>
      MiGameSnapshot(
        gameId: gameIdWordBuilder,
        levelId: 'level-01',
        childProfileId: childId ?? childId1,
        savedAt: DateTime.now(),
        state: {'currentWordIndex': 2, 'score': 10},
      );

  // ─── Mock gateway ─────────────────────────────────────────────────────────
  static MiProgressGateway freshGateway() => InMemoryProgressGateway();
}
