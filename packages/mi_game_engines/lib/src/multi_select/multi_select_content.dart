import 'package:equatable/equatable.dart';

enum MultiSelectSubmissionMode { explicitSubmit, autoSubmit }

typedef MultiSelectSubmitMode = MultiSelectSubmissionMode;

enum MultiSelectEvaluationMode { exactMatch, partialCredit }

enum MultiSelectRetryMode { preserveSelection, clearSelection }

enum MultiSelectHintMode {
  authoredHint,
  revealCorrectOption,
  eliminateIncorrectOption,
  expectedSelectionCount,
}

class MultiSelectValidationError extends Equatable {
  const MultiSelectValidationError({
    required this.contentId,
    required this.field,
    required this.code,
    required this.reason,
    this.optionId,
  });

  final String contentId;
  final String field;
  final String code;
  final String reason;
  final String? optionId;

  @override
  List<Object?> get props => [contentId, field, code, reason, optionId];

  @override
  String toString() {
    final option = optionId == null ? '' : ' optionId=$optionId';
    return '[$contentId] $code field=$field$option: $reason';
  }
}

class MultiSelectValidationResult extends Equatable {
  const MultiSelectValidationResult(this.errors);

  final List<MultiSelectValidationError> errors;
  bool get isValid => errors.isEmpty;

  @override
  List<Object?> get props => [errors];
}

class MultiSelectOption extends Equatable {
  const MultiSelectOption({
    required this.id,
    required this.label,
    this.text,
    this.semanticLabel,
    this.assetId,
    this.isCorrect = false,
    this.explanation,
    this.metadata = const {},
  });

  factory MultiSelectOption.fromJson(Map<String, dynamic> json) =>
      MultiSelectOption(
        id: json['id'] as String,
        label: json['label'] as String,
        text: json['text'] as String?,
        semanticLabel: json['semanticLabel'] as String?,
        assetId: json['assetId'] as String?,
        isCorrect: json['isCorrect'] as bool? ?? false,
        explanation: json['explanation'] as String?,
        metadata:
            (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

  final String id;
  final String label;
  final String? text;
  final String? semanticLabel;
  final String? assetId;
  final bool isCorrect;
  final String? explanation;
  final Map<String, dynamic> metadata;

  String get displayText => (text?.isNotEmpty ?? false) ? text! : label;
  String get accessibleLabel =>
      (semanticLabel?.isNotEmpty ?? false) ? semanticLabel! : label;
  bool get hasAsset => assetId != null && assetId!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        label,
        text,
        semanticLabel,
        assetId,
        isCorrect,
        explanation,
        metadata,
      ];
}

class MultiSelectConfiguration extends Equatable {
  const MultiSelectConfiguration({
    this.submissionMode = MultiSelectSubmissionMode.explicitSubmit,
    this.evaluationMode = MultiSelectEvaluationMode.exactMatch,
    this.shuffleOptions = true,
    this.shuffleSeed,
    this.minimumSelections = 1,
    required this.maximumSelections,
    this.allowDeselect = true,
    this.allowRetry = true,
    this.retryMode = MultiSelectRetryMode.clearSelection,
    this.maxAttempts = 3,
    this.revealCorrectAnswers = true,
    this.showSelectionCount = true,
    this.autoSubmitSelectionCount,
    this.hintModes = const [
      MultiSelectHintMode.expectedSelectionCount,
      MultiSelectHintMode.authoredHint,
      MultiSelectHintMode.revealCorrectOption,
      MultiSelectHintMode.eliminateIncorrectOption,
    ],
    this.incorrectSelectionPenalty = 0.5,
    this.attemptPenalty = 10,
    this.hintPenalty = 5,
  });

