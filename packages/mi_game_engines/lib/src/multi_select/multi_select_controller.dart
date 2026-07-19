import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'multi_select_content.dart';

enum MultiSelectSelectionStatus {
  accepted,
  unknownOption,
  maximumReached,
  deselectDisabled,
  paused,
  complete,
  eliminated,
}

enum MultiSelectSubmissionStatus {
  accepted,
  belowMinimum,
  aboveMaximum,
  paused,
  complete,
}

enum MultiSelectCompletionState { inProgress, completed, exhausted }

enum MultiSelectFeedbackCode {
  none,
  minimumSelectionRequired,
  maximumSelectionReached,
  deselectDisabled,
  incorrect,
  correct,
  noMoreHints,
}

enum MultiSelectHintKind {
  authorHint,
  revealCorrectOption,
  eliminateOption,
  expectedSelectionCount,
}

class MultiSelectSelectionOutcome extends Equatable {
  const MultiSelectSelectionOutcome(this.status, {this.optionId});

  final MultiSelectSelectionStatus status;
  final String? optionId;
  bool get accepted => status == MultiSelectSelectionStatus.accepted;

  @override
  List<Object?> get props => [status, optionId];
}

class MultiSelectSubmissionOutcome extends Equatable {
  const MultiSelectSubmissionOutcome(this.status, {this.evaluation});

  final MultiSelectSubmissionStatus status;
  final MultiSelectEvaluation? evaluation;
  bool get accepted => status == MultiSelectSubmissionStatus.accepted;

  @override
  List<Object?> get props => [status, evaluation];
}

class MultiSelectHintOutcome extends Equatable {
  const MultiSelectHintOutcome({
    required this.applied,
    this.kind,
    this.message,
  });

  final bool applied;
  final MultiSelectHintKind? kind;
  final String? message;

  @override
  List<Object?> get props => [applied, kind, message];
}

class MultiSelectEvaluation extends Equatable {
  const MultiSelectEvaluation({
    required this.correctlySelectedIds,
    required this.incorrectlySelectedIds,
    required this.missedCorrectIds,
    required this.score,
    required this.exact,
  });

  final Set<String> correctlySelectedIds;
  final Set<String> incorrectlySelectedIds;
  final Set<String> missedCorrectIds;
  final int score;
  final bool exact;

  @override
  List<Object?> get props => [
        correctlySelectedIds,
        incorrectlySelectedIds,
        missedCorrectIds,
        score,
        exact,
      ];
}

class MultiSelectAttempt extends Equatable {
  const MultiSelectAttempt({
    required this.attemptNumber,
    required this.selectedIds,
    required this.evaluation,
  });

  final int attemptNumber;
  final Set<String> selectedIds;
  final MultiSelectEvaluation evaluation;

  @override
  List<Object?> get props => [attemptNumber, selectedIds, evaluation];
}

class MultiSelectState extends Equatable {
  const MultiSelectState({
    required this.selectedOptionIds,
    required this.currentAttempt,
    required this.attemptHistory,
    required this.correctSubmissionCount,
    required this.incorrectSubmissionCount,
    required this.hintCount,
    required this.revealedOptionIds,
    required this.eliminatedOptionIds,
    required this.validationFeedback,
    required this.evaluation,
    required this.completionState,
    required this.score,
    required this.stars,
    required this.elapsedDuration,
    required this.isPaused,
  });

  final Set<String> selectedOptionIds;
  final int currentAttempt;
  final List<MultiSelectAttempt> attemptHistory;
  final int correctSubmissionCount;
  final int incorrectSubmissionCount;
  final int hintCount;
  final Set<String> revealedOptionIds;
  final Set<String> eliminatedOptionIds;
  final MultiSelectFeedbackCode validationFeedback;
  final MultiSelectEvaluation? evaluation;
  final MultiSelectCompletionState completionState;
  final int score;
  final int stars;
  final Duration elapsedDuration;
  final bool isPaused;

  @override
  List<Object?> get props => [
        selectedOptionIds,
        currentAttempt,
        attemptHistory,
        correctSubmissionCount,
        incorrectSubmissionCount,
        hintCount,
        revealedOptionIds,
        eliminatedOptionIds,
        validationFeedback,
        evaluation,
        completionState,
        score,
        stars,
        elapsedDuration,
        isPaused,
      ];
}

