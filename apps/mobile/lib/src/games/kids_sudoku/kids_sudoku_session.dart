import 'dart:math';

import 'package:mi_game_core/mi_game_core.dart';

import '../game_locale_text.dart';

enum KidsSudokuStatus {
  idle,
  complete,
  empty,
  rowConflict,
  columnConflict,
  regionConflict,
  incorrect,
}

class KidsSudokuSession {
  KidsSudokuSession({
    required MiLevel level,
    this.childProfileId = 'offline-child',
    this.locale = 'vi',
  }) : _level = level {
    _resetForLevel(level);
  }

  MiLevel _level;
  final String childProfileId;
  final String locale;
  late int _gridSize;
  late List<String> _symbols;
  late Map<int, String> _givens;
  late int _blankIndex;
  late String _answer;
  final Map<int, String> _entries = {};
  int _attempts = 0;
  int _hintsUsed = 0;
  KidsSudokuStatus _status = KidsSudokuStatus.idle;
  String? _feedback;

  MiLevel get level => _level;
  Map<String, dynamic> get content => _level.contentForLocale(locale);
  int get gridSize => _gridSize;
  List<String> get symbols => List.unmodifiable(_symbols);
  Map<int, String> get givens => Map.unmodifiable(_givens);
  int get blankIndex => _blankIndex;
  int get attempts => _attempts;
  int get hintsUsed => _hintsUsed;
  KidsSudokuStatus get status => _status;
  String? get feedback => _feedback;
  GameLocaleText get _text => GameLocaleText(locale);

  String? valueAt(int index) => _givens[index] ?? _entries[index];
  bool isFixed(int index) => _givens.containsKey(index);
  bool isEditable(int index) => index == _blankIndex;

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

  void setSymbol(String symbol) {
    if (!_symbols.contains(symbol)) return;
    _entries[_blankIndex] = symbol;
    _status = KidsSudokuStatus.idle;
    _feedback = null;
  }

  void erase() {
    _entries.remove(_blankIndex);
    _status = KidsSudokuStatus.idle;
    _feedback = null;
  }

  bool check() {
    _attempts++;
    _status = validate();
    _feedback = _messageFor(_status);
    return _status == KidsSudokuStatus.complete;
  }

  KidsSudokuStatus validate() {
    final value = _entries[_blankIndex];
    if (value == null || value.isEmpty) return KidsSudokuStatus.empty;
    if (_hasDuplicate(_rowIndexes(_blankIndex), value)) {
      return KidsSudokuStatus.rowConflict;
    }
    if (_hasDuplicate(_columnIndexes(_blankIndex), value)) {
      return KidsSudokuStatus.columnConflict;
    }
    if (_hasDuplicate(_regionIndexes(_blankIndex), value)) {
      return KidsSudokuStatus.regionConflict;
    }
    return value == _answer
        ? KidsSudokuStatus.complete
        : KidsSudokuStatus.incorrect;
  }

  void showHint() {
    final hints = _level.hints;
    if (hints.isEmpty) {
      _feedback = _text.sudokuHint;
      return;
    }
    final hintIndex = min(_hintsUsed, hints.length - 1);
    _feedback = _text.hintFrom(hints[hintIndex], hintIndex);
    _hintsUsed = min(_hintsUsed + 1, hints.length);
  }

  MiGameSnapshot saveSnapshot({DateTime? now}) {
    return MiGameSnapshot(
      gameId: _level.gameId,
      levelId: _level.id,
      childProfileId: childProfileId,
      state: {
        'entries': _entries.map((key, value) => MapEntry('$key', value)),
        'feedback': _feedback,
        'status': _status.name,
      },
      createdAt: now ?? DateTime.now().toUtc(),
      score: score,
      attemptsUsed: _attempts,
      hintsUsed: _hintsUsed,
      itemsCompleted: _entries.containsKey(_blankIndex) ? 1 : 0,
      totalItems: 1,
      metadata: const {
        'snapshotKind': 'kids_sudoku_session',
      },
    );
  }

