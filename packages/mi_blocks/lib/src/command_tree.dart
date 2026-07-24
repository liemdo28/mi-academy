import 'block.dart';

/// The ordered sequence of blocks the child assembles.
///
/// Always begins with a START block. Supports serialization for
/// save/restore and validation before execution.
class CommandTree {
  CommandTree({List<Block>? blocks}) : _blocks = blocks ?? [];

  final List<Block> _blocks;

  List<Block> get blocks => List.unmodifiable(_blocks);

  int get blockCount {
    int count(List<Block> bs) {
      int c = 0;
      for (final b in bs) {
        c++;
        if (b.children.isNotEmpty) c += count(b.children);
      }
      return c;
    }

    return count(_blocks);
  }

  void add(Block block) => _blocks.add(block);

  void insertAt(int index, Block block) => _blocks.insert(index, block);

  void removeAt(int index) => _blocks.removeAt(index);

  void clear() => _blocks.clear();

  /// Whether this tree begins with a START block.
  bool get hasStart =>
      _blocks.isNotEmpty && _blocks.first.type == BlockType.start;

  /// Validation errors (empty = valid).
  List<String> validate() {
    final errors = <String>[];
    if (_blocks.isEmpty) {
      errors.add('Chương trình trống');
      return errors;
    }
    if (!hasStart) {
      errors.add('Chương trình phải bắt đầu bằng khối START');
    }
    _validateBlocks(_blocks, errors);
    return errors;
  }

  void _validateBlocks(List<Block> blocks, List<String> errors) {
    for (final block in blocks) {
      if (block.type == BlockType.repeat && block.repeatCount < 1) {
        errors.add('Khối REPEAT phải lặp ít nhất 1 lần');
      }
      if (block.type.isContainer && block.children.isEmpty) {
        errors.add('Khối ${block.type.commandName} cần có lệnh bên trong');
      }
      if (block.children.isNotEmpty) {
        _validateBlocks(block.children, errors);
      }
    }
  }

  List<Map<String, dynamic>> toJson() =>
      _blocks.map((b) => b.toJson()).toList();

  factory CommandTree.fromJson(List<dynamic> json) {
    return CommandTree(
      blocks:
          json.map((b) => Block.fromJson(b as Map<String, dynamic>)).toList(),
    );
  }
}
