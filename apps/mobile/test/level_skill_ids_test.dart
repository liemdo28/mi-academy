import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/src/games/level_skill_ids.dart';
import 'package:mi_game_core/mi_game_core.dart';

const _levelWithSkillIds = MiLevel(
  id: 'wb-lv01',
  gameId: 'word_builder',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {'prompt': 'x'},
  },
  hints: [],
  metadata: {
    'skillIds': ['letters.word_building'],
  },
);

const _levelWithoutMetadata = MiLevel(
  id: 'mc-lv1-001',
  gameId: 'memory_cards',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {'prompt': 'x'},
  },
  hints: [],
);

void main() {
  test('uses the level\'s real authored skillIds when present', () {
    final result = skillIdsFor(
      _levelWithSkillIds,
      fallback: const ['vocabulary'],
    );
    expect(result, ['letters.word_building']);
  });

  test('falls back to the given default when a level has no skillIds', () {
    final result = skillIdsFor(
      _levelWithoutMetadata,
      fallback: const ['vocabulary'],
    );
    expect(result, ['vocabulary']);
  });
}
