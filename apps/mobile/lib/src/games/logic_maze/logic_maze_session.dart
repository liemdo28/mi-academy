import 'dart:collection';
import 'dart:math';

import 'package:mi_game_core/mi_game_core.dart';

import '../game_locale_text.dart';

enum LogicMazeRunStatus {
  idle,
  reachedGoal,
  hitObstacle,
  outOfBounds,
  incomplete,
  empty,
}

class LogicMazeRunResult {
  const LogicMazeRunResult({
    required this.status,
    required this.path,
  });

  final LogicMazeRunStatus status;
  final List<int> path;
}

class LogicMazeSession {
  LogicMazeSession({
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
  late int _startIndex;
  late int _goalIndex;
  late Set<int> _obstacles;
  late List<String> _authoredCommands;
  final List<String> _program = [];
  List<int> _visitedPath = const [];
  int _attempts = 0;
  int _hintsUsed = 0;
  String? _feedback;
  LogicMazeRunStatus _status = LogicMazeRunStatus.idle;

  MiLevel get level => _level;
  Map<String, dynamic> get content => _level.contentForLocale(locale);
  int get gridSize => _gridSize;
  int get startIndex => _startIndex;
  int get goalIndex => _goalIndex;
  Set<int> get obstacles => Set.unmodifiable(_obstacles);
  List<String> get authoredCommands => List.unmodifiable(_authoredCommands);
  List<String> get availableCommands => const ['up', 'right', 'down', 'left'];
  List<String> get program => List.unmodifiable(_program);
  List<int> get visitedPath => List.unmodifiable(
        _visitedPath.isEmpty ? [_startIndex] : _visitedPath,
      );
  int get currentIndex => visitedPath.last;
  int get attempts => _attempts;
  int get hintsUsed => _hintsUsed;
  String? get feedback => _feedback;
  LogicMazeRunStatus get status => _status;

  GameLocaleText get _text => GameLocaleText(locale);

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

  void addCommand(String command) {
    if (!availableCommands.contains(command)) return;
    _program.add(command);
    _feedback = null;
    _status = LogicMazeRunStatus.idle;
  }

  void removeLast() {
    if (_program.isEmpty) return;
    _program.removeLast();
    _feedback = null;
    _status = LogicMazeRunStatus.idle;
    _visitedPath = const [];
  }

  void resetProgram() {
    _program.clear();
    _visitedPath = [_startIndex];
    _feedback = null;
    _status = LogicMazeRunStatus.idle;
  }

  bool runProgram() {
    _attempts++;
    final result = simulate(_program);
    _visitedPath = result.path;
    _status = result.status;
    _feedback = _messageFor(result.status);
    return result.status == LogicMazeRunStatus.reachedGoal;
  }

  LogicMazeRunResult simulate(List<String> commands) {
    final path = <int>[_startIndex];
    if (commands.isEmpty) {
      return LogicMazeRunResult(status: LogicMazeRunStatus.empty, path: path);
    }

    var current = _startIndex;
    for (final command in commands) {
      final next = _nextIndex(current, command);
      if (next == null) {
        return LogicMazeRunResult(
          status: LogicMazeRunStatus.outOfBounds,
          path: path,
        );
      }
      path.add(next);
      if (_obstacles.contains(next)) {
        return LogicMazeRunResult(
          status: LogicMazeRunStatus.hitObstacle,
          path: path,
        );
      }
      current = next;
    }

    return LogicMazeRunResult(
      status: current == _goalIndex
          ? LogicMazeRunStatus.reachedGoal
          : LogicMazeRunStatus.incomplete,
      path: path,
    );
  }

  void showHint() {
    final hints = _level.hints;
    if (hints.isEmpty) return;

    final hintIndex = min(_hintsUsed, hints.length - 1);
    final hint = _text.hintFrom(hints[hintIndex], hintIndex);
    _hintsUsed = min(_hintsUsed + 1, hints.length);
    _feedback = hint;
  }

  MiGameSnapshot saveSnapshot({DateTime? now}) {
    return MiGameSnapshot(
      gameId: _level.gameId,
      levelId: _level.id,
      childProfileId: childProfileId,
      state: {
        'program': List<String>.from(_program),
        'visitedPath': List<int>.from(visitedPath),
        'feedback': _feedback,
        'status': _status.name,
      },
      createdAt: now ?? DateTime.now().toUtc(),
      score: score,
      attemptsUsed: _attempts,
      hintsUsed: _hintsUsed,
      itemsCompleted: _program.length,
      totalItems: max(1, _authoredCommands.length),
      metadata: const {
        'snapshotKind': 'logic_maze_session',
      },
    );
  }

  void restoreSnapshot(MiGameSnapshot snapshot) {
    if (snapshot.gameId != _level.gameId || snapshot.levelId != _level.id) {
      throw ArgumentError('Snapshot does not belong to this Logic Maze level.');
    }
    final state = snapshot.state;
    _program
      ..clear()
      ..addAll((state['program'] as List? ?? const []).map((e) => '$e'));
    _visitedPath = (state['visitedPath'] as List? ?? [_startIndex])
        .whereType<num>()
        .map((value) => value.toInt())
        .toList(growable: false);
    if (_visitedPath.isEmpty) _visitedPath = [_startIndex];
    _feedback = state['feedback'] as String?;
    _status = LogicMazeRunStatus.values.firstWhere(
      (status) => status.name == state['status'],
      orElse: () => LogicMazeRunStatus.idle,
    );
    _attempts = snapshot.attemptsUsed;
    _hintsUsed = snapshot.hintsUsed;
  }

  int? _nextIndex(int index, String command) {
    final row = index ~/ _gridSize;
    final col = index % _gridSize;
    final next = switch (command) {
      'up' => row == 0 ? null : (row - 1) * _gridSize + col,
      'down' => row == _gridSize - 1 ? null : (row + 1) * _gridSize + col,
      'left' => col == 0 ? null : row * _gridSize + col - 1,
      'right' => col == _gridSize - 1 ? null : row * _gridSize + col + 1,
      _ => null,
    };
    return next;
  }

  String _messageFor(LogicMazeRunStatus status) {
    return switch (status) {
      LogicMazeRunStatus.reachedGoal => _text.mazeDone,
      LogicMazeRunStatus.hitObstacle => _text.mazeHitWall,
      LogicMazeRunStatus.outOfBounds => _text.mazeOutOfBounds,
      LogicMazeRunStatus.incomplete => _text.mazeRetry,
      LogicMazeRunStatus.empty => _text.mazeEmpty,
      LogicMazeRunStatus.idle => '',
    };
  }

  void _resetForLevel(MiLevel level) {
    final data = _deepDataOf(level);
    _gridSize = _asInt(data['gridSize']) ?? 4;
    _startIndex = _asInt(data['startIndex']) ?? (_gridSize - 1) * _gridSize;
    _goalIndex = _asInt(data['goalIndex']) ?? _gridSize - 1;
    _obstacles = _asIntList(data['obstacles']).toSet();
    _authoredCommands = _asStringList(data['commands']);
    _program.clear();
    _visitedPath = [_startIndex];
    _attempts = 0;
    _hintsUsed = 0;
    _feedback = null;
    _status = LogicMazeRunStatus.idle;
  }

  static bool isLevelReachable(MiLevel level) {
    final data = _deepDataOf(level);
    final size = _asInt(data['gridSize']) ?? 4;
    final start = _asInt(data['startIndex']) ?? (size - 1) * size;
    final goal = _asInt(data['goalIndex']) ?? size - 1;
    final obstacles = _asIntList(data['obstacles']).toSet();
    final maxIndex = size * size - 1;
    if (size < 2 ||
        start < 0 ||
        start > maxIndex ||
        goal < 0 ||
        goal > maxIndex ||
        obstacles.contains(start) ||
        obstacles.contains(goal)) {
      return false;
    }

    final seen = <int>{start};
    final queue = Queue<int>()..add(start);
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (current == goal) return true;
      for (final next in _neighbors(current, size)) {
        if (!obstacles.contains(next) && seen.add(next)) {
          queue.add(next);
        }
      }
    }
    return false;
  }

  static Iterable<int> _neighbors(int index, int size) sync* {
    final row = index ~/ size;
    final col = index % size;
    if (row > 0) yield (row - 1) * size + col;
    if (row < size - 1) yield (row + 1) * size + col;
    if (col > 0) yield row * size + col - 1;
    if (col < size - 1) yield row * size + col + 1;
  }

  static Map<String, dynamic> _deepDataOf(MiLevel level) {
    final value = level.metadata['deepData'];
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static int? _asInt(Object? value) => value is num ? value.toInt() : null;

  static List<int> _asIntList(Object? value) {
    if (value is! List) return const [];
    return value.whereType<num>().map((item) => item.toInt()).toList();
  }

  static List<String> _asStringList(Object? value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList(growable: false);
  }
}
