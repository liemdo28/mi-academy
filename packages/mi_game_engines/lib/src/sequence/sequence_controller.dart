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
    SequenceSnapshot? initialSnapshot,
    this.reducedMotion = false,
    this.soundEnabled = true,
  }) : _content = content {
    _resetForContent();
    if (initialSnapshot != null) {
      restore(initialSnapshot);
    }
  }

  SequenceContent _content;
  SequenceContent get content => _content;

  final bool reducedMotion;
  final bool soundEnabled;

  late List<SequenceItem> _arrangement; // reorder mode's working order
  late Map<int, String?> _missingSelections; // missingItem mode
  int? _selectedMissingIndex;
  int _attempts = 0;
  int _hintsUsed = 0;
  bool _showHint = false;
  bool _paused = false;
  bool _isComplete = false;
  bool? _lastSubmissionCorrect;

  List<SequenceItem> get arrangement => List.unmodifiable(_arrangement);
  Map<int, String?> get missingSelections =>
      Map.unmodifiable(_missingSelections);
  int? get selectedMissingIndex => _selectedMissingIndex;
  int get attempts => _attempts;
  int get hintsUsed => _hintsUsed;
  bool get showHint => _showHint;
  bool get isPaused => _paused;
  bool get isComplete => _isComplete;
  bool? get lastSubmissionCorrect => _lastSubmissionCorrect;

  int get starsEarned {
    if (!_isComplete) return 0;
    if (_attempts <= 1 && _hintsUsed == 0) return 3;
    if (_attempts <= 2 && _hintsUsed <= 1) return 2;
    return 1;
  }

  int get completedItemCount {
    if (_isComplete) return _content.correctOrder.length;
    if (_content.mode == SequenceMode.missingItem) {
      return _missingSelections.values.whereType<String>().length;
    }
    var ordered = 0;
    for (var i = 0; i < _arrangement.length; i++) {
      if (_arrangement[i].id == _content.correctOrder[i].id) ordered++;
    }
    return ordered;
  }

  int get totalItemCount => _content.correctOrder.length;

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
    _lastSubmissionCorrect = null;
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
  void selectMissingIndex(int index) {
    if (_paused || _isComplete) return;
    if (!_content.missingIndices.contains(index)) return;
    _selectedMissingIndex = index;
    notifyListeners();
  }

  /// Missing-item mode: assign [choiceItemId] to blank position [index].
  void selectForMissingIndex(int index, String choiceItemId) {
    if (_paused || _isComplete) return;
    if (!_content.missingIndices.contains(index)) return;
    _missingSelections[index] = choiceItemId;
    _selectedMissingIndex = _nextUnfilledMissingIndex() ?? index;
    _lastSubmissionCorrect = null;
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
    if (_paused || _isComplete) return;
    if (!_showHint) _hintsUsed++;
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

  SequenceSnapshot snapshot() {
    return SequenceSnapshot(
      contentId: _content.contentId,
      mode: _content.mode,
      arrangementIds: _arrangement.map((item) => item.id).toList(),
      missingSelections: Map.unmodifiable(_missingSelections),
      selectedMissingIndex: _selectedMissingIndex,
      attempts: _attempts,
      hintsUsed: _hintsUsed,
      showHint: _showHint,
      isComplete: _isComplete,
      lastSubmissionCorrect: _lastSubmissionCorrect,
      completedItemCount: completedItemCount,
      totalItemCount: totalItemCount,
    );
  }

  bool restore(SequenceSnapshot snapshot) {
    if (snapshot.contentId != _content.contentId ||
        snapshot.mode != _content.mode) {
      return false;
    }

    final idsToItems = {
      for (final item in _content.correctOrder) item.id: item,
    };
    if (_content.mode == SequenceMode.reorder) {
      final restored = <SequenceItem>[];
      final seen = <String>{};
      for (final id in snapshot.arrangementIds) {
        final item = idsToItems[id];
        if (item == null || !seen.add(id)) return false;
        restored.add(item);
      }
      if (restored.length != _content.correctOrder.length) return false;
      _arrangement = restored;
    }

    if (_content.mode == SequenceMode.missingItem) {
      final restoredSelections = <int, String?>{
        for (final index in _content.missingIndices) index: null,
      };
      for (final entry in snapshot.missingSelections.entries) {
        if (!_content.missingIndices.contains(entry.key)) return false;
        final value = entry.value;
        if (value != null && !_choiceIds.contains(value)) return false;
        restoredSelections[entry.key] = value;
      }
      _missingSelections = restoredSelections;
      final selected = snapshot.selectedMissingIndex;
      _selectedMissingIndex =
          selected != null && _content.missingIndices.contains(selected)
              ? selected
              : _nextUnfilledMissingIndex() ?? _content.missingIndices.first;
    }

    _attempts = snapshot.attempts < 0 ? 0 : snapshot.attempts;
    _hintsUsed = snapshot.hintsUsed < 0 ? 0 : snapshot.hintsUsed;
    _showHint = snapshot.showHint;
    _isComplete = snapshot.isComplete;
    _lastSubmissionCorrect = snapshot.lastSubmissionCorrect;
    notifyListeners();
    return true;
  }

  void _resetForContent() {
    _arrangement = List.of(_content.correctOrder);
    if (_content.mode == SequenceMode.reorder) {
      _arrangement
          .shuffleSeeded(_DeterministicRandom(_content.contentId.hashCode));
    }
    _missingSelections = {for (final i in _content.missingIndices) i: null};
    _selectedMissingIndex =
        _content.missingIndices.isEmpty ? null : _content.missingIndices.first;
    _attempts = 0;
    _hintsUsed = 0;
    _showHint = false;
    _paused = false;
    _isComplete = false;
    _lastSubmissionCorrect = null;
  }

  int? _nextUnfilledMissingIndex() {
    for (final index in _content.missingIndices) {
      if (_missingSelections[index] == null) return index;
    }
    return null;
  }

  Set<String> get _choiceIds => {
        for (final index in _content.missingIndices)
          _content.correctOrder[index].id,
        for (final choice in _content.choices) choice.id,
      };
}

