import 'package:mi_game_core/mi_game_core.dart';

import 'fake_services.dart';

/// Common test fixtures for game tests.
class TestFixtures {
  TestFixtures._();

  /// Create a test [MiGameContext] with the given overrides.
  static MiGameContext context({
    String childProfileId = 'test-child',
    String language = 'vi',
    String ageGroup = '5-7',
    AccessibilityPreferences? accessibility,
    AudioPreferences? audio,
    MiGameServices? services,
  }) {
    return MiGameContext(
      childProfileId: childProfileId,
      language: language,
      ageGroup: ageGroup,
      accessibility: accessibility ?? const AccessibilityPreferences(),
      audio: audio ?? const AudioPreferences(),
      services: services ?? FakeGameServices().build(),
    );
  }

  /// Create a test [MiLevel].
  static MiLevel level({
    String id = 'test-level-1',
    String gameId = 'test_game',
    int levelNumber = 1,
    int difficulty = 1,
    Map<String, Map<String, dynamic>>? localizedContent,
    List<Map<String, dynamic>>? hints,
  }) {
    return MiLevel(
      id: id,
      gameId: gameId,
      levelNumber: levelNumber,
      difficulty: difficulty,
      localizedContent: localizedContent ??
          {
            'vi': {'prompt': 'Bài kiểm tra'},
            'en': {'prompt': 'Test prompt'},
          },
      hints: hints ??
          [
            {'text': 'Gợi ý 1'},
            {'text': 'Gợi ý 2'},
          ],
    );
  }

  /// Accessibility prefs with all features enabled (for testing a11y paths).
  static AccessibilityPreferences fullAccessibility() {
    return const AccessibilityPreferences(
      textScaleFactor: 1.5,
      highContrast: true,
      reducedMotion: true,
      screenReaderEnabled: true,
      tapAlternativeForDrag: true,
      extendedResponseTime: true,
      colorIndependentFeedback: true,
      subtitlesEnabled: true,
    );
  }
}
