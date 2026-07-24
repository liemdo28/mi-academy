import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/services/game_levels.dart';
import 'package:mi_academy/services/game_registry.dart';
import 'package:mi_game_content/mi_game_content.dart';

const _expansionGameIds = {
  'picture_word_match',
  'rhyme_picker',
  'speed_spelling',
  'sentence_order',
  'story_comprehension',
  'object_counting',
  'number_quantity_match',
  'greater_less',
  'number_sequence',
  'multiplication_adventure',
  'treasure_division',
  'clock_time',
  'fun_measurement',
  'shape_builder',
  'visual_fractions',
  'odd_one_out',
  'shadow_match',
  'logic_maze',
  'pattern_finder',
  'kids_sudoku',
  'reasoning_detective',
  'free_creativity',
};

void main() {
  test('all 30 registered games have bundled level assets', () {
    final registeredIds = GameRegistry.all.map((entry) => entry.gameId).toSet();

    expect(registeredIds, hasLength(30));
    expect(gameLevelAssets.keys.toSet(), registeredIds);
  });

  test('all registered game packs meet the bilingual depth bar', () async {
    for (final gameId in gameLevelAssets.keys) {
      final raw = File(gameLevelAssets[gameId]!).readAsStringSync();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final levels = (data['levels'] as List).cast<Map<String, dynamic>>();

      expect(levels.length, greaterThanOrEqualTo(30), reason: gameId);
      expect(
        levels.map((level) => level['difficulty']).toSet().length,
        greaterThanOrEqualTo(3),
        reason: gameId,
      );
      for (final level in levels) {
        final localized = level['localizedContent'] as Map<String, dynamic>;
        expect(localized.keys, containsAll(['vi', 'en']),
            reason: '$gameId:${level['id']}');
      }

      final parsed = await GameContentProvider().loadLevels(
        levels,
        gameId: gameId,
      );
      expect(parsed.length, levels.length, reason: gameId);
    }
  });

  test('choice expansion packs have bilingual level progression', () async {
    for (final gameId in _expansionGameIds) {
      final asset = gameLevelAssets[gameId]!;
      final raw = File(asset).readAsStringSync();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final levels = (data['levels'] as List)
          .map((level) => Map<String, dynamic>.from(level as Map))
          .toList();

      expect(levels, hasLength(30), reason: gameId);
      expect(
        levels.map((level) => level['difficulty']).toSet(),
        {1, 2, 3, 4, 5},
        reason: gameId,
      );

      for (final level in levels) {
        final localized = level['localizedContent'] as Map<String, dynamic>;
        expect(localized.keys, containsAll(['vi', 'en']),
            reason: '$gameId:${level['id']}');
        for (final locale in const ['vi', 'en']) {
          final content = localized[locale] as Map<String, dynamic>;
          final options = content['options'] as List;
          expect(content['prompt'], isNotEmpty,
              reason: '$gameId:${level['id']}:$locale');
          expect(options, hasLength(greaterThanOrEqualTo(3)),
              reason: '$gameId:${level['id']}:$locale');
          expect(
            options.where((option) => (option as Map)['correct'] == true),
            hasLength(1),
            reason: '$gameId:${level['id']}:$locale',
          );
        }
      }

      final parsed = await GameContentProvider().loadLevels(
        levels,
        gameId: gameId,
      );
      expect(parsed, hasLength(30), reason: gameId);
      expect(parsed.first.skillTags, isNotEmpty, reason: gameId);
    }
  });
}
