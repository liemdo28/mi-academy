import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_engines/mi_game_engines.dart';
import 'package:mi_academy/src/games/placement_games/placement_game_adapter.dart';

late List<Map<String, dynamic>> levels;

MiLevel _levelFrom(Map<String, dynamic> raw) => MiLevel(
      id: raw['id'] as String,
      gameId: raw['gameId'] as String,
      levelNumber: raw['levelNumber'] as int,
      difficulty: raw['difficulty'] as int,
      localizedContent: (raw['localizedContent'] as Map).map(
        (k, v) => MapEntry(k as String, (v as Map).cast<String, dynamic>()),
      ),
      hints: (raw['hints'] as List).cast<Map<String, dynamic>>(),
      metadata: (raw['metadata'] as Map).cast<String, dynamic>(),
    );

void main() {
  setUpAll(() {
    final file = File('assets/levels/word_sorter.json');
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    levels = (data['levels'] as List)
        .map((level) => Map<String, dynamic>.from(level as Map))
        .toList();
  });

  test('canonical game ID', () {
    expect(levels.every((l) => l['gameId'] == 'word_sorter'), isTrue);
  });

  test('engine mapping metadata declares placement', () {
    expect(
      levels.every((l) => (l['metadata'] as Map)['engineId'] == 'placement'),
      isTrue,
    );
  });

  test('minimum level count (60)', () {
    expect(levels.length, greaterThanOrEqualTo(60));
  });

  test('three real difficulty tiers', () {
    expect(levels.map((l) => l['difficulty']).toSet(), {1, 3, 5});
    final byTier = <int, int>{};
    for (final l in levels) {
      final tier = (l['metadata'] as Map)['tier'] as int;
      byTier[tier] = (byTier[tier] ?? 0) + 1;
    }
    expect(byTier[1], greaterThanOrEqualTo(20));
    expect(byTier[2], greaterThanOrEqualTo(20));
    expect(byTier[3], greaterThanOrEqualTo(20));
  });

  test('English and Vietnamese content exist for every level, independently authored',
      () {
    for (final l in levels) {
      final localized = l['localizedContent'] as Map<String, dynamic>;
      expect(localized.keys, containsAll(['vi', 'en']));
      final viWords = ((localized['vi'] as Map)['items'] as List)
          .map((i) => (i as Map)['text'])
          .toSet();
      final enWords = ((localized['en'] as Map)['items'] as List)
          .map((i) => (i as Map)['text'])
          .toSet();
      // Independent authoring, not mechanical translation: the two
      // locales' visible word sets must not be identical strings.
      expect(viWords, isNot(equals(enWords)));
    }
  });

  test('no duplicate visible words within one locale/level, no empty groups', () {
    for (final l in levels) {
      for (final locale in ['vi', 'en']) {
        final content = (l['localizedContent'] as Map)[locale] as Map;
        final words =
            (content['items'] as List).map((i) => (i as Map)['text']).toList();
        expect(words.toSet().length, words.length,
            reason: '${l['id']} $locale has a duplicate visible word');

        final targets = (content['targets'] as List).cast<Map>();
        final itemCategories = (content['items'] as List)
            .map((i) => (i as Map)['metadata']['sortCategory'])
            .toSet();
        for (final target in targets) {
          final cat = target['metadata']['sortCategory'];
          expect(itemCategories.contains(cat), isTrue,
              reason: '${l['id']} $locale group $cat has no members');
        }
      }
    }
  });

  test('every level parses as valid PlacementContent and every item has a group', () {
    for (final raw in levels) {
      final level = _levelFrom(raw);
      for (final locale in ['vi', 'en']) {
        final content =
            PlacementContent.fromJson(buildPlacementRawContent(level, locale));
        for (final item in content.items) {
          expect(
            content.acceptableTargetIdsFor(item),
            isNotEmpty,
            reason: '${level.id} $locale item ${item.id} has no valid group',
          );
        }
      }
    }
  });

  test('completion is reachable for every level (controller can complete it)', () {
    for (final raw in levels) {
      final level = _levelFrom(raw);
      final content =
          PlacementContent.fromJson(buildPlacementRawContent(level, 'en'));
      final controller = PlacementController(content: content);
      for (final item in content.items) {
        final targetId = content.acceptableTargetIdsFor(item).first;
        controller.placeItem(item.id, targetId);
      }
      expect(controller.isComplete, isTrue,
          reason: '${level.id} did not complete with its own valid mapping');
    }
  });

  test('deterministic content: every level records the same generator seed', () {
    final seeds =
        levels.map((l) => (l['metadata'] as Map)['generatorSeed']).toSet();
    expect(seeds, hasLength(1), reason: 'all levels should share one seed');
  });
}