class MultiSelectResult extends Equatable {
  const MultiSelectResult({
    required this.engineId,
    required this.contentId,
    required this.attempts,
    required this.correctSubmissionCount,
    required this.incorrectSubmissionCount,
    required this.hintCount,
    required this.score,
    required this.stars,
    required this.duration,
    required this.completed,
    required this.selectedOptionIds,
    required this.correctOptionIds,
    required this.missedCorrectOptionIds,
    required this.incorrectlySelectedOptionIds,
    required this.evaluationMode,
    required this.submissionMode,
  });

  final String engineId;
  final String contentId;
  final int attempts;
  final int correctSubmissionCount;
  final int incorrectSubmissionCount;
  final int hintCount;
  final int score;
  final int stars;
  final Duration duration;
  final bool completed;
  final Set<String> selectedOptionIds;
  Set<String> get selectedIds => selectedOptionIds;
  final Set<String> correctOptionIds;
  Set<String> get correctIds => correctOptionIds;
  final Set<String> missedCorrectOptionIds;
  final Set<String> incorrectlySelectedOptionIds;
  final MultiSelectEvaluationMode evaluationMode;
  final MultiSelectSubmissionMode submissionMode;

  Map<String, Object?> toJson() => {
        'engineId': engineId,
        'contentId': contentId,
        'attempts': attempts,
        'correctSubmissionCount': correctSubmissionCount,
        'incorrectSubmissionCount': incorrectSubmissionCount,
        'hintCount': hintCount,
        'score': score,
        'stars': stars,
        'durationMs': duration.inMilliseconds,
        'completed': completed,
        'selectedOptionIds': selectedOptionIds.toList()..sort(),
        'correctOptionIds': correctOptionIds.toList()..sort(),
        'missedCorrectOptionIds': missedCorrectOptionIds.toList()..sort(),
        'incorrectlySelectedOptionIds': incorrectlySelectedOptionIds.toList()
          ..sort(),
        'evaluationMode': evaluationMode.name,
        'submissionMode': submissionMode.name,
      };

  @override
  List<Object?> get props => [
        engineId,
        contentId,
        attempts,
        correctSubmissionCount,
        incorrectSubmissionCount,
        hintCount,
        score,
        stars,
        duration,
        selectedOptionIds,
        correctOptionIds,
        missedCorrectOptionIds,
        incorrectlySelectedOptionIds,
        evaluationMode,
        submissionMode,
        completed,
      ];
}

class MultiSelectController extends ChangeNotifier {
  MultiSelectController({
    required MultiSelectContent content,
    this.reducedMotion = false,
    this.soundEnabled = true,
    DateTime Function()? clock,
    this.onComplete,
  })  : _content = content,
        _clock = clock ?? DateTime.now {
    _resetForContent(reshuffle: true, preserveSelection: false);
  }

  static const String engineId = 'multi_select';

  MultiSelectContent _content;
  MultiSelectContent get content => _content;

  final bool reducedMotion;
  final bool soundEnabled;
  final DateTime Function() _clock;
  final void Function(MultiSelectResult result)? onComplete;

  late List<MultiSelectOption> _orderedOptions;
  final Set<String> _selectedIds = {};
  final Set<String> _eliminatedIds = {};
  final Set<String> _revealedCorrectIds = {};
  final List<MultiSelectAttempt> _attemptHistory = [];
  int _hintCount = 0;
  int _correctSubmissionCount = 0;
  int _incorrectSubmissionCount = 0;
  int _hintCursor = 0;
  bool _showAuthorHint = false;
  bool _paused = false;
  bool _completionCallbackSent = false;
  bool _isSubmitting = false;
  MultiSelectFeedbackCode _feedback = MultiSelectFeedbackCode.none;
  MultiSelectEvaluation? _lastEvaluation;
  MultiSelectHintKind? _lastHintKind;
  MultiSelectCompletionState _completionState =
      MultiSelectCompletionState.inProgress;
  late DateTime _startedAt;
  DateTime? _completedAt;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pausedAt;

