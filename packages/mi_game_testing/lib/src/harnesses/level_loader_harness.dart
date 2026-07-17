import 'package:mi_game_core/mi_game_core.dart';

/// Test harness for verifying level loading across games.
///
/// Provides deterministic level data for testing without depending
/// on content packages.
class LevelLoaderHarness {
  LevelLoaderHarness._();

  /// Generate a test level for any game.
  static Map<String, dynamic> buildLevelContent({
    required String gameId,
    String locale = 'vi',
    Map<String, dynamic>? overrides,
  }) {
    final base = <String, dynamic>{
      'level_id': 'test_level_1',
      'game_id': gameId,
      'language': locale,
      'age_group': '6-8',
      'difficulty': 1,
    };

    // Game-specific defaults
    switch (gameId) {
      case 'memory_cards':
        base['cards'] = [
          {'id': 'a1', 'image': '🍎', 'group': 'A'},
          {'id': 'a2', 'image': '🍎', 'group': 'A'},
          {'id': 'b1', 'image': '🍊', 'group': 'B'},
          {'id': 'b2', 'image': '🍊', 'group': 'B'},
        ];
        break;
      case 'word_builder':
        base['target_word'] = 'mèo';
        base['letters'] = ['m', 'è', 'o'];
        base['distractors'] = ['a', 't'];
        base['hint_image'] = 'cat.png';
        break;
      case 'sound_match':
        base['pairs'] = [
          {'sound': 'meow', 'image': '🐱'},
          {'sound': 'woof', 'image': '🐕'},
        ];
        break;
      case 'math_race':
        base['problems'] = [
          {'expression': '2 + 3', 'answer': 5},
          {'expression': '4 + 1', 'answer': 5},
        ];
        break;
      case 'math_supermarket':
        base['items'] = [
          {'name': 'Sữa', 'price_cents': 25000, 'image': 'milk.png'},
          {'name': 'Bánh', 'price_cents': 15000, 'image': 'bread.png'},
        ];
        base['budget_cents'] = 100000;
        break;
      case 'robot_commands':
        base['grid_size'] = 5;
        base['start_pos'] = {'x': 0, 'y': 0};
        base['goal_pos'] = {'x': 3, 'y': 2};
        base['obstacles'] = [
          {'x': 2, 'y': 1},
        ];
        base['max_steps'] = 10;
        base['commands'] = ['forward', 'left', 'right', 'repeat'];
        break;
    }

    if (overrides != null) {
      base.addAll(overrides);
    }

    return base;
  }

  /// Build a launch request using test level content.
  static MiGameLaunchRequest buildLaunchRequest({
    required String gameId,
    String childProfileId = 'test_child',
    String levelId = 'test_level_1',
    String locale = 'vi',
    String ageGroup = '6-8',
  }) {
    return MiGameLaunchRequest(
      childProfileId: childProfileId,
      gameId: gameId,
      levelId: levelId,
      language: locale,
      ageGroup: ageGroup,
      accessibility: AccessibilityPreferences.defaults,
      audioPreferences: AudioPreferences.defaults,
      levelContent: buildLevelContent(gameId: gameId, locale: locale),
    );
  }
}
