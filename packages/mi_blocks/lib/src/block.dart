import 'package:equatable/equatable.dart';

/// The MVP command types for Robot Commands (blueprint §11).
enum BlockType {
  start,
  moveForward,
  turnLeft,
  turnRight,
  repeat,
  ifPathAhead,
  collect;

  /// Whether this block can contain child blocks (loop/condition).
  bool get isContainer => this == BlockType.repeat || this == BlockType.ifPathAhead;

  /// Serialized command name (matches blueprint uppercase form).
  String get commandName {
    switch (this) {
      case BlockType.start:
        return 'START';
      case BlockType.moveForward:
        return 'MOVE_FORWARD';
      case BlockType.turnLeft:
        return 'TURN_LEFT';
      case BlockType.turnRight:
        return 'TURN_RIGHT';
      case BlockType.repeat:
        return 'REPEAT';
      case BlockType.ifPathAhead:
        return 'IF_PATH_AHEAD';
      case BlockType.collect:
        return 'COLLECT';
    }
  }

  static BlockType fromCommandName(String name) {
    return BlockType.values.firstWhere(
      (t) => t.commandName == name,
      orElse: () => throw ArgumentError('Unknown command: $name'),
    );
  }
}

/// A single command block that can hold children (for loops/conditions).
class Block extends Equatable {
  const Block({
    required this.id,
    required this.type,
    this.repeatCount = 1,
    this.children = const [],
  });

  final String id;
  final BlockType type;

  /// For REPEAT blocks: how many times to loop.
  final int repeatCount;

  /// For container blocks: nested child blocks.
  final List<Block> children;

  Block copyWith({int? repeatCount, List<Block>? children}) {
    return Block(
      id: id,
      type: type,
      repeatCount: repeatCount ?? this.repeatCount,
      children: children ?? this.children,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.commandName,
        'repeatCount': repeatCount,
        'children': children.map((c) => c.toJson()).toList(),
      };

  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      id: json['id'] as String,
      type: BlockType.fromCommandName(json['type'] as String),
      repeatCount: json['repeatCount'] as int? ?? 1,
      children: (json['children'] as List?)
              ?.map((c) => Block.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [id, type, repeatCount, children];
}
