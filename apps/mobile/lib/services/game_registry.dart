import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

import '../src/games/choice/choice_game_screen.dart';
import '../src/games/deep_logic/deep_logic_game_screen.dart';
import '../src/games/free_creativity/free_creativity_screen.dart';
import '../src/games/free_creativity/creative_artifact_store.dart';
import '../src/games/game_locale_text.dart';
import '../src/games/kids_sudoku/kids_sudoku_screen.dart';
import '../src/games/logic_maze/logic_maze_screen.dart';
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

  /// {'vi': ..., 'en': ...} -- sourced from the localization package.
  final Map<String, String> localizedName;

  /// One of 'letters', 'math', 'logic' (see docs/skill-taxonomy.md).
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
  CreativeArtifactStore? creativeArtifactStore,
  bool reduceMotion,
  required String locale,
});

/// Central registry for all playable games. See docs/game-catalog.md for
/// the full 30-game target list. Choice-engine expansion games are content-
/// backed entries with real level packs, not empty menu placeholders.
abstract final class GameRegistry {
  static const List<String> _canonicalGameIds = [
    'alphabet_explorer',
    'word_builder',
    'sound_match',
    'missing_letter',
    'picture_word_match',
    'rhyme_picker',
    'speed_spelling',
    'sentence_order',
    'story_comprehension',
    'object_counting',
    'number_quantity_match',
    'greater_less',
    'math_race',
    'number_sequence',
    'math_supermarket',
    'multiplication_adventure',
    'treasure_division',
    'clock_time',
    'fun_measurement',
    'shape_builder',
    'visual_fractions',
    'memory_cards',
    'odd_one_out',
    'shadow_match',
    'robot_commands',
    'logic_maze',
    'pattern_finder',
    'kids_sudoku',
    'reasoning_detective',
    'free_creativity',
  ];

  static final Map<String, GameRegistryEntry> _entries = {
    for (final entry in _buildEntries()) entry.gameId: entry,
  };

  /// Returns null for an unknown (or not-yet-built) game ID -- callers must
  /// handle that as a safe fallback, never assume a lookup succeeds.
  static GameRegistryEntry? find(String gameId) => _entries[gameId];

  static List<GameRegistryEntry> get all => List.unmodifiable(
        _canonicalGameIds.map((gameId) => _entries[gameId]!),
      );

  static List<GameRegistryEntry> enabledForAgeBand(String ageBand) => all
      .where((entry) => entry.enabled && entry.ageBands.contains(ageBand))
      .toList(growable: false);

  static GameRegistryEntry _choiceEntry({
    required String gameId,
    required Map<String, String> localizedName,
    required String category,
    required List<String> ageBands,
    required List<String> supportedSkills,
    required MiBrandIcon brandIcon,
    required Color primaryColor,
    required String Function(String locale) worldLabel,
  }) {
    return GameRegistryEntry(
      gameId: gameId,
      localizedName: localizedName,
      category: category,
      ageBands: ageBands,
      supportedSkills: supportedSkills,
      engineType: 'choice',
      builder: ({
        required level,
        required allLevels,
        required onExit,
        required onComplete,
        required childProfileId,
        initialSnapshot,
        onSaveSnapshot,
        creativeArtifactStore,
        reduceMotion = false,
        required locale,
      }) =>
          ChoiceGameScreen(
        title: miGameName(gameId, locale),
        worldLabel: worldLabel(locale),
        level: level,
        allLevels: allLevels,
        brandIcon: brandIcon,
        primaryColor: primaryColor,
        onExit: onExit,
        onComplete: onComplete,
        initialSnapshot: initialSnapshot,
        onSaveSnapshot: onSaveSnapshot,
        locale: locale,
      ),
    );
  }