  factory MultiSelectConfiguration.fromJson(
    Map<String, dynamic>? json,
    int optionCount,
  ) {
    final submissionMode = _submissionMode(
      json?['submissionMode'] as String? ?? json?['submitMode'] as String?,
    );
    final evaluationMode = _evaluationMode(json?['evaluationMode'] as String?);
    final retryMode = _retryMode(json?['retryMode'] as String?);
    final rawHintMode = json?['hintMode'];
    final hintModes = rawHintMode is List
        ? rawHintMode
            .map((value) => _hintMode(value as String?))
            .whereType<MultiSelectHintMode>()
            .toList()
        : [
            if (_hintMode(rawHintMode as String?) != null)
              _hintMode(rawHintMode)!,
          ];

    return MultiSelectConfiguration(
      submissionMode: submissionMode,
      evaluationMode: evaluationMode,
      shuffleOptions: json?['shuffleOptions'] as bool? ?? true,
      shuffleSeed: json?['shuffleSeed'] as int?,
      minimumSelections: json?['minimumSelections'] as int? ??
          json?['minSelections'] as int? ??
          1,
      maximumSelections: json?['maximumSelections'] as int? ??
          json?['maxSelections'] as int? ??
          optionCount,
      allowDeselect: json?['allowDeselect'] as bool? ?? true,
      allowRetry: json?['allowRetry'] as bool? ?? true,
      retryMode: retryMode,
      maxAttempts: json?['maxAttempts'] as int? ?? 3,
      revealCorrectAnswers: json?['revealCorrectAnswers'] as bool? ?? true,
      showSelectionCount: json?['showSelectionCount'] as bool? ?? true,
      autoSubmitSelectionCount: json?['autoSubmitSelectionCount'] as int? ??
          json?['expectedAnswerCount'] as int?,
      hintModes: hintModes.isEmpty
          ? const [
              MultiSelectHintMode.expectedSelectionCount,
              MultiSelectHintMode.authoredHint,
              MultiSelectHintMode.revealCorrectOption,
              MultiSelectHintMode.eliminateIncorrectOption,
            ]
          : hintModes,
      incorrectSelectionPenalty:
          (json?['incorrectSelectionPenalty'] as num?)?.toDouble() ?? 0.5,
      attemptPenalty: json?['attemptPenalty'] as int? ?? 10,
      hintPenalty: json?['hintPenalty'] as int? ?? 5,
    );
  }

  final MultiSelectSubmissionMode submissionMode;
  MultiSelectSubmissionMode get submitMode => submissionMode;
  final MultiSelectEvaluationMode evaluationMode;
  final bool shuffleOptions;
  final int? shuffleSeed;
  final int minimumSelections;
  int get minSelections => minimumSelections;
  final int maximumSelections;
  int get maxSelections => maximumSelections;
  final bool allowDeselect;
  final bool allowRetry;
  final MultiSelectRetryMode retryMode;
  final int maxAttempts;
  final bool revealCorrectAnswers;
  final bool showSelectionCount;
  final int? autoSubmitSelectionCount;
  int? get expectedAnswerCount => autoSubmitSelectionCount;
  final List<MultiSelectHintMode> hintModes;
  final double incorrectSelectionPenalty;
  final int attemptPenalty;
  final int hintPenalty;

