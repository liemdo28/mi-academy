import 'dart:convert' as convert;

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
  'word_builder': 'assets/levels/word_builder.json',
  'sound_match': 'assets/levels/sound_match.json',
  'math_race': 'assets/levels/math_race.json',
  'math_supermarket': 'assets/levels/math_supermarket.json',
  'memory_cards': 'assets/levels/memory_cards.json',
  'robot_commands': 'assets/levels/robot_commands.json',
  'category_collector': 'assets/levels/category_collector.json',
  'pattern_parade': 'assets/levels/pattern_parade.json',
  'shape_builder': 'assets/levels/shape_builder.json',
  'word_sorter': 'assets/levels/word_sorter.json',
  'number_balance': 'assets/levels/number_balance.json',
  'logic_detective': 'assets/levels/logic_detective.json',
  'story_steps': 'assets/levels/story_steps.json',
};

/// Loads all levels for a single game from its bundled asset.
Future<List<MiLevel>> loadGameLevels(
    BuildContext context, String gameId) async {
  final assetPath = gameLevelAssets[gameId];
  if (assetPath == null) {
    throw ArgumentError('Unknown game id: $gameId');
  }
  final provider = GameContentProvider();
  final assetBundle = DefaultAssetBundle.of(context);
  final json = await assetBundle.loadString(assetPath);
  final data = convert.jsonDecode(json) as Map<String, dynamic>;
  final levelData = (data['levels'] as List)
      .map((level) => Map<String, dynamic>.from(level as Map))
      .toList();
  return provider.loadLevels(levelData, gameId: gameId);
}
