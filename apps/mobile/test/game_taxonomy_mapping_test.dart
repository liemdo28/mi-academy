import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/services/game_levels.dart';
import 'package:mi_academy/services/game_registry.dart';
import 'package:mi_academy/services/skill_taxonomy_loader.dart';
import 'package:mi_game_content/mi_game_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every registered level resolves to a canonical taxonomy mapping',
      () async {
    final resolver = await loadActivityMappingResolver();

    for (final entry in GameRegistry.all) {
      final levels = await loadGameLevelsFromRootBundle(entry.gameId);
      final descriptor = GameDescriptor(
        gameId: entry.gameId,
        subjectId: entry.category,
        ageBands: entry.ageBands,
      );

      expect(levels, isNotEmpty, reason: entry.gameId);
      for (final level in levels) {
        final result = resolver.resolve(game: descriptor, level: level);
        expect(
          result.mapping,
          isNotNull,
          reason: '${entry.gameId}:${level.id}:${result.errors.join(", ")}',
        );
      }
    }
  });
}
