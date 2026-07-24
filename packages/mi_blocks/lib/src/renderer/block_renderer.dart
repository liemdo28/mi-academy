import 'package:flutter/material.dart';
import '../block.dart';
import '../command_tree.dart';
import 'block_style.dart';

/// Renders a single [Block] as a colored, tappable widget.
class BlockRenderer extends StatelessWidget {
  const BlockRenderer({
    super.key,
    required this.block,
    required this.isSelected,
    required this.isHighlighted,
    this.onTap,
    this.onLongPress,
  });

  final Block block;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final style = BlockStyles.forType(block.type);
    final borderColor = isSelected
        ? style.selectedBorder
        : isHighlighted
            ? Colors.amber
            : style.border;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        constraints: const BoxConstraints(minWidth: 80, minHeight: 44),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: isSelected ? 3 : 2),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: style.iconBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    style.iconLabel,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                block.type.commandName.replaceAll('_', '\n'),
                style: TextStyle(
                  color: style.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (block.type == BlockType.repeat) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: style.categoryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'x${block.repeatCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders a complete [CommandTree] as a vertical stack of blocks.
class CommandTreeRenderer extends StatelessWidget {
  const CommandTreeRenderer({
    super.key,
    required this.tree,
    required this.selectedBlockId,
    required this.highlightedBlockId,
    this.onBlockTap,
    this.onBlockLongPress,
  });

  final CommandTree tree;
  final String? selectedBlockId;
  final String? highlightedBlockId;
  final void Function(Block block)? onBlockTap;
  final void Function(Block block)? onBlockLongPress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final block in tree.blocks)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: BlockRenderer(
              block: block,
              isSelected: block.id == selectedBlockId,
              isHighlighted: block.id == highlightedBlockId,
              onTap: onBlockTap != null ? () => onBlockTap!(block) : null,
              onLongPress: onBlockLongPress != null
                  ? () => onBlockLongPress!(block)
                  : null,
            ),
          ),
      ],
    );
  }
}
