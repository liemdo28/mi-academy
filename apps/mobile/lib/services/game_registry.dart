import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

import '../src/games/choice/choice_game_screen.dart';
import '../src/games/game_locale_text.dart';
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
        reduceMotion = false,
        required locale,
      }) =>
          ChoiceGameScreen(
        title: localizedName[locale] ?? localizedName['en'] ?? gameId,
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
          localizedName: const {
            'vi': 'Nối từ với hình',
            'en': 'Picture Word Match',
          },
          category: 'letters',
          ageBands: const ['junior', 'explorer'],
          supportedSkills: const ['letters.vocabulary'],
          brandIcon: MiBrandIcon.alphabet,
          primaryColor: MiColors.discovery,
          worldLabel: (locale) => locale == 'en'
              ? 'MI matches words with meaning.'
              : 'MI cùng con nối từ với ý nghĩa.',
        ),
        _choiceEntry(
          gameId: 'rhyme_picker',
          localizedName: const {'vi': 'Vần nào đúng?', 'en': 'Rhyme Picker'},
          category: 'letters',
          ageBands: const ['junior', 'explorer'],
          supportedSkills: const ['letters.rhyming'],
          brandIcon: MiBrandIcon.listening,
          primaryColor: MiColors.discovery,
          worldLabel: (locale) => locale == 'en'
              ? 'MI listens for words that sound alike.'
              : 'MI cùng con nghe những từ cùng vần.',
        ),
        _choiceEntry(
          gameId: 'speed_spelling',
          localizedName: const {'vi': 'Chính tả nhanh', 'en': 'Speed Spelling'},
          category: 'letters',
          ageBands: const ['explorer', 'master'],
          supportedSkills: const ['letters.spelling'],
          brandIcon: MiBrandIcon.writing,
          primaryColor: MiColors.discovery,
          worldLabel: (locale) => locale == 'en'
              ? 'MI helps you spot the correct spelling.'
              : 'MI giúp con chọn cách viết đúng.',
        ),
        _choiceEntry(
          gameId: 'sentence_order',
          localizedName: const {'vi': 'Sắp xếp câu', 'en': 'Sentence Order'},
          category: 'letters',
          ageBands: const ['explorer', 'master'],
          supportedSkills: const [
            'letters.simple_sentences',
            'letters.sentence_completion',
          ],
          brandIcon: MiBrandIcon.writing,
          primaryColor: MiColors.discovery,
          worldLabel: (locale) => locale == 'en'
              ? 'MI builds clear sentences with you.'
              : 'MI cùng con ghép câu rõ nghĩa.',
        ),
        _choiceEntry(
          gameId: 'story_comprehension',
          localizedName: const {
            'vi': 'Đọc hiểu truyện ngắn',
            'en': 'Story Comprehension',
          },
          category: 'letters',
          ageBands: const ['explorer', 'master'],
          supportedSkills: const ['letters.reading_comprehension'],
          brandIcon: MiBrandIcon.writing,
          primaryColor: MiColors.discovery,
          worldLabel: (locale) => locale == 'en'
              ? 'MI reads short stories with you.'
              : 'MI cùng con đọc hiểu truyện ngắn.',
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
        _choiceEntry(
          gameId: 'object_counting',
          localizedName: const {'vi': 'Đếm đồ vật', 'en': 'Object Counting'},
          category: 'math',
          ageBands: const ['junior'],
          supportedSkills: const ['math.counting'],
          brandIcon: MiBrandIcon.numbers,
          primaryColor: MiColors.success,
          worldLabel: (locale) => locale == 'en'
              ? 'MI counts objects one by one.'
              : 'MI cùng con đếm từng đồ vật.',
        ),
        _choiceEntry(
          gameId: 'number_quantity_match',
          localizedName: const {
            'vi': 'Ghép số với số lượng',
            'en': 'Number Quantity Match',
          },
          category: 'math',
          ageBands: const ['junior'],
          supportedSkills: const ['math.number_recognition.1_20'],
          brandIcon: MiBrandIcon.numbers,
          primaryColor: MiColors.success,
          worldLabel: (locale) => locale == 'en'
              ? 'MI connects numbers to quantities.'
              : 'MI cùng con ghép số với số lượng.',
        ),
        _choiceEntry(
          gameId: 'greater_less',
          localizedName: const {
            'vi': 'So sánh lớn và bé',
            'en': 'Greater or Less',
          },
          category: 'math',
          ageBands: const ['junior'],
          supportedSkills: const ['math.number_comparison'],
          brandIcon: MiBrandIcon.numbers,
          primaryColor: MiColors.success,
          worldLabel: (locale) => locale == 'en'
              ? 'MI compares numbers with you.'
              : 'MI cùng con so sánh các số.',
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
            title: locale == 'en' ? 'Math Race' : 'Đường đua cộng trừ',
            worldLabel: locale == 'en'
                ? 'MI moves forward when you choose correctly.'
                : 'Xe MI tiến lên khi con chọn đúng.',
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
          localizedName: const {
            'vi': 'Hoàn thành dãy số',
            'en': 'Number Sequence',
          },
          category: 'math',
          ageBands: const ['junior', 'explorer'],
          supportedSkills: const [
            'math.number_recognition.1_20',
            'logic.pattern.basic',
          ],
          brandIcon: MiBrandIcon.numbers,
          primaryColor: MiColors.success,
          worldLabel: (locale) => locale == 'en'
              ? 'MI finds the next number in the pattern.'
              : 'MI cùng con tìm số tiếp theo.',
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
            title: locale == 'en' ? 'Math Supermarket' : 'Siêu thị toán học',
            worldLabel: locale == 'en'
                ? 'MI’s basket helps you practice money math.'
                : 'Giỏ hàng MI giúp con luyện tính tiền.',
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
          localizedName: const {
            'vi': 'Bảng nhân phiêu lưu',
            'en': 'Multiplication Adventure',
          },
          category: 'math',
          ageBands: const ['explorer', 'master'],
          supportedSkills: const ['math.multiplication.tables'],
          brandIcon: MiBrandIcon.numbers,
          primaryColor: MiColors.success,
          worldLabel: (locale) => locale == 'en'
              ? 'MI practices times tables on an adventure.'
              : 'MI cùng con phiêu lưu với bảng nhân.',
        ),
        _choiceEntry(
          gameId: 'treasure_division',
          localizedName: const {
            'vi': 'Chia đều kho báu',
            'en': 'Treasure Division',
          },
          category: 'math',
          ageBands: const ['explorer', 'master'],
          supportedSkills: const ['math.division.basic'],
          brandIcon: MiBrandIcon.achievement,
          primaryColor: MiColors.success,
          worldLabel: (locale) => locale == 'en'
              ? 'MI shares treasure equally.'
              : 'MI cùng con chia đều kho báu.',
        ),
        _choiceEntry(
          gameId: 'clock_time',
          localizedName: const {
            'vi': 'Đồng hồ và thời gian',
            'en': 'Clock Time',
          },
          category: 'math',
          ageBands: const ['junior', 'explorer'],
          supportedSkills: const ['math.time.basic'],
          brandIcon: MiBrandIcon.progress,
          primaryColor: MiColors.success,
          worldLabel: (locale) => locale == 'en'
              ? 'MI reads clocks with you.'
              : 'MI cùng con xem đồng hồ.',
        ),
        _choiceEntry(
          gameId: 'fun_measurement',
          localizedName: const {
            'vi': 'Đo lường vui nhộn',
            'en': 'Fun Measurement',
          },
          category: 'math',
          ageBands: const ['explorer', 'master'],
          supportedSkills: const ['math.measurement'],
          brandIcon: MiBrandIcon.logic,
          primaryColor: MiColors.success,
          worldLabel: (locale) => locale == 'en'
              ? 'MI compares length, weight, and units.'
              : 'MI cùng con so sánh đơn vị đo.',
        ),
        _choiceEntry(
          gameId: 'shape_builder',
          localizedName: const {
            'vi': 'Hình học lắp ghép',
            'en': 'Shape Builder',
          },
          category: 'math',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const [
            'math.shapes.basic',
            'creative.shape_construction',
          ],
          brandIcon: MiBrandIcon.logic,
          primaryColor: MiColors.success,
          worldLabel: (locale) => locale == 'en'
              ? 'MI names and builds shapes.'
              : 'MI cùng con nhận biết hình khối.',
        ),
        _choiceEntry(
          gameId: 'visual_fractions',
          localizedName: const {
            'vi': 'Phân số trực quan',
            'en': 'Visual Fractions',
          },
          category: 'math',
          ageBands: const ['explorer', 'master'],
          supportedSkills: const ['math.fractions.visual'],
          brandIcon: MiBrandIcon.numbers,
          primaryColor: MiColors.success,
          worldLabel: (locale) => locale == 'en'
              ? 'MI sees fractions as equal parts.'
              : 'MI cùng con nhìn phân số bằng hình.',
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
        _choiceEntry(
          gameId: 'logic_maze',
          localizedName: const {'vi': 'Mê cung logic', 'en': 'Logic Maze'},
          category: 'logic',
          ageBands: const ['explorer', 'master'],
          supportedSkills: const ['logic.maze', 'logic.navigation'],
          brandIcon: MiBrandIcon.exploration,
          primaryColor: MiColors.creative,
          worldLabel: (locale) => locale == 'en'
              ? 'MI plans a path through the maze.'
              : 'MI cùng con tìm đường qua mê cung.',
        ),
        _choiceEntry(
          gameId: 'pattern_finder',
          localizedName: const {'vi': 'Tìm quy luật', 'en': 'Pattern Finder'},
          category: 'logic',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const ['logic.pattern.recognition'],
          brandIcon: MiBrandIcon.logic,
          primaryColor: MiColors.creative,
          worldLabel: (locale) => locale == 'en'
              ? 'MI spots the rule in the pattern.'
              : 'MI cùng con tìm quy luật.',
        ),
        _choiceEntry(
          gameId: 'kids_sudoku',
          localizedName: const {'vi': 'Sudoku trẻ em', 'en': 'Kids Sudoku'},
          category: 'logic',
          ageBands: const ['master'],
          supportedSkills: const [
            'logic.conditions',
            'logic.spatial_reasoning',
          ],
          brandIcon: MiBrandIcon.logic,
          primaryColor: MiColors.creative,
          worldLabel: (locale) => locale == 'en'
              ? 'MI solves small grids with clues.'
              : 'MI cùng con giải ô lưới nhỏ.',
        ),
        _choiceEntry(
          gameId: 'reasoning_detective',
          localizedName: const {
            'vi': 'Thám tử suy luận',
            'en': 'Reasoning Detective',
          },
          category: 'logic',
          ageBands: const ['master'],
          supportedSkills: const ['logic.strategy', 'logic.algorithms'],
          brandIcon: MiBrandIcon.logic,
          primaryColor: MiColors.creative,
          worldLabel: (locale) => locale == 'en'
              ? 'MI follows clues step by step.'
              : 'MI cùng con suy luận từng bước.',
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
        _choiceEntry(
          gameId: 'odd_one_out',
          localizedName: const {
            'vi': 'Tìm hình khác biệt',
            'en': 'Odd One Out',
          },
          category: 'logic',
          ageBands: const ['junior', 'explorer'],
          supportedSkills: const [
            'logic.odd_one_out',
            'logic.classification',
          ],
          brandIcon: MiBrandIcon.logic,
          primaryColor: MiColors.creative,
          worldLabel: (locale) => locale == 'en'
              ? 'MI finds the item that does not belong.'
              : 'MI cùng con tìm hình khác nhóm.',
        ),
        _choiceEntry(
          gameId: 'shadow_match',
          localizedName: const {
            'vi': 'Ghép bóng với vật',
            'en': 'Shadow Match',
          },
          category: 'logic',
          ageBands: const ['junior', 'explorer'],
          supportedSkills: const [
            'logic.matching',
            'logic.spatial_reasoning',
          ],
          brandIcon: MiBrandIcon.memory,
          primaryColor: MiColors.creative,
          worldLabel: (locale) => locale == 'en'
              ? 'MI matches each object to its shadow.'
              : 'MI cùng con ghép bóng với vật.',
        ),
        _choiceEntry(
          gameId: 'free_creativity',
          localizedName: const {
            'vi': 'Sáng tạo tự do',
            'en': 'Free Creativity',
          },
          category: 'creative',
          ageBands: const ['junior', 'explorer', 'master'],
          supportedSkills: const [
            'creative.storytelling',
            'letters.storytelling',
          ],
          brandIcon: MiBrandIcon.writing,
          primaryColor: MiColors.primary,
          worldLabel: (locale) => locale == 'en'
              ? 'MI helps turn ideas into a story.'
              : 'MI cùng con biến ý tưởng thành câu chuyện.',
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
