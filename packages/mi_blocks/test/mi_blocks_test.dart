import 'package:flutter_test/flutter_test.dart';
import 'package:mi_blocks/mi_blocks.dart';

void main() {
  group('BlockType', () {
    test('serializes command names used by Robot Commands content', () {
      expect(BlockType.start.commandName, 'START');
      expect(BlockType.moveForward.commandName, 'MOVE_FORWARD');
      expect(BlockType.turnLeft.commandName, 'TURN_LEFT');
      expect(BlockType.turnRight.commandName, 'TURN_RIGHT');
      expect(BlockType.repeat.commandName, 'REPEAT');
      expect(BlockType.ifPathAhead.commandName, 'IF_PATH_AHEAD');
      expect(BlockType.collect.commandName, 'COLLECT');
    });

    test('parses command names and rejects unknown commands', () {
      expect(BlockType.fromCommandName('MOVE_FORWARD'), BlockType.moveForward);
      expect(
        () => BlockType.fromCommandName('TELEPORT'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('identifies only repeat and if-path blocks as containers', () {
      expect(BlockType.repeat.isContainer, isTrue);
      expect(BlockType.ifPathAhead.isContainer, isTrue);
      expect(BlockType.moveForward.isContainer, isFalse);
      expect(BlockType.collect.isContainer, isFalse);
    });
  });

  group('Block', () {
    test('copyWith preserves id and type while updating loop fields', () {
      const block = Block(
        id: 'repeat',
        type: BlockType.repeat,
        repeatCount: 2,
        children: [Block(id: 'move', type: BlockType.moveForward)],
      );

      final updated = block.copyWith(
        repeatCount: 3,
        children: const [Block(id: 'turn', type: BlockType.turnRight)],
      );

      expect(updated.id, 'repeat');
      expect(updated.type, BlockType.repeat);
      expect(updated.repeatCount, 3);
      expect(updated.children.single.id, 'turn');
    });

    test('round-trips JSON including nested children', () {
      const block = Block(
        id: 'repeat',
        type: BlockType.repeat,
        repeatCount: 2,
        children: [Block(id: 'collect', type: BlockType.collect)],
      );

      expect(Block.fromJson(block.toJson()), block);
    });
  });

  group('CommandTree', () {
    test('reports empty program before start validation', () {
      expect(CommandTree().validate(), ['Chương trình trống']);
    });

    test('validates start block requirement', () {
      final tree = CommandTree()
        ..add(const Block(id: 'move', type: BlockType.moveForward));

      expect(tree.validate(),
          contains('Chương trình phải bắt đầu bằng khối START'));
    });

    test('validates repeat count and required container children', () {
      final tree = CommandTree()
        ..add(const Block(id: 'start', type: BlockType.start))
        ..add(const Block(id: 'repeat', type: BlockType.repeat, repeatCount: 0))
        ..add(const Block(id: 'if', type: BlockType.ifPathAhead));

      expect(tree.validate(), contains('Khối REPEAT phải lặp ít nhất 1 lần'));
      expect(tree.validate(), contains('Khối REPEAT cần có lệnh bên trong'));
      expect(
        tree.validate(),
        contains('Khối IF_PATH_AHEAD cần có lệnh bên trong'),
      );
    });

    test('supports insert, remove, clear, and recursive block count', () {
      final tree = CommandTree()
        ..add(const Block(id: 'start', type: BlockType.start))
        ..insertAt(1, const Block(id: 'turn', type: BlockType.turnRight))
        ..add(const Block(
          id: 'repeat',
          type: BlockType.repeat,
          children: [Block(id: 'move', type: BlockType.moveForward)],
        ));

      expect(tree.blockCount, 4);
      expect(tree.blocks[1].id, 'turn');

      tree.removeAt(1);
      expect(tree.blocks[1].id, 'repeat');

      tree.clear();
      expect(tree.blocks, isEmpty);
    });

    test('serializes and restores nested blocks', () {
      final tree = CommandTree()
        ..add(const Block(id: 'start', type: BlockType.start))
        ..add(const Block(
          id: 'repeat',
          type: BlockType.repeat,
          repeatCount: 2,
          children: [
            Block(id: 'move', type: BlockType.moveForward),
          ],
        ));

      final restored = CommandTree.fromJson(tree.toJson());

      expect(restored.blockCount, 3);
      expect(restored.validate(), isEmpty);
    });
  });

  group('Direction and RobotGrid', () {
    test('turns left and right cyclically', () {
      expect(Direction.north.turnLeft(), Direction.west);
      expect(Direction.west.turnRight(), Direction.north);
      expect(Direction.south.turnRight(), Direction.west);
    });

    test('exposes movement deltas for each direction', () {
      expect(Direction.north.delta, (dx: 0, dy: -1));
      expect(Direction.east.delta, (dx: 1, dy: 0));
      expect(Direction.south.delta, (dx: 0, dy: 1));
      expect(Direction.west.delta, (dx: -1, dy: 0));
    });

    test('walkability rejects bounds and obstacles', () {
      final grid = RobotGrid(
        width: 2,
        height: 2,
        obstacles: const {(x: 1, y: 0)},
        collectibles: const {},
        goal: (x: 1, y: 1),
      );

      expect(grid.isWalkable(0, 0), isTrue);
      expect(grid.isWalkable(1, 0), isFalse);
      expect(grid.isWalkable(-1, 0), isFalse);
      expect(grid.isWalkable(2, 0), isFalse);
      expect(grid.isWalkable(0, 2), isFalse);
    });
  });

  group('BlockInterpreter', () {
    test('moves robot to goal with simple commands', () {
      final grid = RobotGrid(
        width: 3,
        height: 1,
        obstacles: const {},
        collectibles: const {},
        goal: (x: 2, y: 0),
      );
      final tree = CommandTree()
        ..add(const Block(id: 'start', type: BlockType.start))
        ..add(const Block(id: 'move1', type: BlockType.moveForward))
        ..add(const Block(id: 'move2', type: BlockType.moveForward));
      final interpreter = BlockInterpreter(grid: grid);

      final steps = interpreter.execute(
        tree,
        initialState: RobotState(x: 0, y: 0, facing: Direction.east),
      );

      expect(steps, hasLength(3));
      expect(steps.last.hasError, isFalse);
      expect(interpreter.reachedGoal(steps.last.state), isTrue);
    });

    test('turns robot and moves in the new direction', () {
      final interpreter = BlockInterpreter(grid: _grid(width: 2, height: 2));
      final tree = CommandTree()
        ..add(const Block(id: 'start', type: BlockType.start))
        ..add(const Block(id: 'right', type: BlockType.turnRight))
        ..add(const Block(id: 'move', type: BlockType.moveForward));

      final steps = interpreter.execute(
        tree,
        initialState: RobotState(x: 0, y: 0, facing: Direction.east),
      );

      expect(steps.last.state.facing, Direction.south);
      expect((steps.last.state.x, steps.last.state.y), (0, 1));
    });

    test('stops with gentle error when movement hits an obstacle', () {
      final interpreter = BlockInterpreter(
        grid: _grid(obstacles: const {(x: 1, y: 0)}),
      );
      final tree = CommandTree()
        ..add(const Block(id: 'start', type: BlockType.start))
        ..add(const Block(id: 'move', type: BlockType.moveForward))
        ..add(const Block(id: 'after-error', type: BlockType.turnRight));

      final steps = interpreter.execute(
        tree,
        initialState: RobotState(x: 0, y: 0, facing: Direction.east),
      );

      expect(steps.last.blockId, 'move');
      expect(steps.last.error, 'Không thể đi tiếp — có chướng ngại vật');
      expect(steps.any((step) => step.blockId == 'after-error'), isFalse);
    });

    test('collects item only when robot is on collectible position', () {
      final interpreter = BlockInterpreter(
        grid: _grid(collectibles: const {(x: 0, y: 0)}),
      );
      final tree = CommandTree()
        ..add(const Block(id: 'start', type: BlockType.start))
        ..add(const Block(id: 'collect', type: BlockType.collect));

      final steps = interpreter.execute(
        tree,
        initialState: RobotState(x: 0, y: 0, facing: Direction.east),
      );

      expect(steps.last.state.collected, contains((x: 0, y: 0)));
    });

    test('repeat executes child blocks exact number of times', () {
      final interpreter = BlockInterpreter(grid: _grid(width: 4));
      final tree = CommandTree()
        ..add(const Block(id: 'start', type: BlockType.start))
        ..add(const Block(
          id: 'repeat',
          type: BlockType.repeat,
          repeatCount: 3,
          children: [Block(id: 'move', type: BlockType.moveForward)],
        ));

      final steps = interpreter.execute(
        tree,
        initialState: RobotState(x: 0, y: 0, facing: Direction.east),
      );

      expect(steps.where((step) => step.blockId == 'move'), hasLength(3));
      expect(steps.last.state.x, 3);
    });

    test('ifPathAhead skips children when blocked', () {
      final interpreter = BlockInterpreter(
        grid: _grid(obstacles: const {(x: 1, y: 0)}),
      );
      final tree = CommandTree()
        ..add(const Block(id: 'start', type: BlockType.start))
        ..add(const Block(
          id: 'if',
          type: BlockType.ifPathAhead,
          children: [Block(id: 'move', type: BlockType.moveForward)],
        ));

      final steps = interpreter.execute(
        tree,
        initialState: RobotState(x: 0, y: 0, facing: Direction.east),
      );

      expect(steps.map((step) => step.blockId), ['start']);
      expect(steps.last.state.x, 0);
    });

    test('ifPathAhead executes children when clear', () {
      final interpreter = BlockInterpreter(grid: _grid(width: 2));
      final tree = CommandTree()
        ..add(const Block(id: 'start', type: BlockType.start))
        ..add(const Block(
          id: 'if',
          type: BlockType.ifPathAhead,
          children: [Block(id: 'move', type: BlockType.moveForward)],
        ));

      final steps = interpreter.execute(
        tree,
        initialState: RobotState(x: 0, y: 0, facing: Direction.east),
      );

      expect(steps.map((step) => step.blockId), ['start', 'move']);
      expect(steps.last.state.x, 1);
    });

    test('copies initial state so execution does not mutate caller state', () {
      final interpreter = BlockInterpreter(grid: _grid(width: 2));
      final initial = RobotState(x: 0, y: 0, facing: Direction.east);
      final tree = CommandTree()
        ..add(const Block(id: 'start', type: BlockType.start))
        ..add(const Block(id: 'move', type: BlockType.moveForward));

      final steps = interpreter.execute(tree, initialState: initial);

      expect(initial.x, 0);
      expect(steps.last.state.x, 1);
    });

    test('reports max step error to prevent runaway programs', () {
      final interpreter = BlockInterpreter(grid: _grid(width: 2000));
      final tree = CommandTree()
        ..add(const Block(id: 'start', type: BlockType.start))
        ..add(const Block(
          id: 'repeat',
          type: BlockType.repeat,
          repeatCount: 1001,
          children: [Block(id: 'move', type: BlockType.moveForward)],
        ));

      final steps = interpreter.execute(
        tree,
        initialState: RobotState(x: 0, y: 0, facing: Direction.east),
      );

      expect(steps.last.hasError, isTrue);
      expect(steps.last.error, contains('Quá nhiều bước'));
    });
  });
}

RobotGrid _grid({
  int width = 3,
  int height = 1,
  Set<({int x, int y})> obstacles = const {},
  Set<({int x, int y})> collectibles = const {},
  ({int x, int y}) goal = const (x: 2, y: 0),
}) {
  return RobotGrid(
    width: width,
    height: height,
    obstacles: obstacles,
    collectibles: collectibles,
    goal: goal,
  );
}
