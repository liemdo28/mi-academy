import 'package:flutter/material.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';
import 'package:localization/localization.dart';

import '../src/games/choice/choice_game_screen.dart';
import '../src/games/engine_backed/engine_backed_game_screen.dart';
import '../src/games/memory_cards/memory_cards_game.dart';
import '../src/games/memory_cards/memory_cards_screen.dart';
import '../src/games/robot_commands/robot_commands_screen.dart';
import '../src/games/sound_match/sound_match_screen.dart';
import '../src/games/word_builder/word_builder_screen.dart';

/// Everything a caller (GameScreen, the child home/world-map navigation,
/// and parent-facing reporting) needs to launch or describe a game, without
/// each of those call sites keeping its own `switch (gameType)` in sync by
/// hand. Adding a new game means adding one [GameRegistryEntry] here, not
/// editing every screen that currently has a game-type conditional.
class GameRegistryEntry {
  const GameRegistryEntry({
    required this.gameId,
    required this.localizedName,
    required this.category,
    required this.ageBands,
    required this.supportedSkills,
    required this.engineType,
    required this.builder,
    this.enabled = true,
  });

  /// Stable ID -- matches `MiLevel.gameId`, the backend `games.game_type`
  /// column, and existing progress/attempt records. Never change this for
  /// an existing game; it's the join key everything else keys off of.
  final String gameId;

  /// {'vi': ..., 'en': ...} -- keep in sync with packages/localization's
  /// arb files if/when this name moves into real UI chrome (see
  /// docs/release-audit.md RA-05).
  final Map<String, String> localizedName;

  /// One of the subject IDs from docs/skill-taxonomy.md.
  final String category;

  /// Subset of 'junior' | 'explorer' | 'master' (see docs/age-bands.md).
  final List<String> ageBands;

  /// Skill IDs from content/skills/skill_taxonomy.json this game can award
  /// evidence for.
  final List<String> supportedSkills;

  /// Which reusable engine this game is built on (see
  /// docs/game-engine-architecture.md) -- 'choice', 'memory', 'grid_maze',
  /// 'drag_drop', 'listen_choice' for the 6 games that exist today; a
  /// future engine's games register their own value here.
  final String engineType;

  /// Feature flag -- when false, [GameScreen] treats this exactly like an
  /// unknown game ID (safe fallback screen), without removing the entry
  /// or touching any other call site.
  final bool enabled;

  final GameScreenBuilder builder;
}

/// Every parameter a game's launcher screen might need. Not every game
/// uses every field (e.g. only Memory Cards uses [reduceMotion] today),
/// but a single shared signature is what lets [GameRegistry] hold one
/// `builder` per entry instead of a bespoke function type per game.
typedef GameScreenBuilder = Widget Function({
  required MiLevel level,
  required List<MiLevel> allLevels,
  required VoidCallback onExit,
  required void Function(MiCompletionResult) onComplete,
  required String childProfileId,
  MiGameSnapshot? initialSnapshot,
  void Function(MiGameSnapshot)? onSaveSnapshot,
  bool reduceMotion,
  required String locale,
});

/// Central registry for all playable games. See docs/game-catalog.md for
/// the full 30-game target list -- only built games are registered here;
/// not-yet-built games simply don't have entries yet (not stubbed/faked).
abstract final class GameRegistry {
  static const List<String> _canonicalOrder = [
    'word_builder',
    'sound_match',
    'math_race',
    'math_supermarket',
    'robot_commands',
    'memory_cards',
    'alphabet_explorer',
    'missing_letter',
    'category_collector',
    'pattern_parade',
    'shape_builder',
    'word_sorter',
    'number_balance',
    'logic_detective',
    'story_steps',
    'picture_detective',
    'color_builder',
    'animal_homes',
    'daily_routine',
    'healthy_foods',
    'letter_hunt',
    'number_train',
    'emotion_match',
    'puzzle_parts',
    'odd_one_out',
    'opposites',
    'weather_today',
    'memory_journey',
    'category_expert',
    'build_the_story',
  ];

  static final Map<String, GameRegistryEntry> _entries = {
    for (final entry in _buildEntries()) entry.gameId: entry,
  };

