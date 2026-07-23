import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:mi_game_audio/mi_game_audio.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_ui/mi_game_ui.dart';

import '../level_skill_ids.dart';
import '../game_locale_text.dart';
import '../snapshot_lifecycle_mixin.dart';
import 'word_builder_session.dart';

class WordBuilderScreen extends StatefulWidget {
  const WordBuilderScreen({
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

  /// From the parent's language setting (see ParentSettingsSnapshot.language)
  /// -- was previously hardcoded to 'vi' regardless of this setting.
  final String locale;

  /// Fired once per level completion with the session's score/attempts/hints,
  /// so a caller (e.g. the production game launcher) can save a real result
  /// without this screen calling the backend or Hive itself.
  final void Function(MiCompletionResult)? onComplete;

  /// A previously-saved in-progress snapshot for this exact (child, game,
  /// level), already validated by the platform (checksum, child/level
  /// match, schema version) -- this screen just applies it. Null means
  /// start fresh.
  final MiGameSnapshot? initialSnapshot;

  /// Called with a snapshot of the current session when the app backgrounds
  /// or this screen is exited mid-level. This screen never persists it
  /// itself — see [SnapshotLifecycleMixin] and Phase 10's "platform owns
  /// save/load" rule.
  final void Function(MiGameSnapshot)? onSaveSnapshot;

  @override
  State<WordBuilderScreen> createState() => _WordBuilderScreenState();
}

class _WordBuilderScreenState extends State<WordBuilderScreen>
    with WidgetsBindingObserver, SnapshotLifecycleMixin<WordBuilderScreen> {
  late WordBuilderSession _session;
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
      _session = WordBuilderSession(level: level, locale: widget.locale);
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

  void _placeLetter(int bankIndex) {
    final slotIndex = _session.placed.indexWhere((letter) => letter == null);
    if (slotIndex == -1) return;

    setState(() {
      _session.placeLetter(bankIndex);
    });
  }

  void _removeLetter(int slotIndex) {
    final letter = _session.placed[slotIndex];
    if (letter == null) return;

    setState(() {
      _session.removeLetter(slotIndex);
    });
  }

  void _checkAnswer() {
    final correct = _session.checkAnswer();
    unawaited(_playEffect(correct ? 'correct' : 'try_again'));
    if (correct) {
      _showCompletion();
    } else {
      setState(() {});
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
      newSkillsAcquired: skillIdsFor(_level, fallback: const ['vocabulary']),
    ));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompletionOverlay(
        starsEarned: _session.stars,
        maxStars: 3,
        message: text.wordBuilderComplete,
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
    final prompt = _content['prompt'] as String? ?? 'Ghép chữ thành từ!';
    final targetWord = _content['targetWord'] as String? ?? '';

    return Scaffold(
      backgroundColor: GameTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
              title: text.wordBuilderTitle,
              score: _level.levelNumber,
              onExit: widget.onExit,
            ),
            ProgressDots(
              total: widget.allLevels.length,
              completed: _level.levelNumber - 1,
            ),
            Expanded(
              child: ListView(
                padding: GameTheme.screenPadding,
                children: [
                  _MiPromptCard(
                    prompt: prompt,
                    targetWord: targetWord,
                    text: text,
                  ),
                  const SizedBox(height: 20),
                  _AnswerSlots(
                    placed: _session.placed,
                    onRemove: _removeLetter,
                    text: text,
                  ),
                  const SizedBox(height: 24),
                  _LetterBank(
                    letters: _session.bank,
                    onPick: _placeLetter,
                    text: text,
                  ),
                  const SizedBox(height: 20),
                  if (_session.feedback != null)
                    FeedbackBubble(
                      isCorrect: _session.feedback!.contains('đúng'),
                      message: _session.feedback!,
                    ),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _checkAnswer,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(text.wordBuilderCheck),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameTheme.primary,
                        foregroundColor: Colors.white,
                        padding: GameTheme.buttonPadding,
                        textStyle: GameTheme.buttonLabel,
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

class _MiPromptCard extends StatelessWidget {
  const _MiPromptCard({
    required this.prompt,
    required this.targetWord,
    required this.text,
  });

  final String prompt;
  final String targetWord;
  final GameLocaleText text;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const MiCharacter(
              expression: MiExpression.hinting,
              size: 56,
              semanticLabel: 'MI',
            ),
            const SizedBox(height: 8),
            Text(prompt, style: GameTheme.headingMedium),
            const SizedBox(height: 8),
            Text(
              text.wordBuilderLength(targetWord.length),
              style: GameTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerSlots extends StatelessWidget {
  const _AnswerSlots({
    required this.placed,
    required this.onRemove,
    required this.text,
  });

  final List<String?> placed;
  final void Function(int slotIndex) onRemove;
  final GameLocaleText text;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(placed.length, (index) {
        final letter = placed[index];
        return SizedBox(
          width: 54,
          height: 58,
          child: Semantics(
            label: letter == null
                ? text.emptySlot(index)
                : letter == ' '
                    ? text.spaceSlot
                    : text.filledLetter(letter),
            button: letter != null,
            child: OutlinedButton(
              onPressed: letter == null ? null : () => onRemove(index),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: GameTheme.primary, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GameTheme.buttonRadius),
                ),
                backgroundColor: Colors.white,
              ),
              child: Text(
                letter == ' ' ? '␣' : letter ?? '',
                style: GameTheme.headingMedium,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _LetterBank extends StatelessWidget {
  const _LetterBank({
    required this.letters,
    required this.onPick,
    required this.text,
  });

  final List<String> letters;
  final void Function(int index) onPick;
  final GameLocaleText text;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: List.generate(letters.length, (index) {
        final letter = letters[index];
        return SizedBox(
          width: 56,
          height: 56,
          child: Semantics(
            label: letter == ' ' ? text.bankSpace : text.bankLetter(letter),
            button: true,
            child: ElevatedButton(
              onPressed: () => onPick(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: GameTheme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GameTheme.buttonRadius),
                ),
              ),
              child: Text(
                letter == ' ' ? '␣' : letter,
                style: GameTheme.headingMedium.copyWith(color: Colors.white),
              ),
            ),
          ),
        );
      }),
    );
  }
}
