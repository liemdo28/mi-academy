import 'package:flutter/foundation.dart';

import 'sequence_content.dart';

/// Drives one Sequence Engine level: current arrangement, selection state
/// (for missing-item mode), attempt counting, scoring, hints, pause/
/// resume, retry. No dependency on any state-management framework or
/// child-profile repository.
class SequenceController extends ChangeNotifier {
  /// Stable identifier for this engine, used by the shared engine
  /// contract test suite (test/engine_contract_test.dart) to verify
  /// every engine reports a consistent identity alongside its result.
  static const String engineId = 'sequence';

  SequenceController({
    required SequenceContent content,
    this.reducedMotion = false,
    this.soundEnabled = true,
  }) : _content = content {
    _resetForContent();
  }

  SequenceContent _content;
  SequenceContent get content => _content;

  final bool reducedMotion;
  final bool soundEnabled;

  late List<SequenceItem> _arrangement; // reorder mode's working order
  late Map<int, String?> _missingSelections; // missingItem mode
  int _attempts = 0;
  bool _showHint = false;
  bool _paused = false;
  bool _isComplete = false;
  bool? _lastSubmissionCorrect;

  List<SequenceItem> get arrangement => List.unmodifiable(_arrangement);
  Map<int, String?> get missingSelections =>
      Map.unmodifiable(_missingSelections);
  int get attempts => _attempts;
  bool get showHint => _showHint;
  bool get isPaused => _paused;
  bool get isComplete => _isComplete;
  bool? get lastSubmissionCorrect => _lastSubmissionCorrect;

  int get starsEarned {
    if (!_isComplete) return 0;
    if (_attempts <= 1) return 3;
    if (_attempts <= 2) return 2;
    return 1;
  }

  /// Reorder mode: swap the items at [from]/[to] in the working
  /// arrangement (drag reorder and tap-then-move both resolve to this).
  void moveItem(int from, int to) {
    if (_paused || _isComplete) return;
    if (from < 0 ||
        from >= _arrangement.length ||
        to < 0 ||
        to >= _arrangement.length) {
      return;
    }
    final item = _arrangement.removeAt(from);
    _arrangement.insert(to, item);
    notifyListeners();
  }

  /// Reorder mode: checks the current arrangement against the authored
  /// correct order.
  void submitReorder() {
    if (_paused || _isComplete || _content.mode != SequenceMode.reorder) {
      return;
    }
    _attempts++;
    final correct = _arrangementMatchesAnswer();
    _lastSubmissionCorrect = correct;
    if (correct) _isComplete = true;
    notifyListeners();
  }

  bool _arrangementMatchesAnswer() {
    if (_arrangement.length != _content.correctOrder.length) return false;
    for (var i = 0; i < _arrangement.length; i++) {
      if (_arrangement[i].id != _content.correctOrder[i].id) return false;
    }
    return true;
  }

  /// Missing-item mode: assign [choiceItemId] to blank position [index].
  void selectForMissingIndex(int index, String choiceItemId) {
    if (_paused || _isComplete) return;
    if (!_content.missingIndices.contains(index)) return;
    _missingSelections[index] = choiceItemId;
    notifyListeners();
  }

  /// Missing-item mode: checks every blank against the authored answer.
  void submitMissingItems() {
    if (_paused || _isComplete || _content.mode != SequenceMode.missingItem) {
      return;
    }
    _attempts++;
    final correct = _content.missingIndices.every(
      (index) => _missingSelections[index] == _content.correctOrder[index].id,
    );
    _lastSubmissionCorrect = correct;
    if (correct) _isComplete = true;
    notifyListeners();
  }

  void requestHint() {
    _showHint = true;
    notifyListeners();
  }

  void dismissHint() {
    _showHint = false;
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

  void retry() {
    _resetForContent();
    notifyListeners();
  }

  void _resetForContent() {
    _arrangement = List.of(_content.correctOrder);
    if (_content.mode == SequenceMode.reorder) {
      _arrangement.shuffleSeeded(
        _DeterministicRandom(_content.contentId.hashCode),
      );
    }
    _missingSelections = {for (final i in _content.missingIndices) i: null};
    _attempts = 0;
    _showHint = false;
    _paused = false;
    _isComplete = false;
    _lastSubmissionCorrect = null;
  }
}

/// Minimal deterministic PRNG so shuffles are reproducible per content id
/// (same rationale as MatchingScreen's shuffle -- see matching_screen.dart).
class _DeterministicRandom {
  _DeterministicRandom(int seed) : _state = seed & 0x7fffffff;
  int _state;

  int nextInt(int max) {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state % max;
  }
}

extension on List<SequenceItem> {
  void shuffleSeeded(_DeterministicRandom random) {
    for (var i = length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final tmp = this[i];
      this[i] = this[j];
      this[j] = tmp;
    }
  }
}
