import 'package:flutter/foundation.dart';

import 'placement_content.dart';

/// One attempted placement (correct or not), for callers that want a full
/// history rather than just the running counters.
class PlacementAttempt {
  const PlacementAttempt({
    required this.itemId,
    required this.targetId,
    required this.isCorrect,
    required this.attemptNumber,
  });

  final String itemId;
  final String targetId;
  final bool isCorrect;
  final int attemptNumber;
}

/// Normalized, engine-agnostic result shape -- the "common engine
/// contract" result. Deliberately a plain immutable data class with no
/// dependency on child-profile storage, Hive, or any backend API; callers
/// (a game screen, a test) decide what to do with it via
/// [PlacementController.onComplete] or by reading [PlacementController.result]
/// at any time.
class PlacementResult {
  const PlacementResult({
    required this.engineId,
    required this.contentId,
    required this.attempts,
    required this.correctCount,
    required this.incorrectCount,
    required this.hintCount,
    required this.score,
    required this.stars,
    required this.duration,
    required this.completed,
    required this.placements,
  });

  final String engineId;
  final String contentId;
  final int attempts;
  final int correctCount;
  final int incorrectCount;
  final int hintCount;
  final int score;
  final int stars;
  final Duration duration;
  final bool completed;

  /// itemId -> targetId, a snapshot of every current placement.
  final Map<String, String> placements;

  @override
  bool operator ==(Object other) =>
      other is PlacementResult &&
      other.engineId == engineId &&
      other.contentId == contentId &&
      other.attempts == attempts &&
      other.correctCount == correctCount &&
      other.incorrectCount == incorrectCount &&
      other.hintCount == hintCount &&
      other.score == score &&
      other.stars == stars &&
      other.duration == duration &&
      other.completed == completed &&
      mapEquals(other.placements, placements);

  @override
  int get hashCode => Object.hash(
        engineId,
        contentId,
        attempts,
        correctCount,
        incorrectCount,
        hintCount,
        score,
        stars,
        duration,
        completed,
        Object.hashAllUnordered(
          placements.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      );
}

/// Drives one Drag-and-drop Placement Engine level: unplaced/placed item
/// tracking, target capacity, tap-accessibility selection, attempts,
/// scoring, hints, pause/resume, and completion -- the "controller" half
/// of the Milestone 1 engine contract, alongside `MatchingController` and
/// `SequenceController`. A plain [ChangeNotifier], no dependency on any
/// state-management framework or child-profile repository, and it never
/// writes to storage/analytics/backends itself -- see [onComplete].
class PlacementController extends ChangeNotifier {
  PlacementController({
    required PlacementContent content,
    this.reducedMotion = false,
    this.soundEnabled = true,
    DateTime Function()? clock,
    this.onComplete,
  })  : _content = content,
        _clock = clock ?? DateTime.now {
    _resetForContent(reshuffle: true);
  }

  static const String engineId = 'placement';

  PlacementContent _content;
  PlacementContent get content => _content;

  final bool reducedMotion;
  final bool soundEnabled;
  final DateTime Function() _clock;

  /// Invoked exactly once, the moment the level is completed. The engine
  /// itself never persists this -- the host decides what to do with it.
  final void Function(PlacementResult result)? onComplete;

  late List<PlacementItem> _sourceOrder;
  final Map<String, String> _placements = {}; // itemId -> targetId
  final List<PlacementAttempt> _attemptLog = [];
  String? _selectedItemId;
  int _attempts = 0;
  int _correctCount = 0;
  int _incorrectCount = 0;
  int _hintCount = 0;
  bool _showHint = false;
  bool _paused = false;
  bool _isComplete = false;
  String? _lastInvalidItemId;
  bool? _lastAttemptWasCorrect;
  late DateTime _startedAt;
  DateTime? _completedAt;

  /// Items not currently on any target, in their (possibly shuffled)
  /// source order.
  List<PlacementItem> get unplacedItems => List.unmodifiable(
        _sourceOrder.where((i) => !_placements.containsKey(i.id)),
      );

  /// All items, in source order, regardless of placement -- useful for a
  /// renderer that wants to show placed items visually docked at their
  /// target instead of removed from a "tray".
  List<PlacementItem> get allItemsInSourceOrder =>
      List.unmodifiable(_sourceOrder);

  List<PlacementItem> placedItemsFor(String targetId) => [
        for (final entry in _placements.entries)
          if (entry.value == targetId) _itemById(entry.key),
      ];

  int occupancyOf(String targetId) =>
      _placements.values.where((t) => t == targetId).length;

  String? targetOf(String itemId) => _placements[itemId];

