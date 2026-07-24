/// Adaptive learning contract registry.
///
/// Defines all adaptive-related contracts including difficulty adjustment,
/// spaced repetition, learning paths, and personalization.
class AdaptiveContractMeta {
  final String contractId;
  final String name;
  final String semanticVersion;
  final String schemaVersion;
  final String owner;
  final String compatibility;
  final String description;
  final List<String> requiredFields;
  final List<String> forbiddenFields;

  const AdaptiveContractMeta({
    required this.contractId,
    required this.name,
    required this.semanticVersion,
    required this.schemaVersion,
    required this.owner,
    required this.compatibility,
    required this.description,
    required this.requiredFields,
    required this.forbiddenFields,
  });
}

/// Central registry of all adaptive learning contracts.
class AdaptiveContracts {
  static const _contracts = <AdaptiveContractMeta>[
    AdaptiveContractMeta(
      contractId: 'adaptive.difficulty_adjustment',
      name: 'DifficultyAdjustment',
      semanticVersion: '1.0.0',
      schemaVersion: '1.0.0',
      owner: 'adaptive_sdk',
      compatibility: 'backward',
      description: 'Difficulty adjustment decision from the adaptive engine.',
      requiredFields: [
        'adjustmentId',
        'childProfileId',
        'gameId',
        'levelId',
        'currentDifficulty',
        'recommendedDifficulty',
        'confidence',
        'direction',
      ],
      forbiddenFields: ['password', 'token', 'secret', 'email', 'child_name'],
    ),
    AdaptiveContractMeta(
      contractId: 'adaptive.spaced_repetition',
      name: 'SpacedRepetitionItem',
      semanticVersion: '1.0.0',
      schemaVersion: '1.0.0',
      owner: 'adaptive_sdk',
      compatibility: 'backward',
      description: 'Spaced repetition scheduling item (SM-2 based).',
      requiredFields: [
        'itemId',
        'childProfileId',
        'skillId',
        'contentId',
        'easeFactor',
        'interval',
        'repetitions',
        'nextReviewAt',
        'status',
      ],
      forbiddenFields: ['password', 'token', 'secret', 'email'],
    ),
    AdaptiveContractMeta(
      contractId: 'adaptive.learning_path',
      name: 'LearningPath',
      semanticVersion: '1.0.0',
      schemaVersion: '1.0.0',
      owner: 'adaptive_sdk',
      compatibility: 'backward',
      description: 'Adaptive learning path for a child.',
      requiredFields: [
        'pathId',
        'childProfileId',
        'ageGroup',
        'subject',
        'status',
      ],
      forbiddenFields: ['password', 'token', 'secret', 'email'],
    ),
    AdaptiveContractMeta(
      contractId: 'adaptive.learning_path_node',
      name: 'LearningPathNode',
      semanticVersion: '1.0.0',
      schemaVersion: '1.0.0',
      owner: 'adaptive_sdk',
      compatibility: 'backward',
      description: 'A single node in a learning path.',
      requiredFields: [
        'nodeId',
        'nodeType',
        'contentId',
        'title',
        'orderIndex',
        'status',
      ],
      forbiddenFields: ['password', 'token', 'secret', 'email'],
    ),
    AdaptiveContractMeta(
      contractId: 'adaptive.personalization_profile',
      name: 'PersonalizationProfile',
      semanticVersion: '1.0.0',
      schemaVersion: '1.0.0',
      owner: 'adaptive_sdk',
      compatibility: 'backward',
      description: 'Child learning preferences and behavioral patterns.',
      requiredFields: ['childProfileId', 'ageGroup'],
      forbiddenFields: [
        'password',
        'token',
        'secret',
        'email',
        'child_name',
        'location',
      ],
    ),
  ];

  static List<AdaptiveContractMeta> get all => List.unmodifiable(_contracts);

  static AdaptiveContractMeta? lookup(String contractId) {
    try {
      return _contracts.firstWhere((c) => c.contractId == contractId);
    } catch (_) {
      return null;
    }
  }

  static List<String> checkForbiddenFields(
    String contractId,
    Map<String, dynamic> data,
  ) {
    final contract = lookup(contractId);
    if (contract == null) return ['Unknown contract: $contractId'];

    final violations = <String>[];
    final lowerKeys = data.keys.map((k) => k.toLowerCase()).toList();
    for (final forbidden in contract.forbiddenFields) {
      if (lowerKeys.contains(forbidden.toLowerCase())) {
        violations.add('Forbidden field "$forbidden" in ${contract.name}');
      }
    }
    return violations;
  }
}
