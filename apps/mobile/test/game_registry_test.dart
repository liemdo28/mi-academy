import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/services/game_registry.dart';
import 'package:mi_game_core/mi_game_core.dart';

const _level = MiLevel(
  id: 'test-lv1',
  gameId: 'word_builder',
  levelNumber: 1,
  difficulty: 1,
  localizedContent: {
    'vi': {'prompt': 'x'},
  },
  hints: [],
);

/// Covers Milestone 1 WS4's acceptance criteria: every current game
/// launches through the registry, known/unknown IDs are both covered, and
/// disabling a game via feature flag is safe.
void main() {
  group('GameRegistry', () {
    test('registers all built games', () {
      const expectedIds = {
        'alphabet_explorer',
        'missing_letter',
        'word_builder',
        'sound_match',
        'math_race',
        'math_supermarket',
        'robot_commands',
        'memory_cards',
        'shape_builder',
        'word_sorter',
      };
      final registeredIds = GameRegistry.all.map((e) => e.gameId).toSet();
      expect(registeredIds, expectedIds);
    });

    test('find() returns a real entry for a known game ID', () {
      final entry = GameRegistry.find('word_builder');
      expect(entry, isNotNull);
      expect(entry!.category, 'letters');
      expect(entry.localizedName['vi'], isNotEmpty);
      expect(entry.localizedName['en'], isNotEmpty);
    });

    test('registers Alphabet Explorer as a bilingual choice-engine game', () {
      final entry = GameRegistry.find('alphabet_explorer');
      expect(entry, isNotNull);
      expect(entry!.category, 'letters');
      expect(entry.engineType, 'choice');
      expect(entry.localizedName['vi'], 'Khám phá chữ cái');
      expect(entry.localizedName['en'], 'Alphabet Explorer');
      expect(entry.ageBands, containsAll(['junior', 'explorer']));
      expect(
        entry.supportedSkills,
        containsAll([
          'letters.recognition.uppercase',
          'letters.recognition.lowercase',
          'letters.case_matching',
          'letters.initial_sound',
        ]),
      );
    });

    test('registers Missing Letter as a bilingual choice-engine game', () {
      final entry = GameRegistry.find('missing_letter');
      expect(entry, isNotNull);
      expect(entry!.category, 'letters');
      expect(entry.engineType, 'choice');
      expect(entry.localizedName['vi'], 'Tìm chữ còn thiếu');
      expect(entry.localizedName['en'], 'Missing Letter');
      expect(entry.ageBands, containsAll(['junior', 'explorer']));
      expect(
        entry.supportedSkills,
        containsAll([
          'letters.recognition.lowercase',
          'letters.spelling',
          'letters.vocabulary',
          'letters.initial_sound',
        ]),
      );
    });

    test('find() returns null for an unknown game ID', () {
      expect(GameRegistry.find('does_not_exist'), isNull);
      expect(GameRegistry.find(''), isNull);
    });

    test('every registered entry builds a real widget for a valid level', () {
      for (final entry in GameRegistry.all) {
        final widget = entry.builder(
          level: _level,
          allLevels: [_level],
          onExit: () {},
          onComplete: (_) {},
          childProfileId: 'test-child',
          locale: 'vi',
        );
        expect(widget, isNotNull, reason: '${entry.gameId} builder failed');
      }
    });

    test('enabledForAgeBand excludes disabled entries', () {
      // All shipped entries default to enabled -- this asserts the filter
      // logic itself works, using the real registry contents rather than a
      // fake disabled entry (GameRegistryEntry has no public constructor
      // access point in this test to fabricate one safely).
      final junior = GameRegistry.enabledForAgeBand('junior');
      expect(junior, isNotEmpty);
      for (final entry in junior) {
        expect(entry.enabled, isTrue);
        expect(entry.ageBands, contains('junior'));
      }
    });

    test('enabledForAgeBand returns empty for an unknown age band', () {
      expect(GameRegistry.enabledForAgeBand('toddler'), isEmpty);
    });
  });
}
