import 'dart:math';

import 'package:mi_game_core/mi_game_core.dart';

import '../game_locale_text.dart';

class SoundMatchSession {
  SoundMatchSession({
    required MiLevel level,
    this.childProfileId = 'offline-child',
    this.locale = 'vi',
  }) : _level = level {
    _resetForLevel(level);
  }

  MiLevel _level;
  final String childProfileId;
  final String locale;
  late List<String> _options;
  int _attempts = 0;
  int _hintsUsed = 0;
  bool _showTranscript = false;
  String? _feedback;

  MiLevel get level => _level;
  List<String> get options => List.unmodifiable(_options);
  int get attempts => _attempts;
  int get hintsUsed => _hintsUsed;
  bool get showTranscript => _showTranscript;
  String? get feedback => _feedback;

  Map<String, dynamic> get content => _level.contentForLocale(locale);
  GameLocaleText get _text => GameLocaleText(locale);

  String get correctAnswer => content['correctAnswer'] as String;

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

  void playPrompt() {
    _showTranscript = true;
    _feedback = _text.soundMatchPlaying;
  }

  bool choose(String option) {
    _attempts++;
    if (option == correctAnswer) {
      _feedback = null;
      return true;
    }

    _feedback = _text.soundMatchRetry;
    _showTranscript = true;
    return false;
  }

  void showHint() {
    final hints = _level.hints;
    if (hints.isEmpty) return;

    final hintIndex = min(_hintsUsed, hints.length - 1);
    final hint = _text.hintFrom(hints[hintIndex], hintIndex);
    _hintsUsed = min(_hintsUsed + 1, hints.length);
    _feedback = hint;
    _showTranscript = true;
  }

  MiGameSnapshot saveSnapshot({DateTime? now}) {
    return MiGameSnapshot(
      gameId: _level.gameId,
      levelId: _level.id,
      childProfileId: childProfileId,
      state: {
        'options': _options,
        'showTranscript': _showTranscript,
        'feedback': _feedback,
      },
      createdAt: now ?? DateTime.now().toUtc(),
      score: score,
      attemptsUsed: _attempts,
      hintsUsed: _hintsUsed,
      itemsCompleted:
          _showTranscript || _attempts > 0 || _hintsUsed > 0 ? 1 : 0,
      totalItems: 2,
      metadata: const {
        'snapshotKind': 'sound_match_session',
      },
    );
  }

  void restoreSnapshot(MiGameSnapshot snapshot) {
    if (snapshot.gameId != _level.gameId || snapshot.levelId != _level.id) {
      throw ArgumentError(
          'Snapshot does not belong to this Sound Match level.');
    }

    final state = snapshot.state;
    _options = (state['options'] as List).cast<String>();
    _showTranscript = state['showTranscript'] as bool? ?? false;
    _feedback = state['feedback'] as String?;
    _attempts = snapshot.attemptsUsed;
    _hintsUsed = snapshot.hintsUsed;
  }

  void _resetForLevel(MiLevel level) {
    final content = level.contentForLocale(locale);
    final options =
        List<String>.of((content['options'] as List).cast<String>());
    options.shuffle(Random(level.levelNumber));

    _options = options;
    _attempts = 0;
    _hintsUsed = 0;
    _showTranscript = false;
    _feedback = null;
  }
}