  /// Returns null for an unknown (or not-yet-built) game ID -- callers must
  /// handle that as a safe fallback, never assume a lookup succeeds.
  static GameRegistryEntry? find(String gameId) => _entries[gameId];

  static List<GameRegistryEntry> get all {
    final entries = List<GameRegistryEntry>.of(_entries.values)
      ..sort((a, b) => _orderOf(a.gameId).compareTo(_orderOf(b.gameId)));
    return List.unmodifiable(entries);
  }

  static List<GameRegistryEntry> enabledForAgeBand(String ageBand) => all
      .where((entry) => entry.enabled && entry.ageBands.contains(ageBand))
      .toList(growable: false);

  static int _orderOf(String gameId) {
    final index = _canonicalOrder.indexOf(gameId);
    return index < 0 ? _canonicalOrder.length : index;
  }

  static List<GameRegistryEntry> _buildEntries() => [
        GameRegistryEntry(
          gameId: 'alphabet_explorer',
          localizedName: const {
            'vi': MiMobileStrings.m006,
            'en': 'Alphabet Explorer',
          },
          category: 'letters',
          ageBands: const ['junior', 'explorer'],
          supportedSkills: const [
            'letters.recognition.uppercase',
            'letters.recognition.lowercase',
            'letters.case_matching',
            'letters.initial_sound',
            'letters.vocabulary',
          ],
          engineType: 'choice',
          builder: ({
            required level,
            required allLevels,
            required onExit,
            required onComplete,
            required childProfileId,
            initialSnapshot,
            onSaveSnapshot,
            reduceMotion = false,
            required locale,
          }) =>
              ChoiceGameScreen(
            title: locale == 'en' ? 'Alphabet Explorer' : MiMobileStrings.m006,
            worldLabel: locale == 'en'
                ? 'MI explores letters with you.'
                : MiMobileStrings.m019,
            level: level,
            allLevels: allLevels,
            heroIcon: Icons.abc_rounded,
            primaryColor: GameTheme.primary,
            onExit: onExit,
            onComplete: onComplete,
            initialSnapshot: initialSnapshot,
            onSaveSnapshot: onSaveSnapshot,
            locale: locale,
          ),
        ),
        GameRegistryEntry(
          gameId: 'missing_letter',
          localizedName: const {
            'vi': MiMobileStrings.m008,
            'en': 'Missing Letter'
          },
          category: 'letters',
          ageBands: const ['junior', 'explorer'],
          supportedSkills: const [
            'letters.recognition.lowercase',
            'letters.spelling',
            'letters.vocabulary',
            'letters.initial_sound',
          ],
          engineType: 'choice',
          builder: ({
            required level,
            required allLevels,
            required onExit,
            required onComplete,
            required childProfileId,
            initialSnapshot,
            onSaveSnapshot,
            reduceMotion = false,
            required locale,
          }) =>
              ChoiceGameScreen(
            title: locale == 'en' ? 'Missing Letter' : MiMobileStrings.m008,
            worldLabel: locale == 'en'
                ? 'MI looks for the missing letters with you.'
                : MiMobileStrings.m020,
            level: level,
            allLevels: allLevels,
            heroIcon: Icons.edit_note_rounded,
            primaryColor: MiGameColors.secondary,
            onExit: onExit,
            onComplete: onComplete,
            initialSnapshot: initialSnapshot,
            onSaveSnapshot: onSaveSnapshot,
            locale: locale,
          ),
        ),
        GameRegistryEntry(
          gameId: 'word_builder',
          localizedName: const {
            'vi': MiMobileStrings.m010,
            'en': 'Word Builder'
          },
          category: 'letters',
          ageBands: const ['junior', 'explorer'],
          supportedSkills: const ['letters.word_building'],
          engineType: 'drag_drop',
          builder: ({
            required level,
            required allLevels,
            required onExit,
            required onComplete,
            required childProfileId,
            initialSnapshot,
            onSaveSnapshot,
            reduceMotion = false,
            required locale,
          }) =>
              WordBuilderScreen(
            level: level,
            allLevels: allLevels,
            onExit: onExit,
            onComplete: onComplete,
            initialSnapshot: initialSnapshot,
            onSaveSnapshot: onSaveSnapshot,
            locale: locale,
          ),
        ),
        GameRegistryEntry(
          gameId: 'sound_match',
          localizedName: const {
            'vi': MiMobileStrings.m012,
            'en': 'Sound Match'
          },
          category: 'letters',
          ageBands: const ['junior'],
          supportedSkills: const ['letters.initial_sound'],
          engineType: 'listen_choice',
          builder: ({
            required level,
            required allLevels,
            required onExit,
            required onComplete,
            required childProfileId,
            initialSnapshot,
            onSaveSnapshot,
            reduceMotion = false,
            required locale,
          }) =>
              SoundMatchScreen(
            level: level,
            allLevels: allLevels,
            onExit: onExit,
            onComplete: onComplete,
            initialSnapshot: initialSnapshot,
            onSaveSnapshot: onSaveSnapshot,
            locale: locale,
          ),
        ),
        GameRegistryEntry(
          gameId: 'math_race',
          localizedName: const {'vi': MiMobileStrings.m013, 'en': 'Math Race'},
          category: 'math',
          ageBands: const ['junior', 'explorer'],
          supportedSkills: const ['math.addition', 'math.subtraction'],
          engineType: 'choice',
          builder: ({
            required level,
            required allLevels,
            required onExit,
            required onComplete,
            required childProfileId,
            initialSnapshot,
            onSaveSnapshot,
            reduceMotion = false,
            required locale,
          }) =>
              ChoiceGameScreen(
            title: MiMobileStrings.m013,
            worldLabel: MiMobileStrings.m021,
            level: level,
            allLevels: allLevels,
            heroIcon: Icons.directions_car_rounded,
            primaryColor: GameTheme.warning,
            onExit: onExit,
            onComplete: onComplete,
            initialSnapshot: initialSnapshot,
            onSaveSnapshot: onSaveSnapshot,
            locale: locale,
          ),
        ),
        GameRegistryEntry(
          gameId: 'math_supermarket',
          localizedName: const {
            'vi': MiMobileStrings.m015,
            'en': 'Math Supermarket',
          },
          category: 'math',
          ageBands: const ['explorer'],
          supportedSkills: const ['math.addition', 'math.numberSense'],
          engineType: 'choice',
          builder: ({
            required level,
            required allLevels,
            required onExit,
            required onComplete,
            required childProfileId,
            initialSnapshot,
            onSaveSnapshot,
            reduceMotion = false,
            required locale,
          }) =>
              ChoiceGameScreen(
            title: MiMobileStrings.m015,
            worldLabel: MiMobileStrings.m022,
            level: level,
            allLevels: allLevels,
            heroIcon: Icons.shopping_cart_rounded,
            primaryColor: MiGameColors.tertiary,
            onExit: onExit,
            onComplete: onComplete,
            initialSnapshot: initialSnapshot,
            onSaveSnapshot: onSaveSnapshot,
            locale: locale,
          ),
        ),
        GameRegistryEntry(
          gameId: 'robot_commands',
          localizedName: const {
            'vi': MiMobileStrings.m018,
            'en': 'Robot Commands',
          },
          category: 'logic',
          ageBands: const ['explorer', 'master'],
          supportedSkills: const ['logic.algorithm', 'logic.sequence'],
          engineType: 'grid_maze',
          builder: ({
            required level,
            required allLevels,
            required onExit,
            required onComplete,
            required childProfileId,
            initialSnapshot,
            onSaveSnapshot,
            reduceMotion = false,
            required locale,
          }) =>
              RobotCommandsScreen(
            level: level,
            allLevels: allLevels,
            onExit: onExit,
            onComplete: onComplete,
            initialSnapshot: initialSnapshot,
            onSaveSnapshot: onSaveSnapshot,
            locale: locale,
          ),
        ),
        GameRegistryEntry(
          gameId: 'memory_cards',
          localizedName: const {
            'vi': MiMobileStrings.m016,
            'en': 'Memory Cards'
          },
          category: 'logic',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const ['logic.memory'],
          engineType: 'memory',
          builder: ({
            required level,
            required allLevels,
            required onExit,
            required onComplete,
            required childProfileId,
            initialSnapshot,
            onSaveSnapshot,
            reduceMotion = false,
            required locale,
          }) =>
              _MemoryCardsRegistryHost(
            level: level,
            allLevels: allLevels,
            onExit: onExit,
            onComplete: onComplete,
            childProfileId: childProfileId,
            initialSnapshot: initialSnapshot,
            onSaveSnapshot: onSaveSnapshot,
            reduceMotion: reduceMotion,
            locale: locale,
          ),
        ),
        GameRegistryEntry(
          gameId: 'category_collector',
          localizedName: const {
            'vi': 'Nhom do vat',
            'en': 'Category Collector'
          },
          category: 'logic',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const [
            'letters.vocabulary',
            'math.number_comparison',
            'math.shapes.basic',
          ],
          engineType: 'multi_select',
          builder: _engineBackedBuilder(EngineBackedGameKind.multiSelect),
        ),
        GameRegistryEntry(
          gameId: 'pattern_parade',
          localizedName: const {
            'vi': 'Dieu hanh mau hinh',
            'en': 'Pattern Parade'
          },
          category: 'logic',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const [
            'logic.pattern.basic',
            'logic.pattern.recognition',
          ],
          engineType: 'sequence',
          builder: _engineBackedBuilder(EngineBackedGameKind.sequence),
        ),
        GameRegistryEntry(
          gameId: 'shape_builder',
          localizedName: const {'vi': 'Lap ghep hinh', 'en': 'Shape Builder'},
          category: 'math',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const ['math.shapes.basic', 'math.geometry'],
          engineType: 'placement',
          builder: _engineBackedBuilder(EngineBackedGameKind.placement),
        ),
        GameRegistryEntry(
          gameId: 'word_sorter',
          localizedName: const {'vi': 'Sap xep tu', 'en': 'Word Sorter'},
          category: 'letters',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const [
            'letters.initial_sound',
            'letters.vocabulary',
            'letters.simple_sentences',
          ],
          engineType: 'placement',
          builder: _engineBackedBuilder(EngineBackedGameKind.placement),
        ),
        GameRegistryEntry(
          gameId: 'number_balance',
          localizedName: const {'vi': 'Can bang so', 'en': 'Number Balance'},
          category: 'math',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const [
            'math.addition.within_20',
            'math.subtraction.within_20',
            'math.multiplication.tables',
          ],
          engineType: 'matching',
          builder: _engineBackedBuilder(EngineBackedGameKind.matching),
        ),
        GameRegistryEntry(
          gameId: 'logic_detective',
          localizedName: const {'vi': 'Tham tu logic', 'en': 'Logic Detective'},
          category: 'logic',
          ageBands: const ['explorer', 'master'],
          supportedSkills: const ['logic.conditions', 'logic.algorithms'],
          engineType: 'multi_select',
          builder: _engineBackedBuilder(EngineBackedGameKind.multiSelect),
        ),
        GameRegistryEntry(
          gameId: 'story_steps',
          localizedName: const {
            'vi': 'Cac buoc cau chuyen',
            'en': 'Story Steps'
          },
          category: 'letters',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const [
            'letters.reading_comprehension',
            'letters.storytelling',
            'logic.pattern.basic',
          ],
          engineType: 'sequence',
          builder: _engineBackedBuilder(EngineBackedGameKind.sequence),
        ),
        GameRegistryEntry(
          gameId: 'picture_detective',
          localizedName: const {
            'vi': MiMobileStrings.m153,
            'en': 'Picture Detective',
          },
          category: 'science',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const ['science.observation', 'logic.matching'],
          engineType: 'matching',
          builder: _engineBackedBuilder(EngineBackedGameKind.matching),
        ),
        GameRegistryEntry(
          gameId: 'color_builder',
          localizedName: const {
            'vi': MiMobileStrings.m154,
            'en': 'Color Builder'
          },
          category: 'creative',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const [
            'creative.color_recognition',
            'logic.spatial_reasoning',
          ],
          engineType: 'placement',
          builder: _engineBackedBuilder(EngineBackedGameKind.placement),
        ),
        GameRegistryEntry(
          gameId: 'animal_homes',
          localizedName: const {
            'vi': MiMobileStrings.m155,
            'en': 'Animal Homes'
          },
          category: 'science',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const ['science.observation', 'logic.matching'],
          engineType: 'matching',
          builder: _engineBackedBuilder(EngineBackedGameKind.matching),
        ),
        GameRegistryEntry(
          gameId: 'daily_routine',
          localizedName: const {
            'vi': MiMobileStrings.m156,
            'en': 'Daily Routine'
          },
          category: 'science',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const [
            'logic.pattern.basic',
            'science.cause_effect'
          ],
          engineType: 'sequence',
          builder: _engineBackedBuilder(EngineBackedGameKind.sequence),
        ),
        GameRegistryEntry(
          gameId: 'healthy_foods',
          localizedName: const {
            'vi': MiMobileStrings.m157,
            'en': 'Healthy Foods'
          },
          category: 'science',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const [
            'science.observation',
            'logic.classification'
          ],
          engineType: 'multi_select',
          builder: _engineBackedBuilder(EngineBackedGameKind.multiSelect),
        ),
        GameRegistryEntry(
          gameId: 'letter_hunt',
          localizedName: const {
            'vi': MiMobileStrings.m158,
            'en': 'Letter Hunt'
          },
          category: 'letters',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const [
            'letters.recognition.lowercase',
            'letters.spelling',
          ],
          engineType: 'placement',
          builder: _engineBackedBuilder(EngineBackedGameKind.placement),
        ),
        GameRegistryEntry(
          gameId: 'number_train',
          localizedName: const {
            'vi': MiMobileStrings.m159,
            'en': 'Number Train'
          },
          category: 'math',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const [
            'math.number_recognition.1_20',
            'math.counting'
          ],
          engineType: 'sequence',
          builder: _engineBackedBuilder(EngineBackedGameKind.sequence),
        ),
        GameRegistryEntry(
          gameId: 'emotion_match',
          localizedName: const {
            'vi': MiMobileStrings.m160,
            'en': 'Emotion Match'
          },
          category: 'science',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const ['science.observation', 'logic.matching'],
          engineType: 'matching',
          builder: _engineBackedBuilder(EngineBackedGameKind.matching),
        ),
        GameRegistryEntry(
          gameId: 'puzzle_parts',
          localizedName: const {
            'vi': MiMobileStrings.m161,
            'en': 'Puzzle Parts'
          },
          category: 'creative',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const [
            'creative.shape_construction',
            'logic.spatial_reasoning',
          ],
          engineType: 'placement',
          builder: _engineBackedBuilder(EngineBackedGameKind.placement),
        ),
        GameRegistryEntry(
          gameId: 'odd_one_out',
          localizedName: const {
            'vi': MiMobileStrings.m162,
            'en': 'Odd One Out'
          },
          category: 'logic',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const ['logic.odd_one_out', 'logic.classification'],
          engineType: 'multi_select',
          builder: _engineBackedBuilder(EngineBackedGameKind.multiSelect),
        ),
        GameRegistryEntry(
          gameId: 'opposites',
          localizedName: const {'vi': MiMobileStrings.m163, 'en': 'Opposites'},
          category: 'letters',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const [
            'letters.synonyms_antonyms',
            'logic.matching'
          ],
          engineType: 'matching',
          builder: _engineBackedBuilder(EngineBackedGameKind.matching),
        ),
        GameRegistryEntry(
          gameId: 'weather_today',
          localizedName: const {
            'vi': MiMobileStrings.m164,
            'en': 'Weather Today'
          },
          category: 'science',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const ['science.cause_effect', 'logic.matching'],
          engineType: 'matching',
          builder: _engineBackedBuilder(EngineBackedGameKind.matching),
        ),
        GameRegistryEntry(
          gameId: 'memory_journey',
          localizedName: const {
            'vi': MiMobileStrings.m165,
            'en': 'Memory Journey'
          },
          category: 'logic',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const ['logic.memory', 'logic.pattern.basic'],
          engineType: 'sequence',
          builder: _engineBackedBuilder(EngineBackedGameKind.sequence),
        ),
        GameRegistryEntry(
          gameId: 'category_expert',
          localizedName: const {
            'vi': MiMobileStrings.m166,
            'en': 'Category Expert',
          },
          category: 'logic',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const ['logic.classification', 'letters.vocabulary'],
          engineType: 'multi_select',
          builder: _engineBackedBuilder(EngineBackedGameKind.multiSelect),
        ),
        GameRegistryEntry(
          gameId: 'build_the_story',
          localizedName: const {
            'vi': MiMobileStrings.m167,
            'en': 'Build the Story'
          },
          category: 'letters',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const [
            'letters.storytelling',
            'creative.storytelling'
          ],
          engineType: 'sequence',
          builder: _engineBackedBuilder(EngineBackedGameKind.sequence),
        ),
      ];
}

