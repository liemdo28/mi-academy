import 'package:flutter/material.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_engines/mi_game_engines.dart';

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

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
  }

  void _handleComplete(SequenceCompletionResult result) {
    _stopwatch.stop();
    final stars = result.starsEarned;
    const maxScore = 100;
    final score = (maxScore * stars / 3).round();
    widget.onComplete(
      MiCompletionResult(
        gameId: widget.level.gameId,
        levelId: widget.level.id,
        childProfileId: widget.childProfileId,
        completedAt: DateTime.now(),
        score: score,
        maxScore: maxScore,
        attemptsUsed: result.attempts,
        duration: _stopwatch.elapsed,
        perfectRun: result.attempts <= 1,
        newSkillsAcquired: skillIdsFor(
          widget.level,
          fallback: const ['letters.simple_sentences'],
        ),
        metadata: {
          'engine': SequenceController.engineId,
          'stars': stars,
          'contentId': result.contentId,
        },
      ),
    );
  }

  void _saveAttempts(int attempts) {
    widget.onSaveSnapshot?.call(
      MiGameSnapshot(
        gameId: widget.level.gameId,
        levelId: widget.level.id,
        childProfileId: widget.childProfileId,
        state: {
          'engine': SequenceController.engineId,
          'attempts': attempts,
          'contentVersion': widget.level.contentVersion,
        },
        createdAt: DateTime.now(),
        attemptsUsed: attempts,
        itemsCompleted: attempts > 0 ? 1 : 0,
        totalItems: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SequenceScreen(
      key: ValueKey('sentence-order-${widget.level.id}-${widget.locale}'),
      rawContent: _sequenceContentFor(widget.level, widget.locale),
      onExit: widget.onExit,
      onComplete: _handleComplete,
      onSaveProgress: _saveAttempts,
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
