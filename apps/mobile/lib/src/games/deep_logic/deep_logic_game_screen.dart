import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:mi_game_audio/mi_game_audio.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

import '../choice/choice_game_session.dart';
import '../game_locale_text.dart';
import '../level_skill_ids.dart';
import '../snapshot_lifecycle_mixin.dart';

enum DeepLogicScene {
  maze,
  sudoku,
  detective,
  creative,
  reading,
}

class DeepLogicGameScreen extends StatefulWidget {
  const DeepLogicGameScreen({
    super.key,
    required this.title,
    required this.worldLabel,
    required this.level,
    required this.allLevels,
    required this.scene,
    required this.primaryColor,
    this.onExit,
    this.onComplete,
    this.initialSnapshot,
    this.onSaveSnapshot,
    this.locale = 'vi',
  });

  final String title;
  final String worldLabel;
  final MiLevel level;
  final List<MiLevel> allLevels;
  final DeepLogicScene scene;
  final Color primaryColor;
  final VoidCallback? onExit;
  final void Function(MiCompletionResult)? onComplete;
  final MiGameSnapshot? initialSnapshot;
  final void Function(MiGameSnapshot)? onSaveSnapshot;
  final String locale;

  @override
  State<DeepLogicGameScreen> createState() => _DeepLogicGameScreenState();
}

