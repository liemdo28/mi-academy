import 'package:equatable/equatable.dart';

/// How the child confirms their selection.
enum MultiSelectSubmitMode {
  /// The child taps an explicit "submit"/"check" action.
  explicitSubmit,

  /// Submission happens automatically once the selection count reaches
  /// [MultiSelectConfiguration.expectedAnswerCount].
  autoSubmit,
}

/// How a submitted selection is scored.
enum MultiSelectEvaluationMode {
  /// The level completes only if the selected set exactly equals the
  /// correct set -- no partial credit, retry required otherwise.
  exactMatch,

  /// Any valid-size submission completes the level; the score is
  /// prorated by how many correct/incorrect options were selected.
  partialCredit,
}

/// What [MultiSelectController.retry] does to the current selection.
enum MultiSelectRetryMode {
  /// Keep the child's current selection -- they adjust it, not restart
  /// from nothing.
  preserveSelection,

  /// Clear the selection entirely -- a fresh attempt.
  clearSelection,
}

/// One selectable option in a Multi-select Engine level.
class MultiSelectOption extends Equatable {
  const MultiSelectOption({
    required this.id,
    required this.label,
    this.text,
    this.assetId,
    this.isCorrect = false,
    this.metadata = const {},
  });

  factory MultiSelectOption.fromJson(Map<String, dynamic> json) {
    for (final field in ['id', 'label']) {
      if (!json.containsKey(field) ||
          (json[field] as String?)?.isEmpty == true) {
        throw MultiSelectContentException(
          'Option is missing required field "$field"',
        );
      }
    }
    final text = json['text'] as String?;
    final assetId = json['assetId'] as String?;
    if ((text == null || text.isEmpty) &&
        (assetId == null || assetId.isEmpty)) {
      throw MultiSelectContentException(
        'Option "${json['id']}" has neither text nor assetId -- it would '
        'have no visible representation',
      );
    }
    if (assetId != null && assetId.isEmpty) {
      throw MultiSelectContentException(
        'Option "${json['id']}" has an empty assetId',
      );
    }
    return MultiSelectOption(
      id: json['id'] as String,
      label: json['label'] as String,
      text: text,
      assetId: assetId,
      isCorrect: json['isCorrect'] as bool? ?? false,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  final String id;
  final String label;
  final String? text;
  final String? assetId;
  final bool isCorrect;
  final Map<String, dynamic> metadata;

  @override
  List<Object?> get props => [id, label, text, assetId, isCorrect, metadata];
}

/// Global gameplay configuration for one [MultiSelectContent] level.
class MultiSelectConfiguration extends Equatable {
  const MultiSelectConfiguration({
    this.submitMode = MultiSelectSubmitMode.explicitSubmit,
    this.evaluationMode = MultiSelectEvaluationMode.exactMatch,
    this.minSelections = 1,
    required this.maxSelections,
    this.expectedAnswerCount,
    this.retryMode = MultiSelectRetryMode.clearSelection,
  });

  factory MultiSelectConfiguration.fromJson(
    Map<String, dynamic>? json,
    int optionCount,
  ) {
    final submitMode = json?['submitMode'] == 'autoSubmit'
        ? MultiSelectSubmitMode.autoSubmit
        : MultiSelectSubmitMode.explicitSubmit;
    final evaluationMode = json?['evaluationMode'] == 'partialCredit'
        ? MultiSelectEvaluationMode.partialCredit
        : MultiSelectEvaluationMode.exactMatch;
    final retryMode = json?['retryMode'] == 'preserveSelection'
        ? MultiSelectRetryMode.preserveSelection
        : MultiSelectRetryMode.clearSelection;
    final min = json?['minSelections'] as int? ?? 1;
    final max = json?['maxSelections'] as int? ?? optionCount;
    final expected = json?['expectedAnswerCount'] as int?;

    return MultiSelectConfiguration(
      submitMode: submitMode,
      evaluationMode: evaluationMode,
      minSelections: min,
      maxSelections: max,
      expectedAnswerCount: expected,
      retryMode: retryMode,
    );
  }

  final MultiSelectSubmitMode submitMode;
  final MultiSelectEvaluationMode evaluationMode;
  final int minSelections;
  final int maxSelections;

  /// The number of selections a submit is expected to contain. Required
  /// (and validated) when [submitMode] is [MultiSelectSubmitMode.autoSubmit];
  /// optional otherwise, used only to display "Select N answers" to the
  /// child.
  final int? expectedAnswerCount;
  final MultiSelectRetryMode retryMode;

  @override
  List<Object?> get props => [
        submitMode,
        evaluationMode,
        minSelections,
        maxSelections,
        expectedAnswerCount,
        retryMode,
      ];
}

/// Typed content for one Multi-select Engine level -- the fourth and
/// final Milestone 1 WS5 shared engine, alongside Matching, Sequence,
/// and Placement. Independent of `MiLevel` (packages/mi_game_core), same
/// rationale as the other three: real internal structure (typed
/// options + configuration), not an opaque `Map<String, dynamic>`.
class MultiSelectContent extends Equatable {
  const MultiSelectContent({
    required this.contentId,
    required this.gameId,
    required this.locale,
    required this.ageBand,
    required this.difficulty,
    required this.instruction,
    required this.options,
    this.hint,
    this.configuration = const MultiSelectConfiguration(maxSelections: 1),
    this.estimatedSeconds = 60,
    this.schemaVersion = '1.0',
  });

  static const supportedSchemaVersions = {'1.0'};

  final String contentId;
  final String gameId;
  final String locale;
  final String ageBand;
  final int difficulty;
  final String instruction;
  final String? hint;
  final List<MultiSelectOption> options;
  final MultiSelectConfiguration configuration;
  final int estimatedSeconds;
  final String schemaVersion;

  List<MultiSelectOption> get correctOptions =>
      options.where((o) => o.isCorrect).toList();

  Set<String> get correctIds => correctOptions.map((o) => o.id).toSet();

  /// Parses and validates [json], throwing [MultiSelectContentException]
  /// with an actionable message for any malformed or logically
  /// impossible content, rather than a bare cast failure or a later
  /// assertion.
  factory MultiSelectContent.fromJson(Map<String, dynamic> json) {
    final contentId = json['contentId'] as String? ?? '(unknown)';
    void fail(String message) =>
        throw MultiSelectContentException('[$contentId] $message');

    final missing = <String>[
      for (final field in [
        'contentId',
        'gameId',
        'locale',
        'ageBand',
        'difficulty',
        'instruction',
        'options',
      ])
        if (!json.containsKey(field)) field,
    ];
    if (missing.isNotEmpty) fail('Missing required field(s): $missing');

    final schemaVersion = json['schemaVersion'] as String? ?? '1.0';
    if (!supportedSchemaVersions.contains(schemaVersion)) {
      fail('Unsupported schemaVersion: $schemaVersion');
    }

    final difficulty = json['difficulty'];
    if (difficulty is! int || difficulty < 1 || difficulty > 5) {
      fail('difficulty must be an integer 1-5, got $difficulty');
    }

    final rawOptions = json['options'] as List?;
    if (rawOptions == null || rawOptions.isEmpty) {
      fail('options must be a non-empty list');
    }

    final options = <MultiSelectOption>[];
    final seenIds = <String>{};
    for (final raw in rawOptions!) {
      final MultiSelectOption option;
      try {
        option = MultiSelectOption.fromJson(raw as Map<String, dynamic>);
      } on MultiSelectContentException catch (e) {
        fail(e.message);
        rethrow;
      }
      if (!seenIds.add(option.id)) {
        fail('Duplicate option id: ${option.id}');
      }
      options.add(option);
    }

    final correctCount = options.where((o) => o.isCorrect).length;
    if (correctCount == 0) {
      fail('At least one option must be marked correct');
    }

    final configuration = MultiSelectConfiguration.fromJson(
      json['configuration'] as Map<String, dynamic>?,
      options.length,
    );

    if (configuration.minSelections < 1) {
      fail('minSelections must be at least 1');
    }
    if (configuration.maxSelections < configuration.minSelections) {
      fail(
        'maxSelections (${configuration.maxSelections}) must be >= '
        'minSelections (${configuration.minSelections})',
      );
    }
    if (configuration.maxSelections > options.length) {
      fail(
        'maxSelections (${configuration.maxSelections}) exceeds the number '
        'of options (${options.length})',
      );
    }
    if (configuration.minSelections > options.length) {
      fail(
        'Impossible completion: minSelections (${configuration.minSelections}) '
        'exceeds the number of options (${options.length})',
      );
    }

    // Impossible completion: exact-match mode can never be satisfied if
    // the correct-answer count itself falls outside the configured
    // min/max selection window.
    if (configuration.evaluationMode == MultiSelectEvaluationMode.exactMatch) {
      if (correctCount < configuration.minSelections ||
          correctCount > configuration.maxSelections) {
        fail(
          'Impossible completion: exactMatch requires selecting exactly '
          'the $correctCount correct option(s), which falls outside the '
          'configured range [${configuration.minSelections}, '
          '${configuration.maxSelections}]',
        );
      }
    }

    if (configuration.submitMode == MultiSelectSubmitMode.autoSubmit) {
      final expected = configuration.expectedAnswerCount;
      if (expected == null) {
        fail('autoSubmit requires configuration.expectedAnswerCount to be set');
      } else if (expected < configuration.minSelections ||
          expected > configuration.maxSelections) {
        fail(
          'expectedAnswerCount ($expected) must fall within '
          '[${configuration.minSelections}, ${configuration.maxSelections}] '
          'for autoSubmit',
        );
      }
    }

    return MultiSelectContent(
      contentId: json['contentId'] as String,
      gameId: json['gameId'] as String,
      locale: json['locale'] as String,
      ageBand: json['ageBand'] as String,
      difficulty: difficulty as int,
      instruction: json['instruction'] as String,
      hint: json['hint'] as String?,
      options: options,
      configuration: configuration,
      estimatedSeconds: json['estimatedSeconds'] as int? ?? 60,
      schemaVersion: schemaVersion,
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
        options,
        configuration,
        estimatedSeconds,
        schemaVersion,
      ];
}

class MultiSelectContentException implements Exception {
  MultiSelectContentException(this.message);
  final String message;

  @override
  String toString() => 'MultiSelectContentException: $message';
}