class SequenceSnapshot {
  const SequenceSnapshot({
    required this.contentId,
    required this.mode,
    required this.arrangementIds,
    required this.missingSelections,
    required this.selectedMissingIndex,
    required this.attempts,
    required this.hintsUsed,
    required this.showHint,
    required this.isComplete,
    required this.lastSubmissionCorrect,
    required this.completedItemCount,
    required this.totalItemCount,
  });

  factory SequenceSnapshot.fromJson(Map<String, dynamic> json) {
    final mode = json['mode'] == 'missingItem'
        ? SequenceMode.missingItem
        : SequenceMode.reorder;
    final rawSelections = json['missingSelections'] as Map? ?? const {};
    return SequenceSnapshot(
      contentId: json['contentId'] as String? ?? '',
      mode: mode,
      arrangementIds: (json['arrangementIds'] as List? ?? const [])
          .map((id) => id.toString())
          .toList(),
      missingSelections: {
        for (final entry in rawSelections.entries)
          int.parse(entry.key.toString()): entry.value?.toString(),
      },
      selectedMissingIndex: json['selectedMissingIndex'] as int?,
      attempts: json['attempts'] as int? ?? 0,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      showHint: json['showHint'] as bool? ?? false,
      isComplete: json['isComplete'] as bool? ?? false,
      lastSubmissionCorrect: json['lastSubmissionCorrect'] as bool?,
      completedItemCount: json['completedItemCount'] as int? ?? 0,
      totalItemCount: json['totalItemCount'] as int? ?? 0,
    );
  }

  final String contentId;
  final SequenceMode mode;
  final List<String> arrangementIds;
  final Map<int, String?> missingSelections;
  final int? selectedMissingIndex;
  final int attempts;
  final int hintsUsed;
  final bool showHint;
  final bool isComplete;
  final bool? lastSubmissionCorrect;
  final int completedItemCount;
  final int totalItemCount;

  Map<String, dynamic> toJson() => {
        'contentId': contentId,
        'mode': mode == SequenceMode.missingItem ? 'missingItem' : 'reorder',
        'arrangementIds': arrangementIds,
        'missingSelections': {
          for (final entry in missingSelections.entries)
            entry.key.toString(): entry.value,
        },
        'selectedMissingIndex': selectedMissingIndex,
        'attempts': attempts,
        'hintsUsed': hintsUsed,
        'showHint': showHint,
        'isComplete': isComplete,
        'lastSubmissionCorrect': lastSubmissionCorrect,
        'completedItemCount': completedItemCount,
        'totalItemCount': totalItemCount,
      };
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
