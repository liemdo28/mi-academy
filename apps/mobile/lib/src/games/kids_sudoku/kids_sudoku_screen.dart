import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:mi_game_audio/mi_game_audio.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

import '../game_locale_text.dart';
import '../level_skill_ids.dart';
import '../snapshot_lifecycle_mixin.dart';
import 'kids_sudoku_session.dart';

class KidsSudokuScreen extends StatefulWidget {
  const KidsSudokuScreen({
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
  State<KidsSudokuScreen> createState() => _KidsSudokuScreenState();
}

class _KidsSudokuScreenState extends State<KidsSudokuScreen>
    with WidgetsBindingObserver, SnapshotLifecycleMixin<KidsSudokuScreen> {
  late KidsSudokuSession _session;
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
      _session = KidsSudokuSession(level: level, locale: widget.locale);
      if (snapshot != null) _session.restoreSnapshot(snapshot);
      _stopwatch
        ..reset()
        ..start();
    });
  }

  MiLevel get _level => _session.level;
  Map<String, dynamic> get _content => _session.content;

  void _setSymbol(String symbol) {
    setState(() => _session.setSymbol(symbol));
  }

  void _erase() {
    setState(() => _session.erase());
  }

  void _check() {
    final complete = _session.check();
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
      newSkillsAcquired: skillIdsFor(_level, fallback: const ['logic']),
      metadata: {
        'stars': _session.stars,
        'engine': 'kids_sudoku_grid',
      },
    ));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompletionOverlay(
        starsEarned: _session.stars,
        maxStars: 3,
        message: text.sudokuComplete,
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
    final prompt = _content['prompt'] as String? ?? text.sudokuHint;

    return Scaffold(
      backgroundColor: GameTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
              title: text.sudokuTitle,
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
                  _SudokuIntroCard(prompt: prompt, text: text),
                  const SizedBox(height: 16),
                  _SudokuGrid(session: _session, text: text),
                  const SizedBox(height: 16),
                  Text(text.sudokuSymbols, style: GameTheme.headingMedium),
                  const SizedBox(height: 8),
                  _SymbolBank(
                    symbols: _session.symbols,
                    onSelect: _setSymbol,
                    onErase: _erase,
                    text: text,
                  ),
                  if (_session.feedback != null) ...[
                    const SizedBox(height: 16),
                    FeedbackBubble(
                      isCorrect: _session.status == KidsSudokuStatus.complete,
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
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _check,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(text.wordBuilderCheck),
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

class _SudokuIntroCard extends StatelessWidget {
  const _SudokuIntroCard({required this.prompt, required this.text});

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
              icon: MiBrandIcon.logic,
              color: MiColors.creative,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text.sudokuBoard, style: GameTheme.headingMedium),
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

class _SudokuGrid extends StatelessWidget {
  const _SudokuGrid({required this.session, required this.text});

  final KidsSudokuSession session;
  final GameLocaleText text;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        key: const ValueKey('kids-sudoku-grid'),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: session.gridSize * session.gridSize,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: session.gridSize,
        ),
        itemBuilder: (context, index) {
          final value = session.valueAt(index);
          final fixed = session.isFixed(index);
          final editable = session.isEditable(index);
          return Semantics(
            button: editable,
            label: value == null
                ? text.sudokuEmptyCellLabel(index)
                : text.sudokuCellLabel(index, value, fixed),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: editable
                    ? MiColors.creative.withValues(alpha: 0.14)
                    : Colors.white,
                border: Border.all(
                  color: editable
                      ? MiColors.creative
                      : MiColors.navy.withValues(alpha: 0.2),
                  width: editable ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                value ?? '?',
                style: GameTheme.headingLarge.copyWith(
                  color: editable ? MiColors.creative : MiColors.navy,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SymbolBank extends StatelessWidget {
  const _SymbolBank({
    required this.symbols,
    required this.onSelect,
    required this.onErase,
    required this.text,
  });

  final List<String> symbols;
  final ValueChanged<String> onSelect;
  final VoidCallback onErase;
  final GameLocaleText text;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final symbol in symbols)
          ElevatedButton(
            key: ValueKey('kids-sudoku-symbol-$symbol'),
            onPressed: () => onSelect(symbol),
            style: ElevatedButton.styleFrom(
              backgroundColor: MiColors.creative,
              foregroundColor: Colors.white,
              minimumSize: const Size(56, 48),
            ),
            child: Text(symbol),
          ),
        OutlinedButton.icon(
          onPressed: onErase,
          icon: const Icon(Icons.backspace_rounded),
          label: Text(text.sudokuErase),
          style: OutlinedButton.styleFrom(
            foregroundColor: MiColors.creative,
            minimumSize: const Size(80, 48),
          ),
        ),
      ],
    );
  }
}
