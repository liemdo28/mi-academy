import 'dart:math';

import 'package:mi_game_core/mi_game_core.dart';
import 'package:localization/localization.dart';

class WordBuilderSession {
  WordBuilderSession({
    required MiLevel level,
    this.childProfileId = 'offline-child',
    this.locale = 'vi',
  }) : _level = level {
    _resetForLevel(level);
  }

  MiLevel _level;
  final String childProfileId;
  final String locale;
  late List<String> _bank;
  late List<String?> _placed;
  int _attempts = 0;
  int _hintsUsed = 0;
  String? _feedback;

  MiLevel get level => _level;
  List<String> get bank => List.unmodifiable(_bank);
  List<String?> get placed => List.unmodifiable(_placed);
  int get attempts => _attempts;
  int get hintsUsed => _hintsUsed;
  String? get feedback => _feedback;

  Map<String, dynamic> get content => _level.contentForLocale(locale);

  String get targetWord => content['targetWord'] as String? ?? '';

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

  void placeLetter(int bankIndex) {
    final slotIndex = _placed.indexWhere((letter) => letter == null);
    if (slotIndex == -1 || bankIndex < 0 || bankIndex >= _bank.length) return;
    _placed[slotIndex] = _bank.removeAt(bankIndex);
    _feedback = null;
  }

  void removeLetter(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= _placed.length) return;
    final letter = _placed[slotIndex];
    if (letter == null) return;
    _placed[slotIndex] = null;
    _bank.add(letter);
    _feedback = null;
  }

  bool checkAnswer() {
    if (_placed.any((letter) => letter == null)) {
      _feedback = MiMobileStrings.m237;
      return false;
    }

    _attempts++;
    if (_placed.join() == targetWord) {
      _feedback = null;
      return true;
    }

    _feedback = MiMobileStrings.m238;
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
      state: {'placed': _placed, 'bank': _bank, 'feedback': _feedback},
      createdAt: now ?? DateTime.now().toUtc(),
      score: score,
      attemptsUsed: _attempts,
      hintsUsed: _hintsUsed,
      itemsCompleted: _placed.whereType<String>().length,
      totalItems: _placed.length,
      metadata: const {'snapshotKind': 'word_builder_session'},
    );
  }

  void restoreSnapshot(MiGameSnapshot snapshot) {
    if (snapshot.gameId != _level.gameId || snapshot.levelId != _level.id) {
      throw ArgumentError(
        'Snapshot does not belong to this Word Builder level.',
      );
    }

    final state = snapshot.state;
    _placed = (state['placed'] as List)
        .map((value) => value == null ? null : value as String)
        .toList();
    _bank = (state['bank'] as List).cast<String>();
    _feedback = state['feedback'] as String?;
    _attempts = snapshot.attemptsUsed;
    _hintsUsed = snapshot.hintsUsed;
  }

  void _resetForLevel(MiLevel level) {
    final content = level.contentForLocale(locale);
    final targetTokens = (content['letters'] as List).cast<String>();
    final distractors =
        (content['distractors'] as List? ?? const []).cast<String>();
    final bank = [...targetTokens, ...distractors];
    bank.shuffle(Random(level.levelNumber));

    _bank = bank;
    _placed = List<String?>.filled(targetTokens.length, null);
    _attempts = 0;
    _hintsUsed = 0;
    _feedback = null;
  }
}
