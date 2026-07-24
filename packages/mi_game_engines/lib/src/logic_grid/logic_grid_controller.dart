// Logic Grid Engine — controller for deduction puzzles.
//
// The child marks cells in a grid as TRUE (yes), FALSE (no), or UNKNOWN
// (empty). The controller validates each mark against the solution and
// provides feedback. Completion requires all solution cells to be marked
// TRUE and no incorrect marks to remain.

import 'package:flutter/foundation.dart';

import 'logic_grid_content.dart';

/// Cell mark states.
enum LogicGridMark { yes, no, empty }

/// Result of a single mark attempt.
class LogicGridAttemptResult {
  const LogicGridAttemptResult({
    required this.isCorrect,
    required this.pairing,
    required this.mark,
    required this.attemptsSoFar,
    required this.correctMarkCount,
    required this.totalSolutionCells,
  });

  final bool isCorrect;
  final LogicGridPairing pairing;
  final LogicGridMark mark;
  final int attemptsSoFar;
  final int correctMarkCount;
  final int totalSolutionCells;
}

/// Drives one Logic Grid puzzle: mark state, validation, hints, completion.
class LogicGridController extends ChangeNotifier {
  static const String engineId = 'logic_grid';

  LogicGridController({
    required LogicGridContent content,
    this.reducedMotion = false,
    this.soundEnabled = true,
  }) : _content = content {
    _solutionKeys = {
      for (final p in content.solution) p.normalizedKey,
    };
  }

  LogicGridContent _content;
  LogicGridContent get content => _content;

  final bool reducedMotion;
  final bool soundEnabled;

  /// Normalized solution keys for fast lookup.
  late final Set<String> _solutionKeys;

  /// Grid state: normalized pairing key -> mark.
  final Map<String, LogicGridMark> _marks = {};

  int _attempts = 0;
  int _correctMarks = 0;
  bool _showHint = false;
  bool _paused = false;
  String? _lastFeedback;
  bool _lastFeedbackWasCorrect = false;

  int get attempts => _attempts;
  int get correctMarks => _correctMarks;
  int get totalSolutionCells => _content.solution.length;
  bool get showHint => _showHint;
  bool get isPaused => _paused;
  String? get lastFeedback => _lastFeedback;
  bool get lastFeedbackWasCorrect => _lastFeedbackWasCorrect;

  LogicGridMark markFor(LogicGridPairing pairing) =>
      _marks[pairing.normalizedKey] ?? LogicGridMark.empty;

  bool get isComplete => _correctMarks == totalSolutionCells;

  /// 3/2/1 stars by accuracy: perfect = 3, up to 1.5x attempts = 2, else 1.
  int get starsEarned {
    if (!isComplete) return 0;
    if (_attempts <= totalSolutionCells) return 3;
    if (_attempts <= (totalSolutionCells * 1.5).ceil()) return 2;
    return 1;
  }

  /// Toggles a cell mark. Tapping cycles empty → yes → no → empty.
  /// Only YES marks on solution cells count toward completion.
  LogicGridAttemptResult? toggleMark(LogicGridPairing pairing) {
    if (_paused) return null;

    final key = pairing.normalizedKey;
    final current = _marks[key] ?? LogicGridMark.empty;
    final nextMark = switch (current) {
      LogicGridMark.empty => LogicGridMark.yes,
      LogicGridMark.yes => LogicGridMark.no,
      LogicGridMark.no => LogicGridMark.empty,
    };

    _attempts++;
    final isSolution = _solutionKeys.contains(key);
    var isCorrect = false;

    if (nextMark == LogicGridMark.yes) {
      if (isSolution) {
        _correctMarks++;
        isCorrect = true;
        _lastFeedback = 'correct';
        _lastFeedbackWasCorrect = true;
      } else {
        _lastFeedback = 'incorrect';
        _lastFeedbackWasCorrect = false;
      }
    } else if (current == LogicGridMark.yes && isSolution) {
      // Un-marking a correct solution cell.
      _correctMarks--;
    }

    if (nextMark == LogicGridMark.empty) {
      _marks.remove(key);
    } else {
      _marks[key] = nextMark;
    }

    notifyListeners();

    return LogicGridAttemptResult(
      isCorrect: isCorrect,
      pairing: pairing,
      mark: nextMark,
      attemptsSoFar: _attempts,
      correctMarkCount: _correctMarks,
      totalSolutionCells: totalSolutionCells,
    );
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
    _marks.clear();
    _attempts = 0;
    _correctMarks = 0;
    _showHint = false;
    _paused = false;
    _lastFeedback = null;
    _lastFeedbackWasCorrect = false;
    notifyListeners();
  }

  void loadContent(LogicGridContent content) {
    _content = content;
    _solutionKeys = {for (final p in content.solution) p.normalizedKey};
    retry();
  }
}