class _DeepLogicGameScreenState extends State<DeepLogicGameScreen>
    with WidgetsBindingObserver, SnapshotLifecycleMixin<DeepLogicGameScreen> {
  late ChoiceGameSession _session;
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
      _session = ChoiceGameSession(level: level, locale: widget.locale);
      if (snapshot != null) _session.restoreSnapshot(snapshot);
      _stopwatch
        ..reset()
        ..start();
    });
  }

  MiLevel get _level => _session.level;
  Map<String, dynamic> get _content => _session.content;

  void _choose(ChoiceGameOption option) {
    final correct = _session.choose(option);
    unawaited(_playEffect(correct ? 'correct' : 'try_again'));
    setState(() {});
    if (correct) _showCompletion();
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
      newSkillsAcquired: skillIdsFor(_level, fallback: const ['logic']),
      metadata: {
        'stars': _session.stars,
        'deepLogicScene': widget.scene.name,
      },
    ));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompletionOverlay(
        starsEarned: _session.stars,
        maxStars: 3,
        message: _completionMessage(),
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
    final prompt = _content['prompt'] as String? ?? '';
    final deepData = _DeepLevelData.from(level: _level, content: _content);

    return Scaffold(
      backgroundColor: GameTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
              title: widget.title,
              score: _level.levelNumber,
              onExit: widget.onExit,
            ),
            ProgressDots(
              total: widget.allLevels.length,
              completed: _level.levelNumber - 1,
              color: widget.primaryColor,
            ),
            Expanded(
              child: ListView(
                padding: GameTheme.screenPadding,
                children: [
                  _DeepScenePanel(
                    scene: widget.scene,
                    color: widget.primaryColor,
                    locale: widget.locale,
                    worldLabel: widget.worldLabel,
                    levelNumber: _level.levelNumber,
                    difficulty: _level.difficulty,
                    options: _session.options,
                    deepData: deepData,
                  ),
                  const SizedBox(height: 16),
                  _PromptCard(
                    prompt: prompt,
                    color: widget.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  for (final option in _session.options)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DeepChoiceButton(
                        option: option,
                        color: widget.primaryColor,
                        onPressed: () => _choose(option),
                      ),
                    ),
                ],
              ),
            ),
            if (_session.feedback != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: FeedbackBubble(
                  isCorrect: _session.lastCorrect ?? false,
                  message: _session.feedback!,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: HintButton(
                onPressed: _showHint,
                hintsAvailable: _level.hints.length,
                hintsRemaining: (_level.hints.length - _session.hintsUsed)
                    .clamp(0, _level.hints.length),
                availableSemanticLabel: text.hintAvailable,
                emptySemanticLabel: text.hintEmpty,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _completionMessage() {
    return switch (widget.scene) {
      DeepLogicScene.maze => widget.locale == 'en'
          ? 'You planned a clear path for MI!'
          : 'Con đã vạch đường đi rõ ràng cho MI!',
      DeepLogicScene.sudoku => widget.locale == 'en'
          ? 'You solved the grid clue!'
          : 'Con đã giải được ô lưới!',
      DeepLogicScene.detective => widget.locale == 'en'
          ? 'Great detective thinking!'
          : 'Suy luận như thám tử thật giỏi!',
      DeepLogicScene.creative => widget.locale == 'en'
          ? 'Your story idea is taking shape!'
          : 'Ý tưởng câu chuyện của con đang thành hình!',
      DeepLogicScene.reading => widget.locale == 'en'
          ? 'You understood the story clue!'
          : 'Con đã hiểu chi tiết trong câu chuyện!',
    };
  }
}

class _DeepScenePanel extends StatelessWidget {
  const _DeepScenePanel({
    required this.scene,
    required this.color,
    required this.locale,
    required this.worldLabel,
    required this.levelNumber,
    required this.difficulty,
    required this.options,
    required this.deepData,
  });

  final DeepLogicScene scene;
  final Color color;
  final String locale;
  final String worldLabel;
  final int levelNumber;
  final int difficulty;
  final List<ChoiceGameOption> options;
  final _DeepLevelData deepData;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MiBrandIconView(
                  icon: _iconForScene(scene),
                  color: color,
                  size: 40,
                  semanticLabel: _sceneTitle,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_sceneTitle, style: GameTheme.headingMedium),
                      const SizedBox(height: 4),
                      Text(
                        worldLabel,
                        style: GameTheme.bodyMedium.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            switch (scene) {
              DeepLogicScene.maze => _MazeBoard(
                  color: color,
                  levelNumber: levelNumber,
                  difficulty: difficulty,
                  deepData: deepData,
                ),
              DeepLogicScene.sudoku => _SudokuBoard(
                  color: color,
                  options: options,
                  levelNumber: levelNumber,
                  locale: locale,
                  deepData: deepData,
                ),
              DeepLogicScene.detective => _DetectiveBoard(
                  color: color,
                  locale: locale,
                  levelNumber: levelNumber,
                  deepData: deepData,
                ),
              DeepLogicScene.creative => _CreativeBoard(
                  color: color,
                  locale: locale,
                  options: options,
                  deepData: deepData,
                ),
              DeepLogicScene.reading => _ReadingBoard(
                  color: color,
                  locale: locale,
                  levelNumber: levelNumber,
                  deepData: deepData,
                ),
            },
            if (deepData.sceneNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SceneNotes(notes: deepData.sceneNotes, color: color),
            ],
          ],
        ),
      ),
    );
  }

  String get _sceneTitle {
    return switch (scene) {
      DeepLogicScene.maze => locale == 'en' ? 'Path planner' : 'Bàn tìm đường',
      DeepLogicScene.sudoku => locale == 'en' ? 'Mini grid' : 'Ô lưới nhỏ',
      DeepLogicScene.detective =>
        locale == 'en' ? 'Clue board' : 'Bảng manh mối',
      DeepLogicScene.creative =>
        locale == 'en' ? 'Story lab' : 'Xưởng câu chuyện',
      DeepLogicScene.reading =>
        locale == 'en' ? 'Story lens' : 'Ống kính đọc hiểu',
    };
  }

  MiBrandIcon _iconForScene(DeepLogicScene scene) {
    return switch (scene) {
      DeepLogicScene.maze => MiBrandIcon.exploration,
      DeepLogicScene.sudoku => MiBrandIcon.logic,
      DeepLogicScene.detective => MiBrandIcon.logic,
      DeepLogicScene.creative => MiBrandIcon.writing,
      DeepLogicScene.reading => MiBrandIcon.writing,
    };
  }
}

class _MazeBoard extends StatelessWidget {
  const _MazeBoard({
    required this.color,
    required this.levelNumber,
    required this.difficulty,
    required this.deepData,
  });

