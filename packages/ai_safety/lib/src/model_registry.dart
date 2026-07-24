import 'package:equatable/equatable.dart';

/// Model registry entry.
///
/// Per blueprint §21: Every model or rule must be registered.
class ModelRegistry {
  const ModelRegistry();

  static final Map<String, ModelEntry> _registry = {};

  /// Register a new model version.
  void register(ModelEntry entry) {
    _registry[entry.modelId] = entry;
  }

  /// Get a model by ID.
  ModelEntry? get(String modelId) => _registry[modelId];

  /// Get all active models.
  List<ModelEntry> get activeModels => _registry.values
      .where((m) => m.status == ModelStatus.production)
      .toList();

  /// Get all models in a specific status.
  List<ModelEntry> getByStatus(ModelStatus status) =>
      _registry.values.where((m) => m.status == status).toList();
}

/// Entry in the model registry.
class ModelEntry extends Equatable {
  const ModelEntry({
    required this.modelId,
    required this.type,
    required this.version,
    required this.status,
    required this.owner,
    this.approvedAt,
    this.evaluationDataset,
    this.fallbackModelId,
    this.description,
    this.tags = const [],
  });

  final String modelId;
  final ModelType type;
  final String version;
  final ModelStatus status;
  final String owner;
  final DateTime? approvedAt;
  final String? evaluationDataset;
  final String? fallbackModelId;
  final String? description;
  final List<String> tags;

  @override
  List<Object?> get props => [
        modelId,
        type,
        version,
        status,
        owner,
        approvedAt,
        evaluationDataset,
        fallbackModelId,
        description,
        tags,
      ];

  Map<String, dynamic> toJson() => {
        'modelId': modelId,
        'type': type.value,
        'version': version,
        'status': status.value,
        'owner': owner,
        if (approvedAt != null) 'approvedAt': approvedAt!.toIso8601String(),
        if (evaluationDataset != null) 'evaluationDataset': evaluationDataset,
        if (fallbackModelId != null) 'fallbackModelId': fallbackModelId,
        if (description != null) 'description': description,
        'tags': tags,
      };
}

enum ModelType {
  deterministicRule,
  statisticalModel,
  generativeAI,
  hybrid,
}

extension ModelTypeExtension on ModelType {
  String get value {
    switch (this) {
      case ModelType.deterministicRule:
        return 'deterministic_rule';
      case ModelType.statisticalModel:
        return 'statistical_model';
      case ModelType.generativeAI:
        return 'generative_ai';
      case ModelType.hybrid:
        return 'hybrid';
    }
  }
}

enum ModelStatus {
  experimental,
  shadow,
  canary,
  production,
  deprecated,
  disabled,
}

extension ModelStatusExtension on ModelStatus {
  String get value {
    switch (this) {
      case ModelStatus.experimental:
        return 'experimental';
      case ModelStatus.shadow:
        return 'shadow';
      case ModelStatus.canary:
        return 'canary';
      case ModelStatus.production:
        return 'production';
      case ModelStatus.deprecated:
        return 'deprecated';
      case ModelStatus.disabled:
        return 'disabled';
    }
  }
}

/// Pre-seeded registry entries for MVP.
class DefaultModelRegistry {
  static List<ModelEntry> get entries => [
        const ModelEntry(
          modelId: 'mastery-rule-v1',
          type: ModelType.deterministicRule,
          version: '1.0.0',
          status: ModelStatus.experimental,
          owner: 'adaptive-team',
          description:
              'Rule-based mastery calculation with weighted evidence components',
          tags: ['mastery', 'skill', 'offline'],
        ),
        const ModelEntry(
          modelId: 'recommendation-rule-v1',
          type: ModelType.deterministicRule,
          version: '1.0.0',
          status: ModelStatus.experimental,
          owner: 'adaptive-team',
          description:
              'Deterministic recommendation engine with prerequisite enforcement',
          tags: ['recommendation', 'prerequisite', 'offline'],
        ),
        const ModelEntry(
          modelId: 'session-planner-v1',
          type: ModelType.deterministicRule,
          version: '1.0.0',
          status: ModelStatus.experimental,
          owner: 'adaptive-team',
          description: 'Daily session composition planner',
          tags: ['session', 'planning'],
        ),
        const ModelEntry(
          modelId: 'spaced-repetition-rule-v1',
          type: ModelType.deterministicRule,
          version: '1.0.0',
          status: ModelStatus.experimental,
          owner: 'adaptive-team',
          description: 'Spaced repetition interval scheduler',
          tags: ['spaced-repetition', 'retention'],
        ),
        const ModelEntry(
          modelId: 'struggle-detection-rule-v1',
          type: ModelType.deterministicRule,
          version: '1.0.0',
          status: ModelStatus.experimental,
          owner: 'adaptive-team',
          description: 'Signal-based struggle detection from session evidence',
          tags: ['struggle', 'detection', 'signals'],
        ),
        const ModelEntry(
          modelId: 'difficulty-rule-v1',
          type: ModelType.deterministicRule,
          version: '1.0.0',
          status: ModelStatus.experimental,
          owner: 'adaptive-team',
          description: 'Difficulty adjustment based on mastery and history',
          tags: ['difficulty', 'adjustment'],
        ),
      ];
}