  void restoreSnapshot(MiGameSnapshot snapshot) {
    if (snapshot.gameId != _level.gameId || snapshot.levelId != _level.id) {
      throw ArgumentError(
          'Snapshot does not belong to this Kids Sudoku level.');
    }
    _entries
      ..clear()
      ..addAll((snapshot.state['entries'] as Map? ?? const {}).map(
        (key, value) => MapEntry(int.parse('$key'), '$value'),
      ));
    _feedback = snapshot.state['feedback'] as String?;
    _status = KidsSudokuStatus.values.firstWhere(
      (status) => status.name == snapshot.state['status'],
      orElse: () => KidsSudokuStatus.idle,
    );
    _attempts = snapshot.attemptsUsed;
    _hintsUsed = snapshot.hintsUsed;
  }

  bool _hasDuplicate(Iterable<int> indexes, String value) {
    return indexes.where((index) => index != _blankIndex).any(
          (index) => valueAt(index) == value,
        );
  }

  Iterable<int> _rowIndexes(int index) sync* {
    final row = index ~/ _gridSize;
    for (var col = 0; col < _gridSize; col++) {
      yield row * _gridSize + col;
    }
  }

  Iterable<int> _columnIndexes(int index) sync* {
    final col = index % _gridSize;
    for (var row = 0; row < _gridSize; row++) {
      yield row * _gridSize + col;
    }
  }

  Iterable<int> _regionIndexes(int index) sync* {
    final (height, width) = _regionShape(_gridSize);
    final row = index ~/ _gridSize;
    final col = index % _gridSize;
    final startRow = (row ~/ height) * height;
    final startCol = (col ~/ width) * width;
    for (var r = startRow; r < startRow + height; r++) {
      for (var c = startCol; c < startCol + width; c++) {
        yield r * _gridSize + c;
      }
    }
  }

  String _messageFor(KidsSudokuStatus status) {
    return switch (status) {
      KidsSudokuStatus.complete => _text.sudokuDone,
      KidsSudokuStatus.empty => _text.sudokuEmpty,
      KidsSudokuStatus.rowConflict => _text.sudokuRowConflict,
      KidsSudokuStatus.columnConflict => _text.sudokuColumnConflict,
      KidsSudokuStatus.regionConflict => _text.sudokuRegionConflict,
      KidsSudokuStatus.incorrect => _text.sudokuRetry,
      KidsSudokuStatus.idle => '',
    };
  }

  void _resetForLevel(MiLevel level) {
    final data = _deepDataOf(level);
    _gridSize = _asInt(data['gridSize']) ?? 3;
    _symbols = _asStringList(data['symbols']);
    if (_symbols.isEmpty) _symbols = const ['A', 'B', 'C'];
    _blankIndex = _asInt(data['blankIndex']) ?? 0;
    _givens = _asIntStringMap(data['givens']);
    _answer = (data['answer'] as String?) ?? _symbols.first;
    _entries.clear();
    _attempts = 0;
    _hintsUsed = 0;
    _status = KidsSudokuStatus.idle;
    _feedback = null;
  }

  static bool isLevelSolvable(MiLevel level) {
    final session = KidsSudokuSession(level: level, locale: 'en')
      ..setSymbol((_deepDataOf(level)['answer'] as String?) ?? '');
    return session.validate() == KidsSudokuStatus.complete;
  }

  static (int height, int width) _regionShape(int size) {
    final root = sqrt(size).round();
    if (root * root == size) return (root, root);
    return (1, size);
  }

  static Map<String, dynamic> _deepDataOf(MiLevel level) {
    final value = level.metadata['deepData'];
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static int? _asInt(Object? value) => value is num ? value.toInt() : null;

  static List<String> _asStringList(Object? value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList(growable: false);
  }

  static Map<int, String> _asIntStringMap(Object? value) {
    if (value is! Map) return const {};
    final result = <int, String>{};
    for (final entry in value.entries) {
      final parsedKey = int.tryParse(entry.key.toString());
      if (parsedKey != null) result[parsedKey] = entry.value.toString();
    }
    return result;
  }
}
