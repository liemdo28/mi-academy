import 'package:equatable/equatable.dart';

/// How a [SequenceItem]'s [SequenceItem.content] should be rendered.
enum SequenceItemType { text, number, image }

/// One position in a sequence. [id] is unique within the sequence even
/// when two items share the same visible [content] (e.g. a repeating
/// pattern like red/blue/red/blue uses distinct IDs per occurrence) --
/// this is what lets "duplicate visible values with distinct IDs" work
/// without ambiguity.
class SequenceItem extends Equatable {
  const SequenceItem({
    required this.id,
    required this.content,
    this.type = SequenceItemType.text,
  });

  factory SequenceItem.fromJson(Map<String, dynamic> json) {
    return SequenceItem(
      id: json['id'] as String,
      content: json['content'] as String,
      type: _typeFromString(json['type'] as String?),
    );
  }

  final String id;
  final String content;
  final SequenceItemType type;

  static SequenceItemType _typeFromString(String? value) {
    switch (value) {
      case 'number':
        return SequenceItemType.number;
      case 'image':
        return SequenceItemType.image;
      default:
        return SequenceItemType.text;
    }
  }

  @override
  List<Object?> get props => [id, content, type];
}

/// How the correct order is determined and validated.
enum SequenceRuleType {
  /// The order is exactly [SequenceContent.correctOrder] -- no arithmetic
  /// relationship, just an authored answer key (e.g. a fixed
  /// picture-story order).
  fixed,

  /// Each numeric item is [step] more than the previous one.
  ascending,

  /// Each numeric item is [step] less than the previous one.
  descending,

  /// Steps alternate between [step] and -[step] (e.g. 2, 5, 3, 6, 4...).
  alternating,

  /// The sequence repeats a fixed-length cycle of values
  /// (`repeatingCycleLength` items), e.g. red/blue/red/blue.
  repeating,
}

class SequenceRule extends Equatable {
  const SequenceRule({
    required this.type,
    this.step,
    this.repeatingCycleLength,
  });

  factory SequenceRule.fromJson(Map<String, dynamic> json) {
    final type = _ruleTypeFromString(json['type'] as String);
    final step = json['step'] as int?;
    final cycleLength = json['repeatingCycleLength'] as int?;

    if ((type == SequenceRuleType.ascending ||
            type == SequenceRuleType.descending ||
            type == SequenceRuleType.alternating) &&
        (step == null || step == 0)) {
      throw SequenceContentException(
        'Rule type "${json['type']}" requires a non-zero "step"',
      );
    }
    if (type == SequenceRuleType.repeating &&
        (cycleLength == null || cycleLength < 1)) {
      throw SequenceContentException(
        'Rule type "repeating" requires a positive "repeatingCycleLength"',
      );
    }

    return SequenceRule(
      type: type,
      step: step,
      repeatingCycleLength: cycleLength,
    );
  }

  final SequenceRuleType type;
  final int? step;
  final int? repeatingCycleLength;

  static SequenceRuleType _ruleTypeFromString(String value) {
    switch (value) {
      case 'fixed':
        return SequenceRuleType.fixed;
      case 'ascending':
        return SequenceRuleType.ascending;
      case 'descending':
        return SequenceRuleType.descending;
      case 'alternating':
        return SequenceRuleType.alternating;
      case 'repeating':
        return SequenceRuleType.repeating;
      default:
        throw SequenceContentException('Unknown rule type: "$value"');
    }
  }

  @override
  List<Object?> get props => [type, step, repeatingCycleLength];
}

/// Which interaction the level uses.
enum SequenceMode {
  /// Child reorders every item from a scrambled presentation.
  reorder,

  /// Some positions are pre-filled; the child chooses the value(s) for
  /// the missing position(s) from [SequenceContent.choices].
  missingItem,
}

/// Typed content for one Sequence Engine level. Independent of `MiLevel`
/// (packages/mi_game_core) -- see docs/game-engine-architecture.md.
class SequenceContent extends Equatable {
  const SequenceContent({
    required this.contentId,
    required this.gameId,
    required this.locale,
    required this.ageBand,
    required this.difficulty,
    required this.instruction,
    required this.mode,
    required this.correctOrder,
    required this.rule,
    this.hint,
    this.missingIndices = const [],
    this.choices = const [],
    this.estimatedSeconds = 60,
  });

  final String contentId;
  final String gameId;
  final String locale;
  final String ageBand;
  final int difficulty;
  final String instruction;
  final String? hint;
  final SequenceMode mode;

  /// The authored correct order -- ground truth for both interaction
  /// modes. In [SequenceMode.reorder] this is what the child must
  /// reconstruct; in [SequenceMode.missingItem] it's used to check the
  /// chosen values at [missingIndices].
  final List<SequenceItem> correctOrder;

  final SequenceRule rule;

  /// 0-based positions in [correctOrder] that start blank in
  /// [SequenceMode.missingItem] (ignored in reorder mode).
  final List<int> missingIndices;

