import 'dart:convert' as convert;

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter/widgets.dart';
import 'package:mi_game_content/mi_game_content.dart';
import 'package:mi_game_core/mi_game_core.dart';

/// Local asset path for each MVP game's level pack. Shared by the debug
/// game picker (`main.dart`) and the production game launcher
/// (`screens/game_screen.dart`) so there's one source of truth for where
/// level content lives.
const gameLevelAssets = {
  'alphabet_explorer': 'assets/levels/alphabet_explorer.json',
  'missing_letter': 'assets/levels/missing_letter.json',
  'picture_word_match': 'assets/levels/picture_word_match.json',
  'rhyme_picker': 'assets/levels/rhyme_picker.json',
  'speed_spelling': 'assets/levels/speed_spelling.json',
  'sentence_order': 'assets/levels/sentence_order.json',
  'story_comprehension': 'assets/levels/story_comprehension.json',
  'word_builder': 'assets/levels/word_builder.json',
  'sound_match': 'assets/levels/sound_match.json',
  'object_counting': 'assets/levels/object_counting.json',
  'number_quantity_match': 'assets/levels/number_quantity_match.json',
  'greater_less': 'assets/levels/greater_less.json',
  'math_race': 'assets/levels/math_race.json',
  'number_sequence': 'assets/levels/number_sequence.json',
  'math_supermarket': 'assets/levels/math_supermarket.json',
  'multiplication_adventure': 'assets/levels/multiplication_adventure.json',
  'treasure_division': 'assets/levels/treasure_division.json',
  'clock_time': 'assets/levels/clock_time.json',
  'fun_measurement': 'assets/levels/fun_measurement.json',
  'shape_builder': 'assets/levels/shape_builder.json',
  'visual_fractions': 'assets/levels/visual_fractions.json',
  'memory_cards': 'assets/levels/memory_cards.json',
  'odd_one_out': 'assets/levels/odd_one_out.json',
  'shadow_match': 'assets/levels/shadow_match.json',
  'robot_commands': 'assets/levels/robot_commands.json',
  'logic_maze': 'assets/levels/logic_maze.json',
  'pattern_finder': 'assets/levels/pattern_finder.json',
  'kids_sudoku': 'assets/levels/kids_sudoku.json',
  'reasoning_detective': 'assets/levels/reasoning_detective.json',
  'free_creativity': 'assets/levels/free_creativity.json',
};

/// Loads all levels for a single game from its bundled asset.
Future<List<MiLevel>> loadGameLevels(
    BuildContext context, String gameId) async {
  return _loadGameLevels(gameId, DefaultAssetBundle.of(context));
}

/// Same as [loadGameLevels], for callers with no [BuildContext] to hand
/// (e.g. a Riverpod provider computing the world map's level set) --
/// [rootBundle] is exactly what `DefaultAssetBundle.of(context)` resolves
/// to absent a test override, so this loads the identical real content.
Future<List<MiLevel>> loadGameLevelsFromRootBundle(String gameId) async {
  return _loadGameLevels(gameId, rootBundle);
}

Future<List<MiLevel>> _loadGameLevels(String gameId, AssetBundle bundle) async {
  final assetPath = gameLevelAssets[gameId];
  if (assetPath == null) {
    throw ArgumentError('Unknown game id: $gameId');
  }
  final provider = GameContentProvider();
  final json = await bundle.loadString(assetPath);
  final data = convert.jsonDecode(json) as Map<String, dynamic>;
  final levelData = (data['levels'] as List)
      .map((level) => Map<String, dynamic>.from(level as Map))
      .toList();
  return provider.loadLevels(levelData, gameId: gameId);
}
