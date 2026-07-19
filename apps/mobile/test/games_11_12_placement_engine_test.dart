import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_engines/mi_game_engines.dart';

const _placementGames = {'shape_builder': 45, 'word_sorter': 60};

void main() {
  for (final entry in _placementGames.entries) {
    final gameId = entry.key;
    final expectedLevels = entry.value;

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

      test('all localized levels parse through public placement barrel', () {
        expect(levels, hasLength(expectedLevels));
        for (final level in levels) {
          for (final locale in const ['en', 'vi']) {
            final content = PlacementContent.fromJson(
              _rawPlacementContent(level, locale),
            );

            expect(content.gameId, gameId);
            expect(content.locale, locale);
            expect(content.items, isNotEmpty);
            expect(content.targets, isNotEmpty);
          }
        }
      });

      test('all localized levels complete with authored placements', () {
        for (final level in levels) {
          for (final locale in const ['en', 'vi']) {
            final content = PlacementContent.fromJson(
              _rawPlacementContent(level, locale),
            );
            final controller = PlacementController(content: content);

            for (final item in content.items) {
              final targetId = content.acceptableTargetIdsFor(item).first;
              controller.placeItem(item.id, targetId);
            }

            expect(controller.isComplete, isTrue);
            expect(controller.result.completed, isTrue);
            expect(controller.result.incorrectCount, 0);
          }
        }
      });

      test('locale payloads keep stable rule ids and localized prompts', () {
        for (final level in levels) {
          final localized = level['localizedContent'] as Map<String, dynamic>;
          final en = localized['en'] as Map<String, dynamic>;
          final vi = localized['vi'] as Map<String, dynamic>;

          expect(en['prompt'], isNot(vi['prompt']));
          expect(_ids(en['items'] as List), _ids(vi['items'] as List));
          expect(_ids(en['targets'] as List), _ids(vi['targets'] as List));
          expect(
            _acceptedTargets(en['items'] as List),
            _acceptedTargets(vi['items'] as List),
          );
        }
      });
    });
  }
}

Map<String, dynamic> _rawPlacementContent(
  Map<String, dynamic> level,
  String locale,
) {
  final localized = level['localizedContent'] as Map<String, dynamic>;
  final content = localized[locale] as Map<String, dynamic>;
  final metadata = level['metadata'] as Map<String, dynamic>? ?? {};
  return {
    ...content,
    'contentId': level['id'],
    'gameId': level['gameId'],
    'locale': locale,
    'ageBand': metadata['ageGroup'] ?? 'junior',
    'difficulty': level['difficulty'],
    'instruction': content['instruction'] ?? content['prompt'],
    'estimatedSeconds': level['estimatedSeconds'] ?? 60,
    'schemaVersion': '1.0',
  };
}

List<String?> _ids(List values) =>
    values.map((value) => (value as Map)['id'] as String?).toList();

List<List<String>> _acceptedTargets(List values) => [
      for (final value in values)
        [
          for (final targetId
              in ((value as Map)['acceptedTargetIds'] as List? ?? []))
            targetId as String,
        ],
    ];
