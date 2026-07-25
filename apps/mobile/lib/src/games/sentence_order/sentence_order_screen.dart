import 'package:flutter/material.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_engines/mi_game_engines.dart';

import '../game_locale_text.dart';
import '../level_skill_ids.dart';

class SentenceOrderScreen extends StatefulWidget {
  const SentenceOrderScreen({
    super.key,
    required this.level,
    required this.allLevels,
    required this.onExit,
    required this.onComplete,
    required this.childProfileId,
    this.initialSnapshot,
    this.onSaveSnapshot,
    this.reduceMotion = false,
    required this.locale,
  });

  final MiLevel level;
  final List<MiLevel> allLevels;
  final VoidCallback onExit;
  final void Function(MiCompletionResult) onComplete;
  final String childProfileId;
  final MiGameSnapshot? initialSnapshot;
  final void Function(MiGameSnapshot)? onSaveSnapshot;
  final bool reduceMotion;
  final String locale;

  @override
  State<SentenceOrderScreen> createState() => _SentenceOrderScreenState();
}

class _SentenceOrderScreenState extends State<SentenceOrderScreen> {
  late final Stopwatch _stopwatch;
  late MiLevel _level;
  SequenceSnapshot? _initialSequenceSnapshot;

  @override
  void initState() {
    super.initState();
    _level = widget.level;
    _initialSequenceSnapshot = _snapshotFrom(widget.initialSnapshot);
    _stopwatch = Stopwatch()..start();
  }

  @override
  void didUpdateWidget(covariant SentenceOrderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level.id != widget.level.id ||
        oldWidget.locale != widget.locale) {
      _level = widget.level;
      _initialSequenceSnapshot = _snapshotFrom(widget.initialSnapshot);
      _restartTimer();
    }
  }

  void _handleComplete(SequenceCompletionResult result) {
    _stopwatch.stop();
    final stars = result.starsEarned;
    const maxScore = 100;
    final score = switch (stars) {
      3 => 100,
      2 => 80,
      _ => 60,
    };
    widget.onComplete(
      MiCompletionResult(
        gameId: _level.gameId,
        levelId: _level.id,
        childProfileId: widget.childProfileId,
        completedAt: DateTime.now(),
        score: score,
        maxScore: maxScore,
        attemptsUsed: result.attempts,
        hintsUsed: result.hintsUsed,
        duration: _stopwatch.elapsed,
        perfectRun: result.attempts <= 1 && result.hintsUsed == 0,
        newSkillsAcquired: skillIdsFor(
          _level,
          fallback: const ['letters.simple_sentences'],
        ),
        metadata: {
          'engine': SequenceController.engineId,
          'stars': stars,
          'contentId': result.contentId,
          'completedItems': result.completedItemCount,
          'totalItems': result.totalItemCount,
          'isMasteryScore': true,
        },
      ),
    );
  }

  void _saveSnapshot(SequenceSnapshot snapshot) {
    widget.onSaveSnapshot?.call(
      MiGameSnapshot(
        gameId: _level.gameId,
        levelId: _level.id,
        childProfileId: widget.childProfileId,
        state: {
          'engine': SequenceController.engineId,
          'sequence': snapshot.toJson(),
          'contentVersion': _level.contentVersion,
        },
        createdAt: DateTime.now(),
        attemptsUsed: snapshot.attempts,
        hintsUsed: snapshot.hintsUsed,
        itemsCompleted: snapshot.completedItemCount,
        totalItems: snapshot.totalItemCount,
        metadata: {
          'engine': SequenceController.engineId,
          'contentId': snapshot.contentId,
          'mode': snapshot.mode == SequenceMode.missingItem
              ? 'missingItem'
              : 'reorder',
        },
      ),
    );
  }

  void _goNext() {
    final next = _nextLevel;
    if (next == null) {
      widget.onExit();
      return;
    }
    setState(() {
      _level = next;
      _initialSequenceSnapshot = null;
      _restartTimer();
    });
  }

  MiLevel? get _nextLevel {
    final index = widget.allLevels.indexWhere((level) => level.id == _level.id);
    if (index < 0 || index + 1 >= widget.allLevels.length) return null;
    return widget.allLevels[index + 1];
  }

  void _restartTimer() {
    _stopwatch
      ..reset()
      ..start();
  }

  SequenceSnapshot? _snapshotFrom(MiGameSnapshot? snapshot) {
    if (snapshot == null ||
        snapshot.gameId != widget.level.gameId ||
        snapshot.levelId != widget.level.id) {
      return null;
    }
    final state = snapshot.state;
    if (state['engine'] != SequenceController.engineId) return null;
    final sequence = state['sequence'];
    if (sequence is! Map) return null;
    return SequenceSnapshot.fromJson(Map<String, dynamic>.from(sequence));
  }

  @override
  Widget build(BuildContext context) {
    final text = GameLocaleText(widget.locale);
    return SequenceScreen(
      key: ValueKey('sentence-order-${_level.id}-${widget.locale}'),
      rawContent: _sequenceContentFor(_level, widget.locale),
      text: SequenceScreenText(
        check: text.sequenceCheck,
        exit: text.sequenceExit,
        next: text.sequenceNext,
        pause: text.sequencePause,
        resume: text.sequenceResume,
        hint: text.sequenceHint,
        replay: text.sequenceReplay,
        contentUnavailable: text.sequenceContentUnavailable,
        moveLeft: text.sequenceMoveLeft,
        moveRight: text.sequenceMoveRight,
        tryAgain: text.sequenceTryAgain,
        choose: text.sequenceChoose,
        moveItem: text.sequenceMoveItem,
        blankSlot: text.sequenceBlankSlot,
        stars: text.sequenceStars,
        completed: text.sequenceCompleted,
      ),
      initialSnapshot: _initialSequenceSnapshot,
      onExit: widget.onExit,
      onComplete: _handleComplete,
      onNext: _nextLevel == null ? null : _goNext,
      onRestart: _restartTimer,
      onSnapshotChanged: _saveSnapshot,
      reducedMotion: widget.reduceMotion,
      locale: widget.locale,
    );
  }

  Map<String, dynamic> _sequenceContentFor(MiLevel level, String locale) {
    final content = level.contentForLocale(locale);
    final sequence = content['sequence'];
    if (sequence is Map) {
      return Map<String, dynamic>.from(sequence);
    }
    return Map<String, dynamic>.from(content);
  }
}