  /// Pure predicate (no state mutation) for whether [itemId] could
  /// legally land on [targetId] right now -- used by the renderer to
  /// highlight a target while a drag is hovering over it, and to preview
  /// tap-mode placement, without actually committing anything.
  bool canAccept(String itemId, String targetId) {
    final item = _content.items.where((i) => i.id == itemId).firstOrNull;
    final target = _targetById(targetId);
    if (item == null || target == null) return false;
    final occupancy =
        occupancyOf(targetId) - (_placements[itemId] == targetId ? 1 : 0);
    return _content.rule.accepts(item, target) && occupancy < target.capacity;
  }

  String? get selectedItemId => _selectedItemId;
  List<PlacementAttempt> get attemptLog => List.unmodifiable(_attemptLog);
  int get attempts => _attempts;
  int get correctCount => _correctCount;
  int get incorrectCount => _incorrectCount;
  int get hintCount => _hintCount;
  bool get showHint => _showHint;
  bool get isPaused => _paused;
  bool get isComplete => _isComplete;
  String? get lastInvalidItemId => _lastInvalidItemId;
  bool? get lastAttemptWasCorrect => _lastAttemptWasCorrect;
  Map<String, String> get placements => Map.unmodifiable(_placements);

  Duration get duration => (_completedAt ?? _clock()).difference(_startedAt);

  /// 3/2/1 stars by placement accuracy, same shape as Matching/Sequence's
  /// attempt-efficiency scoring: a perfect run (zero incorrect attempts)
  /// is 3 stars, up to one incorrect per item is 2, more is 1. Never
  /// negative, never zero for a completed level.
  int get starsEarned {
    if (!_isComplete) return 0;
    if (_incorrectCount == 0) return 3;
    if (_incorrectCount <= _content.items.length) return 2;
    return 1;
  }

  /// A 0-100 score: full credit for a perfect run, moderate deductions
  /// for incorrect attempts and hint usage, floored at 0 (children can
  /// never receive a negative score). Score never blocks completion --
  /// it is purely informational.
  int get score {
    final penalty = (_incorrectCount * 5) + (_hintCount * 5);
    final raw = 100 - penalty;
    return raw < 0 ? 0 : raw;
  }

  PlacementResult get result => PlacementResult(
        engineId: engineId,
        contentId: _content.contentId,
        attempts: _attempts,
        correctCount: _correctCount,
        incorrectCount: _incorrectCount,
        hintCount: _hintCount,
        score: score,
        stars: starsEarned,
        duration: duration,
        completed: _isComplete,
        placements: placements,
      );

  PlacementItem _itemById(String id) =>
      _content.items.firstWhere((i) => i.id == id);

  PlacementTarget? _targetById(String id) {
    for (final target in _content.targets) {
      if (target.id == id) return target;
    }
    return null;
  }

  /// Tap-accessibility mode, step 1: select (or toggle off) an item.
  /// Selecting a different item replaces the current selection; the
  /// entire level is completable through [selectItem] + [placeItem]
  /// alone, with no drag gesture required.
  void selectItem(String itemId) {
    if (_paused || _isComplete) return;
    _selectedItemId = _selectedItemId == itemId ? null : itemId;
    notifyListeners();
  }

  void clearSelection() {
    _selectedItemId = null;
    notifyListeners();
  }

  /// Attempts to place [itemId] on [targetId] -- used by both drag-drop
  /// and tap-accessibility ("select item, then tap target") interaction.
  /// Also used to move an already-placed item: the previous target's
  /// capacity is released first and restored if the new placement is
  /// invalid, so a failed move never leaves the item in limbo.
  void placeItem(String itemId, String targetId) {
    if (_paused || _isComplete) return;
    final item = _content.items.where((i) => i.id == itemId).firstOrNull;
    final target = _targetById(targetId);
    if (item == null || target == null) return;

    final previousTargetId = _placements[itemId];
    // Tentatively release the item's current spot so capacity math below
    // doesn't count the item against its own previous target.
    _placements.remove(itemId);

    final currentOccupancy = occupancyOf(targetId);
    final acceptedByRule = _content.rule.accepts(item, target);
    final hasCapacity = currentOccupancy < target.capacity;
    final isValid = acceptedByRule && hasCapacity;

    _attempts++;
    _attemptLog.add(
      PlacementAttempt(
        itemId: itemId,
        targetId: targetId,
        isCorrect: isValid,
        attemptNumber: _attempts,
      ),
    );

    if (isValid) {
      _placements[itemId] = targetId;
      _correctCount++;
      _lastAttemptWasCorrect = true;
      _lastInvalidItemId = null;
    } else {
      // Restore the prior valid placement (or leave unplaced) -- a
      // failed move/placement never corrupts existing state.
      if (previousTargetId != null) {
        _placements[itemId] = previousTargetId;
      }
      _incorrectCount++;
      _lastAttemptWasCorrect = false;
      _lastInvalidItemId = itemId;
    }

    _selectedItemId = null;
    _checkCompletion();
    notifyListeners();
  }

