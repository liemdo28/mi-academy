// MI Blocks Block Styling

import 'package:flutter/material.dart';
import '../block.dart';

/// Visual style for a [BlockType].
class BlockStyle {
  const BlockStyle({
    required this.background,
    required this.border,
    required this.selectedBorder,
    required this.iconBackground,
    required this.categoryColor,
    required this.textColor,
    required this.iconLabel,
  });

  final Color background;
  final Color border;
  final Color selectedBorder;
  final Color iconBackground;
  final Color categoryColor;
  final Color textColor;
  final String iconLabel;
}

/// Pre-defined styles for each MVP block type.
class BlockStyles {
  BlockStyles._();

  static const _styles = <BlockType, BlockStyle>{
    BlockType.start: BlockStyle(
      background: Color(0xFFE8F5E9),
      border: Color(0xFF388E3C),
      selectedBorder: Color(0xFF1B5E20),
      iconBackground: Color(0xFF388E3C),
      categoryColor: Color(0xFF2E7D32),
      textColor: Color(0xFF1B5E20),
      iconLabel: '▶',
    ),
    BlockType.moveForward: BlockStyle(
      background: Color(0xFFE3F2FD),
      border: Color(0xFF1976D2),
      selectedBorder: Color(0xFF0D47A1),
      iconBackground: Color(0xFF1976D2),
      categoryColor: Color(0xFF1565C0),
      textColor: Color(0xFF0D47A1),
      iconLabel: '↑',
    ),
    BlockType.turnLeft: BlockStyle(
      background: Color(0xFFFCE4EC),
      border: Color(0xFFC2185B),
      selectedBorder: Color(0xFF880E4F),
      iconBackground: Color(0xFFC2185B),
      categoryColor: Color(0xFFAD1457),
      textColor: Color(0xFF880E4F),
      iconLabel: '↺',
    ),
    BlockType.turnRight: BlockStyle(
      background: Color(0xFFFCE4EC),
      border: Color(0xFFC2185B),
      selectedBorder: Color(0xFF880E4F),
      iconBackground: Color(0xFFC2185B),
      categoryColor: Color(0xFFAD1457),
      textColor: Color(0xFF880E4F),
      iconLabel: '↻',
    ),
    BlockType.repeat: BlockStyle(
      background: Color(0xFFFFF3E0),
      border: Color(0xFFF57C00),
      selectedBorder: Color(0xFFE65100),
      iconBackground: Color(0xFFF57C00),
      categoryColor: Color(0xFFEF6C00),
      textColor: Color(0xFFE65100),
      iconLabel: '🔁',
    ),
    BlockType.ifPathAhead: BlockStyle(
      background: Color(0xFFF3E5F5),
      border: Color(0xFF7B1FA2),
      selectedBorder: Color(0xFF4A148C),
      iconBackground: Color(0xFF7B1FA2),
      categoryColor: Color(0xFF6A1B9A),
      textColor: Color(0xFF4A148C),
      iconLabel: '?',
    ),
    BlockType.collect: BlockStyle(
      background: Color(0x33FFEB3B),
      border: Color(0xFFF9A825),
      selectedBorder: Color(0xFFF57F17),
      iconBackground: Color(0xFFF9A825),
      categoryColor: Color(0xFFF57F17),
      textColor: Color(0xFF4E342E),
      iconLabel: '★',
    ),
  };

  /// Get the style for a block type.
  static BlockStyle forType(BlockType type) => _styles[type]!;
}
