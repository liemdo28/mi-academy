import 'dart:math';

import 'package:mi_blocks/mi_blocks.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:localization/localization.dart';

class RobotCommandsSession {
  RobotCommandsSession({
    required MiLevel level,
    this.childProfileId = 'offline-child',
    this.locale = 'vi',
  }) : _level = level {
    _resetForLevel(level);
  }

  MiLevel _level;
  final String childProfileId;
  final String locale;
  late RobotGrid _grid;
  late RobotState _initialState;
  late RobotState _robotState;
  late List<BlockType> _availableCommands;
  final List<BlockType> _program = [];
  int _attempts = 0;
  int _hintsUsed = 0;
  String? _feedback;

  MiLevel get level => _level;
  RobotGrid get grid => _grid;
  RobotState get initialState => _initialState;
  RobotState get robotState => _robotState;
  List<BlockType> get availableCommands =>
      List.unmodifiable(_availableCommands);
  List<BlockType> get program => List.unmodifiable(_program);
  int get attempts => _attempts;
  int get hintsUsed => _hintsUsed;
  String? get feedback => _feedback;

  Map<String, dynamic> get content => _level.contentForLocale(locale);

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

  void addCommand(BlockType type) {
    _program.add(type);
    _feedback = null;
  }

  void removeLast() {
    if (_program.isEmpty) return;
    _program.removeLast();
    _feedback = null;
  }

  void removeAt(int index) {
    if (index < 0 || index >= _program.length) return;
    _program.removeAt(index);
    _feedback = null;
  }

  void moveCommand(int index, int offset) {
    final newIndex = index + offset;
    if (index < 0 ||
        index >= _program.length ||
        newIndex < 0 ||
        newIndex >= _program.length) {
      return;
    }

    final command = _program.removeAt(index);
    _program.insert(newIndex, command);
    _feedback = null;
  }

  void resetProgram() {
    _program.clear();
    _robotState = _initialState.copy();
    _feedback = null;
  }

  bool runProgram() {
    _attempts++;
    final tree = _buildCommandTree();

    final errors = tree.validate();
    if (errors.isNotEmpty) {
      _feedback = errors.first;
      return false;
    }

    final interpreter = BlockInterpreter(grid: _grid);
    final steps = interpreter.execute(tree, initialState: _initialState);
    final finalState = steps.isEmpty ? _initialState.copy() : steps.last.state;
    final reachedGoal = interpreter.reachedGoal(finalState);
    final collectedAll =
        _grid.collectibles.difference(finalState.collected).isEmpty;

    _robotState = finalState;
    _feedback = steps.isNotEmpty && steps.last.hasError
        ? steps.last.error
        : reachedGoal && collectedAll
            ? MiMobileStrings.m222
            : MiMobileStrings.m223;

    return reachedGoal && collectedAll;
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
        'program': _program.map((type) => type.commandName).toList(),
        'robot': _robotStateToJson(_robotState),
        'feedback': _feedback,
      },
      createdAt: now ?? DateTime.now().toUtc(),
      score: score,
      attemptsUsed: _attempts,
      hintsUsed: _hintsUsed,
      itemsCompleted: _program.length,
      totalItems: _minimumExpectedCommands,
      metadata: const {'snapshotKind': 'robot_commands_session'},
    );
  }

  void restoreSnapshot(MiGameSnapshot snapshot) {
    if (snapshot.gameId != _level.gameId || snapshot.levelId != _level.id) {
      throw ArgumentError(
        'Snapshot does not belong to this Robot Commands level.',
      );
    }

    final state = snapshot.state;
    _program
      ..clear()
      ..addAll((state['program'] as List).cast<String>().map(_blockFrom));
    _robotState = _robotStateFromJson(
      Map<String, dynamic>.from(state['robot'] as Map),
    );
    _feedback = state['feedback'] as String?;
    _attempts = snapshot.attemptsUsed;
    _hintsUsed = snapshot.hintsUsed;
  }

  CommandTree _buildCommandTree() {
    final tree = CommandTree()
      ..add(const Block(id: 'start', type: BlockType.start));
    for (var i = 0; i < _program.length; i++) {
      tree.add(Block(id: 'cmd-$i', type: _program[i]));
    }
    return tree;
  }

  int get _minimumExpectedCommands =>
      max(1, _grid.width + _grid.height + _grid.collectibles.length);

  void _resetForLevel(MiLevel level) {
    final metadata = level.metadata;
    final gridData = metadata['grid'] as Map<String, dynamic>;
    final startData = metadata['start'] as Map<String, dynamic>;
    final goalData = metadata['goal'] as Map<String, dynamic>;
    final content = level.contentForLocale(locale);

    _grid = RobotGrid(
      width: gridData['width'] as int,
      height: gridData['height'] as int,
      obstacles: _pointsFrom(metadata['obstacles'] as List? ?? const []),
      collectibles: _pointsFrom(metadata['collectibles'] as List? ?? const []),
      goal: (x: goalData['x'] as int, y: goalData['y'] as int),
    );
    _initialState = RobotState(
      x: startData['x'] as int,
      y: startData['y'] as int,
      facing: _directionFrom(startData['facing'] as String? ?? 'east'),
    );
    _availableCommands = (content['availableCommands'] as List)
        .cast<String>()
        .map(_blockFrom)
        .toList();
    _robotState = _initialState.copy();
    _program.clear();
    _attempts = 0;
    _hintsUsed = 0;
    _feedback = null;
  }
}

Map<String, dynamic> _robotStateToJson(RobotState state) => {
      'x': state.x,
      'y': state.y,
      'facing': state.facing.name,
      'collected':
          state.collected.map((point) => {'x': point.x, 'y': point.y}).toList(),
    };

RobotState _robotStateFromJson(Map<String, dynamic> json) {
  return RobotState(
    x: json['x'] as int,
    y: json['y'] as int,
    facing: _directionFrom(json['facing'] as String? ?? 'east'),
    collected: _pointsFrom(json['collected'] as List? ?? const []),
  );
}

Set<({int x, int y})> _pointsFrom(List<dynamic> values) {
  return values.map((value) {
    final map = value as Map<String, dynamic>;
    return (x: map['x'] as int, y: map['y'] as int);
  }).toSet();
}

BlockType _blockFrom(String command) => BlockType.fromCommandName(command);

Direction _directionFrom(String value) {
  return Direction.values.firstWhere(
    (direction) => direction.name == value,
    orElse: () => Direction.east,
  );
}
