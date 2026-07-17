import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String childId;
  final String gameType;
  const GameScreen({super.key, required this.childId, required this.gameType});

  @override
  ConsumerState<GameScreen> createState() => _GameState();
}

class _GameState extends ConsumerState<GameScreen> {
  int _level = 1;
  int _score = 0;
  int _stars = 0;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: Text(_gameTitle()),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(children: [
              const Icon(Icons.star, color: MiColors.accent),
              const SizedBox(width: 4),
              Text('$_stars',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              Text('$_score điểm',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                  value: _level / 10, color: MiColors.primary),
              const SizedBox(height: 12),
              Text('Cấp độ $_level',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
              // MI robot helper
              if (!_completed) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MiColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: MiColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: const Row(children: [
                    Text('🤖', style: TextStyle(fontSize: 48)),
                    SizedBox(width: 12),
                    Expanded(
                        child: Text('Gần đúng rồi, mình thử lại nhé!',
                            style: TextStyle(fontSize: 16))),
                  ]),
                ),
                const SizedBox(height: 20),
                // Demo game action buttons
                ElevatedButton(
                  onPressed: _answer,
                  child: const Text('Trả lời đúng'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _answer,
                  child: const Text('Thử lại'),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _hint,
                  icon: const Icon(Icons.lightbulb),
                  label: const Text('Gợi ý'),
                ),
              ] else ...[
                Center(
                  child: Column(children: [
                    const Icon(Icons.celebration,
                        size: 80, color: MiColors.accent),
                    const SizedBox(height: 16),
                    Text('Tuyệt vời!',
                        style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 8),
                    const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, color: MiColors.accent, size: 32),
                          Icon(Icons.star, color: MiColors.accent, size: 32),
                          Icon(Icons.star, color: MiColors.accent, size: 32),
                        ]),
                    const SizedBox(height: 24),
                    ElevatedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Quay lại bản đồ')),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _answer() {
    setState(() {
      _score += 10;
      _stars += 1;
      if (_level >= 10) {
        _completed = true;
      } else {
        _level += 1;
      }
    });
  }

  void _hint() {
    // Hint doesn't cost stars
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('💡 MI gợi ý: hãy đếm từng bước nhé!')),
    );
  }

  String _gameTitle() {
    switch (widget.gameType) {
      case 'word_builder':
        return 'Ghép chữ tạo từ';
      case 'sound_match':
        return 'Nghe âm tìm chữ';
      case 'math_race':
        return 'Đường đua cộng trừ';
      case 'math_supermarket':
        return 'Siêu thị toán học';
      case 'memory_cards':
        return 'Ghi nhớ vị trí';
      case 'robot_commands':
        return 'Robot làm theo lệnh';
      default:
        return 'Trò chơi';
    }
  }
}
