import 'block.dart';
import 'command_tree.dart';

/// Direction the robot is facing.
enum Direction {
  north,
  east,
  south,
  west;

  Direction turnLeft() =>
      Direction.values[(index - 1 + Direction.values.length) %
          Direction.values.length];

  Direction turnRight() =>
      Direction.values[(index + 1) % Direction.values.length];

  ({int dx, int dy}) get delta {
    switch (this) {
      case Direction.north:
        return (dx: 0, dy: -1);
      case Direction.east:
        return (dx: 1, dy: 0);
      case Direction.south:
        return (dx: 0, dy: 1);
      case Direction.west:
        return (dx: -1, dy: 0);
    }
  }
}

/// The robot's state during execution.
class RobotState {
  RobotState({
    required this.x,
    required this.y,
    required this.facing,
    Set<({int x, int y})>? collected,
  }) : collected = collected ?? {};

  int x;
  int y;
  Direction facing;
  final Set<({int x, int y})> collected;

  RobotState copy() => RobotState(
        x: x,
        y: y,
        facing: facing,
        collected: {...collected},
      );
}

/// A single execution step, emitted for step-by-step highlighting.
class ExecutionStep {
  const ExecutionStep({
    required this.blockId,
    required this.state,
    this.error,
  });

  final String blockId;
  final RobotState state;
  final String? error;

  bool get hasError => error != null;
}

/// The grid environment the robot runs in.
class RobotGrid {
  RobotGrid({
    required this.width,
    required this.height,
    required this.obstacles,
    required this.collectibles,
    required this.goal,
  });

  final int width;
  final int height;
  final Set<({int x, int y})> obstacles;
  final Set<({int x, int y})> collectibles;
  final ({int x, int y}) goal;

  bool isWalkable(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return false;
    return !obstacles.contains((x: x, y: y));
  }
}

/// Interprets a [CommandTree] step-by-step against a [RobotGrid].
///
/// Emits [ExecutionStep]s so the UI can highlight the current block
/// (blueprint §11 "Block hiện tại được highlight").
class BlockInterpreter {
  BlockInterpreter({required this.grid});

  final RobotGrid grid;

  /// Maximum steps to prevent infinite loops.
  static const int maxSteps = 1000;

  /// Execute the tree and return the list of steps.
  List<ExecutionStep> execute(
    CommandTree tree, {
    required RobotState initialState,
  }) {
    final steps = <ExecutionStep>[];
    final state = initialState.copy();
    _run(tree.blocks, state, steps);
    return steps;
  }

  void _run(List<Block> blocks, RobotState state, List<ExecutionStep> steps) {
    for (final block in blocks) {
      if (steps.length >= maxSteps) {
        steps.add(ExecutionStep(
          blockId: block.id,
          state: state.copy(),
          error: 'Quá nhiều bước — có thể có vòng lặp vô hạn',
        ));
        return;
      }

      switch (block.type) {
        case BlockType.start:
          steps.add(ExecutionStep(blockId: block.id, state: state.copy()));
          break;
        case BlockType.moveForward:
          final d = state.facing.delta;
          final nx = state.x + d.dx;
          final ny = state.y + d.dy;
          if (grid.isWalkable(nx, ny)) {
            state.x = nx;
            state.y = ny;
            steps.add(ExecutionStep(blockId: block.id, state: state.copy()));
          } else {
            steps.add(ExecutionStep(
              blockId: block.id,
              state: state.copy(),
              error: 'Không thể đi tiếp — có chướng ngại vật',
            ));
            return;
          }
          break;
        case BlockType.turnLeft:
          state.facing = state.facing.turnLeft();
          steps.add(ExecutionStep(blockId: block.id, state: state.copy()));
          break;
        case BlockType.turnRight:
          state.facing = state.facing.turnRight();
          steps.add(ExecutionStep(blockId: block.id, state: state.copy()));
          break;
        case BlockType.collect:
          final pos = (x: state.x, y: state.y);
          if (grid.collectibles.contains(pos)) {
            state.collected.add(pos);
          }
          steps.add(ExecutionStep(blockId: block.id, state: state.copy()));
          break;
        case BlockType.repeat:
          for (int i = 0; i < block.repeatCount; i++) {
            _run(block.children, state, steps);
            if (steps.isNotEmpty && steps.last.hasError) return;
          }
          break;
        case BlockType.ifPathAhead:
          final d = state.facing.delta;
          if (grid.isWalkable(state.x + d.dx, state.y + d.dy)) {
            _run(block.children, state, steps);
          }
          break;
      }
    }
  }

  /// Whether the robot reached the goal after execution.
  bool reachedGoal(RobotState finalState) {
    return finalState.x == grid.goal.x && finalState.y == grid.goal.y;
  }
}