  static GameRegistryEntry _deepLogicEntry({
    required String gameId,
    required Map<String, String> localizedName,
    required String category,
    required List<String> ageBands,
    required List<String> supportedSkills,
    required String engineType,
    required DeepLogicScene scene,
    required Color primaryColor,
    required String Function(String locale) worldLabel,
  }) {
    return GameRegistryEntry(
      gameId: gameId,
      localizedName: localizedName,
      category: category,
      ageBands: ageBands,
      supportedSkills: supportedSkills,
      engineType: engineType,
      builder: ({
        required level,
        required allLevels,
        required onExit,
        required onComplete,
        required childProfileId,
        initialSnapshot,
        onSaveSnapshot,
        creativeArtifactStore,
        reduceMotion = false,
        required locale,
      }) =>
          DeepLogicGameScreen(
        title: miGameName(gameId, locale),
        worldLabel: worldLabel(locale),
        level: level,
        allLevels: allLevels,
        scene: scene,
        primaryColor: primaryColor,
        onExit: onExit,
        onComplete: onComplete,
        initialSnapshot: initialSnapshot,
        onSaveSnapshot: onSaveSnapshot,
        locale: locale,
      ),
    );
  }

  static List<GameRegistryEntry> _buildEntries() => [
        GameRegistryEntry(
          gameId: 'alphabet_explorer',
          localizedName: miGameNameMap('alphabet_explorer'),
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
            creativeArtifactStore,
            reduceMotion = false,
            required locale,
          }) =>
              ChoiceGameScreen(
            title: miGameName('alphabet_explorer', locale),
            worldLabel: miGameWorldLabel('alphabet_explorer', locale),
            level: level,
            allLevels: allLevels,
            brandIcon: MiBrandIcon.alphabet,
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
          localizedName: miGameNameMap('missing_letter'),
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
            creativeArtifactStore,
            reduceMotion = false,
            required locale,
          }) =>
              ChoiceGameScreen(
            title: miGameName('missing_letter', locale),
            worldLabel: miGameWorldLabel('missing_letter', locale),
            level: level,
            allLevels: allLevels,
            brandIcon: MiBrandIcon.writing,
            primaryColor: MiGameColors.secondary,
            onExit: onExit,
            onComplete: onComplete,
            initialSnapshot: initialSnapshot,
            onSaveSnapshot: onSaveSnapshot,
            locale: locale,
          ),
        ),
        _choiceEntry(
          gameId: 'picture_word_match',
          localizedName: miGameNameMap('picture_word_match'),
          category: 'letters',
          ageBands: const ['junior', 'explorer'],
          supportedSkills: const ['letters.vocabulary'],
          brandIcon: MiBrandIcon.alphabet,
          primaryColor: MiColors.discovery,
          worldLabel: (locale) =>
              miGameWorldLabel('picture_word_match', locale),
        ),
        _choiceEntry(
          gameId: 'rhyme_picker',
          localizedName: miGameNameMap('rhyme_picker'),
          category: 'letters',
          ageBands: const ['junior', 'explorer'],
          supportedSkills: const ['letters.rhyming'],
          brandIcon: MiBrandIcon.listening,
          primaryColor: MiColors.discovery,
          worldLabel: (locale) => miGameWorldLabel('rhyme_picker', locale),
        ),
        _choiceEntry(
          gameId: 'speed_spelling',
          localizedName: miGameNameMap('speed_spelling'),
          category: 'letters',
          ageBands: const ['explorer', 'master'],
          supportedSkills: const ['letters.spelling'],
          brandIcon: MiBrandIcon.writing,
          primaryColor: MiColors.discovery,
          worldLabel: (locale) => miGameWorldLabel('speed_spelling', locale),
        ),
        _choiceEntry(
          gameId: 'sentence_order',
          localizedName: miGameNameMap('sentence_order'),
          category: 'letters',
          ageBands: const ['explorer', 'master'],
          supportedSkills: const [
            'letters.simple_sentences',
            'letters.sentence_completion',
          ],
          brandIcon: MiBrandIcon.writing,
          primaryColor: MiColors.discovery,
          worldLabel: (locale) => miGameWorldLabel('sentence_order', locale),
        ),
        _deepLogicEntry(
          gameId: 'story_comprehension',
          localizedName: miGameNameMap('story_comprehension'),
          category: 'letters',
          ageBands: const ['explorer', 'master'],
          supportedSkills: const ['letters.reading_comprehension'],
          engineType: 'reading_lab',
          scene: DeepLogicScene.reading,
          primaryColor: MiColors.discovery,
          worldLabel: (locale) =>
              miGameWorldLabel('story_comprehension', locale),
        ),
        GameRegistryEntry(
          gameId: 'word_builder',
          localizedName: miGameNameMap('word_builder'),
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
            creativeArtifactStore,
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
          localizedName: miGameNameMap('sound_match'),
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
            creativeArtifactStore,
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
        _choiceEntry(
          gameId: 'object_counting',
          localizedName: miGameNameMap('object_counting'),
          category: 'math',
          ageBands: const ['junior'],
          supportedSkills: const ['math.counting'],
          brandIcon: MiBrandIcon.numbers,
          primaryColor: MiColors.success,
          worldLabel: (locale) => miGameWorldLabel('object_counting', locale),
        ),
        _choiceEntry(
          gameId: 'number_quantity_match',
          localizedName: miGameNameMap('number_quantity_match'),
          category: 'math',
          ageBands: const ['junior'],
          supportedSkills: const ['math.number_recognition.1_20'],
          brandIcon: MiBrandIcon.numbers,
          primaryColor: MiColors.success,
          worldLabel: (locale) =>
              miGameWorldLabel('number_quantity_match', locale),
        ),
        _choiceEntry(
          gameId: 'greater_less',
          localizedName: miGameNameMap('greater_less'),
          category: 'math',
          ageBands: const ['junior'],
          supportedSkills: const ['math.number_comparison'],
          brandIcon: MiBrandIcon.numbers,
          primaryColor: MiColors.success,
          worldLabel: (locale) => miGameWorldLabel('greater_less', locale),
        ),
        GameRegistryEntry(
          gameId: 'math_race',
          localizedName: miGameNameMap('math_race'),
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
            creativeArtifactStore,
            reduceMotion = false,
            required locale,
          }) =>
              ChoiceGameScreen(
            title: miGameName('math_race', locale),
            worldLabel: miGameWorldLabel('math_race', locale),
            level: level,
            allLevels: allLevels,
            brandIcon: MiBrandIcon.numbers,
            primaryColor: GameTheme.warning,
            onExit: onExit,
            onComplete: onComplete,
            initialSnapshot: initialSnapshot,
            onSaveSnapshot: onSaveSnapshot,
            locale: locale,
          ),
        ),
        _choiceEntry(
          gameId: 'number_sequence',
          localizedName: miGameNameMap('number_sequence'),
          category: 'math',
          ageBands: const ['junior', 'explorer'],
          supportedSkills: const [
            'math.number_recognition.1_20',
            'logic.pattern.basic',
          ],
          brandIcon: MiBrandIcon.numbers,
          primaryColor: MiColors.success,
          worldLabel: (locale) => miGameWorldLabel('number_sequence', locale),
        ),
        GameRegistryEntry(
          gameId: 'math_supermarket',
          localizedName: miGameNameMap('math_supermarket'),
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
            creativeArtifactStore,
            reduceMotion = false,
            required locale,
          }) =>
              ChoiceGameScreen(
            title: miGameName('math_supermarket', locale),
            worldLabel: miGameWorldLabel('math_supermarket', locale),
            level: level,
            allLevels: allLevels,
            brandIcon: MiBrandIcon.numbers,
            primaryColor: MiGameColors.tertiary,
            onExit: onExit,
            onComplete: onComplete,
            initialSnapshot: initialSnapshot,
            onSaveSnapshot: onSaveSnapshot,
            locale: locale,
          ),
        ),
        _choiceEntry(
          gameId: 'multiplication_adventure',
          localizedName: miGameNameMap('multiplication_adventure'),
          category: 'math',
          ageBands: const ['explorer', 'master'],
          supportedSkills: const ['math.multiplication.tables'],
          brandIcon: MiBrandIcon.numbers,
          primaryColor: MiColors.success,
          worldLabel: (locale) =>
              miGameWorldLabel('multiplication_adventure', locale),
        ),
        _choiceEntry(
          gameId: 'treasure_division',
          localizedName: miGameNameMap('treasure_division'),
          category: 'math',
          ageBands: const ['explorer', 'master'],
          supportedSkills: const ['math.division.basic'],
          brandIcon: MiBrandIcon.achievement,
          primaryColor: MiColors.success,
          worldLabel: (locale) => miGameWorldLabel('treasure_division', locale),
        ),
        _choiceEntry(
          gameId: 'clock_time',
          localizedName: miGameNameMap('clock_time'),
          category: 'math',
          ageBands: const ['junior', 'explorer'],
          supportedSkills: const ['math.time.basic'],
          brandIcon: MiBrandIcon.progress,
          primaryColor: MiColors.success,
          worldLabel: (locale) => miGameWorldLabel('clock_time', locale),
        ),
        _choiceEntry(
          gameId: 'fun_measurement',
          localizedName: miGameNameMap('fun_measurement'),
          category: 'math',
          ageBands: const ['explorer', 'master'],
          supportedSkills: const ['math.measurement'],
          brandIcon: MiBrandIcon.logic,
          primaryColor: MiColors.success,
          worldLabel: (locale) => miGameWorldLabel('fun_measurement', locale),
        ),
        _choiceEntry(
          gameId: 'shape_builder',
          localizedName: miGameNameMap('shape_builder'),
          category: 'math',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const [
            'math.shapes.basic',
            'creative.shape_construction',
          ],
          brandIcon: MiBrandIcon.logic,
          primaryColor: MiColors.success,
          worldLabel: (locale) => miGameWorldLabel('shape_builder', locale),
        ),
        _choiceEntry(
          gameId: 'visual_fractions',
          localizedName: miGameNameMap('visual_fractions'),
          category: 'math',
          ageBands: const ['explorer', 'master'],
          supportedSkills: const ['math.fractions.visual'],
          brandIcon: MiBrandIcon.numbers,
          primaryColor: MiColors.success,
          worldLabel: (locale) => miGameWorldLabel('visual_fractions', locale),
        ),
        GameRegistryEntry(
          gameId: 'robot_commands',
          localizedName: miGameNameMap('robot_commands'),
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
            creativeArtifactStore,
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
          gameId: 'logic_maze',
          localizedName: miGameNameMap('logic_maze'),
          category: 'logic',
          ageBands: const ['explorer', 'master'],
          supportedSkills: const ['logic.maze', 'logic.navigation'],
          engineType: 'logic_maze_movement',
          builder: ({
            required level,
            required allLevels,
            required onExit,
            required onComplete,
            required childProfileId,
            initialSnapshot,
            onSaveSnapshot,
            creativeArtifactStore,
            reduceMotion = false,
            required locale,
          }) =>
              LogicMazeScreen(
            level: level,
            allLevels: allLevels,
            onExit: onExit,
            onComplete: onComplete,
            initialSnapshot: initialSnapshot,
            onSaveSnapshot: onSaveSnapshot,
            locale: locale,
          ),
        ),
        _choiceEntry(
          gameId: 'pattern_finder',
          localizedName: miGameNameMap('pattern_finder'),
          category: 'logic',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const ['logic.pattern.recognition'],
          brandIcon: MiBrandIcon.logic,
          primaryColor: MiColors.creative,
          worldLabel: (locale) => miGameWorldLabel('pattern_finder', locale),
        ),
        GameRegistryEntry(
          gameId: 'kids_sudoku',
          localizedName: miGameNameMap('kids_sudoku'),
          category: 'logic',
          ageBands: const ['master'],
          supportedSkills: const [
            'logic.conditions',
            'logic.spatial_reasoning',
          ],
          engineType: 'kids_sudoku_grid',
          builder: ({
            required level,
            required allLevels,
            required onExit,
            required onComplete,
            required childProfileId,
            initialSnapshot,
            onSaveSnapshot,
            creativeArtifactStore,
            reduceMotion = false,
            required locale,
          }) =>
              KidsSudokuScreen(
            level: level,
            allLevels: allLevels,
            onExit: onExit,
            onComplete: onComplete,
            initialSnapshot: initialSnapshot,
            onSaveSnapshot: onSaveSnapshot,
            locale: locale,
          ),
        ),
        _deepLogicEntry(
          gameId: 'reasoning_detective',
          localizedName: miGameNameMap('reasoning_detective'),
          category: 'logic',
          ageBands: const ['master'],
          supportedSkills: const ['logic.strategy', 'logic.algorithms'],
          engineType: 'clue_board',
          scene: DeepLogicScene.detective,
          primaryColor: MiColors.creative,
          worldLabel: (locale) =>
              miGameWorldLabel('reasoning_detective', locale),
        ),
        GameRegistryEntry(
          gameId: 'memory_cards',
          localizedName: miGameNameMap('memory_cards'),
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
            creativeArtifactStore,
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
        _choiceEntry(
          gameId: 'odd_one_out',
          localizedName: miGameNameMap('odd_one_out'),
          category: 'logic',
          ageBands: const ['junior', 'explorer'],
          supportedSkills: const [
            'logic.odd_one_out',
            'logic.classification',
          ],
          brandIcon: MiBrandIcon.logic,
          primaryColor: MiColors.creative,
          worldLabel: (locale) => miGameWorldLabel('odd_one_out', locale),
        ),
        _choiceEntry(
          gameId: 'shadow_match',
          localizedName: miGameNameMap('shadow_match'),
          category: 'logic',
          ageBands: const ['junior', 'explorer'],
          supportedSkills: const [
            'logic.matching',
            'logic.spatial_reasoning',
          ],
          brandIcon: MiBrandIcon.memory,
          primaryColor: MiColors.creative,
          worldLabel: (locale) => miGameWorldLabel('shadow_match', locale),
        ),
        GameRegistryEntry(
          gameId: 'free_creativity',
          localizedName: miGameNameMap('free_creativity'),
          category: 'creative',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const [
            'creative.storytelling',
            'letters.storytelling',
          ],
          engineType: 'creative_story_lab',
          builder: ({
            required level,
            required allLevels,
            required onExit,
            required onComplete,
            required childProfileId,
            initialSnapshot,
            onSaveSnapshot,
            creativeArtifactStore,
            reduceMotion = false,
            required locale,
          }) =>
              FreeCreativityScreen(
            level: level,
            allLevels: allLevels,
            childProfileId: childProfileId,
            onExit: onExit,
            onComplete: onComplete,
            initialSnapshot: initialSnapshot,
            onSaveSnapshot: onSaveSnapshot,
            artifactStore: creativeArtifactStore!,
            reduceMotion: reduceMotion,
            locale: locale,
          ),
        ),
      ];
}

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
    final text = GameLocaleText(widget.locale);
    final completion = text.completion;
    widget.onComplete(result);
    final stars = result.metadata['stars'] as int? ?? 1;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompletionOverlay(
        starsEarned: stars,
        maxStars: 3,
        message: text.memoryCongrats,
        score: result.score,
        scoreLabel: completion.scoreLabel,
        nextLabel: completion.nextLabel,
        replayLabel: completion.replayLabel,
        exitLabel: completion.exitLabel,
        mascotSemanticLabel: completion.mascotSemanticLabel,
        earnedStarSemanticLabel: completion.earnedStarSemanticLabel,
        unearnedStarSemanticLabel: completion.unearnedStarSemanticLabel,
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