GameScreenBuilder _engineBackedBuilder(EngineBackedGameKind kind) => ({
      required level,
      required allLevels,
      required onExit,
      required onComplete,
      required childProfileId,
      initialSnapshot,
      onSaveSnapshot,
      reduceMotion = false,
      required locale,
    }) =>
        EngineBackedGameScreen(
          kind: kind,
          level: level,
          onExit: onExit,
          onComplete: onComplete,
          childProfileId: childProfileId,
          initialSnapshot: initialSnapshot,
          onSaveSnapshot: onSaveSnapshot,
          reduceMotion: reduceMotion,
          locale: locale,
        );

/// Registry-facing wrapper around [MemoryCardsScreen] with the same
/// level-advance/replay/exit host logic `GameScreen`'s old
/// `_MemoryCardsHost` had -- Memory Cards is the one game whose screen
/// reports completion without owning its own "you did it" UI.
class _MemoryCardsRegistryHost extends StatefulWidget {
  const _MemoryCardsRegistryHost({
    required this.level,
    required this.allLevels,
    required this.onExit,
    required this.onComplete,
    required this.childProfileId,
    this.initialSnapshot,
    this.onSaveSnapshot,
    this.reduceMotion = false,
    required this.locale,
  });

  final MiLevel level;
  final List<MiLevel> allLevels;
  final VoidCallback onExit;
  final void Function(MiCompletionResult) onComplete;
  final String childProfileId;
  final MiGameSnapshot? initialSnapshot;
  final void Function(MiGameSnapshot)? onSaveSnapshot;
  final bool reduceMotion;
  final String locale;