  final Color color;
  final int levelNumber;
  final int difficulty;
  final _DeepLevelData deepData;

  @override
  Widget build(BuildContext context) {
    final size = deepData.gridSize ?? (difficulty >= 4 ? 5 : 4);
    final start = deepData.startIndex ?? (size - 1) * size;
    final goal = deepData.goalIndex ?? size - 1;
    final path = deepData.pathIndexes.isNotEmpty
        ? deepData.pathIndexes.toSet()
        : _fallbackMazePath(size, levelNumber, difficulty);
    final obstacles = deepData.obstacleIndexes.toSet();

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: size * size,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: size,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final isStart = index == start;
              final isGoal = index == goal;
              final isPath = path.contains(index);
              final isObstacle = obstacles.contains(index);
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: isObstacle
                      ? MiColors.navy.withValues(alpha: 0.08)
                      : isPath
                          ? color.withValues(alpha: 0.16)
                          : MiColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isGoal || isStart
                        ? color
                        : color.withValues(alpha: 0.2),
                    width: isGoal || isStart ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: isStart
                      ? Text(
                          'MI',
                          style: GameTheme.buttonLabel.copyWith(color: color),
                        )
                      : isGoal
                          ? const Icon(
                              Icons.star_rounded,
                              color: MiColors.accent,
                            )
                          : isPath
                              ? Icon(Icons.arrow_forward_rounded, color: color)
                              : const SizedBox.shrink(),
                ),
              );
            },
          ),
        ),
        if (deepData.commands.isNotEmpty) ...[
          const SizedBox(height: 12),
          _CommandTrail(
            key: const ValueKey('deep-command-trail'),
            commands: deepData.commands,
            color: color,
          ),
        ],
      ],
    );
  }

  Set<int> _fallbackMazePath(int size, int levelNumber, int difficulty) {
    final pathLength = (levelNumber % 4) + difficulty + 1;
    final path = <int>{};
    var row = size - 1;
    var col = 0;
    path.add(row * size + col);
    for (var step = 0;
        step < pathLength && (row > 0 || col < size - 1);
        step++) {
      if ((step + levelNumber).isEven && col < size - 1) {
        col++;
      } else if (row > 0) {
        row--;
      }
      path.add(row * size + col);
    }
    return path;
  }
}

class _SudokuBoard extends StatelessWidget {
  const _SudokuBoard({
    required this.color,
    required this.options,
    required this.levelNumber,
    required this.locale,
    required this.deepData,
  });

  final Color color;
  final List<ChoiceGameOption> options;
  final int levelNumber;
  final String locale;
  final _DeepLevelData deepData;

  @override
  Widget build(BuildContext context) {
    final symbols = deepData.symbols.isNotEmpty
        ? deepData.symbols
        : const ['A', 'B', 'C', 'D'];
    final size = deepData.gridSize ?? 4;
    final blank = deepData.blankIndex ?? levelNumber % (size * size);
    final blankRow = blank ~/ size;
    final blankCol = blank % size;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: size * size,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: size,
            ),
            itemBuilder: (context, index) {
              final isBlank = index == blank;
              final isFocused = !isBlank &&
                  (index ~/ size == blankRow || index % size == blankCol);
              final authoredValue = deepData.givens[index];
              final value = isBlank
                  ? '?'
                  : authoredValue ??
                      symbols[(index + levelNumber) % symbols.length];
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: isBlank
                      ? color.withValues(alpha: 0.14)
                      : isFocused
                          ? color.withValues(alpha: 0.06)
                          : Colors.white,
                  border: Border.all(
                    color: isBlank
                        ? color
                        : isFocused
                            ? color.withValues(alpha: 0.44)
                            : MiColors.navy.withValues(alpha: 0.2),
                    width: isBlank || isFocused ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    isBlank ? '?' : value,
                    style: GameTheme.headingMedium.copyWith(
                      color: isBlank ? color : MiColors.navy,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${locale == 'en' ? 'Choices' : 'Lựa chọn'}: '
          '${options.map((option) => option.text).join(' / ')}',
          style: GameTheme.bodyMedium.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 8),
        _TinyInstruction(
          key: const ValueKey('deep-sudoku-focus-hint'),
          text: locale == 'en'
              ? 'Check the highlighted row and column'
              : 'Nhìn hàng và cột đang được tô sáng',
          color: color,
        ),
      ],
    );
  }
}

