import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:mi_game_audio/mi_game_audio.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

import '../game_locale_text.dart';
import '../level_skill_ids.dart';
import '../snapshot_lifecycle_mixin.dart';
import 'choice_game_session.dart';
import 'choice_visual_board.dart';

class ChoiceGameScreen extends StatefulWidget {
  const ChoiceGameScreen({
    super.key,
    required this.title,
    required this.worldLabel,
    required this.level,
    required this.allLevels,
    required this.primaryColor,
    this.brandIcon,
    this.heroIcon,
    this.onExit,
    this.onComplete,
    this.initialSnapshot,
    this.onSaveSnapshot,
    this.locale = 'vi',
  }) : assert(brandIcon != null || heroIcon != null);

  final String title;
  final String worldLabel;
  final MiLevel level;
  final List<MiLevel> allLevels;
  final MiBrandIcon? brandIcon;

  @Deprecated('Use brandIcon instead.')
  final IconData? heroIcon;
  final Color primaryColor;
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
  State<ChoiceGameScreen> createState() => _ChoiceGameScreenState();
}

class _ChoiceGameScreenState extends State<ChoiceGameScreen>
    with WidgetsBindingObserver, SnapshotLifecycleMixin<ChoiceGameScreen> {
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
    unawaited(_playEffect(correct ? 'correct' : 'try_again'));
    setState(() {});
    if (correct) {
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
      newSkillsAcquired: skillIdsFor(_level, fallback: const ['math']),
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
    final visualBoardEmbedsPrompt =
        ChoiceVisualBoard.embedsPromptFor(_level.gameId);

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
                    brandIcon: widget.brandIcon,
                    legacyIcon: widget.heroIcon,
                    color: widget.primaryColor,
                    progress: _session.progress,
                  ),
                  const SizedBox(height: 18),
                  ChoiceVisualBoard(
                    level: _level,
                    content: _content,
                    options: _session.options,
                    color: widget.primaryColor,
                    locale: widget.locale,
                  ),
                  if (!visualBoardEmbedsPrompt) ...[
                    const SizedBox(height: 18),
                    Text(
                      prompt,
                      style: GameTheme.headingMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
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
                hintsRemaining: _level.hints.length - _session.hintsUsed < 0
                    ? 0
                    : _level.hints.length - _session.hintsUsed,
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
    if (_level.gameId == 'missing_letter') {
      return widget.locale == 'en'
          ? 'You found the missing letter!'
          : 'Con đã tìm được chữ còn thiếu!';
    }
    return widget.locale == 'en'
        ? 'MI can see you understand this!'
        : 'MI thấy con đã hiểu bài!';
  }
}

class _RacePanel extends StatelessWidget {
  const _RacePanel({
    required this.worldLabel,
    required this.brandIcon,
    required this.legacyIcon,
    required this.color,
    required this.progress,
  });

  final String worldLabel;
  final MiBrandIcon? brandIcon;
  final IconData? legacyIcon;
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
                if (brandIcon != null)
                  MiBrandIconView(
                    icon: brandIcon!,
                    color: color,
                    size: 36,
                    semanticLabel: worldLabel,
                  )
                else
                  Icon(legacyIcon, color: color, size: 36),
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
