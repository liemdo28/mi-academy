import 'package:flutter/material.dart';
import 'package:mi_game_core/mi_game_core.dart';
import 'package:mi_game_engines/mi_game_engines.dart';
import 'package:localization/localization.dart';

import '../level_skill_ids.dart';
import '../snapshot_lifecycle_mixin.dart';

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
    this.initialSnapshot,
    this.onSaveSnapshot,
    this.reduceMotion = false,
  });

  final EngineBackedGameKind kind;
  final MiLevel level;
  final VoidCallback onExit;
  final void Function(MiCompletionResult) onComplete;
  final String childProfileId;
  final String locale;
  final MiGameSnapshot? initialSnapshot;
  final void Function(MiGameSnapshot)? onSaveSnapshot;
  final bool reduceMotion;

  @override
  State<EngineBackedGameScreen> createState() => _EngineBackedGameScreenState();
}

class _EngineBackedGameScreenState extends State<EngineBackedGameScreen>
    with
        WidgetsBindingObserver,
        SnapshotLifecycleMixin<EngineBackedGameScreen> {
  late final Stopwatch _stopwatch;
  bool _completionSent = false;
  Map<String, dynamic>? _latestEngineState;
  int _attempts = 0;
  int _itemsCompleted = 0;
  int _totalItems = 0;
  int _hints = 0;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
  }

  @override
  void dispose() {
    disposeSnapshotLifecycle();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  void Function(MiGameSnapshot)? get onSaveSnapshot => widget.onSaveSnapshot;

  @override
  MiGameSnapshot? captureSnapshot() {
    if (_completionSent || _latestEngineState == null) return null;
    if (_attempts == 0 && _itemsCompleted == 0 && _hints == 0) return null;
    return MiGameSnapshot(
      gameId: widget.level.gameId,
      levelId: widget.level.id,
      childProfileId: widget.childProfileId,
      state: {
        'engineKind': widget.kind.name,
        'engineState': _latestEngineState,
      },
      createdAt: DateTime.now(),
      attemptsUsed: _attempts,
      hintsUsed: _hints,
      itemsCompleted: _itemsCompleted,
      totalItems: _totalItems,
      metadata: {'engine_id': widget.kind.name},
    );
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
          locale: widget.locale,
          initialState: _initialEngineState(),
          onSaveState: (state) => _rememberState(
            state,
            attempts: state['attempts'] as int? ?? 0,
            itemsCompleted: (state['matchedLeftIds'] as List?)?.length ?? 0,
            totalItems: (state['totalPairCount'] as int?) ??
                ((state['matchedLeftIds'] as List?)?.length ?? 0),
          ),
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
          locale: widget.locale,
          initialState: _initialEngineState(),
          onSaveState: (state) => _rememberState(
            state,
            attempts: state['attempts'] as int? ?? 0,
            itemsCompleted: state['attempts'] as int? ?? 0,
            totalItems: 1,
          ),
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
          initialState: _initialEngineState(),
          onSaveState: (state) => _rememberState(
            state,
            attempts: state['attempts'] as int? ?? 0,
            itemsCompleted: (state['placements'] as Map?)?.length ?? 0,
            totalItems: (_rawContent['items'] as List?)?.length ?? 0,
            hints: state['hintCount'] as int? ?? 0,
          ),
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
          initialState: _initialEngineState(),
          onSaveState: (state) => _rememberState(
            state,
            attempts: state['attempts'] as int? ?? 0,
            itemsCompleted: (state['selectedIds'] as List?)?.length ?? 0,
            totalItems: (_rawContent['options'] as List?)?.length ?? 0,
            hints: state['hintCount'] as int? ?? 0,
          ),
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

  Map<String, dynamic>? _initialEngineState() {
    final snapshot = widget.initialSnapshot;
    if (snapshot == null) return null;
    if (!snapshot.canRestoreFor(
      childProfileId: widget.childProfileId,
      gameId: widget.level.gameId,
      levelId: widget.level.id,
    )) {
      return null;
    }
    if (snapshot.state['engineKind'] != widget.kind.name) return null;
    final engineState = snapshot.state['engineState'];
    if (engineState is Map) {
      return Map<String, dynamic>.from(engineState);
    }
    return null;
  }

  void _rememberState(
    Map<String, dynamic> state, {
    required int attempts,
    required int itemsCompleted,
    required int totalItems,
    int hints = 0,
  }) {
    _latestEngineState = Map<String, dynamic>.from(state);
    _attempts = attempts;
    _itemsCompleted = itemsCompleted;
    _totalItems = totalItems;
    _hints = hints;
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
    exitLabel: en ? 'Exit' : MiMobileStrings.m172,
    pauseLabel: en ? 'Pause' : MiMobileStrings.m173,
    resumeLabel: en ? 'Resume' : MiMobileStrings.m174,
    hintLabel: en ? 'Hint' : MiMobileStrings.m175,
    retryLabel: en ? 'Try again' : MiMobileStrings.m176,
    completionLabel: en ? 'Complete' : MiMobileStrings.m177,
    invalidPlacementMessage: en ? 'Try another place.' : MiMobileStrings.m178,
    malformedContentMessage:
        en ? 'This level is not available.' : MiMobileStrings.m179,
    selectedAnnouncement: (label) =>
        en ? '$label selected' : MiMobileStrings.text('m180', {'p0': label}),
    targetAnnouncement: (label, occupied, capacity) => en
        ? '$label, $occupied of $capacity'
        : MiMobileStrings.text(
            'm181', {'p0': label, 'p1': occupied, 'p2': capacity}),
    removeLabel: en ? 'Remove' : MiMobileStrings.m182,
  );
}

MultiSelectLocalization _multiSelectLocalization(String locale) {
  final en = locale == 'en';
  return MultiSelectLocalization(
    exitLabel: en ? 'Exit' : MiMobileStrings.m172,
    pauseLabel: en ? 'Pause' : MiMobileStrings.m173,
    resumeLabel: en ? 'Resume' : MiMobileStrings.m174,
    submitLabel: en ? 'Submit' : MiMobileStrings.m183,
    checkAnswersLabel: en ? 'Check answers' : MiMobileStrings.m184,
    clearLabel: en ? 'Clear' : MiMobileStrings.m185,
    retryLabel: en ? 'Try again' : MiMobileStrings.m176,
    completionLabel: en ? 'Complete' : MiMobileStrings.m177,
    authorHintLabel: en ? 'Hint' : MiMobileStrings.m175,
    hintLabel: en ? 'Hint' : MiMobileStrings.m175,
    revealCorrectLabel: en ? 'Reveal one' : MiMobileStrings.m186,
    revealAnswersLabel: en ? 'Reveal answers' : MiMobileStrings.m187,
    eliminateIncorrectLabel: en ? 'Remove one' : MiMobileStrings.m188,
    noMoreHintsLabel: en ? 'No more hints' : MiMobileStrings.m189,
    malformedContentMessage:
        en ? 'This level is not available.' : MiMobileStrings.m179,
    incorrectMessage: en ? 'Try again.' : MiMobileStrings.m190,
    correctMessage: en ? 'Nice work.' : MiMobileStrings.m191,
    partiallyCorrectMessage:
        en ? 'Some answers are right.' : MiMobileStrings.m192,
    tryAgainMessage: en ? 'Try again.' : MiMobileStrings.m190,
    minimumSelectionRequiredMessage:
        en ? 'Choose a few more answers.' : MiMobileStrings.m193,
    maximumSelectionReachedMessage:
        en ? 'That is enough choices.' : MiMobileStrings.m194,
    selectionCountMessage: (min, max) => en
        ? 'Choose $min to $max answers.'
        : MiMobileStrings.text('m195', {'p0': min, 'p1': max}),
    optionAnnouncement: (label, selected) =>
        en ? '$label, ${selected ? 'selected' : 'not selected'}' : label,
    optionSelectedAnnouncement: (label) =>
        en ? '$label selected' : MiMobileStrings.text('m180', {'p0': label}),
    optionDeselectedAnnouncement: (label) =>
        en ? '$label cleared' : MiMobileStrings.text('m196', {'p0': label}),
    correctOptionAnnouncement: (label) =>
        en ? '$label is correct' : MiMobileStrings.text('m197', {'p0': label}),
    incorrectOptionAnnouncement: (label) => en
        ? '$label is not correct'
        : MiMobileStrings.text('m198', {'p0': label}),
  );
}
