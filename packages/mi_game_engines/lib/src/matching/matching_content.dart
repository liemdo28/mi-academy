import 'package:equatable/equatable.dart';

/// How a [MatchingItem]'s [MatchingItem.content] should be rendered.
enum MatchingItemType { text, image }

/// One side of a match pair (the left-column item or its right-column
/// partner). [id] is unique within its own column, not globally -- a pair
/// is `(leftId, rightId)`, not a single shared id, so left and right sides
/// can each be independently shuffled for presentation.
class MatchingItem extends Equatable {
  const MatchingItem({
    required this.id,
    required this.content,
    this.type = MatchingItemType.text,
    this.semanticLabel,
  });

  factory MatchingItem.fromJson(Map<String, dynamic> json) {
    return MatchingItem(
      id: json['id'] as String,
      content: json['content'] as String,
      type: json['type'] == 'image'
          ? MatchingItemType.image
          : MatchingItemType.text,
      semanticLabel: json['semanticLabel'] as String?,
    );
  }

  final String id;
  final String content;
  final MatchingItemType type;
  final String? semanticLabel;

  @override
  List<Object?> get props => [id, content, type, semanticLabel];
}

/// One correct left/right pairing.
class MatchingPair extends Equatable {
  const MatchingPair({required this.left, required this.right});

  factory MatchingPair.fromJson(Map<String, dynamic> json) {
    return MatchingPair(
      left: MatchingItem.fromJson(json['left'] as Map<String, dynamic>),
      right: MatchingItem.fromJson(json['right'] as Map<String, dynamic>),
    );
  }

  final MatchingItem left;
  final MatchingItem right;

  @override
  List<Object?> get props => [left, right];
}

/// Typed content for one Matching Engine level -- see
/// docs/game-engine-architecture.md and the Milestone 1 spec's "Common
/// engine contract". Deliberately independent of `MiLevel`
/// (packages/mi_game_core): this engine's content has a real internal
/// structure (pairs of typed items), not an opaque `Map<String, dynamic>`
/// gameplay payload, per the "do not use an untyped Map throughout
/// gameplay" requirement.
class MatchingContent extends Equatable {
  const MatchingContent({
    required this.contentId,
    required this.gameId,
    required this.locale,
    required this.ageBand,
    required this.difficulty,
    required this.instruction,
    required this.pairs,
    this.hint,
    this.estimatedSeconds = 60,
  });

  final String contentId;
  final String gameId;
  final String locale;
  final String ageBand;
  final int difficulty;
  final String instruction;
  final String? hint;
  final List<MatchingPair> pairs;
  final int estimatedSeconds;

  /// Parses and validates [json], throwing [MatchingContentException] with
  /// an actionable message for any malformed input rather than a bare cast
  /// failure -- callers (the engine widget) catch this and show a
  /// recoverable "content unavailable" state instead of crashing.
  factory MatchingContent.fromJson(Map<String, dynamic> json) {
    final missing = <String>[
      for (final field in [
        'contentId',
        'gameId',
        'locale',
        'ageBand',
        'difficulty',
        'instruction',
        'pairs',
      ])
        if (!json.containsKey(field)) field,
    ];
    if (missing.isNotEmpty) {
      throw MatchingContentException('Missing required field(s): $missing');
    }

    final difficulty = json['difficulty'];
    if (difficulty is! int || difficulty < 1 || difficulty > 5) {
      throw MatchingContentException(
        'difficulty must be an integer 1-5, got $difficulty',
      );
    }

    final rawPairs = json['pairs'];
    if (rawPairs is! List || rawPairs.isEmpty) {
      throw MatchingContentException('pairs must be a non-empty list');
    }

    final pairs = <MatchingPair>[];
    final seenLeftIds = <String>{};
    final seenRightIds = <String>{};
    for (final raw in rawPairs) {
      final pair = MatchingPair.fromJson(raw as Map<String, dynamic>);
      if (!seenLeftIds.add(pair.left.id)) {
        throw MatchingContentException(
          'Duplicate left item id: ${pair.left.id}',
        );
      }
      if (!seenRightIds.add(pair.right.id)) {
        throw MatchingContentException(
          'Duplicate right item id: ${pair.right.id}',
        );
      }
      pairs.add(pair);
    }

    return MatchingContent(
      contentId: json['contentId'] as String,
      gameId: json['gameId'] as String,
      locale: json['locale'] as String,
      ageBand: json['ageBand'] as String,
      difficulty: difficulty,
      instruction: json['instruction'] as String,
      hint: json['hint'] as String?,
      pairs: pairs,
      estimatedSeconds: json['estimatedSeconds'] as int? ?? 60,
    );
  }

  @override
  List<Object?> get props => [
        contentId,
        gameId,
        locale,
        ageBand,
        difficulty,
        instruction,
        hint,
        pairs,
        estimatedSeconds,
      ];
}

class MatchingContentException implements Exception {
  MatchingContentException(this.message);
  final String message;

  @override
  String toString() => 'MatchingContentException: $message';
}
