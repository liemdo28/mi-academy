import 'dart:math';

import 'package:mi_game_core/mi_game_core.dart';

class ChoiceGameSession {
  ChoiceGameSession({
    required MiLevel level,
    this.childProfileId = 'offline-child',
  }) : _level = level {
    _resetForLevel(level);
  }

  MiLevel _level;
  final String childProfileId;
  late List<ChoiceGameOption> _options;
  int _attempts = 0;
  int _hintsUsed = 0;
  double _progress = 0.12;
  String? _feedback;

  MiLevel get level => _level;
  List<ChoiceGameOption> get options => List.unmodifiable(_options);
  int get attempts => _attempts;
  int get hintsUsed => _hintsUsed;
  double get progress => _progress;
  String? get feedback => _feedback;

  Map<String, dynamic> get content => _level.contentForLocale('vi');

  int get score => max(10, 100 - (_attempts - 1) * 10 - _hintsUsed * 5);

  int get stars {
    if (_attempts <= 1 && _hintsUsed == 0) return 3;
    if (_attempts <= 2) return 2;
    return 1;
  }

  void loadLevel(MiLevel level) {
    _level = level;
    _resetForLevel(level);
  }

  bool choose(ChoiceGameOption option) {
    _attempts++;
    if (option.correct) {
      _progress = 1;
      _feedback = 'Đúng rồi, xe của MI tiến lên!';
      return true;
    }

    _progress = min(0.86, _progress + 0.18);
    _feedback = 'Gần đúng rồi, mình thử cách khác nhé!';
    return false;
  }

  void showHint() {
    final hints = _level.hints;
    if (hints.isEmpty) return;

    final hint = hints[min(_hintsUsed, hints.length - 1)]['text'] as String;
    _hintsUsed = min(_hintsUsed + 1, hints.length);
    _feedback = hint;
  }

  MiGameSnapshot saveSnapshot({DateTime? now}) {
    return MiGameSnapshot(
      gameId: _level.gameId,
      levelId: _level.id,
      childProfileId: childProfileId,
      state: {
        'progress': _progress,
        'feedback': _feedback,
      },
      createdAt: now ?? DateTime.now().toUtc(),
      score: score,
      attemptsUsed: _attempts,
      hintsUsed: _hintsUsed,
      itemsCompleted: _attempts > 0 || _hintsUsed > 0 ? 1 : 0,
      totalItems: 2,
      metadata: const {
        'snapshotKind': 'choice_game_session',
      },
    );
  }

  void restoreSnapshot(MiGameSnapshot snapshot) {
    if (snapshot.gameId != _level.gameId || snapshot.levelId != _level.id) {
      throw ArgumentError('Snapshot does not belong to this choice level.');
    }

    final state = snapshot.state;
    _progress = (state['progress'] as num?)?.toDouble() ?? 0.12;
    _feedback = state['feedback'] as String?;
    _attempts = snapshot.attemptsUsed;
    _hintsUsed = snapshot.hintsUsed;
  }

  void _resetForLevel(MiLevel level) {
    final content = level.contentForLocale('vi');
    _options = (content['options'] as List)
        .map((option) => ChoiceGameOption.fromJson(option as Map))
        .toList();
    _attempts = 0;
    _hintsUsed = 0;
    _progress = 0.12;
    _feedback = null;
  }
}

class ChoiceGameOption {
  const ChoiceGameOption({required this.text, required this.correct});

  factory ChoiceGameOption.fromJson(Map<dynamic, dynamic> json) {
    return ChoiceGameOption(
      text: json['text'] as String,
      correct: json['correct'] as bool? ?? false,
    );
  }

  final String text;
  final bool correct;
}
