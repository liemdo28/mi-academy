import 'package:flutter/foundation.dart';

import 'multi_select_content.dart';

/// Which assistive action a hint call performed -- exposed so the
/// renderer can show the right feedback for whichever hint was used.
enum MultiSelectHintKind { authorHint, revealCorrectOption, eliminateOption }

/// Normalized, engine-agnostic result shape -- the "common engine
/// contract" result, matching the shape already established by
/// PlacementResult (see placement_controller.dart). A plain immutable
/// data class with no dependency on child-profile storage, Hive, or any
/// backend API.
class MultiSelectResult {
  const MultiSelectResult({
    required this.engineId,
    required this.contentId,
    required this.score,
    required this.stars,
    required this.attempts,
    required this.duration,
    required this.selectedIds,
    required this.correctIds,
    required this.hintCount,
    required this.completed,
  });

  final String engineId;
  final String contentId;
  final int score;
  final int stars;
  final int attempts;
  final Duration duration;
  final Set<String> selectedIds;
  final Set<String> correctIds;
  final int hintCount;
  final bool completed;

  @override
  bool operator ==(Object other) =>
      other is MultiSelectResult &&
      other.engineId == engineId &&
      other.contentId == contentId &&
      other.score == score &&
      other.stars == stars &&
      other.attempts == attempts &&
      other.duration == duration &&
      setEquals(other.selectedIds, selectedIds) &&
      setEquals(other.correctIds, correctIds) &&
      other.hintCount == hintCount &&
      other.completed == completed;

  @override
  int get hashCode => Object.hash(
        engineId,
        contentId,
        score,
        stars,
        attempts,
        duration,
        Object.hashAllUnordered(selectedIds),
        Object.hashAllUnordered(correctIds),
        hintCount,
        completed,
      );
}

/// Drives one Multi-select Engine level: selection state, submit
/// (explicit or automatic), exact-match/partial-credit evaluation,
/// hints (author hint, reveal-correct, eliminate-incorrect), pause/
/// resume, and completion -- the fourth Milestone 1 shared engine
/// controller, alongside MatchingController, SequenceController, and
/// PlacementController. A plain [ChangeNotifier], no dependency on any
/// state-management framework or child-profile repository, and it never
/// writes to storage/analytics/backends itself -- see [onComplete].
class MultiSelectController extends ChangeNotifier {
  MultiSelectController({
    required MultiSelectContent content,
    this.reducedMotion = false,
    this.soundEnabled = true,
    DateTime Function()? clock,
    this.onComplete,
  })  : _content = content,
        _clock = clock ?? DateTime.now {
    _resetForContent(preserveSelection: false);
  }

  static const String engineId = 'multi_select';

  MultiSelectContent _content;
  MultiSelectContent get content => _content;

  final bool reducedMotion;
  final bool soundEnabled;
  final DateTime Function() _clock;

  /// Invoked exactly once, the moment the level is completed. The engine
  /// itself never persists this -- the host decides what to do with it.
  final void Function(MultiSelectResult result)? onComplete;

  final Set<String> _selectedIds = {};
  final Set<String> _eliminatedIds = {};
  final Set<String> _revealedCorrectIds = {};
  int _attempts = 0;
  int _hintCount = 0;
  bool _showAuthorHint = false;
  bool _paused = false;
  bool _isComplete = false;
  bool? _lastSubmissionCorrect;
  MultiSelectHintKind? _lastHintKind;
  late DateTime _startedAt;
  DateTime? _completedAt;

  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  Set<String> get eliminatedIds => Set.unmodifiable(_eliminatedIds);
  Set<String> get revealedCorrectIds => Set.unmodifiable(_revealedCorrectIds);
  int get attempts => _attempts;
  int get hintCount => _hintCount;
  bool get showAuthorHint => _showAuthorHint;
  bool get isPaused => _paused;
  bool get isComplete => _isComplete;
  bool? get lastSubmissionCorrect => _lastSubmissionCorrect;
  MultiSelectHintKind? get lastHintKind => _lastHintKind;

  Duration get duration => (_completedAt ?? _clock()).difference(_startedAt);

  bool isSelected(String optionId) => _selectedIds.contains(optionId);
  bool isEliminated(String optionId) => _eliminatedIds.contains(optionId);

  /// Toggles [optionId]'s selection. A no-op for an eliminated option
  /// (the child already ruled it out via a hint) or while paused/complete.
  void toggle(String optionId) {
    if (_paused || _isComplete || _eliminatedIds.contains(optionId)) return;
    if (_selectedIds.contains(optionId)) {
      _selectedIds.remove(optionId);
    } else {
      if (_selectedIds.length >= _content.configuration.maxSelections) return;
      _selectedIds.add(optionId);
    }
    notifyListeners();
    _maybeAutoSubmit();
  }

  void select(String optionId) {
    if (_selectedIds.contains(optionId)) return;
    toggle(optionId);
  }

  void deselect(String optionId) {
    if (!_selectedIds.contains(optionId)) return;
    toggle(optionId);
  }

  void clear() {
    if (_paused || _isComplete) return;
    if (_selectedIds.isEmpty) return;
    _selectedIds.clear();
    notifyListeners();
  }

  void _maybeAutoSubmit() {
    if (_content.configuration.submitMode != MultiSelectSubmitMode.autoSubmit) {
      return;
    }
    if (_selectedIds.length == _content.configuration.expectedAnswerCount) {
      submit();
    }
  }

