import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';
import 'package:mi_game_content/mi_game_content.dart';

import 'screens/parent_pin_screen.dart';
import 'screens/parent_settings_screen.dart';
import 'services/parent_settings_store.dart';
import 'src/games/choice/choice_game_screen.dart';
import 'src/games/memory_cards/memory_cards_game.dart';
import 'src/games/memory_cards/memory_cards_screen.dart';
import 'src/games/robot_commands/robot_commands_screen.dart';
import 'src/games/sound_match/sound_match_screen.dart';
import 'src/games/word_builder/word_builder_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final parentSettingsStore = await HiveParentSettingsStore.open();
  runApp(MiAcademyApp(parentSettingsStore: parentSettingsStore));
}

class MiAcademyApp extends StatelessWidget {
  MiAcademyApp({
    super.key,
    ParentSettingsStore? parentSettingsStore,
  }) : parentSettingsStore = parentSettingsStore ?? MemoryParentSettingsStore();

  final ParentSettingsStore parentSettingsStore;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'MI Academy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: GameTheme.primary,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: HomeScreen(parentSettingsStore: parentSettingsStore),
      ),
    );
  }
}

/// Simple home screen — shows the first playable MVP game slices.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.parentSettingsStore});

  final ParentSettingsStore parentSettingsStore;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  Map<String, List<MiLevel>> _levelsByGame = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    try {
      final provider = GameContentProvider();
      final assetBundle = DefaultAssetBundle.of(context);
      final levelsByGame = <String, List<MiLevel>>{};
      for (final entry in _gameAssets.entries) {
        final json = await assetBundle.loadString(entry.value);
        final data = convert.jsonDecode(json) as Map<String, dynamic>;
        final levelData = (data['levels'] as List)
            .map((level) => Map<String, dynamic>.from(level as Map))
            .toList();
        levelsByGame[entry.key] = await provider.loadLevels(
          levelData,
          gameId: entry.key,
        );
      }
      setState(() {
        _levelsByGame = levelsByGame;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.background,
      appBar: AppBar(
        title: const Text('MI Academy'),
        centerTitle: true,
        backgroundColor: GameTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    'Lỗi: $_error',
                    style: GameTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                )
              : _buildGameList(),
    );
  }

  Widget _buildGameList() {
    return ListView(
      padding: GameTheme.screenPadding,
      children: [
        const Text('Thế giới khám phá', style: GameTheme.headingLarge),
        const SizedBox(height: 8),
        const Text(
          'MI chọn sẵn vài nhiệm vụ nhẹ nhàng cho hôm nay.',
          style: GameTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        const _ChildProfileCard(),
        const SizedBox(height: 12),
        _ParentAreaCard(onTap: _openParentGate),
        const SizedBox(height: 16),
        _GameCard(
          title: 'Ghép chữ tạo từ',
          subtitle: 'Thành phố chữ cái - 10 cấp độ',
          icon: Icons.abc_rounded,
          color: GameTheme.primary,
          levels: _levelsFor('word_builder'),
          onLaunch: () => _launchGame('word_builder'),
        ),
        const SizedBox(height: 12),
        _GameCard(
          title: 'Nghe âm tìm chữ',
          subtitle: 'Thành phố chữ cái - 10 cấp độ',
          icon: Icons.volume_up_rounded,
          color: GameTheme.secondary,
          levels: _levelsFor('sound_match'),
          onLaunch: () => _launchGame('sound_match'),
        ),
        const SizedBox(height: 12),
        _GameCard(
          title: 'Đường đua cộng trừ',
          subtitle: 'Vương quốc toán học - 10 cấp độ',
          icon: Icons.directions_car_rounded,
          color: GameTheme.warning,
          levels: _levelsFor('math_race'),
          onLaunch: () => _launchGame('math_race'),
        ),
        const SizedBox(height: 12),
        _GameCard(
          title: 'Siêu thị toán học',
          subtitle: 'Vương quốc toán học - 10 cấp độ',
          icon: Icons.shopping_cart_rounded,
          color: MiGameColors.tertiary,
          levels: _levelsFor('math_supermarket'),
          onLaunch: () => _launchGame('math_supermarket'),
        ),
        const SizedBox(height: 12),
        _GameCard(
          title: 'Ghi nhớ vị trí',
          subtitle: 'Đảo tư duy - 10 cấp độ',
          icon: Icons.style_rounded,
          color: GameTheme.success,
          levels: _levelsFor('memory_cards'),
          onLaunch: () => _launchGame('memory_cards'),
        ),
        const SizedBox(height: 12),
        _GameCard(
          title: 'Robot làm theo lệnh',
          subtitle: 'Đảo tư duy - 10 cấp độ',
          icon: Icons.smart_toy_rounded,
          color: GameTheme.primary,
          levels: _levelsFor('robot_commands'),
          onLaunch: () => _launchGame('robot_commands'),
        ),
      ],
    );
  }

  List<MiLevel> _levelsFor(String gameId) => _levelsByGame[gameId] ?? const [];

  void _launchGame(String gameId) {
    final levels = _levelsFor(gameId);
    if (levels.isEmpty) return;

    Widget screen;
    switch (gameId) {
      case 'word_builder':
        screen = WordBuilderScreen(
          level: levels.first,
          allLevels: levels,
          onExit: () => Navigator.of(context).pop(),
        );
      case 'sound_match':
        screen = SoundMatchScreen(
          level: levels.first,
          allLevels: levels,
          onExit: () => Navigator.of(context).pop(),
        );
      case 'math_race':
        screen = ChoiceGameScreen(
          title: 'Đường đua cộng trừ',
          worldLabel: 'Xe MI tiến lên khi con chọn đúng.',
          level: levels.first,
          allLevels: levels,
          heroIcon: Icons.directions_car_rounded,
          primaryColor: GameTheme.warning,
          onExit: () => Navigator.of(context).pop(),
        );
      case 'math_supermarket':
        screen = ChoiceGameScreen(
          title: 'Siêu thị toán học',
          worldLabel: 'Giỏ hàng MI giúp con luyện tính tiền.',
          level: levels.first,
          allLevels: levels,
          heroIcon: Icons.shopping_cart_rounded,
          primaryColor: MiGameColors.tertiary,
          onExit: () => Navigator.of(context).pop(),
        );
      case 'memory_cards':
        screen = _MemoryCardsEntry(level: levels.first, allLevels: levels);
      case 'robot_commands':
        screen = RobotCommandsScreen(
          level: levels.first,
          allLevels: levels,
          onExit: () => Navigator.of(context).pop(),
        );
      default:
        return;
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openParentGate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParentPinScreen(
          enableBiometricPrompt: false,
          onClose: () => Navigator.of(context).pop(),
          onUnlocked: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => LocalParentAreaScreen(
                  parentSettingsStore: widget.parentSettingsStore,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChildProfileCard extends StatelessWidget {
  const _ChildProfileCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
      ),
      child: Padding(
        padding: GameTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: GameTheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: GameTheme.primary,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hồ sơ của bé', style: GameTheme.headingMedium),
                      SizedBox(height: 4),
                      Text(
                        'MI Junior - hôm nay học nhẹ 15-25 phút',
                        style: GameTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(icon: Icons.star_rounded, label: 'Sao MI: 0'),
                _StatusChip(
                  icon: Icons.verified_rounded,
                  label: 'Huy hiệu: sẵn sàng',
                ),
                _StatusChip(
                  icon: Icons.offline_bolt_rounded,
                  label: '6 game offline',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: GameTheme.primary),
      label: Text(label),
      backgroundColor: Colors.white,
      side: BorderSide(color: GameTheme.primary.withValues(alpha: 0.22)),
    );
  }
}

class _ParentAreaCard extends StatelessWidget {
  const _ParentAreaCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
      ),
      child: ListTile(
        leading:
            const Icon(Icons.family_restroom_rounded, color: GameTheme.primary),
        title: const Text('Khu vực phụ huynh', style: GameTheme.headingMedium),
        subtitle: const Text('Báo cáo tiến độ, cài đặt và dữ liệu của bé'),
        trailing: const Icon(Icons.lock_rounded, color: GameTheme.primary),
        onTap: onTap,
      ),
    );
  }
}

class LocalParentAreaScreen extends StatelessWidget {
  const LocalParentAreaScreen({
    super.key,
    required this.parentSettingsStore,
  });

  final ParentSettingsStore parentSettingsStore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.background,
      appBar: AppBar(
        title: const Text('Khu vực phụ huynh'),
        backgroundColor: GameTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Cài đặt',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ParentSettingsScreen(store: parentSettingsStore),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: GameTheme.screenPadding,
          children: [
            const Text('Báo cáo nhẹ nhàng', style: GameTheme.headingLarge),
            const SizedBox(height: 8),
            const Text(
              'MI chỉ tóm tắt tiến độ để phụ huynh đồng hành, không xếp hạng hay tạo áp lực điểm số.',
            ),
            const SizedBox(height: 16),
            const _ParentMetricGrid(),
            const SizedBox(height: 16),
            const _ParentInfoCard(
              icon: Icons.favorite_rounded,
              title: 'Kỹ năng đang làm tốt',
              body: 'Nhận biết chữ cái, đếm số và quan sát thẻ nhớ.',
              color: GameTheme.success,
            ),
            const SizedBox(height: 12),
            const _ParentInfoCard(
              icon: Icons.lightbulb_rounded,
              title: 'Gợi ý luyện thêm',
              body: 'Cùng bé đọc một từ ngắn và đếm đồ vật trong nhà.',
              color: GameTheme.warning,
            ),
            const SizedBox(height: 12),
            const _ParentInfoCard(
              icon: Icons.offline_bolt_rounded,
              title: 'Offline',
              body: 'Sáu trò chơi MVP có thể mở từ nội dung đã tải trong app.',
              color: GameTheme.primary,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Mở cài đặt phụ huynh'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ParentSettingsScreen(store: parentSettingsStore),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentMetricGrid extends StatelessWidget {
  const _ParentMetricGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: const [
        _MetricTile(label: 'Hôm nay', value: '0 phút', icon: Icons.timer),
        _MetricTile(label: 'Bài hoàn thành', value: '0', icon: Icons.task_alt),
        _MetricTile(label: 'Sao MI', value: '0', icon: Icons.star),
        _MetricTile(label: 'Tuần này', value: 'Mẫu', icon: Icons.bar_chart),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: GameTheme.primary),
            Text(value, style: GameTheme.headingMedium),
            Text(label, style: GameTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ParentInfoCard extends StatelessWidget {
  const _ParentInfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: GameTheme.cardPadding,
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GameTheme.headingMedium),
                  const SizedBox(height: 4),
                  Text(body, style: GameTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.levels,
    required this.onLaunch,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<MiLevel> levels;
  final VoidCallback onLaunch;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
        onTap: levels.isNotEmpty ? onLaunch : null,
        child: Padding(
          padding: GameTheme.cardPadding,
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GameTheme.headingMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: GameTheme.bodyMedium),
                    const SizedBox(height: 8),
                    ProgressDots(
                      total: levels.length,
                      completed: 0,
                      color: color,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

const _gameAssets = {
  'word_builder': 'assets/levels/word_builder.json',
  'sound_match': 'assets/levels/sound_match.json',
  'math_race': 'assets/levels/math_race.json',
  'math_supermarket': 'assets/levels/math_supermarket.json',
  'memory_cards': 'assets/levels/memory_cards.json',
  'robot_commands': 'assets/levels/robot_commands.json',
};

class _MemoryCardsEntry extends StatefulWidget {
  const _MemoryCardsEntry({required this.level, required this.allLevels});

  final MiLevel level;
  final List<MiLevel> allLevels;

  @override
  State<_MemoryCardsEntry> createState() => _MemoryCardsEntryState();
}

class _MemoryCardsEntryState extends State<_MemoryCardsEntry> {
  late MemoryCardsGame _game;

  @override
  void initState() {
    super.initState();
    _game = MemoryCardsGame();
  }

  @override
  void dispose() {
    _game.dispose();
    super.dispose();
  }

  void _onComplete(MiCompletionResult result) {
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
          // Advance to next level
          final nextIdx =
              widget.allLevels.indexWhere((l) => l.id == widget.level.id) + 1;
          if (nextIdx < widget.allLevels.length) {
            setState(() {
              _game = MemoryCardsGame();
              _launchLevel(widget.allLevels[nextIdx]);
            });
          }
        },
        onReplay: () {
          Navigator.of(context).pop();
          setState(() {
            _game = MemoryCardsGame();
            _launchLevel(widget.level);
          });
        },
        onExit: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _launchLevel(MiLevel level) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MemoryCardsScreen(
          game: _game,
          level: level,
          onComplete: _onComplete,
          onExit: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MemoryCardsScreen(
      game: _game,
      level: widget.level,
      onComplete: _onComplete,
      onExit: () {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      },
    );
  }
}
