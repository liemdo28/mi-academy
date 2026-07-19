import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_content/mi_game_content.dart';

const _games = {
  'category_collector': ('multi_select', 60),
  'pattern_parade': ('sequence', 60),
  'shape_builder': ('placement', 45),
  'word_sorter': ('placement', 60),
  'number_balance': ('matching', 60),
  'logic_detective': ('multi_select', 45),
  'story_steps': ('sequence', 45),
};

void main() {
  for (final entry in _games.entries) {
    final gameId = entry.key;
    final engine = entry.value.$1;
    final minimum = entry.value.$2;

    group(gameId, () {
      late List<Map<String, dynamic>> levels;

      setUpAll(() {
        final file = File('assets/levels/$gameId.json');
        final data =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        levels = (data['levels'] as List)
            .map((level) => Map<String, dynamic>.from(level as Map))
            .toList();
      });

      test('has bilingual production levels and three tiers', () {
        expect(levels.length, greaterThanOrEqualTo(minimum));
        expect(levels.map((level) => level['gameId']).toSet(), {gameId});
        expect(levels.map((level) => level['difficulty']).toSet(), {1, 3, 5});
        expect(levels.map((level) => level['id']).toSet(),
            hasLength(levels.length));

        for (final level in levels) {
          final localized = level['localizedContent'] as Map<String, dynamic>;
          expect(localized.keys, containsAll(['vi', 'en']));
          expect((level['metadata'] as Map)['reviewStatus'],
              'pending_human_review');
          for (final locale in const ['vi', 'en']) {
            final content = localized[locale] as Map<String, dynamic>;
            expect(content['prompt'], isNotEmpty);
            _expectEnginePayload(engine, content);
          }
        }
      });

      test('loads through the shared content loader', () async {
        final parsed =
            await GameContentProvider().loadLevels(levels, gameId: gameId);
        expect(parsed, hasLength(levels.length));
        expect(parsed.first.gameId, gameId);
        expect(parsed.first.contentForLocale('en')['prompt'], isNotEmpty);
      });
    });
  }
}

void _expectEnginePayload(String engine, Map<String, dynamic> content) {
  switch (engine) {
    case 'multi_select':
      final options = content['options'] as List;
      expect(options.length, greaterThanOrEqualTo(2));
      expect(options.where((option) => (option as Map)['isCorrect'] == true),
          isNotEmpty);
      expect(content['configuration'], isA<Map>());
      break;
    case 'sequence':
      expect(content['correctOrder'], isA<List>());
      expect(content['rule'], isA<Map>());
      expect(content['mode'], isIn(['reorder', 'missingItem']));
      break;
    case 'placement':
      expect(content['items'], isA<List>());
      expect(content['targets'], isA<List>());
      expect(content['configuration'], isA<Map>());
      break;
    case 'matching':
      expect(content['pairs'], isA<List>());
      break;
  }
}