  @override
  State<_MemoryCardsRegistryHost> createState() =>
      _MemoryCardsRegistryHostState();
}

class _MemoryCardsRegistryHostState extends State<_MemoryCardsRegistryHost> {
  late MemoryCardsGame _game;
  late MiLevel _level;

  @override
  void initState() {
    super.initState();
    _level = widget.level;
    _game = MemoryCardsGame();
  }

  @override
  void dispose() {
    _game.dispose();
    super.dispose();
  }

  void _onGameComplete(MiCompletionResult result) {
    widget.onComplete(result);
    final stars = result.metadata['stars'] as int? ?? 1;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompletionOverlay(
        starsEarned: stars,
        maxStars: 3,
        message: MiMobileStrings.m040,
        score: result.score,
        onNext: () {
          Navigator.of(context).pop();
          final nextIndex =
              widget.allLevels.indexWhere((l) => l.id == _level.id) + 1;
          if (nextIndex < widget.allLevels.length) {
            setState(() {
              _game = MemoryCardsGame();
              _level = widget.allLevels[nextIndex];
            });
          } else {
            widget.onExit();
          }
        },
        onReplay: () {
          Navigator.of(context).pop();
          setState(() => _game = MemoryCardsGame());
        },
        onExit: () {
          Navigator.of(context).pop();
          widget.onExit();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MemoryCardsScreen(
      key: ValueKey(_level.id),
      game: _game,
      level: _level,
      onComplete: _onGameComplete,
      onExit: widget.onExit,
      childProfileId: widget.childProfileId,
      initialSnapshot:
          _level.id == widget.level.id ? widget.initialSnapshot : null,
      onSaveSnapshot: widget.onSaveSnapshot,
      reduceMotion: widget.reduceMotion,
      locale: widget.locale,
    );
  }
}