class _DetectiveBoard extends StatelessWidget {
  const _DetectiveBoard({
    required this.color,
    required this.locale,
    required this.levelNumber,
    required this.deepData,
  });

  final Color color;
  final String locale;
  final int levelNumber;
  final _DeepLevelData deepData;

  @override
  Widget build(BuildContext context) {
    final labels = locale == 'en'
        ? ['Clue 1', 'Clue 2', 'Conclusion']
        : ['Manh mối 1', 'Manh mối 2', 'Kết luận'];
    final values = deepData.clues.isNotEmpty
        ? deepData.clues
        : ['A before B', 'B before C', 'Who is first?'];
    return Column(
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Text('${i + 1}', style: TextStyle(color: color)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${labels[i]}: ${values[(i + levelNumber) % values.length]}',
                    style: GameTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CreativeBoard extends StatelessWidget {
  const _CreativeBoard({
    required this.color,
    required this.locale,
    required this.options,
    required this.deepData,
  });

  final Color color;
  final String locale;
  final List<ChoiceGameOption> options;
  final _DeepLevelData deepData;

  @override
  Widget build(BuildContext context) {
    final labels = deepData.storyLabels.isNotEmpty
        ? deepData.storyLabels
        : locale == 'en'
            ? ['Setting', 'Feeling', 'Detail']
            : ['Bối cảnh', 'Cảm xúc', 'Chi tiết'];
    final cards = deepData.storyCards.isNotEmpty
        ? deepData.storyCards
        : options.map((option) => option.text).toList(growable: false);
    return Column(
      children: [
        if (deepData.targetFeeling != null) ...[
          _TinyInstruction(
            key: const ValueKey('deep-creative-feeling-goal'),
            text: locale == 'en'
                ? 'Feeling goal: ${deepData.targetFeeling}'
                : 'Cảm xúc mục tiêu: ${deepData.targetFeeling}',
            color: color,
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            for (var i = 0; i < labels.take(3).length; i++)
              Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.only(right: i == labels.length - 1 ? 0 : 8),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 112),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: i == 1
                          ? color.withValues(alpha: 0.14)
                          : MiColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.24)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          i == 0
                              ? Icons.landscape_rounded
                              : i == 1
                                  ? Icons.favorite_rounded
                                  : Icons.edit_rounded,
                          color: color,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          labels[i],
                          style: GameTheme.buttonLabel.copyWith(
                            color: MiColors.navy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cards.isEmpty ? '' : cards[i % cards.length],
                          style: GameTheme.bodyMedium.copyWith(fontSize: 13),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ReadingBoard extends StatelessWidget {
  const _ReadingBoard({
    required this.color,
    required this.locale,
    required this.levelNumber,
    required this.deepData,
  });

  final Color color;
  final String locale;
  final int levelNumber;
  final _DeepLevelData deepData;

  @override
  Widget build(BuildContext context) {
    final steps = deepData.readingSteps.isNotEmpty
        ? deepData.readingSteps
        : locale == 'en'
            ? ['Read', 'Find the fact', 'Choose']
            : ['Đọc', 'Tìm chi tiết', 'Chọn đáp án'];
    return Column(
      children: [
        if (deepData.passage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              deepData.passage!,
              style: GameTheme.bodyMedium.copyWith(color: MiColors.navy),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(
              value: (i + 1) / steps.length,
              minHeight: 20,
              color:
                  i <= levelNumber % 3 ? color : color.withValues(alpha: 0.28),
              backgroundColor: MiColors.background,
              borderRadius: BorderRadius.circular(20),
              semanticsLabel: steps[i],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps
              .map(
                (step) => Text(
                  step,
                  style: GameTheme.buttonLabel.copyWith(
                    color: MiColors.navy,
                    fontSize: 14,
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _CommandTrail extends StatelessWidget {
  const _CommandTrail({
    super.key,
    required this.commands,
    required this.color,
  });

  final List<String> commands;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < commands.length; i += 1)
          Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: i.isEven ? color : color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(MiTokens.radiusFull),
              border: Border.all(color: color.withValues(alpha: 0.24)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _iconForCommand(commands[i]),
                  size: 20,
                  color: i.isEven ? Colors.white : color,
                ),
                const SizedBox(width: 6),
                Text(
                  '${i + 1}',
                  style: GameTheme.buttonLabel.copyWith(
                    color: i.isEven ? Colors.white : color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _iconForCommand(String command) {
    return switch (command.toLowerCase()) {
      'up' => Icons.arrow_upward_rounded,
      'down' => Icons.arrow_downward_rounded,
      'left' => Icons.arrow_back_rounded,
      'right' => Icons.arrow_forward_rounded,
      _ => Icons.near_me_rounded,
    };
  }
}

class _TinyInstruction extends StatelessWidget {
  const _TinyInstruction({
    super.key,
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MiTokens.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.22)),
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

class _DeepLevelData {
  const _DeepLevelData({
    required this.localized,
    required this.structural,
  });

  factory _DeepLevelData.from({
    required MiLevel level,
    required Map<String, dynamic> content,
  }) {
    return _DeepLevelData(
      localized: _asMap(content['deepData']),
      structural: _asMap(level.metadata['deepData']),
    );
  }

  final Map<String, dynamic> localized;
  final Map<String, dynamic> structural;

  int? get gridSize => _asInt(structural['gridSize']);
  int? get startIndex => _asInt(structural['startIndex']);
  int? get goalIndex => _asInt(structural['goalIndex']);
  int? get blankIndex => _asInt(structural['blankIndex']);
  List<int> get pathIndexes => _asIntList(structural['path']);
  List<int> get obstacleIndexes => _asIntList(structural['obstacles']);
  List<String> get commands => _asStringList(structural['commands']);
  List<String> get symbols => _asStringList(structural['symbols']);
  Map<int, String> get givens => _asIntStringMap(structural['givens']);
  List<String> get clues => _asStringList(localized['clues']);
  List<String> get storyLabels => _asStringList(localized['storyLabels']);
  List<String> get storyCards => _asStringList(localized['storyCards']);
  String? get targetFeeling => structural['targetFeeling'] as String?;
  List<String> get readingSteps => _asStringList(localized['steps']);
  String? get passage => localized['passage'] as String?;
  List<String> get sceneNotes => [
        if (localized['pathSummary'] case final String pathSummary) pathSummary,
        ...readingSteps,
      ];

  static Map<String, dynamic> _asMap(Object? value) {
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

  static Map<int, String> _asIntStringMap(Object? value) {
    if (value is! Map) return const {};
    final result = <int, String>{};
    for (final entry in value.entries) {
      final parsedKey = int.tryParse(entry.key.toString());
      if (parsedKey != null) result[parsedKey] = entry.value.toString();
    }
    return result;
  }
}

class _SceneNotes extends StatelessWidget {
  const _SceneNotes({
    required this.notes,
    required this.color,
  });

  final List<String> notes;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final note in notes)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              note,
              style: GameTheme.bodyMedium.copyWith(
                color: MiColors.navy,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.prompt,
    required this.color,
  });

  final String prompt;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        prompt,
        style: GameTheme.headingMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _DeepChoiceButton extends StatelessWidget {
  const _DeepChoiceButton({
    required this.option,
    required this.color,
    required this.onPressed,
  });

  final ChoiceGameOption option;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: Colors.white,
          foregroundColor: MiColors.navy,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withValues(alpha: 0.32)),
          ),
          textStyle: GameTheme.buttonLabel.copyWith(color: MiColors.navy),
        ),
        onPressed: onPressed,
        child: Text(option.text, textAlign: TextAlign.center),
      ),
    );
  }
}
