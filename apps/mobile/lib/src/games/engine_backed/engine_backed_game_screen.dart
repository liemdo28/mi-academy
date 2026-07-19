import 'package:flutter/material.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_engines/mi_game_engines.dart';

import '../level_skill_ids.dart';

enum EngineBackedGameKind { matching, sequence, placement, multiSelect }

class EngineBackedGameScreen extends StatefulWidget {
  const EngineBackedGameScreen({
    super.key,
    required this.kind,
    required this.level,
    required this.onExit,
    required this.onComplete,
    required this.childProfileId,
    required this.locale,
    this.reduceMotion = false,
  });

  final EngineBackedGameKind kind;
  final MiLevel level;
  final VoidCallback onExit;
  final void Function(MiCompletionResult) onComplete;
  final String childProfileId;
  final String locale;
  final bool reduceMotion;

  @override
  State<EngineBackedGameScreen> createState() => _EngineBackedGameScreenState();
}

class _EngineBackedGameScreenState extends State<EngineBackedGameScreen> {
  late final Stopwatch _stopwatch;
  bool _completionSent = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  Map<String, dynamic> get _rawContent {
    final localized = widget.level.contentForLocale(widget.locale);
    final engineContent = Map<String, dynamic>.from(
      localized['engineContent'] as Map? ?? localized,
    );
    final hint = localized['hint'] as String? ??
        (widget.level.hints.isEmpty
            ? null
            : widget.level.hints.first['text'] as String?);
    return {
      ...engineContent,
      'contentId': widget.level.id,
      'gameId': widget.level.gameId,
      'locale': widget.locale,
      'ageBand': widget.level.ageBand ??
          _ageBandForDifficulty(widget.level.difficulty),
      'difficulty': widget.level.difficulty,
      'instruction': engineContent['instruction'] ?? localized['prompt'] ?? '',
      if (engineContent['prompt'] == null)
        'prompt': localized['prompt'] ?? engineContent['instruction'] ?? '',
      if (hint != null && engineContent['hint'] == null) 'hint': hint,
      'estimatedSeconds': widget.level.estimatedSeconds,
      'metadata': {
        ...Map<String, dynamic>.from(
          engineContent['metadata'] as Map? ?? const {},
        ),
        'levelNumber': widget.level.levelNumber,
        'learningObjective': widget.level.learningObjective,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.kind) {
      case EngineBackedGameKind.matching:
        return MatchingScreen(
          rawContent: _rawContent,
          onExit: widget.onExit,
          reducedMotion: widget.reduceMotion,
          onComplete: (result) => _complete(
            score: _scoreFromStars(result.starsEarned),
            attempts: result.attempts,
            hints: 0,
            stars: result.starsEarned,
            metadata: {'engine_id': 'matching', 'content_id': result.contentId},
          ),
        );
      case EngineBackedGameKind.sequence:
        return SequenceScreen(
          rawContent: _rawContent,
          onExit: widget.onExit,
          reducedMotion: widget.reduceMotion,
          onComplete: (result) => _complete(
            score: _scoreFromStars(result.starsEarned),
            attempts: result.attempts,
            hints: 0,
            stars: result.starsEarned,
            metadata: {'engine_id': 'sequence', 'content_id': result.contentId},
          ),
        );
      case EngineBackedGameKind.placement:
        return PlacementScreen(
          rawContent: _rawContent,
          localization: _placementLocalization(widget.locale),
          onExit: widget.onExit,
          reducedMotion: widget.reduceMotion,
          onComplete: (result) => _complete(
            score: result.score,
            attempts: result.attempts,
            hints: result.hintCount,
            stars: result.stars,
            duration: result.duration,
            metadata: {
              'engine_id': result.engineId,
              'content_id': result.contentId,
              'placements': result.placements,
            },
          ),
        );
      case EngineBackedGameKind.multiSelect:
        return MultiSelectScreen(
          rawContent: _rawContent,
          localization: _multiSelectLocalization(widget.locale),
          onExit: widget.onExit,
          reducedMotion: widget.reduceMotion,
          onComplete: (result) => _complete(
            score: result.score,
            attempts: result.attempts,
            hints: result.hintCount,
            stars: result.stars,
            duration: result.duration,
            metadata: result.toJson(),
          ),
        );
    }
  }

  void _complete({
    required int score,
    required int attempts,
    required int hints,
    required int stars,
    required Map<String, Object?> metadata,
    Duration? duration,
  }) {
    if (_completionSent) return;
    _completionSent = true;
    _stopwatch.stop();
    widget.onComplete(
      MiCompletionResult(
        gameId: widget.level.gameId,
        levelId: widget.level.id,
        childProfileId: widget.childProfileId,
        completedAt: DateTime.now(),
        score: score,
        maxScore: 100,
        attemptsUsed: attempts <= 0 ? 1 : attempts,
        hintsUsed: hints,
        duration: duration ?? _stopwatch.elapsed,
        perfectRun: stars >= 3 && hints == 0,
        newSkillsAcquired: skillIdsFor(
          widget.level,
          fallback: const ['logic.memory'],
        ),
        metadata: metadata,
      ),
    );
  }
}

String _ageBandForDifficulty(int difficulty) {
  if (difficulty <= 2) return 'junior';
  if (difficulty <= 4) return 'explorer';
  return 'master';
}

int _scoreFromStars(int stars) {
  if (stars >= 3) return 100;
  if (stars == 2) return 80;
  return 60;
}

PlacementLocalization _placementLocalization(String locale) {
  final en = locale == 'en';
  return PlacementLocalization(
    exitLabel: en ? 'Exit' : 'Thoat',
    pauseLabel: en ? 'Pause' : 'Tam dung',
    resumeLabel: en ? 'Resume' : 'Tiep tuc',
    hintLabel: en ? 'Hint' : 'Goi y',
    retryLabel: en ? 'Try again' : 'Thu lai',
    completionLabel: en ? 'Complete' : 'Hoan thanh',
    invalidPlacementMessage: en ? 'Try another place.' : 'Thu vi tri khac.',
    malformedContentMessage:
        en ? 'This level is not available.' : 'Cap do nay chua san sang.',
    selectedAnnouncement: (label) => en ? '$label selected' : 'Da chon $label',
    targetAnnouncement: (label, occupied, capacity) => en
        ? '$label, $occupied of $capacity'
        : '$label, $occupied tren $capacity',
    removeLabel: en ? 'Remove' : 'Bo ra',
  );
}

MultiSelectLocalization _multiSelectLocalization(String locale) {
  final en = locale == 'en';
  return MultiSelectLocalization(
    exitLabel: en ? 'Exit' : 'Thoat',
    pauseLabel: en ? 'Pause' : 'Tam dung',
    resumeLabel: en ? 'Resume' : 'Tiep tuc',
    submitLabel: en ? 'Submit' : 'Nop bai',
    checkAnswersLabel: en ? 'Check answers' : 'Kiem tra',
    clearLabel: en ? 'Clear' : 'Xoa chon',
    retryLabel: en ? 'Try again' : 'Thu lai',
    completionLabel: en ? 'Complete' : 'Hoan thanh',
    authorHintLabel: en ? 'Hint' : 'Goi y',
    hintLabel: en ? 'Hint' : 'Goi y',
    revealCorrectLabel: en ? 'Reveal one' : 'Mo mot dap an',
    revealAnswersLabel: en ? 'Reveal answers' : 'Mo dap an',
    eliminateIncorrectLabel: en ? 'Remove one' : 'Bo mot dap an sai',
    noMoreHintsLabel: en ? 'No more hints' : 'Het goi y',
    malformedContentMessage:
        en ? 'This level is not available.' : 'Cap do nay chua san sang.',
    incorrectMessage: en ? 'Try again.' : 'Thu lai nhe.',
    correctMessage: en ? 'Nice work.' : 'Lam tot lam.',
    partiallyCorrectMessage: en ? 'Some answers are right.' : 'Co dap an dung.',
    tryAgainMessage: en ? 'Try again.' : 'Thu lai nhe.',
    minimumSelectionRequiredMessage:
        en ? 'Choose a few more answers.' : 'Hay chon them dap an.',
    maximumSelectionReachedMessage:
        en ? 'That is enough choices.' : 'Da du lua chon.',
    selectionCountMessage: (min, max) =>
        en ? 'Choose $min to $max answers.' : 'Chon $min den $max dap an.',
    optionAnnouncement: (label, selected) =>
        en ? '$label, ${selected ? 'selected' : 'not selected'}' : label,
    optionSelectedAnnouncement: (label) =>
        en ? '$label selected' : 'Da chon $label',
    optionDeselectedAnnouncement: (label) =>
        en ? '$label cleared' : 'Bo chon $label',
    correctOptionAnnouncement: (label) =>
        en ? '$label is correct' : '$label dung',
    incorrectOptionAnnouncement: (label) =>
        en ? '$label is not correct' : '$label chua dung',
  );
}