  List<MultiSelectOption> get orderedOptions =>
      List.unmodifiable(_orderedOptions);
  Set<String> get selectedOptionIds => Set.unmodifiable(_selectedIds);
  Set<String> get selectedIds => selectedOptionIds;
  Set<String> get eliminatedOptionIds => Set.unmodifiable(_eliminatedIds);
  Set<String> get eliminatedIds => eliminatedOptionIds;
  Set<String> get revealedOptionIds => Set.unmodifiable(_revealedCorrectIds);
  Set<String> get revealedCorrectIds => revealedOptionIds;
  List<MultiSelectAttempt> get attemptHistory =>
      List.unmodifiable(_attemptHistory);
  int get currentAttempt => _attemptHistory.length + 1;
  int get attempts => _attemptHistory.length;
  int get correctSubmissionCount => _correctSubmissionCount;
  int get incorrectSubmissionCount => _incorrectSubmissionCount;
  int get hintCount => _hintCount;
  bool get showAuthorHint => _showAuthorHint;
  bool get isPaused => _paused;
  bool get isComplete =>
      _completionState != MultiSelectCompletionState.inProgress;
  bool? get lastSubmissionCorrect => _lastEvaluation?.exact;
  MultiSelectHintKind? get lastHintKind => _lastHintKind;
  MultiSelectFeedbackCode get validationFeedback => _feedback;
  MultiSelectEvaluation? get evaluation => _lastEvaluation;
  MultiSelectCompletionState get completionState => _completionState;

  Duration get duration {
    final end = _completedAt ?? (_pausedAt ?? _clock());
    final active = end.difference(_startedAt) - _pausedDuration;
    return active.isNegative ? Duration.zero : active;
  }

  MultiSelectState get state => MultiSelectState(
        selectedOptionIds: selectedOptionIds,
        currentAttempt: currentAttempt,
        attemptHistory: attemptHistory,
        correctSubmissionCount: correctSubmissionCount,
        incorrectSubmissionCount: incorrectSubmissionCount,
        hintCount: hintCount,
        revealedOptionIds: revealedOptionIds,
        eliminatedOptionIds: eliminatedOptionIds,
        validationFeedback: validationFeedback,
        evaluation: evaluation,
        completionState: completionState,
        score: score,
        stars: starsEarned,
        elapsedDuration: duration,
        isPaused: isPaused,
      );

  bool isSelected(String optionId) => _selectedIds.contains(optionId);
  bool isEliminated(String optionId) => _eliminatedIds.contains(optionId);

  MultiSelectSelectionOutcome selectOption(String optionId) {
    if (_paused) return _rejectSelection(MultiSelectSelectionStatus.paused);
    if (isComplete)
      return _rejectSelection(MultiSelectSelectionStatus.complete);
    if (!_validOptionIds.contains(optionId)) {
      return _rejectSelection(
        MultiSelectSelectionStatus.unknownOption,
        optionId: optionId,
      );
    }
    if (_eliminatedIds.contains(optionId)) {
      return _rejectSelection(
        MultiSelectSelectionStatus.eliminated,
        optionId: optionId,
      );
    }
    if (_selectedIds.contains(optionId)) {
      return const MultiSelectSelectionOutcome(
        MultiSelectSelectionStatus.accepted,
      );
    }
    if (_selectedIds.length >= _content.configuration.maximumSelections) {
      _feedback = MultiSelectFeedbackCode.maximumSelectionReached;
      notifyListeners();
      return MultiSelectSelectionOutcome(
        MultiSelectSelectionStatus.maximumReached,
        optionId: optionId,
      );
    }
    _selectedIds.add(optionId);
    _feedback = MultiSelectFeedbackCode.none;
    notifyListeners();
    _maybeAutoSubmit();
    return const MultiSelectSelectionOutcome(
      MultiSelectSelectionStatus.accepted,
    );
  }

  MultiSelectSelectionOutcome deselectOption(String optionId) {
    if (_paused) return _rejectSelection(MultiSelectSelectionStatus.paused);
    if (isComplete)
      return _rejectSelection(MultiSelectSelectionStatus.complete);
    if (!_validOptionIds.contains(optionId)) {
      return _rejectSelection(
        MultiSelectSelectionStatus.unknownOption,
        optionId: optionId,
      );
    }
    if (!_selectedIds.contains(optionId)) {
      return const MultiSelectSelectionOutcome(
        MultiSelectSelectionStatus.accepted,
      );
    }
    if (!_content.configuration.allowDeselect) {
      _feedback = MultiSelectFeedbackCode.deselectDisabled;
      notifyListeners();
      return MultiSelectSelectionOutcome(
        MultiSelectSelectionStatus.deselectDisabled,
        optionId: optionId,
      );
    }
    _selectedIds.remove(optionId);
    _feedback = MultiSelectFeedbackCode.none;
    notifyListeners();
    return const MultiSelectSelectionOutcome(
      MultiSelectSelectionStatus.accepted,
    );
  }

  MultiSelectSelectionOutcome toggleOption(String optionId) =>
      _selectedIds.contains(optionId)
          ? deselectOption(optionId)
          : selectOption(optionId);