  @override
  List<Object?> get props => [
        submissionMode,
        evaluationMode,
        shuffleOptions,
        shuffleSeed,
        minimumSelections,
        maximumSelections,
        allowDeselect,
        allowRetry,
        retryMode,
        maxAttempts,
        revealCorrectAnswers,
        showSelectionCount,
        autoSubmitSelectionCount,
        hintModes,
        incorrectSelectionPenalty,
        attemptPenalty,
        hintPenalty,
      ];
}

class MultiSelectContent extends Equatable {
  const MultiSelectContent({
    required this.contentId,
    required this.gameId,
    required this.locale,
    required this.ageBand,
    required this.difficulty,
    required this.instruction,
    required this.prompt,
    required this.options,
    this.hint,
    this.configuration = const MultiSelectConfiguration(maximumSelections: 1),
    this.metadata = const {},
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
  final String prompt;
  final String? hint;
  final List<MultiSelectOption> options;
  final MultiSelectConfiguration configuration;
  final Map<String, dynamic> metadata;
  final int estimatedSeconds;
  final String schemaVersion;

  List<MultiSelectOption> get correctOptions =>
      options.where((o) => o.isCorrect).toList();

  Set<String> get correctIds => correctOptions.map((o) => o.id).toSet();

  factory MultiSelectContent.fromJson(Map<String, dynamic> json) {
    final result = MultiSelectContentValidator.validateJson(json);
    if (!result.isValid) {
      throw MultiSelectContentException(result.errors);
    }
    final rawOptions = json['options'] as List;
    final options = [
      for (final raw in rawOptions)
        MultiSelectOption.fromJson((raw as Map).cast<String, dynamic>()),
    ];
    return MultiSelectContent(
      contentId: json['contentId'] as String,
      gameId: json['gameId'] as String,
      locale: json['locale'] as String,
      ageBand: json['ageBand'] as String,
      difficulty: json['difficulty'] as int,
      instruction: json['instruction'] as String,
      prompt: json['prompt'] as String? ?? json['instruction'] as String,
      hint: json['hint'] as String?,
      options: options,
      configuration: MultiSelectConfiguration.fromJson(
        json['configuration'] as Map<String, dynamic>?,
        options.length,
      ),
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      estimatedSeconds: json['estimatedSeconds'] as int? ?? 60,
      schemaVersion: json['schemaVersion'] as String? ?? '1.0',
    );
  }

  MultiSelectValidationResult validate() =>
      MultiSelectContentValidator.validate(this);

  @override
  List<Object?> get props => [
        contentId,
        gameId,
        locale,
        ageBand,
        difficulty,
        instruction,
        prompt,
        hint,
        options,
        configuration,
        metadata,
        estimatedSeconds,
        schemaVersion,
      ];
}

class MultiSelectContentValidator {
  static MultiSelectValidationResult validateJson(Map<String, dynamic> json) {
    final errors = <MultiSelectValidationError>[];
    final contentId = (json['contentId'] as String?) ?? '(unknown)';
    void add(String field, String code, String reason, {String? optionId}) {
      errors.add(
        MultiSelectValidationError(
          contentId: contentId,
          field: field,
          code: code,
          reason: reason,
          optionId: optionId,
        ),
      );
    }

    final required = [
      'contentId',
      'gameId',
      'locale',
      'ageBand',
      'difficulty',
      'instruction',
      'prompt',
      'options',
    ];
    for (final field in required) {
      if (!json.containsKey(field)) {
        add(field, 'missing_required_field', 'Required field is missing.');
      }
    }
    if (errors.isNotEmpty) return MultiSelectValidationResult(errors);

    for (final field in ['contentId', 'gameId', 'locale', 'ageBand']) {
      if (!_isNonBlankString(json[field])) {
        add(
          field,
          'blank_required_field',
          '$field must be a non-empty string.',
        );
      }
    }
    if (!_isNonBlankString(json['instruction'])) {
      add(
        'instruction',
        'blank_instruction',
        'instruction must be a non-empty string.',
      );
    }
    if (!_isNonBlankString(json['prompt'])) {
      add('prompt', 'blank_prompt', 'prompt must be a non-empty string.');
    }
    final schemaVersion = json['schemaVersion'] as String? ?? '1.0';
    if (!MultiSelectContent.supportedSchemaVersions.contains(schemaVersion)) {
      add(
        'schemaVersion',
        'unsupported_schema_version',
        'Unsupported schemaVersion: $schemaVersion.',
      );
    }
    final difficulty = json['difficulty'];
    if (difficulty is! int || difficulty < 1 || difficulty > 5) {
      add(
        'difficulty',
        'invalid_difficulty',
        'difficulty must be an integer between 1 and 5.',
      );
    }

    final rawOptions = json['options'];
    if (rawOptions is! List || rawOptions.isEmpty) {
      add('options', 'empty_options', 'options must be a non-empty list.');
      return MultiSelectValidationResult(errors);
    }

    final seenIds = <String>{};
    final seenVisible = <String>{};
    final options = <MultiSelectOption>[];
    for (var index = 0; index < rawOptions.length; index++) {
      final raw = rawOptions[index];
      if (raw is! Map) {
        add(
          'options[$index]',
          'invalid_option_shape',
          'Each option must be a JSON object.',
        );
        continue;
      }
      final optionJson = raw.cast<String, dynamic>();
      final optionId = optionJson['id'] as String?;
      if (!_isNonBlankString(optionId)) {
        add(
          'options[$index].id',
          'blank_option_id',
          'Option id must be a non-empty string.',
        );
        continue;
      }
      if (!seenIds.add(optionId!)) {
        add(
          'options.id',
          'duplicate_option_id',
          'Option ids must be unique.',
          optionId: optionId,
        );
      }
      if (!_isNonBlankString(optionJson['label'])) {
        add(
          'options[$index].label',
          'blank_option_label',
          'Option label must be a non-empty string.',
          optionId: optionId,
        );
      }
      final text = optionJson['text'] as String?;
      final assetId = optionJson['assetId'] as String?;
      final semanticLabel = optionJson['semanticLabel'] as String?;
      if ((text == null || text.trim().isEmpty) &&
          (assetId == null || assetId.trim().isEmpty)) {
        add(
          'options[$index]',
          'option_without_visible_content',
          'Option must provide text or assetId.',
          optionId: optionId,
        );
      }
      if (assetId != null && assetId.trim().isEmpty) {
        add(
          'options[$index].assetId',
          'blank_asset_id',
          'assetId must be non-empty when supplied.',
          optionId: optionId,
        );
      }
      if ((assetId?.trim().isNotEmpty ?? false) &&
          (text == null || text.trim().isEmpty) &&
          !_isNonBlankString(semanticLabel)) {
        add(
          'options[$index].semanticLabel',
          'image_only_option_missing_semantic_label',
          'Image-only options require semanticLabel.',
          optionId: optionId,
        );
      }
      if ((assetId?.isNotEmpty ?? false) &&
          !RegExp(r'^[a-zA-Z0-9_./-]+$').hasMatch(assetId!)) {
        add(
          'options[$index].assetId',
          'unsupported_asset_reference',
          'assetId contains unsupported characters.',
          optionId: optionId,
        );
      }
      if (optionJson['isCorrect'] != null && optionJson['isCorrect'] is! bool) {
        add(
          'options[$index].isCorrect',
          'invalid_correct_flag',
          'isCorrect must be a boolean.',
          optionId: optionId,
        );
      }
      final visibleKey = '${(text ?? '').trim()}|'
          '${(assetId ?? '').trim()}|${(semanticLabel ?? '').trim()}';
      if (!seenVisible.add(visibleKey)) {
        add(
          'options[$index]',
          'duplicate_visible_option',
          'Visible option content must be distinguishable.',
          optionId: optionId,
        );
      }
      if (!errors.any((e) => e.optionId == optionId)) {
        options.add(MultiSelectOption.fromJson(optionJson));
      }
    }

    if (options.where((o) => o.isCorrect).isEmpty) {
      add(
        'options',
        'no_correct_option',
        'At least one option must be marked correct.',
      );
    }
    final configuration = MultiSelectConfiguration.fromJson(
      json['configuration'] as Map<String, dynamic>?,
      rawOptions.length,
    );
    errors.addAll(
      _validateConfiguration(
        contentId,
        configuration,
        optionCount: rawOptions.length,
        correctCount: options.where((o) => o.isCorrect).length,
      ),
    );
    return MultiSelectValidationResult(errors);
  }

  static MultiSelectValidationResult validate(MultiSelectContent content) {
    final errors = <MultiSelectValidationError>[];
    errors.addAll(
      _validateConfiguration(
        content.contentId,
        content.configuration,
        optionCount: content.options.length,
        correctCount: content.correctOptions.length,
      ),
    );
    return MultiSelectValidationResult(errors);
  }

  static List<MultiSelectValidationError> _validateConfiguration(
    String contentId,
    MultiSelectConfiguration config, {
    required int optionCount,
    required int correctCount,
  }) {
    final errors = <MultiSelectValidationError>[];
    void add(String field, String code, String reason) {
      errors.add(
        MultiSelectValidationError(
          contentId: contentId,
          field: field,
          code: code,
          reason: reason,
        ),
      );
    }

    if (config.minimumSelections < 0) {
      add(
        'configuration.minimumSelections',
        'negative_minimum_selection_count',
        'minimumSelections cannot be negative.',
      );
    }
    if (config.minimumSelections < 1) {
      add(
        'configuration.minimumSelections',
        'minimum_selection_below_one',
        'minimumSelections must be at least 1.',
      );
    }
    if (config.maximumSelections < 1) {
      add(
        'configuration.maximumSelections',
        'maximum_selection_below_one',
        'maximumSelections must be at least 1.',
      );
    }
    if (config.minimumSelections > config.maximumSelections) {
      add(
        'configuration',
        'minimum_greater_than_maximum',
        'minimumSelections must not exceed maximumSelections.',
      );
    }
    if (config.maximumSelections > optionCount) {
      add(
        'configuration.maximumSelections',
        'maximum_selection_exceeds_option_count',
        'maximumSelections cannot exceed option count.',
      );
    }
    if (config.evaluationMode == MultiSelectEvaluationMode.exactMatch) {
      if (config.maximumSelections < correctCount) {
        add(
          'configuration.maximumSelections',
          'exact_match_maximum_below_correct_count',
          'Exact match cannot succeed when maximumSelections is below the correct answer count.',
        );
      }
      if (config.minimumSelections > correctCount) {
        add(
          'configuration.minimumSelections',
          'exact_match_minimum_above_correct_count',
          'Exact match cannot succeed when minimumSelections is above the correct answer count.',
        );
      }
    }
    if (config.submissionMode == MultiSelectSubmissionMode.autoSubmit) {
      final count = config.autoSubmitSelectionCount;
      if (count == null) {
        add(
          'configuration.autoSubmitSelectionCount',
          'missing_auto_submit_count',
          'autoSubmit requires autoSubmitSelectionCount.',
        );
      } else {
        if (count < config.minimumSelections || count < 1) {
          add(
            'configuration.autoSubmitSelectionCount',
            'invalid_auto_submit_count',
            'autoSubmitSelectionCount must meet minimumSelections.',
          );
        }
        if (count > optionCount) {
          add(
            'configuration.autoSubmitSelectionCount',
            'auto_submit_count_exceeds_option_count',
            'autoSubmitSelectionCount cannot exceed option count.',
          );
        }
        if (count > config.maximumSelections) {
          add(
            'configuration.autoSubmitSelectionCount',
            'auto_submit_count_exceeds_maximum',
            'autoSubmitSelectionCount cannot exceed maximumSelections.',
          );
        }
        if (config.evaluationMode == MultiSelectEvaluationMode.exactMatch &&
            count != correctCount) {
          add(
            'configuration.autoSubmitSelectionCount',
            'auto_submit_exact_match_incompatible',
            'autoSubmit exact match requires the count to equal the correct answer count.',
          );
        }
      }
    }
    if (config.maxAttempts < 1) {
      add(
        'configuration.maxAttempts',
        'invalid_max_attempt_count',
        'maxAttempts must be at least 1.',
      );
    }
    if (config.allowRetry && config.maxAttempts < 2) {
      add(
        'configuration',
        'contradictory_retry_configuration',
        'allowRetry requires maxAttempts of at least 2.',
      );
    }
    if (!config.revealCorrectAnswers &&
        config.evaluationMode == MultiSelectEvaluationMode.exactMatch &&
        config.maxAttempts < 1) {
      add(
        'configuration.revealCorrectAnswers',
        'unreachable_terminal_reveal_configuration',
        'Reveal configuration must not create an unreachable terminal state.',
      );
    }
    if (config.incorrectSelectionPenalty < 0 ||
        config.incorrectSelectionPenalty > 1) {
      add(
        'configuration.incorrectSelectionPenalty',
        'invalid_penalty_range',
        'incorrectSelectionPenalty must be between 0 and 1.',
      );
    }
    if (config.attemptPenalty < 0 || config.attemptPenalty > 100) {
      add(
        'configuration.attemptPenalty',
        'invalid_penalty_range',
        'attemptPenalty must be between 0 and 100.',
      );
    }
    if (config.hintPenalty < 0 || config.hintPenalty > 100) {
      add(
        'configuration.hintPenalty',
        'invalid_penalty_range',
        'hintPenalty must be between 0 and 100.',
      );
    }
    if (correctCount == 0 || optionCount == 0) {
      add(
        'configuration',
        'impossible_completion_state',
        'Content must contain options and at least one correct answer.',
      );
    }
    return errors;
  }
}

class MultiSelectContentException implements Exception {
  MultiSelectContentException(this.errors);

  final List<MultiSelectValidationError> errors;
  String get message => errors.map((error) => error.toString()).join('\n');

  @override
  String toString() => 'MultiSelectContentException: $message';
}

bool _isNonBlankString(Object? value) =>
    value is String && value.trim().isNotEmpty;

MultiSelectSubmissionMode _submissionMode(String? value) =>
    value == 'autoSubmit'
        ? MultiSelectSubmissionMode.autoSubmit
        : MultiSelectSubmissionMode.explicitSubmit;

MultiSelectEvaluationMode _evaluationMode(String? value) =>
    value == 'partialCredit'
        ? MultiSelectEvaluationMode.partialCredit
        : MultiSelectEvaluationMode.exactMatch;

MultiSelectRetryMode _retryMode(String? value) => value == 'preserveSelection'
    ? MultiSelectRetryMode.preserveSelection
    : MultiSelectRetryMode.clearSelection;

MultiSelectHintMode? _hintMode(String? value) => switch (value) {
      'authoredHint' => MultiSelectHintMode.authoredHint,
      'revealCorrectOption' => MultiSelectHintMode.revealCorrectOption,
      'eliminateIncorrectOption' =>
        MultiSelectHintMode.eliminateIncorrectOption,
      'expectedSelectionCount' => MultiSelectHintMode.expectedSelectionCount,
      _ => null,
    };
