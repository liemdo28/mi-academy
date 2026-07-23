import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mi_blocks/mi_blocks.dart';
import 'package:mi_game_audio/mi_game_audio.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

import '../game_locale_text.dart';
import '../level_skill_ids.dart';
import '../snapshot_lifecycle_mixin.dart';
import 'robot_commands_session.dart';

class RobotCommandsScreen extends StatefulWidget {
  const RobotCommandsScreen({
    super.key,
    required this.level,
    required this.allLevels,
    this.onExit,
    this.onComplete,
    this.initialSnapshot,
    this.onSaveSnapshot,
    this.locale = 'vi',
  });

  final MiLevel level;
  final List<MiLevel> allLevels;
  final VoidCallback? onExit;

  /// Fired once per level completion — see WordBuilderScreen.onComplete.
  final void Function(MiCompletionResult)? onComplete;

  /// See WordBuilderScreen.initialSnapshot.
  final MiGameSnapshot? initialSnapshot;

  /// See WordBuilderScreen.onSaveSnapshot.
  final void Function(MiGameSnapshot)? onSaveSnapshot;

  /// From the parent's language setting (see ParentSettingsSnapshot.language)
  /// -- was previously hardcoded to 'vi' regardless of this setting.
  final String locale;

  @override
  State<RobotCommandsScreen> createState() => _RobotCommandsScreenState();
}

