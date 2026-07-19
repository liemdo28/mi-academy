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
    final file = File('assets/levels/shape_builder.json');
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    levels = (data['levels'] as List)
        .map((level) => Map<String, dynamic>.from(level as Map))
        .toList();
  });

  test('canonical game ID', () {
    expect(levels.every((l) => l['gameId'] == 'shape_builder'), isTrue);
  });

  test('engine mapping metadata declares placement', () {
    expect(
      levels.every((l) => (l['metadata'] as Map)['engineId'] == 'placement'),
      isTrue,
    );
  });

  test('minimum level count (45)', () {
    expect(levels.length, greaterThanOrEqualTo(45));
  });

  test('three real difficulty tiers', () {
    expect(levels.map((l) => l['difficulty']).toSet(), {1, 3, 5});
    final byTier = <int, int>{};
    for (final l in levels) {
      final tier = (l['metadata'] as Map)['tier'] as int;
      byTier[tier] = (byTier[tier] ?? 0) + 1;
    }
    expect(byTier[1], greaterThanOrEqualTo(15));
    expect(byTier[2], greaterThanOrEqualTo(15));
    expect(byTier[3], greaterThanOrEqualTo(15));
  });

  test('English and Vietnamese content exist for every level', () {
    for (final l in levels) {
      final localized = l['localizedContent'] as Map<String, dynamic>;
      expect(localized.keys, containsAll(['vi', 'en']));
    }
  });

  test('unique level IDs and unique item/target IDs within each level', () {
    final levelIds = levels.map((l) => l['id']).toSet();
    expect(levelIds.length, levels.length, reason: 'duplicate level id');

    for (final l in levels) {
      for (final locale in ['vi', 'en']) {
        final content = (l['localizedContent'] as Map)[locale] as Map;
        final itemIds = (content['items'] as List)
            .map((i) => (i as Map)['id'])
            .toSet();
        final targetIds = (content['targets'] as List)
            .map((t) => (t as Map)['id'])
            .toSet();
        expect(itemIds.length, (content['items'] as List).length,
            reason: '${l['id']} $locale has duplicate item ids');
        expect(targetIds.length, (content['targets'] as List).length,
            reason: '${l['id']} $locale has duplicate target ids');
      }
    }
  });

  test('every level parses as valid PlacementContent and every item is placeable', () {
    for (final raw in levels) {
      final level = _levelFrom(raw);
      for (final locale in ['vi', 'en']) {
        final content =
            PlacementContent.fromJson(buildPlacementRawContent(level, locale));
        for (final item in content.items) {
          expect(
            content.acceptableTargetIdsFor(item),
            isNotEmpty,
            reason: '${level.id} $locale item ${item.id} has no valid target',
          );
        }
      }
    }
  });

  test('completion is reachable for every level (controller can complete it)', () {
    for (final raw in levels) {
      final level = _levelFrom(raw);
      final content =
          PlacementContent.fromJson(buildPlacementRawContent(level, 'vi'));
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
    // Full seed-to-output reproducibility is verified at generation time
    // (tools/content_generators/shape_builder_generator.py's own
    // independent-validation pass, plus re-running --write and diffing
    // is a zero-byte-diff no-op) -- this test asserts the committed
    // artifact's own claim of determinism (one fixed seed value stamped
    // on every generated level) rather than re-invoking Python from
    // inside a Flutter test run.
    final seeds =
        levels.map((l) => (l['metadata'] as Map)['generatorSeed']).toSet();
    expect(seeds, hasLength(1), reason: 'all levels should share one seed');
  });
}
