// Logic Grid Engine — typed content for deduction puzzles.
//
// A logic grid puzzle has N categories, each with M values. The solver must
// determine which combination of values (one per category) is correct, using
// a set of clues. Clues are either positive ("A is paired with X") or
// negative ("A is NOT paired with Y"). The engine enforces that every clue
// is actually satisfiable by the solution, and that the solution is unique.

import 'package:equatable/equatable.dart';

/// A single cell in the logic grid: the pairing of one category-value with
/// another category-value. Encoded as `(categoryA, valueA, categoryB,
/// valueB)` so it is order-independent -- `(cA, vA, cB, vB)` and
/// `(cB, vB, cA, vA)` are the same pairing and the engine normalizes them.
class LogicGridPairing extends Equatable {
  const LogicGridPairing({
    required this.categoryA,
    required this.valueA,
    required this.categoryB,
    required this.valueB,
  });

  factory LogicGridPairing.fromJson(Map<String, dynamic> json) {
    return LogicGridPairing(
      categoryA: json['categoryA'] as String,
      valueA: json['valueA'] as String,
      categoryB: json['categoryB'] as String,
      valueB: json['valueB'] as String,
    );
  }

  final String categoryA;
  final String valueA;
  final String categoryB;
  final String valueB;

  /// Normalized key so `(A,X,B,Y)` and `(B,Y,A,X)` compare equal.
  String get normalizedKey {
    if (categoryA.compareTo(categoryB) <= 0) {
      return '$categoryA|$valueA|$categoryB|$valueB';
    }
    return '$categoryB|$valueB|$categoryA|$valueA';
  }

  @override
  List<Object?> get props => [normalizedKey];
}

/// One clue the child uses to deduce the solution. Positive clues assert a
/// pairing is TRUE; negative clues assert a pairing is FALSE.
class LogicGridClue extends Equatable {
  const LogicGridClue({
    required this.id,
    required this.text,
    required this.pairing,
    required this.isPositive,
  });

  factory LogicGridClue.fromJson(Map<String, dynamic> json) {
    return LogicGridClue(
      id: json['id'] as String,
      text: json['text'] as String,
      pairing: LogicGridPairing.fromJson(
        json['pairing'] as Map<String, dynamic>,
      ),
      isPositive: json['isPositive'] as bool,
    );
  }

  final String id;
  final String text;
  final LogicGridPairing pairing;
  final bool isPositive;

  @override
  List<Object?> get props => [id, text, pairing, isPositive];
}

/// Typed content for one Logic Grid puzzle. The [solution] is the full set
/// of correct pairings; [clues] are what the child sees. The engine verifies
/// at construction time that clues are consistent with the solution and that
/// the solution is unique given those clues.
class LogicGridContent extends Equatable {
  const LogicGridContent({
    required this.contentId,
    required this.gameId,
    required this.locale,
    required this.ageBand,
    required this.difficulty,
    required this.instruction,
    required this.categories,
    required this.clues,
    required this.solution,
    this.hint,
    this.estimatedSeconds = 120,
  });

  final String contentId;
  final String gameId;
  final String locale;
  final String ageBand;
  final int difficulty;
  final String instruction;
  final String? hint;

  /// Ordered list of category names, e.g. ['child', 'color', 'fruit'].
  final List<String> categories;

  /// Clues presented to the child.
  final List<LogicGridClue> clues;

  /// The complete solution: one pairing connecting all categories.
  final List<LogicGridPairing> solution;

  final int estimatedSeconds;

  factory LogicGridContent.fromJson(Map<String, dynamic> json) {
    final missing = <String>[
      for (final field in [
        'contentId',
        'gameId',
        'locale',
        'ageBand',
        'difficulty',
        'instruction',
        'categories',
        'clues',
        'solution',
      ])
        if (!json.containsKey(field)) field,
    ];
    if (missing.isNotEmpty) {
      throw LogicGridContentException('Missing required field(s): $missing');
    }

    final difficulty = json['difficulty'];
    if (difficulty is! int || difficulty < 1 || difficulty > 5) {
      throw LogicGridContentException(
        'difficulty must be an integer 1-5, got $difficulty',
      );
    }

    final rawCategories = json['categories'];
    if (rawCategories is! List || rawCategories.length < 2) {
      throw LogicGridContentException(
        'categories must be a list with at least 2 elements',
      );
    }
    final categories =
        rawCategories.map((e) => e.toString()).toList(growable: false);

    final rawClues = json['clues'];
    if (rawClues is! List || rawClues.isEmpty) {
      throw LogicGridContentException('clues must be a non-empty list');
    }
    final clueIds = <String>{};
    final clues = <LogicGridClue>[];
    for (final raw in rawClues) {
      final clue = LogicGridClue.fromJson(raw as Map<String, dynamic>);
      if (!clueIds.add(clue.id)) {
        throw LogicGridContentException(
          'Duplicate clue id: ${clue.id}',
        );
      }
      clues.add(clue);
    }

    final rawSolution = json['solution'];
    if (rawSolution is! List || rawSolution.isEmpty) {
      throw LogicGridContentException('solution must be a non-empty list');
    }
    final solution = rawSolution
        .map((e) => LogicGridPairing.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    return LogicGridContent(
      contentId: json['contentId'] as String,
      gameId: json['gameId'] as String,
      locale: json['locale'] as String,
      ageBand: json['ageBand'] as String,
      difficulty: difficulty,
      instruction: json['instruction'] as String,
      hint: json['hint'] as String?,
      categories: categories,
      clues: List.unmodifiable(clues),
      solution: solution,
      estimatedSeconds: json['estimatedSeconds'] as int? ?? 120,
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
        categories,
        clues,
        solution,
        estimatedSeconds,
      ];
}

class LogicGridContentException implements Exception {
  LogicGridContentException(this.message);
  final String message;

  @override
  String toString() => 'LogicGridContentException: $message';
}