class _RobotCommandsScreenState extends State<RobotCommandsScreen>
    with WidgetsBindingObserver, SnapshotLifecycleMixin<RobotCommandsScreen> {
  late RobotCommandsSession _session;
  late Stopwatch _stopwatch;
  late final MiAudioService _audio = MiAudioService();
  bool _completed = false;

  @override
  void Function(MiGameSnapshot)? get onSaveSnapshot => widget.onSaveSnapshot;

  @override
  MiGameSnapshot? captureSnapshot() {
    if (_completed) return null;
    return _session.saveSnapshot();
  }

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _loadLevel(widget.level, snapshot: widget.initialSnapshot);
  }

  @override
  void dispose() {
    disposeSnapshotLifecycle();
    unawaited(_audio.dispose());
    _stopwatch.stop();
    super.dispose();
  }

  void _loadLevel(MiLevel level, {MiGameSnapshot? snapshot}) {
    setState(() {
      _completed = false;
      _session = RobotCommandsSession(level: level, locale: widget.locale);
      if (snapshot != null) {
        _session.restoreSnapshot(snapshot);
      }
      _stopwatch
        ..reset()
        ..start();
    });
  }

  MiLevel get _level => _session.level;
  Map<String, dynamic> get _content => _session.content;

  void _addCommand(BlockType type) {
    setState(() {
      _session.addCommand(type);
    });
  }

  void _removeLast() {
    setState(() {
      _session.removeLast();
    });
  }

  void _removeAt(int index) {
    setState(() {
      _session.removeAt(index);
    });
  }

  void _moveCommand(int index, int offset) {
    setState(() {
      _session.moveCommand(index, offset);
    });
  }

  void _resetProgram() {
    setState(() {
      _session.resetProgram();
    });
  }

  void _runProgram() {
    final complete = _session.runProgram();
    unawaited(_playEffect(complete ? 'correct' : 'try_again'));
    setState(() {});
    if (complete) {
      _showCompletion();
    }
  }

  void _showHint() {
    setState(() {
      _session.showHint();
    });
    unawaited(_playEffect('try_again'));
  }

  Future<void> _playEffect(String assetKey) async {
    try {
      await _audio.playEffect('audio/$assetKey.wav');
    } catch (_) {
      // Audio feedback should never interrupt gameplay.
    }
  }

  void _showCompletion() {
    final text = GameLocaleText(widget.locale);
    final completion = text.completion;
    _completed = true;
    _stopwatch.stop();
    widget.onComplete?.call(MiCompletionResult(
      gameId: _level.gameId,
      levelId: _level.id,
      childProfileId: _session.childProfileId,
      completedAt: DateTime.now(),
      score: _session.score,
      maxScore: 100,
      attemptsUsed: _session.attempts,
      hintsUsed: _session.hintsUsed,
      duration: _stopwatch.elapsed,
      perfectRun: _session.attempts <= 1 && _session.hintsUsed == 0,
      newSkillsAcquired: skillIdsFor(_level, fallback: const ['sequencing']),
    ));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompletionOverlay(
        starsEarned: _session.stars,
        maxStars: 3,
        message: text.robotComplete,
        score: _session.score,
        scoreLabel: completion.scoreLabel,
        nextLabel: completion.nextLabel,
        replayLabel: completion.replayLabel,
        exitLabel: completion.exitLabel,
        mascotSemanticLabel: completion.mascotSemanticLabel,
        earnedStarSemanticLabel: completion.earnedStarSemanticLabel,
        unearnedStarSemanticLabel: completion.unearnedStarSemanticLabel,
        onNext: _goNext,
        onReplay: () {
          Navigator.of(context).pop();
          _loadLevel(_level);
        },
        onExit: () {
          Navigator.of(context).pop();
          widget.onExit?.call();
        },
      ),
    );
  }

  void _goNext() {
    Navigator.of(context).pop();
    final nextIndex =
        widget.allLevels.indexWhere((level) => level.id == _level.id) + 1;
    if (nextIndex > 0 && nextIndex < widget.allLevels.length) {
      _loadLevel(widget.allLevels[nextIndex]);
    } else {
      widget.onExit?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = GameLocaleText(widget.locale);
    final prompt = _content['prompt'] as String? ?? text.robotPrompt;

    return Scaffold(
      backgroundColor: GameTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
              title: text.robotTitle,
              score: _level.levelNumber,
              onExit: widget.onExit,
            ),
            ProgressDots(
              total: widget.allLevels.length,
              completed: _level.levelNumber - 1,
              color: GameTheme.primary,
            ),
            Expanded(
              child: ListView(
                padding: GameTheme.screenPadding,
                children: [
                  Text(prompt, style: GameTheme.headingMedium),
                  const SizedBox(height: 16),
                  _RobotGridView(
                    grid: _session.grid,
                    state: _session.robotState,
                  ),
                  const SizedBox(height: 16),
                  Text(text.robotProgram, style: GameTheme.headingMedium),
                  const SizedBox(height: 8),
                  _ProgramView(
                    program: _session.program,
                    onRemove: _removeAt,
                    onMoveLeft: (index) => _moveCommand(index, -1),
                    onMoveRight: (index) => _moveCommand(index, 1),
                    text: text,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _session.availableCommands
                        .map(
                          (type) => ElevatedButton.icon(
                            onPressed: () => _addCommand(type),
                            icon: Icon(_iconForBlock(type), size: 20),
                            label: Text(_labelFor(type, text)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _colorForBlock(type),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  if (_session.feedback != null) ...[
                    const SizedBox(height: 16),
                    FeedbackBubble(
                      isCorrect: _session.feedback == text.robotDone,
                      message: _session.feedback!,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  HintButton(
                    onPressed: _showHint,
                    hintsAvailable: _level.hints.length,
                    hintsRemaining: _level.hints.length - _session.hintsUsed < 0
                        ? 0
                        : _level.hints.length - _session.hintsUsed,
                    availableSemanticLabel: text.hintAvailable,
                    emptySemanticLabel: text.hintEmpty,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _removeLast,
                    icon: const Icon(Icons.undo_rounded),
                    tooltip: text.robotUndoTooltip,
                  ),
                  IconButton(
                    onPressed: _resetProgram,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: text.robotResetTooltip,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _runProgram,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(text.robotRun),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameTheme.primary,
                        foregroundColor: Colors.white,
                        padding: GameTheme.buttonPadding,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RobotGridView extends StatelessWidget {
  const _RobotGridView({required this.grid, required this.state});

  final RobotGrid grid;
  final RobotState state;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: grid.width / grid.height,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: grid.width,
        ),
        itemCount: grid.width * grid.height,
        itemBuilder: (context, index) {
          final x = index % grid.width;
          final y = index ~/ grid.width;
          final isRobot = state.x == x && state.y == y;
          final isGoal = grid.goal.x == x && grid.goal.y == y;
          final isObstacle = grid.obstacles.contains((x: x, y: y));
          final isCollectible = grid.collectibles.contains((x: x, y: y)) &&
              !state.collected.contains((x: x, y: y));
          final icon = _cellIcon(
            isRobot: isRobot,
            isObstacle: isObstacle,
            isGoal: isGoal,
            isCollectible: isCollectible,
            facing: state.facing,
          );

          return Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isObstacle
                  ? GameTheme.textSecondary.withValues(alpha: 0.18)
                  : isGoal
                      ? GameTheme.warning.withValues(alpha: 0.25)
                      : GameTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: GameTheme.primary.withValues(alpha: 0.35)),
            ),
            child: Center(
              child: icon == null
                  ? const SizedBox.shrink()
                  : Icon(icon, size: 34, color: GameTheme.textPrimary),
            ),
          );
        },
      ),
    );
  }
}

IconData? _cellIcon({
  required bool isRobot,
  required bool isObstacle,
  required bool isGoal,
  required bool isCollectible,
  required Direction facing,
}) {
  if (isRobot) {
    return _robotIcon(facing);
  }
  if (isObstacle) {
    return Icons.stop_rounded;
  }
  if (isGoal) {
    return Icons.star_rounded;
  }
  if (isCollectible) {
    return Icons.battery_charging_full_rounded;
  }
  return null;
}

class _ProgramView extends StatelessWidget {
  const _ProgramView({
    required this.program,
    required this.onRemove,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.text,
  });

  final List<BlockType> program;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onMoveLeft;
  final ValueChanged<int> onMoveRight;
  final GameLocaleText text;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        const Chip(label: Text('START')),
        for (var i = 0; i < program.length; i++)
          _ProgramCommandChip(
            index: i,
            type: program[i],
            text: text,
            canMoveLeft: i > 0,
            canMoveRight: i < program.length - 1,
            onRemove: () => onRemove(i),
            onMoveLeft: () => onMoveLeft(i),
            onMoveRight: () => onMoveRight(i),
          ),
      ],
    );
  }
}

class _ProgramCommandChip extends StatelessWidget {
  const _ProgramCommandChip({
    required this.index,
    required this.type,
    required this.text,
    required this.canMoveLeft,
    required this.canMoveRight,
    required this.onRemove,
    required this.onMoveLeft,
    required this.onMoveRight,
  });

  final int index;
  final BlockType type;
  final GameLocaleText text;
  final bool canMoveLeft;
  final bool canMoveRight;
  final VoidCallback onRemove;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;

  @override
  Widget build(BuildContext context) {
    final label = '${index + 1}. ${_labelFor(type, text)}';
    final blockColor = _colorForBlock(type);
    // Rounded corners require a uniform border color, so the color-coded
    // accent is a solid leading bar rather than a mixed-color Border.
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GameTheme.surface,
          border: Border.all(color: blockColor.withValues(alpha: 0.35)),
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 4, color: blockColor),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconForBlock(type), size: 18, color: blockColor),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      key: ValueKey('robot-program-label-$index'),
                      style: GameTheme.bodyMedium
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      key: ValueKey('robot-command-move-left-$index'),
                      onPressed: canMoveLeft ? onMoveLeft : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                      tooltip: text.robotMoveBefore,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      key: ValueKey('robot-command-move-right-$index'),
                      onPressed: canMoveRight ? onMoveRight : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                      tooltip: text.robotMoveAfter,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      key: ValueKey('robot-command-remove-$index'),
                      onPressed: onRemove,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: text.robotRemoveCommand,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _labelFor(BlockType type, GameLocaleText text) {
  switch (type) {
    case BlockType.moveForward:
      return text.isEnglish ? 'FORWARD' : 'TIẾN';
    case BlockType.turnLeft:
      return text.isEnglish ? 'TURN LEFT' : 'RẼ TRÁI';
    case BlockType.turnRight:
      return text.isEnglish ? 'TURN RIGHT' : 'RẼ PHẢI';
    case BlockType.collect:
      return text.isEnglish ? 'COLLECT' : 'NHẶT';
    case BlockType.start:
      return 'START';
    case BlockType.repeat:
      return text.isEnglish ? 'REPEAT' : 'LẶP';
    case BlockType.ifPathAhead:
      return text.isEnglish ? 'IF CLEAR' : 'NẾU TRỐNG';
  }
}

/// Command blocks must be distinguishable by icon + text + color, never
/// color alone (docs/design/MI_DESIGN_SYSTEM.md §1, design/games/GAME_SHELL_SPEC.md §7).
IconData _iconForBlock(BlockType type) {
  switch (type) {
    case BlockType.moveForward:
      return Icons.arrow_upward_rounded;
    case BlockType.turnLeft:
      return Icons.rotate_left_rounded;
    case BlockType.turnRight:
      return Icons.rotate_right_rounded;
    case BlockType.collect:
      return Icons.battery_charging_full_rounded;
    case BlockType.start:
      return Icons.flag_rounded;
    case BlockType.repeat:
      return Icons.repeat_rounded;
    case BlockType.ifPathAhead:
      return Icons.help_outline_rounded;
  }
}

Color _colorForBlock(BlockType type) {
  switch (type) {
    case BlockType.moveForward:
      return GameTheme.primary;
    case BlockType.turnLeft:
      return MiGameColors.secondary;
    case BlockType.turnRight:
      return MiGameColors.tertiary;
    case BlockType.collect:
      return GameTheme.warning;
    case BlockType.start:
      return GameTheme.success;
    case BlockType.repeat:
      return MiGameColors.info;
    case BlockType.ifPathAhead:
      return GameTheme.textSecondary;
  }
}

IconData _robotIcon(Direction direction) {
  switch (direction) {
    case Direction.north:
      return Icons.keyboard_arrow_up_rounded;
    case Direction.east:
      return Icons.keyboard_arrow_right_rounded;
    case Direction.south:
      return Icons.keyboard_arrow_down_rounded;
    case Direction.west:
      return Icons.keyboard_arrow_left_rounded;
  }
}