  /// Explicit (or auto-triggered) submission. Validates the selection
  /// size is within the configured range before counting it as a real
  /// attempt -- a too-small/too-large selection is simply not
  /// submittable, not a wasted attempt.
  void submit() {
    if (_paused || _isComplete) return;
    final count = _selectedIds.length;
    final config = _content.configuration;
    if (count < config.minSelections || count > config.maxSelections) return;

    _attempts++;
    final correctIds = _content.correctIds;

    if (config.evaluationMode == MultiSelectEvaluationMode.exactMatch) {
      final isExact = setEquals(_selectedIds, correctIds);
      _lastSubmissionCorrect = isExact;
      if (isExact) {
        _isComplete = true;
        _completedAt = _clock();
        onComplete?.call(result);
      }
    } else {
      // partialCredit: any valid-size submission completes the level.
      _lastSubmissionCorrect = setEquals(_selectedIds, correctIds);
      _isComplete = true;
      _completedAt = _clock();
      onComplete?.call(result);
    }
    notifyListeners();
  }

  /// Reveals the textual author-authored hint, if any.
  void requestAuthorHint() {
    if (_content.hint == null) return;
    _hintCount++;
    _showAuthorHint = true;
    _lastHintKind = MultiSelectHintKind.authorHint;
    notifyListeners();
  }

  void dismissAuthorHint() {
    _showAuthorHint = false;
    notifyListeners();
  }

  /// Reveals one not-yet-revealed correct option (a green "this one's
  /// right" nudge) without selecting it for the child.
  void revealCorrectOption() {
    final remaining = _content.correctIds.difference(_revealedCorrectIds);
    if (remaining.isEmpty) return;
    _hintCount++;
    _revealedCorrectIds.add(remaining.first);
    _lastHintKind = MultiSelectHintKind.revealCorrectOption;
    notifyListeners();
  }

  /// Eliminates one incorrect, not-yet-selected, not-yet-eliminated
  /// option (narrows the field, classic assistive elimination).
  void eliminateIncorrectOption() {
    final incorrect = _content.options
        .where((o) =>
            !o.isCorrect &&
            !_eliminatedIds.contains(o.id) &&
            !_selectedIds.contains(o.id))
        .toList();
    if (incorrect.isEmpty) return;
    _hintCount++;
    _eliminatedIds.add(incorrect.first.id);
    _lastHintKind = MultiSelectHintKind.eliminateOption;
    notifyListeners();
  }

  void pause() {
    _paused = true;
    notifyListeners();
  }

  void resume() {
    _paused = false;
    notifyListeners();
  }

  /// Clears progress; whether the current selection survives depends on
  /// [MultiSelectConfiguration.retryMode].
  void retry() {
    final preserve = _content.configuration.retryMode ==
        MultiSelectRetryMode.preserveSelection;
    _resetForContent(preserveSelection: preserve);
    notifyListeners();
  }

  /// A full fresh start -- always clears the selection, regardless of
  /// [MultiSelectConfiguration.retryMode].
  void restart() {
    _resetForContent(preserveSelection: false);
    notifyListeners();
  }

  /// Idempotent, explicit completion check -- exposed for API parity
  /// with the other engines' `complete()`. Multi-select's real
  /// completion happens inside [submit]; this only re-fires the
  /// callback-safe check if somehow not yet marked complete despite an
  /// exact-match selection already being present (defensive, not
  /// expected in normal flow).
  void complete() {
    if (_isComplete) return;
    if (_content.configuration.evaluationMode ==
            MultiSelectEvaluationMode.exactMatch &&
        setEquals(_selectedIds, _content.correctIds)) {
      submit();
    }
  }

  int get score {
    final config = _content.configuration;
    if (config.evaluationMode == MultiSelectEvaluationMode.exactMatch) {
      if (!_isComplete) return 0;
      final penalty = ((_attempts - 1) * 10) + (_hintCount * 5);
      final raw = 100 - penalty;
      return raw < 0 ? 0 : raw;
    }
    // partialCredit: proportional to net-correct selections.
    final correctIds = _content.correctIds;
    final correctSelected = _selectedIds.intersection(correctIds).length;
    final incorrectSelected = _selectedIds.difference(correctIds).length;
    final totalCorrect = correctIds.length;
    if (totalCorrect == 0) return 0;
    final net = correctSelected - incorrectSelected;
    final raw = ((net / totalCorrect) * 100).round() - (_hintCount * 5);
    return raw < 0 ? 0 : (raw > 100 ? 100 : raw);
  }

  /// Deterministic 0-3 stars derived from [score] once complete -- the
  /// same score-to-stars mapping for both evaluation modes, so the
  /// child-facing meaning of "3 stars" doesn't silently differ by mode.
  int get starsEarned {
    if (!_isComplete) return 0;
    final s = score;
    if (s >= 90) return 3;
    if (s >= 60) return 2;
    if (s > 0) return 1;
    return 0;
  }

  MultiSelectResult get result => MultiSelectResult(
        engineId: engineId,
        contentId: _content.contentId,
        score: score,
        stars: starsEarned,
        attempts: _attempts,
        duration: duration,
        selectedIds: selectedIds,
        correctIds: _content.correctIds,
        hintCount: _hintCount,
        completed: _isComplete,
      );

  void loadContent(MultiSelectContent content) {
    _content = content;
    _resetForContent(preserveSelection: false);
    notifyListeners();
  }

  void _resetForContent({required bool preserveSelection}) {
    if (!preserveSelection) {
      _selectedIds.clear();
    }
    _eliminatedIds.clear();
    _revealedCorrectIds.clear();
    _attempts = 0;
    _hintCount = 0;
    _showAuthorHint = false;
    _paused = false;
    _isComplete = false;
    _lastSubmissionCorrect = null;
    _lastHintKind = null;
    _startedAt = _clock();
    _completedAt = null;
  }
}
