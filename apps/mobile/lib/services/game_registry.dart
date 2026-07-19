import 'package:flutter/material.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

import '../src/games/choice/choice_game_screen.dart';
import '../src/games/memory_cards/memory_cards_game.dart';
import '../src/games/memory_cards/memory_cards_screen.dart';
import '../src/games/robot_commands/robot_commands_screen.dart';
import '../src/games/shape_builder/shape_builder_screen.dart';
import '../src/games/sound_match/sound_match_screen.dart';
import '../src/games/word_builder/word_builder_screen.dart';
import '../src/games/word_sorter/word_sorter_screen.dart';

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
  bool reduceMotion,
  required String locale,
});

/// Central registry for all playable games. See docs/game-catalog.md for
/// the full 30-game target list -- only built games are registered here;
/// not-yet-built games simply don't have entries yet (not stubbed/faked).
abstract final class GameRegistry {
  static final Map<String, GameRegistryEntry> _entries = {
    for (final entry in _buildEntries()) entry.gameId: entry,
  };

  /// Returns null for an unknown (or not-yet-built) game ID -- callers must
  /// handle that as a safe fallback, never assume a lookup succeeds.
  static GameRegistryEntry? find(String gameId) => _entries[gameId];

  static List<GameRegistryEntry> get all => List.unmodifiable(_entries.values);

  static List<GameRegistryEntry> enabledForAgeBand(String ageBand) => all
      .where((entry) => entry.enabled && entry.ageBands.contains(ageBand))
      .toList(growable: false);

  static List<GameRegistryEntry> _buildEntries() => [
        GameRegistryEntry(
          gameId: 'alphabet_explorer',
          localizedName: const {
            'vi': 'Khám phá chữ cái',
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
            title: locale == 'en' ? 'Alphabet Explorer' : 'Khám phá chữ cái',
            worldLabel: locale == 'en'
                ? 'MI explores letters with you.'
                : 'MI cùng con khám phá chữ cái.',
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
            'vi': 'Tìm chữ còn thiếu',
            'en': 'Missing Letter',
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
            title: locale == 'en' ? 'Missing Letter' : 'Tìm chữ còn thiếu',
            worldLabel: locale == 'en'
                ? 'MI looks for the missing letters with you.'
                : 'MI cùng con tìm chữ còn thiếu.',
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
          localizedName: const {'vi': 'Ghép chữ tạo từ', 'en': 'Word Builder'},
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
            'vi': 'Nghe âm tìm chữ',
            'en': 'Sound Match',
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
          localizedName: const {
            'vi': 'Đường đua cộng trừ',
            'en': 'Math Race',
          },
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
            title: 'Đường đua cộng trừ',
            worldLabel: 'Xe MI tiến lên khi con chọn đúng.',
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
            'vi': 'Siêu thị toán học',
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
            title: 'Siêu thị toán học',
            worldLabel: 'Giỏ hàng MI giúp con luyện tính tiền.',
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
            'vi': 'Robot làm theo lệnh',
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
          localizedName: const {'vi': 'Ghi nhớ vị trí', 'en': 'Memory Cards'},
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
          gameId: 'shape_builder',
          localizedName: const {'vi': 'Xây hình khối', 'en': 'Shape Builder'},
          category: 'logic',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const [
            'math.shapes.basic',
            'logic.spatial_reasoning',
            'creative.shape_construction',
            'creative.tangram',
            'math.geometry',
          ],
          engineType: 'placement',
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
              ShapeBuilderScreen(
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
          gameId: 'word_sorter',
          localizedName: const {'vi': 'Phân loại từ', 'en': 'Word Sorter'},
          category: 'letters',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const [
            'letters.vocabulary',
            'letters.initial_sound',
            'letters.rhyming',
            'logic.classification',
          ],
          engineType: 'placement',
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
              WordSorterScreen(
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
    widget.onComplete(result);
    final stars = result.metadata['stars'] as int? ?? 1;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompletionOverlay(
        starsEarned: stars,
        maxStars: 3,
        message: 'Chúc mừng!',
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