  void toggle(String optionId) => toggleOption(optionId);
  void select(String optionId) => selectOption(optionId);
  void deselect(String optionId) => deselectOption(optionId);

  void clearSelection() {
    if (_paused || isComplete || !content.configuration.allowDeselect) return;
    if (_selectedIds.isEmpty) return;
    _selectedIds.clear();
    _feedback = MultiSelectFeedbackCode.none;
    notifyListeners();
  }

  void clear() => clearSelection();

  MultiSelectSubmissionOutcome submit() {
    if (_paused) {
      return const MultiSelectSubmissionOutcome(
        MultiSelectSubmissionStatus.paused,
      );
    }
    if (isComplete) {
      return const MultiSelectSubmissionOutcome(
        MultiSelectSubmissionStatus.complete,
      );
    }
    if (_isSubmitting) {
      return const MultiSelectSubmissionOutcome(
        MultiSelectSubmissionStatus.complete,
      );
    }
    final count = _selectedIds.length;
    final config = _content.configuration;
    if (count < config.minimumSelections) {
      _feedback = MultiSelectFeedbackCode.minimumSelectionRequired;
      notifyListeners();
      return const MultiSelectSubmissionOutcome(
        MultiSelectSubmissionStatus.belowMinimum,
      );
    }
    if (count > config.maximumSelections) {
      _feedback = MultiSelectFeedbackCode.maximumSelectionReached;
      notifyListeners();
      return const MultiSelectSubmissionOutcome(
        MultiSelectSubmissionStatus.aboveMaximum,
      );
    }

    _isSubmitting = true;
    final evaluation = _evaluate();
    _lastEvaluation = evaluation;
    _attemptHistory.add(
      MultiSelectAttempt(
        attemptNumber: _attemptHistory.length + 1,
        selectedIds: selectedOptionIds,
        evaluation: evaluation,
      ),
    );
    if (evaluation.exact) {
      _correctSubmissionCount++;
      _feedback = MultiSelectFeedbackCode.correct;
    } else {
      _incorrectSubmissionCount++;
      _feedback = MultiSelectFeedbackCode.incorrect;
    }

    final terminal = evaluation.exact ||
        config.evaluationMode == MultiSelectEvaluationMode.partialCredit ||
        attempts >= config.maxAttempts ||
        !config.allowRetry;
    if (terminal) {
      _complete(
        evaluation.exact
            ? MultiSelectCompletionState.completed
            : MultiSelectCompletionState.exhausted,
      );
    }
    _isSubmitting = false;
    notifyListeners();
    return MultiSelectSubmissionOutcome(
      MultiSelectSubmissionStatus.accepted,
      evaluation: evaluation,
    );
  }

  MultiSelectHintOutcome requestHint() {
    if (_paused || isComplete) {
      return const MultiSelectHintOutcome(applied: false);
    }
    for (var i = 0; i < _content.configuration.hintModes.length; i++) {
      final mode = _content.configuration.hintModes[
          (_hintCursor + i) % _content.configuration.hintModes.length];
      final outcome = _applyHint(mode);
      if (outcome.applied) {
        _hintCursor =
            (_hintCursor + i + 1) % _content.configuration.hintModes.length;
        notifyListeners();
        return outcome;
      }
    }
    _feedback = MultiSelectFeedbackCode.noMoreHints;
    notifyListeners();
    return const MultiSelectHintOutcome(applied: false);
  }

  void requestAuthorHint() {
    _applyHint(MultiSelectHintMode.authoredHint);
    notifyListeners();
  }

  void dismissAuthorHint() {
    _showAuthorHint = false;
    notifyListeners();
  }

  void revealCorrectOption() {
    _applyHint(MultiSelectHintMode.revealCorrectOption);
    notifyListeners();
  }

  void revealCorrectAnswers() {
    if (!_content.configuration.revealCorrectAnswers) return;
    _revealedCorrectIds.addAll(_content.correctIds);
    notifyListeners();
  }

  void eliminateIncorrectOption() {
    _applyHint(MultiSelectHintMode.eliminateIncorrectOption);
    notifyListeners();
  }

  void retry() {
    if (!_content.configuration.allowRetry) return;
    final preserve = _content.configuration.retryMode ==
        MultiSelectRetryMode.preserveSelection;
    _completionState = MultiSelectCompletionState.inProgress;
    _completedAt = null;
    _completionCallbackSent = false;
    _showAuthorHint = false;
    _feedback = MultiSelectFeedbackCode.none;
    if (!preserve) {
      _selectedIds.clear();
    }
    notifyListeners();
  }

