import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

import '../snapshot_lifecycle_mixin.dart';
import 'choice_game_session.dart';

class ChoiceGameScreen extends StatefulWidget {
  const ChoiceGameScreen({
    super.key,
    required this.title,
    required this.worldLabel,
    required this.level,
    required this.allLevels,
    required this.heroIcon,
    required this.primaryColor,
    this.onExit,
    this.onComplete,
    this.initialSnapshot,
    this.onSaveSnapshot,
  });

  final String title;
  final String worldLabel;
  final MiLevel level;
  final List<MiLevel> allLevels;
  final IconData heroIcon;
  final Color primaryColor;
  final VoidCallback? onExit;

  /// Fired once per level completion — see WordBuilderScreen.onComplete.
  final void Function(MiCompletionResult)? onComplete;

  /// See WordBuilderScreen.initialSnapshot.
  final MiGameSnapshot? initialSnapshot;

  /// See WordBuilderScreen.onSaveSnapshot.
  final void Function(MiGameSnapshot)? onSaveSnapshot;

  @override
  State<ChoiceGameScreen> createState() => _ChoiceGameScreenState();
}

class _ChoiceGameScreenState extends State<ChoiceGameScreen>
    with WidgetsBindingObserver, SnapshotLifecycleMixin<ChoiceGameScreen> {
  late ChoiceGameSession _session;
  late Stopwatch _stopwatch;
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
    _stopwatch.stop();
    super.dispose();
  }

  void _loadLevel(MiLevel level, {MiGameSnapshot? snapshot}) {
    setState(() {
      _completed = false;
      _session = ChoiceGameSession(level: level);
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

  void _choose(ChoiceGameOption option) {
    final correct = _session.choose(option);
    setState(() {});
    if (correct) {
      _showCompletion();
    }
  }

  void _showHint() {
    setState(() {
      _session.showHint();
    });
  }

  void _showCompletion() {
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
      newSkillsAcquired: const ['math'],
    ));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompletionOverlay(
        starsEarned: _session.stars,
        maxStars: 3,
        message: 'MI thấy con đã hiểu bài!',
        score: _session.score,
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
    final prompt = _content['prompt'] as String? ?? '';

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
                  _RacePanel(
                    worldLabel: widget.worldLabel,
                    icon: widget.heroIcon,
                    color: widget.primaryColor,
                    progress: _session.progress,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    prompt,
                    style: GameTheme.headingMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  ..._session.options.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ChoiceButton(
                        option: option,
                        color: widget.primaryColor,
                        onPressed: () => _choose(option),
                      ),
                    ),
                  ),
                  if (_session.feedback != null) ...[
                    const SizedBox(height: 8),
                    FeedbackBubble(
                      isCorrect: _session.feedback!.contains('Đúng'),
                      message: _session.feedback!,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: HintButton(
                onPressed: _showHint,
                hintsAvailable: _level.hints.length,
                hintsRemaining: _level.hints.length - _session.hintsUsed < 0
                    ? 0
                    : _level.hints.length - _session.hintsUsed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RacePanel extends StatelessWidget {
  const _RacePanel({
    required this.worldLabel,
    required this.icon,
    required this.color,
    required this.progress,
  });

  final String worldLabel;
  final IconData icon;
  final Color color;
  final double progress;

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
                Icon(icon, color: color, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(worldLabel, style: GameTheme.headingMedium),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 16,
                color: color,
                backgroundColor: color.withValues(alpha: 0.14),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.lerp(
                    Alignment.centerLeft,
                    Alignment.centerRight,
                    progress,
                  ) ??
                  Alignment.centerLeft,
              child: const MiCharacterHead(size: 32, semanticLabel: 'MI'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
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
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: GameTheme.textPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameTheme.buttonRadius),
            side: BorderSide(color: color),
          ),
        ),
        child: Text(option.text, style: GameTheme.headingMedium),
      ),
    );
  }
}
