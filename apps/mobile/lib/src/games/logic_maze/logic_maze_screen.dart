import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:mi_game_audio/mi_game_audio.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

import '../game_locale_text.dart';
import '../level_skill_ids.dart';
import '../snapshot_lifecycle_mixin.dart';
import 'logic_maze_session.dart';

class LogicMazeScreen extends StatefulWidget {
  const LogicMazeScreen({
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
  final void Function(MiCompletionResult)? onComplete;
  final MiGameSnapshot? initialSnapshot;
  final void Function(MiGameSnapshot)? onSaveSnapshot;
  final String locale;

  @override
  State<LogicMazeScreen> createState() => _LogicMazeScreenState();
}

class _LogicMazeScreenState extends State<LogicMazeScreen>
    with WidgetsBindingObserver, SnapshotLifecycleMixin<LogicMazeScreen> {
  late LogicMazeSession _session;
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
      _session = LogicMazeSession(level: level, locale: widget.locale);
      if (snapshot != null) _session.restoreSnapshot(snapshot);
      _stopwatch
        ..reset()
        ..start();
    });
  }

  MiLevel get _level => _session.level;
  Map<String, dynamic> get _content => _session.content;

  void _addCommand(String command) {
    setState(() => _session.addCommand(command));
  }

  void _removeLast() {
    setState(() => _session.removeLast());
  }

  void _resetProgram() {
    setState(() => _session.resetProgram());
  }

  void _runProgram() {
    final complete = _session.runProgram();
    unawaited(_playEffect(complete ? 'correct' : 'try_again'));
    setState(() {});
    if (complete) _showCompletion();
  }

  void _showHint() {
    setState(() => _session.showHint());
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
      newSkillsAcquired: skillIdsFor(_level, fallback: const ['logic.maze']),
      metadata: {
        'stars': _session.stars,
        'engine': 'logic_maze_movement',
      },
    ));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompletionOverlay(
        starsEarned: _session.stars,
        maxStars: 3,
        message: text.mazeComplete,
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
    final prompt = _content['prompt'] as String? ?? text.mazePlanner;

    return Scaffold(
      backgroundColor: GameTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
              title: text.mazeTitle,
              score: _level.levelNumber,
              onExit: widget.onExit,
            ),
            ProgressDots(
              total: widget.allLevels.length,
              completed: _level.levelNumber - 1,
              color: MiColors.creative,
            ),
            Expanded(
              child: ListView(
                padding: GameTheme.screenPadding,
                children: [
                  _MazeIntroCard(prompt: prompt, text: text),
                  const SizedBox(height: 16),
                  _MazeGrid(session: _session),
                  const SizedBox(height: 16),
                  Text(text.mazeProgram, style: GameTheme.headingMedium),
                  const SizedBox(height: 8),
                  _MazeProgramView(session: _session, text: text),
                  const SizedBox(height: 16),
                  _MazeCommandButtons(
                    commands: _session.availableCommands,
                    onAdd: _addCommand,
                    text: text,
                  ),
                  if (_session.feedback != null) ...[
                    const SizedBox(height: 16),
                    FeedbackBubble(
                      isCorrect:
                          _session.status == LogicMazeRunStatus.reachedGoal,
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
                    hintsRemaining: (_level.hints.length - _session.hintsUsed)
                        .clamp(0, _level.hints.length),
                    availableSemanticLabel: text.hintAvailable,
                    emptySemanticLabel: text.hintEmpty,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _removeLast,
                    icon: const Icon(Icons.undo_rounded),
                    tooltip: text.mazeUndoTooltip,
                  ),
                  IconButton(
                    onPressed: _resetProgram,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: text.mazeResetTooltip,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _runProgram,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(text.mazeRun),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MiColors.creative,
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

class _MazeIntroCard extends StatelessWidget {
  const _MazeIntroCard({required this.prompt, required this.text});

  final String prompt;
  final GameLocaleText text;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const MiBrandIconView(
              icon: MiBrandIcon.exploration,
              color: MiColors.creative,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text.mazePlanner, style: GameTheme.headingMedium),
                  const SizedBox(height: 6),
                  Text(prompt, style: GameTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MazeGrid extends StatelessWidget {
  const _MazeGrid({required this.session});

  final LogicMazeSession session;

  @override
  Widget build(BuildContext context) {
    final visited = session.visitedPath.toSet();
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        key: const ValueKey('logic-maze-grid'),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: session.gridSize * session.gridSize,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: session.gridSize,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final isCurrent = index == session.currentIndex;
          final isStart = index == session.startIndex;
          final isGoal = index == session.goalIndex;
          final isObstacle = session.obstacles.contains(index);
          final isVisited = visited.contains(index);
          return DecoratedBox(
            decoration: BoxDecoration(
              color: isObstacle
                  ? MiColors.navy.withValues(alpha: 0.12)
                  : isCurrent
                      ? MiColors.primary.withValues(alpha: 0.28)
                      : isGoal
                          ? MiColors.accent.withValues(alpha: 0.24)
                          : isVisited
                              ? MiColors.creative.withValues(alpha: 0.16)
                              : MiColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCurrent || isGoal
                    ? MiColors.creative
                    : MiColors.creative.withValues(alpha: 0.2),
                width: isCurrent || isGoal ? 2 : 1,
              ),
            ),
            child: Center(
              child: _MazeCellIcon(
                isCurrent: isCurrent,
                isStart: isStart,
                isGoal: isGoal,
                isObstacle: isObstacle,
                isVisited: isVisited,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MazeCellIcon extends StatelessWidget {
  const _MazeCellIcon({
    required this.isCurrent,
    required this.isStart,
    required this.isGoal,
    required this.isObstacle,
    required this.isVisited,
  });

  final bool isCurrent;
  final bool isStart;
  final bool isGoal;
  final bool isObstacle;
  final bool isVisited;

  @override
  Widget build(BuildContext context) {
    if (isCurrent) {
      return Text(
        'MI',
        style: GameTheme.buttonLabel.copyWith(color: MiColors.primary),
      );
    }
    if (isGoal) {
      return const Icon(Icons.star_rounded, color: MiColors.accent);
    }
    if (isObstacle) {
      return const Icon(Icons.block_rounded, color: MiColors.navy, size: 20);
    }
    if (isVisited) {
      return const Icon(
        Icons.arrow_forward_rounded,
        color: MiColors.creative,
        size: 20,
      );
    }
    if (isStart) {
      return Text(
        'MI',
        style: GameTheme.bodyMedium.copyWith(color: MiColors.creative),
      );
    }
    return const SizedBox.shrink();
  }
}

class _MazeProgramView extends StatelessWidget {
  const _MazeProgramView({required this.session, required this.text});

  final LogicMazeSession session;
  final GameLocaleText text;

  @override
  Widget build(BuildContext context) {
    if (session.program.isEmpty) {
      return _ProgramChip(text: text.mazeEmpty);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < session.program.length; i++)
          _ProgramChip(
            text: '${i + 1}. ${text.mazeCommandLabel(session.program[i])}',
          ),
      ],
    );
  }
}

class _MazeCommandButtons extends StatelessWidget {
  const _MazeCommandButtons({
    required this.commands,
    required this.onAdd,
    required this.text,
  });

  final List<String> commands;
  final ValueChanged<String> onAdd;
  final GameLocaleText text;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final command in commands)
          ElevatedButton.icon(
            key: ValueKey('logic-maze-command-$command'),
            onPressed: () => onAdd(command),
            icon: Icon(_iconFor(command), size: 20),
            label: Text(text.mazeCommandLabel(command)),
            style: ElevatedButton.styleFrom(
              backgroundColor: MiColors.creative,
              foregroundColor: Colors.white,
              minimumSize: const Size(64, 48),
            ),
          ),
      ],
    );
  }

  IconData _iconFor(String command) {
    return switch (command) {
      'up' => Icons.arrow_upward_rounded,
      'down' => Icons.arrow_downward_rounded,
      'left' => Icons.arrow_back_rounded,
      'right' => Icons.arrow_forward_rounded,
      _ => Icons.touch_app_rounded,
    };
  }
}

class _ProgramChip extends StatelessWidget {
  const _ProgramChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: MiColors.creative.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MiTokens.radiusFull),
        border: Border.all(color: MiColors.creative.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: GameTheme.bodyMedium.copyWith(
          color: MiColors.navy,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