  /// Extra decoy items offered alongside the real missing value(s) in
  /// [SequenceMode.missingItem] (ignored in reorder mode).
  final List<SequenceItem> choices;

  final int estimatedSeconds;

  factory SequenceContent.fromJson(Map<String, dynamic> json) {
    final missing = <String>[
      for (final field in [
        'contentId',
        'gameId',
        'locale',
        'ageBand',
        'difficulty',
        'instruction',
        'mode',
        'correctOrder',
        'rule',
      ])
        if (!json.containsKey(field)) field,
    ];
    if (missing.isNotEmpty) {
      throw SequenceContentException('Missing required field(s): $missing');
    }

    final difficulty = json['difficulty'];
    if (difficulty is! int || difficulty < 1 || difficulty > 5) {
      throw SequenceContentException(
        'difficulty must be an integer 1-5, got $difficulty',
      );
    }

    final rawOrder = json['correctOrder'];
    if (rawOrder is! List || rawOrder.length < 2) {
      throw SequenceContentException(
        'correctOrder must be a list of at least 2 items',
      );
    }
    final order = <SequenceItem>[];
    final seenIds = <String>{};
    for (final raw in rawOrder) {
      final item = SequenceItem.fromJson(raw as Map<String, dynamic>);
      if (!seenIds.add(item.id)) {
        throw SequenceContentException('Duplicate item id: ${item.id}');
      }
      order.add(item);
    }

    final rule = SequenceRule.fromJson(json['rule'] as Map<String, dynamic>);
    _validateRuleAgainstOrder(rule, order);

    final mode = json['mode'] == 'missingItem'
        ? SequenceMode.missingItem
        : SequenceMode.reorder;

    final missingIndices =
        (json['missingIndices'] as List?)?.cast<int>() ?? const [];
    if (mode == SequenceMode.missingItem) {
      if (missingIndices.isEmpty) {
        throw SequenceContentException(
          'mode "missingItem" requires at least one entry in missingIndices',
        );
      }
      for (final index in missingIndices) {
        if (index < 0 || index >= order.length) {
          throw SequenceContentException(
            'missingIndices contains out-of-range index: $index',
          );
        }
      }
    }

    final choices = (json['choices'] as List?)
            ?.map((c) => SequenceItem.fromJson(c as Map<String, dynamic>))
            .toList() ??
        const [];

    return SequenceContent(
      contentId: json['contentId'] as String,
      gameId: json['gameId'] as String,
      locale: json['locale'] as String,
      ageBand: json['ageBand'] as String,
      difficulty: difficulty,
      instruction: json['instruction'] as String,
      hint: json['hint'] as String?,
      mode: mode,
      correctOrder: order,
      rule: rule,
      missingIndices: missingIndices,
      choices: choices,
      estimatedSeconds: json['estimatedSeconds'] as int? ?? 60,
    );
  }

  static void _validateRuleAgainstOrder(
    SequenceRule rule,
    List<SequenceItem> order,
  ) {
    if (rule.type == SequenceRuleType.fixed) return;

    final values = <int>[];
    for (final item in order) {
      final parsed = int.tryParse(item.content);
      if (parsed == null) {
        throw SequenceContentException(
          'Rule type "${rule.type.name}" requires numeric item content, '
          'got "${item.content}"',
        );
      }
      values.add(parsed);
    }

    switch (rule.type) {
      case SequenceRuleType.ascending:
        for (var i = 1; i < values.length; i++) {
          if (values[i] - values[i - 1] != rule.step) {
            throw SequenceContentException(
              'correctOrder does not match an ascending rule with '
              'step ${rule.step} at position $i',
            );
          }
        }
        break;
      case SequenceRuleType.descending:
        for (var i = 1; i < values.length; i++) {
          if (values[i - 1] - values[i] != rule.step) {
            throw SequenceContentException(
              'correctOrder does not match a descending rule with '
              'step ${rule.step} at position $i',
            );
          }
        }
        break;
      case SequenceRuleType.alternating:
        for (var i = 1; i < values.length; i++) {
          final expectedStep = (i.isOdd ? rule.step! : -rule.step!);
          if (values[i] - values[i - 1] != expectedStep) {
            throw SequenceContentException(
              'correctOrder does not match an alternating rule with '
              'step ${rule.step} at position $i',
            );
          }
        }
        break;
      case SequenceRuleType.repeating:
        final cycle = rule.repeatingCycleLength!;
        for (var i = cycle; i < values.length; i++) {
          if (values[i] != values[i - cycle]) {
            throw SequenceContentException(
              'correctOrder does not repeat with cycle length $cycle '
              'at position $i',
            );
          }
        }
        break;
      case SequenceRuleType.fixed:
        break;
    }
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
        mode,
        correctOrder,
        rule,
        missingIndices,
        choices,
        estimatedSeconds,
      ];
}

class SequenceContentException implements Exception {
  SequenceContentException(this.message);
  final String message;

  @override
  String toString() => 'SequenceContentException: $message';
}