  void reset() {
    _resetForContent(reshuffle: false, preserveSelection: false);
    notifyListeners();
  }

  void restart() {
    _resetForContent(reshuffle: true, preserveSelection: false);
    notifyListeners();
  }

  void pause() {
    if (_paused || isComplete) return;
    _paused = true;
    _pausedAt = _clock();
    notifyListeners();
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    final pausedAt = _pausedAt;
    if (pausedAt != null) {
      _pausedDuration += _clock().difference(pausedAt);
    }
    _pausedAt = null;
    notifyListeners();
  }

  void complete() {
    if (isComplete) return;
    if (_content.configuration.evaluationMode ==
            MultiSelectEvaluationMode.exactMatch &&
        setEquals(_selectedIds, _content.correctIds)) {
      submit();
    }
  }

  int get score {
    if (_attemptHistory.isEmpty) return 0;
    return _attemptHistory
        .map((attempt) => attempt.evaluation.score)
        .reduce((best, value) => value > best ? value : best);
  }

  int get starsEarned {
    if (!isComplete) return 0;
    final s = score;
    if (s >= 90) return 3;
    if (s >= 60) return 2;
    if (s > 0) return 1;
    return 0;
  }

  MultiSelectResult get result {
    final eval = _lastEvaluation ?? _evaluate();
    return MultiSelectResult(
      engineId: engineId,
      contentId: _content.contentId,
      attempts: attempts,
      correctSubmissionCount: correctSubmissionCount,
      incorrectSubmissionCount: incorrectSubmissionCount,
      hintCount: hintCount,
      score: score,
      stars: starsEarned,
      duration: duration,
      completed: isComplete,
      selectedOptionIds: selectedOptionIds,
      correctOptionIds: _content.correctIds,
      missedCorrectOptionIds: eval.missedCorrectIds,
      incorrectlySelectedOptionIds: eval.incorrectlySelectedIds,
      evaluationMode: _content.configuration.evaluationMode,
      submissionMode: _content.configuration.submissionMode,
    );
  }

  void loadContent(MultiSelectContent content) {
    _content = content;
    _resetForContent(reshuffle: true, preserveSelection: false);
    notifyListeners();
  }

  MultiSelectEvaluation _evaluate() {
    final correctIds = _content.correctIds;
    final correctlySelected = _selectedIds.intersection(correctIds);
    final incorrectlySelected = _selectedIds.difference(correctIds);
    final missedCorrect = correctIds.difference(_selectedIds);
    final exact = setEquals(_selectedIds, correctIds);
    final config = _content.configuration;
    final baseScore =
        config.evaluationMode == MultiSelectEvaluationMode.exactMatch
            ? (exact ? 100 : 0)
            : _partialScore(
                correctlySelected.length,
                incorrectlySelected.length,
                correctIds.length,
              );
    final penalty =
        (attempts * config.attemptPenalty) + (_hintCount * config.hintPenalty);
    final score = (baseScore - penalty).clamp(0, 100);
    return MultiSelectEvaluation(
      correctlySelectedIds: correctlySelected,
      incorrectlySelectedIds: incorrectlySelected,
      missedCorrectIds: missedCorrect,
      score: score,
      exact: exact,
    );
  }

  int _partialScore(
    int correctSelected,
    int incorrectSelected,
    int totalCorrect,
  ) {
    if (totalCorrect == 0) return 0;
    final totalIncorrect = _content.options.length - totalCorrect;
    final correctRatio = correctSelected / totalCorrect;
    final incorrectRatio =
        totalIncorrect == 0 ? 0 : incorrectSelected / totalIncorrect;
    final rawAccuracy = correctRatio -
        (incorrectRatio * _content.configuration.incorrectSelectionPenalty);
    final normalizedAccuracy = rawAccuracy.clamp(0.0, 1.0);
    return (normalizedAccuracy * 100).round();
  }

