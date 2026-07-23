import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:mi_game_core/mi_game_core.dart';

import '../game_locale_text.dart';

/// Card state during gameplay.
enum CardState {
  /// Card is face-down, waiting to be tapped.
  faceDown,

  /// Card has been revealed (face-up) but not yet matched.
  faceUp,

  /// Card has been matched and stays face-up permanently.
  matched,

  /// Card is temporarily face-up but mismatched — will flip back.
  mismatched,
}

/// A single card in the memory game.
class MemoryCard extends Equatable {
  const MemoryCard({
    required this.id,
    required this.pairId,
    required this.content,
    required this.type,
    this.state = CardState.faceDown,
  });

  final String id;
  final String pairId;
  final String content;
  final String type; // image, text, number
  final CardState state;

  MemoryCard copyWith({CardState? state}) {
    return MemoryCard(
      id: id,
      pairId: pairId,
      content: content,
      type: type,
      state: state ?? this.state,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pairId': pairId,
        'content': content,
        'type': type,
        'state': state.name,
      };

  factory MemoryCard.fromJson(Map<String, dynamic> json) {
    return MemoryCard(
      id: json['id'] as String,
      pairId: json['pairId'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      state: CardState.values.byName(json['state'] as String),
    );
  }

  @override
  List<Object?> get props => [id, pairId, content, type, state];
}

/// Memory Cards game implementing [MiGame] from the blueprint §6.
class MemoryCardsGame extends BaseGame {
  @override
  String get gameId => 'memory_cards';

  // Game state
  List<MemoryCard> _cards = [];
  int? _firstFlippedIndex;
  int _matchedPairs = 0;
  int _totalPairs = 0;
  int _score = 0;
  final Stopwatch _playStopwatch = Stopwatch();
  bool _isProcessing = false;
  Timer? _mismatchTimer;

  // Level config
  int _gridCols = 4;
  int _gridRows = 2;
  int _initialRevealMs = 1500;

  // Snapshotted for save/restore
  int _attemptsUsed = 0;

  @override
  Future<void> onInitialize(MiGameContext context) async {}

  @override
  Future<void> onLoadLevel(MiLevel level) async {
    final locale = context?.language ?? 'vi';
    final content = level.contentForLocale(locale);
    final cardData = content['cards'] as List? ?? [];

    _gridCols = level.metadata['gridCols'] as int? ?? 4;
    _gridRows = level.metadata['gridRows'] as int? ?? 2;
    _initialRevealMs = level.metadata['initialRevealMs'] as int? ?? 1500;

    _cards = [];
    for (final cardJson in cardData) {
      _cards.add(MemoryCard(
        id: cardJson['id'] as String,
        pairId: cardJson['pairId'] as String,
        content: cardJson['content'] as String,
        type: cardJson['type'] as String? ?? 'text',
      ));
    }

    // Shuffle using Fisher-Yates
    final rng = Random();
    for (int i = _cards.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = _cards[i];
      _cards[i] = _cards[j];
      _cards[j] = tmp;
    }

    _matchedPairs = 0;
    _totalPairs = _cards.length ~/ 2;
    _score = 0;
    _firstFlippedIndex = null;
    _isProcessing = false;
    _attemptsUsed = 0;
  }

  @override
  Future<void> onStart() async {
    _playStopwatch.reset();
    _playStopwatch.start();

    // Initial reveal: flip all cards face-up briefly
    if (_initialRevealMs > 0) {
      _isProcessing = true;
      _cards = _cards.map((c) => c.copyWith(state: CardState.faceUp)).toList();
      await Future.delayed(Duration(milliseconds: _initialRevealMs));
      _cards =
          _cards.map((c) => c.copyWith(state: CardState.faceDown)).toList();
      _isProcessing = false;
    }
  }

  @override
  Future<void> onPause() async {
    _playStopwatch.stop();
    _mismatchTimer?.cancel();
  }

  @override
  Future<void> onResume() async {
    _playStopwatch.start();
  }

  @override
  Future<MiActionResult> onHandleAction(MiGameAction action) async {
    if (action.type != 'tap' || _isProcessing) {
      return const MiActionResult(correct: false);
    }

    final index = int.tryParse(action.targetId ?? '');
    if (index == null || index < 0 || index >= _cards.length) {
      return const MiActionResult(correct: false);
    }

    final card = _cards[index];

    // Cannot interact with matched or already face-up cards
    if (card.state == CardState.matched || card.state == CardState.faceUp) {
      return const MiActionResult(correct: false);
    }

    // Flip the card
    _cards[index] = card.copyWith(state: CardState.faceUp);

    if (_firstFlippedIndex == null) {
      // First card of a pair
      _firstFlippedIndex = index;
      return MiActionResult(
        correct: false,
        feedback: null,
        audioRef: 'card_flip',
        metadata: {'cards': _cards.map((c) => c.toJson()).toList()},
      );
    } else {
      // Second card — check for match
      _attemptsUsed++;
      _isProcessing = true;
      final firstCard = _cards[_firstFlippedIndex!];

      if (firstCard.pairId == card.pairId && firstCard.id != card.id) {
        final text = GameLocaleText(context?.language ?? 'vi');
        // Match!
        _cards[_firstFlippedIndex!] =
            firstCard.copyWith(state: CardState.matched);
        _cards[index] = _cards[index].copyWith(state: CardState.matched);
        _matchedPairs++;
        _score += 10;

        final completed = _matchedPairs >= _totalPairs;

        _firstFlippedIndex = null;
        _isProcessing = false;

        return MiActionResult(
          correct: true,
          feedback: completed ? text.memoryDone : text.memoryMatched,
          audioRef: 'match_correct',
          isLevelComplete: completed,
          metadata: {
            'matchedPairs': _matchedPairs,
            'totalPairs': _totalPairs,
            'score': _score,
            'cards': _cards.map((c) => c.toJson()).toList(),
          },
        );
      } else {
        // Mismatch — show briefly then flip back
        _cards[index] = _cards[index].copyWith(state: CardState.mismatched);

        final text = GameLocaleText(context?.language ?? 'vi');
        final feedback = MiActionResult.incorrect(
          feedback: text.memoryRetry,
          metadata: {'cards': _cards.map((c) => c.toJson()).toList()},
        );

        _firstFlippedIndex = null;

        // Auto-flip back after a delay
        _mismatchTimer?.cancel();
        _mismatchTimer = Timer(const Duration(milliseconds: 1200), () {
          _cards = _cards.map((c) {
            if (c.state == CardState.mismatched) {
              return c.copyWith(state: CardState.faceDown);
            }
            return c;
          }).toList();
          _isProcessing = false;
        });

        return feedback;
      }
    }
  }

  @override
  Future<MiGameSnapshot> createSnapshot() async {
    return MiGameSnapshot(
      gameId: gameId,
      levelId: level!.id,
      childProfileId: context!.childProfileId,
      state: {
        'cards': _cards.map((c) => c.toJson()).toList(),
        'firstFlippedIndex': _firstFlippedIndex,
        'matchedPairs': _matchedPairs,
        'totalPairs': _totalPairs,
        'score': _score,
        'attemptsUsed': _attemptsUsed,
      },
      createdAt: DateTime.now(),
      score: _score,
      attemptsUsed: _attemptsUsed,
      itemsCompleted: _matchedPairs,
      totalItems: _totalPairs,
      metadata: {'playTimeMs': _playStopwatch.elapsedMilliseconds},
    );
  }

  @override
  Future<void> onRestoreSnapshot(MiGameSnapshot snapshot) async {
    final state = snapshot.state;
    _cards = (state['cards'] as List)
        .map((c) => MemoryCard.fromJson(c as Map<String, dynamic>))
        .toList();
    _firstFlippedIndex = state['firstFlippedIndex'] as int?;
    _matchedPairs = state['matchedPairs'] as int;
    _totalPairs = state['totalPairs'] as int;
    _score = state['score'] as int;
    _attemptsUsed = state['attemptsUsed'] as int;
    _playStopwatch.reset();
    _playStopwatch.start();
  }

  @override
  Future<MiCompletionResult> createCompletionResult({
    required Duration duration,
    required int hintsUsed,
  }) async {
    final perfectRun = _attemptsUsed <= _totalPairs;
    final stars = _score >= _totalPairs * 15
        ? 3
        : _score >= _totalPairs * 10
            ? 2
            : 1;

    return MiCompletionResult(
      gameId: gameId,
      levelId: level!.id,
      childProfileId: context!.childProfileId,
      completedAt: DateTime.now(),
      score: _score,
      maxScore: _totalPairs * 15,
      attemptsUsed: _attemptsUsed,
      hintsUsed: hintsUsed,
      duration: duration,
      perfectRun: perfectRun,
      newSkillsAcquired: const ['memory_matching', 'visual_recall'],
      metadata: {
        'stars': stars,
        'matchedPairs': _matchedPairs,
        'totalPairs': _totalPairs,
        'playTimeMs': _playStopwatch.elapsedMilliseconds,
      },
    );
  }

  @override
  Future<void> onDispose() async {
    _mismatchTimer?.cancel();
    _playStopwatch.stop();
  }

  // --- Public getters for the UI ---

  List<MemoryCard> get cards => List.unmodifiable(_cards);
  int get matchedPairs => _matchedPairs;
  int get totalPairs => _totalPairs;
  int get gridCols => _gridCols;
  int get gridRows => _gridRows;
  bool get isProcessing => _isProcessing;
}
