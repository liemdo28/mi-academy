import 'package:flutter/foundation.dart';

import 'matching_content.dart';

/// Emitted after every attempted match (correct or not), for scoring/
/// persistence callers. Deliberately has no dependency on any child
/// profile or storage type -- callers decide what to do with it.
class MatchingAttemptResult {
  const MatchingAttemptResult({
    required this.isCorrect,
    required this.leftId,
    required this.rightId,
    required this.attemptsSoFar,
    required this.matchedPairCount,
    required this.totalPairCount,
  });

  final bool isCorrect;
  final String leftId;
  final String rightId;
  final int attemptsSoFar;
  final int matchedPairCount;
  final int totalPairCount;
}

/// Drives one Matching Engine level: selection state, scoring, hints,
/// pause/resume, and completion -- the "controller" half of the Milestone 1
/// engine contract (content model + renderer + controller). A plain
/// [ChangeNotifier] rather than anything Riverpod/Provider-specific, so it
/// has no dependency on the host app's state-management choice, let alone
/// a child-profile repository.
class MatchingController extends ChangeNotifier {
  /// Stable identifier for this engine, used by the shared engine
  /// contract test suite (test/engine_contract_test.dart) to verify
  /// every engine reports a consistent identity alongside its result.
  static const String engineId = 'matching';

  MatchingController({
    required MatchingContent content,
    this.reducedMotion = false,
    this.soundEnabled = true,
  }) : _content = content {
    _resetSelectionState();
  }

  MatchingContent _content;
  MatchingContent get content => _content;

  final bool reducedMotion;
  final bool soundEnabled;

  String? _selectedLeftId;
  String? _selectedRightId;
  final Set<String> _matchedLeftIds = {};
  final Set<String> _matchedRightIds = {};
  int _attempts = 0;
  bool _showHint = false;
  bool _paused = false;
  String? _lastFeedback;
  bool _lastFeedbackWasCorrect = false;

  String? get selectedLeftId => _selectedLeftId;
  String? get selectedRightId => _selectedRightId;
  bool isLeftMatched(String id) => _matchedLeftIds.contains(id);
  bool isRightMatched(String id) => _matchedRightIds.contains(id);
  int get attempts => _attempts;
  bool get showHint => _showHint;
  bool get isPaused => _paused;
  String? get lastFeedback => _lastFeedback;
  bool get lastFeedbackWasCorrect => _lastFeedbackWasCorrect;
  int get matchedPairCount => _matchedLeftIds.length;
  int get totalPairCount => _content.pairs.length;
  bool get isComplete => matchedPairCount == totalPairCount;

  Map<String, dynamic> exportState() => {
        'selectedLeftId': _selectedLeftId,
        'selectedRightId': _selectedRightId,
        'matchedLeftIds': _matchedLeftIds.toList()..sort(),
        'matchedRightIds': _matchedRightIds.toList()..sort(),
        'attempts': _attempts,
        'totalPairCount': totalPairCount,
        'showHint': _showHint,
        'lastFeedback': _lastFeedback,
        'lastFeedbackWasCorrect': _lastFeedbackWasCorrect,
      };

  void restoreState(Map<String, dynamic> state) {
    _selectedLeftId = state['selectedLeftId'] as String?;
    _selectedRightId = state['selectedRightId'] as String?;
    _matchedLeftIds
      ..clear()
      ..addAll(_stringSet(state['matchedLeftIds']));
    _matchedRightIds
      ..clear()
      ..addAll(_stringSet(state['matchedRightIds']));
    _attempts = state['attempts'] as int? ?? 0;
    _showHint = state['showHint'] as bool? ?? false;
    _paused = false;
    _lastFeedback = state['lastFeedback'] as String?;
    _lastFeedbackWasCorrect = state['lastFeedbackWasCorrect'] as bool? ?? false;
    notifyListeners();
  }

  /// 3/2/1 stars by attempt efficiency, same shape as the existing five
  /// games' scoring (see packages/game_core/scoring.py's calculate_stars)
  /// -- perfect (one attempt per pair) is 3 stars, up to double is 2, more
  /// is 1. Never negative, never zero for a completed level.
  int get starsEarned {
    if (!isComplete) return 0;
    if (_attempts <= totalPairCount) return 3;
    if (_attempts <= totalPairCount * 2) return 2;
    return 1;
  }

  void selectLeft(String id) {
    if (_paused || isLeftMatched(id)) return;
    _selectedLeftId = id;
    _tryResolveMatch();
    notifyListeners();
  }

  void selectRight(String id) {
    if (_paused || isRightMatched(id)) return;
    _selectedRightId = id;
    _tryResolveMatch();
    notifyListeners();
  }

  void _tryResolveMatch() {
    final left = _selectedLeftId;
    final right = _selectedRightId;
    if (left == null || right == null) return;

    _attempts++;
    final correctPair = _content.pairs.any(
      (pair) => pair.left.id == left && pair.right.id == right,
    );

    if (correctPair) {
      _matchedLeftIds.add(left);
      _matchedRightIds.add(right);
      _lastFeedback = 'correct';
      _lastFeedbackWasCorrect = true;
    } else {
      _lastFeedback = 'incorrect';
      _lastFeedbackWasCorrect = false;
    }

    _selectedLeftId = null;
    _selectedRightId = null;
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
    _resetSelectionState();
    notifyListeners();
  }

  /// Loads new content, resetting all progress -- used by "restart" and by
  /// a host screen advancing to the next level (a new [MatchingController]
  /// is usually simpler for that case; this exists for hosts that keep one
  /// controller instance alive across levels).
  void loadContent(MatchingContent content) {
    _content = content;
    _resetSelectionState();
    notifyListeners();
  }

  void _resetSelectionState() {
    _selectedLeftId = null;
    _selectedRightId = null;
    _matchedLeftIds.clear();
    _matchedRightIds.clear();
    _attempts = 0;
    _showHint = false;
    _paused = false;
    _lastFeedback = null;
    _lastFeedbackWasCorrect = false;
  }
}

Set<String> _stringSet(Object? value) {
  if (value is Iterable) return value.map((item) => item.toString()).toSet();
  return const {};
}