  MultiSelectHintOutcome _applyHint(MultiSelectHintMode mode) {
    switch (mode) {
      case MultiSelectHintMode.expectedSelectionCount:
        _hintCount++;
        _lastHintKind = MultiSelectHintKind.expectedSelectionCount;
        return const MultiSelectHintOutcome(
          applied: true,
          kind: MultiSelectHintKind.expectedSelectionCount,
        );
      case MultiSelectHintMode.authoredHint:
        if (_content.hint == null || _showAuthorHint) {
          return const MultiSelectHintOutcome(applied: false);
        }
        _hintCount++;
        _showAuthorHint = true;
        _lastHintKind = MultiSelectHintKind.authorHint;
        return const MultiSelectHintOutcome(
          applied: true,
          kind: MultiSelectHintKind.authorHint,
        );
      case MultiSelectHintMode.revealCorrectOption:
        final remaining = _content.correctIds
            .difference(_revealedCorrectIds)
            .difference(_selectedIds);
        if (remaining.isEmpty)
          return const MultiSelectHintOutcome(applied: false);
        _hintCount++;
        _revealedCorrectIds.add(_orderedRemaining(remaining).first);
        _lastHintKind = MultiSelectHintKind.revealCorrectOption;
        return const MultiSelectHintOutcome(
          applied: true,
          kind: MultiSelectHintKind.revealCorrectOption,
        );
      case MultiSelectHintMode.eliminateIncorrectOption:
        final remaining = _content.options
            .where(
              (option) =>
                  !option.isCorrect &&
                  !_eliminatedIds.contains(option.id) &&
                  !_selectedIds.contains(option.id),
            )
            .map((option) => option.id)
            .toSet();
        if (remaining.isEmpty)
          return const MultiSelectHintOutcome(applied: false);
        _hintCount++;
        _eliminatedIds.add(_orderedRemaining(remaining).first);
        _lastHintKind = MultiSelectHintKind.eliminateOption;
        return const MultiSelectHintOutcome(
          applied: true,
          kind: MultiSelectHintKind.eliminateOption,
        );
    }
  }

  void _maybeAutoSubmit() {
    final config = _content.configuration;
    if (config.submissionMode != MultiSelectSubmissionMode.autoSubmit) return;
    if (_selectedIds.length == config.autoSubmitSelectionCount &&
        !_isSubmitting &&
        !isComplete) {
      submit();
    }
  }

  void _complete(MultiSelectCompletionState state) {
    _completionState = state;
    _completedAt = _clock();
    if (state == MultiSelectCompletionState.exhausted &&
        _content.configuration.revealCorrectAnswers) {
      _revealedCorrectIds.addAll(_content.correctIds);
    }
    if (!_completionCallbackSent) {
      _completionCallbackSent = true;
      onComplete?.call(result);
    }
  }

  MultiSelectSelectionOutcome _rejectSelection(
    MultiSelectSelectionStatus status, {
    String? optionId,
  }) {
    return MultiSelectSelectionOutcome(status, optionId: optionId);
  }

  Set<String> get _validOptionIds => _content.options.map((o) => o.id).toSet();

  List<String> _orderedRemaining(Set<String> ids) => [
        for (final option in _orderedOptions)
          if (ids.contains(option.id)) option.id,
      ];

  void _resetForContent({
    required bool reshuffle,
    required bool preserveSelection,
  }) {
    if (reshuffle || !_isInitialized) {
      _orderedOptions = List.of(_content.options);
      if (_content.configuration.shuffleOptions) {
        final seed = _content.configuration.shuffleSeed ??
            _stableSeed(_content.contentId);
        _orderedOptions.shuffleSeeded(_DeterministicRandom(seed));
      }
    }
    if (!preserveSelection) {
      _selectedIds.clear();
    }
    _eliminatedIds.clear();
    _revealedCorrectIds.clear();
    _attemptHistory.clear();
    _hintCount = 0;
    _correctSubmissionCount = 0;
    _incorrectSubmissionCount = 0;
    _hintCursor = 0;
    _showAuthorHint = false;
    _paused = false;
    _completionCallbackSent = false;
    _isSubmitting = false;
    _feedback = MultiSelectFeedbackCode.none;
    _lastEvaluation = null;
    _lastHintKind = null;
    _completionState = MultiSelectCompletionState.inProgress;
    _startedAt = _clock();
    _completedAt = null;
    _pausedDuration = Duration.zero;
    _pausedAt = null;
    _isInitialized = true;
  }

  bool _isInitialized = false;
}

int _stableSeed(String value) {
  var hash = 0;
  for (final unit in value.codeUnits) {
    hash = ((hash * 31) + unit) & 0x7fffffff;
  }
  return hash;
}

class _DeterministicRandom {
  _DeterministicRandom(int seed) : _state = seed & 0x7fffffff;
  int _state;

  int nextInt(int max) {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state % max;
  }
}

extension on List<MultiSelectOption> {
  void shuffleSeeded(_DeterministicRandom random) {
    for (var i = length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final tmp = this[i];
      this[i] = this[j];
      this[j] = tmp;
    }
  }
}