  /// Explicit alias for moving an already-placed item -- identical
  /// behavior to [placeItem], exposed separately so callers reading the
  /// public API can see "move" as its own supported operation.
  void moveItem(String itemId, String newTargetId) =>
      placeItem(itemId, newTargetId);

  /// Removes [itemId] from whatever target it currently occupies, if any.
  /// Not an attempt and does not affect scoring -- purely lets the child
  /// change their mind before placing it elsewhere.
  void removeItem(String itemId) {
    if (_paused || _isComplete) return;
    if (!_content.configuration.allowRemoveFromTarget) return;
    if (_placements.remove(itemId) != null) {
      notifyListeners();
    }
  }

  void requestHint() {
    _hintCount++;
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

  /// Clears progress (placements, attempts, scoring) but keeps the same
  /// shuffled source order -- "try this exact layout again".
  void reset() {
    _resetForContent(reshuffle: false);
    notifyListeners();
  }

  /// Clears progress AND re-shuffles the source order -- a fresh start.
  void restart() {
    _resetForContent(reshuffle: true);
    notifyListeners();
  }

  /// Idempotent, explicit completion check -- exposed for API parity with
  /// the other required operations and for hosts that want to force a
  /// re-check without a placement having just happened. Completion
  /// itself is otherwise evaluated automatically after every
  /// [placeItem]/[removeItem] call.
  void complete() {
    _checkCompletion();
    notifyListeners();
  }

  void _checkCompletion() {
    if (_isComplete) return;
    if (!_content.configuration.requireAllItemsPlacedForCompletion) return;

    final allPlaced = _content.items.every(
      (item) => _placements.containsKey(item.id),
    );
    if (!allPlaced) return;

    // Every current placement must still be valid under the rule (it
    // always should be, since only valid placements are ever committed,
    // but this re-check keeps completion honest rather than assuming).
    final allValid = _placements.entries.every((entry) {
      final item = _itemById(entry.key);
      final target = _targetById(entry.value);
      return target != null && _content.rule.accepts(item, target);
    });
    if (!allValid) return;

    _isComplete = true;
    _completedAt = _clock();
    onComplete?.call(result);
  }

  void loadContent(PlacementContent content) {
    _content = content;
    _resetForContent(reshuffle: true);
    notifyListeners();
  }

  void _resetForContent({required bool reshuffle}) {
    if (reshuffle || !_isInitialized) {
      _sourceOrder = List.of(_content.items)
        ..sort((a, b) => a.initialOrder.compareTo(b.initialOrder));
      if (_content.configuration.shuffleItems) {
        _sourceOrder.shuffleSeeded(
          _DeterministicRandom(_content.contentId.hashCode),
        );
      }
    }
    _isInitialized = true;
    _placements.clear();
    _attemptLog.clear();
    _selectedItemId = null;
    _attempts = 0;
    _correctCount = 0;
    _incorrectCount = 0;
    _hintCount = 0;
    _showHint = false;
    _paused = false;
    _isComplete = false;
    _lastInvalidItemId = null;
    _lastAttemptWasCorrect = null;
    _startedAt = _clock();
    _completedAt = null;
  }

  bool _isInitialized = false;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Minimal deterministic PRNG so the initial shuffle is reproducible per
/// content id (same rationale/shape as MatchingScreen's and
/// SequenceController's own private shuffle helpers -- each engine file
/// keeps its own copy rather than sharing one, matching this package's
/// existing convention).
class _DeterministicRandom {
  _DeterministicRandom(int seed) : _state = seed & 0x7fffffff;
  int _state;

  int nextInt(int max) {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state % max;
  }
}

extension on List<PlacementItem> {
  /// Named `shuffleSeeded`, not `shuffle`: `List` already declares a
  /// built-in `shuffle([Random?])` that always wins over a same-named
  /// extension even with an incompatible parameter type, which fails to
  /// compile with `argument_type_not_assignable` (hit and fixed twice
  /// already in this package's Matching/Sequence engines).
  void shuffleSeeded(_DeterministicRandom random) {
    for (var i = length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final tmp = this[i];
      this[i] = this[j];
      this[j] = tmp;
    }
  }
}
