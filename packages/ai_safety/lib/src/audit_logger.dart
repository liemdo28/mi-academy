/// Audit logger for AI decisions.
///
/// Per blueprint §27: All AI decisions must be logged.
class AuditLogger {
  AuditLogger();

  void logMasteryEvaluation(MasteryAuditEntry entry) {
    _masteryEntries.add(entry);
  }

  void logRecommendation(RecommendationAuditEntry entry) {
    _recommendationEntries.add(entry);
  }

  void logContentGeneration(ContentGenerationAuditEntry entry) {
    _contentEntries.add(entry);
  }

  final List<MasteryAuditEntry> _masteryEntries = [];
  final List<RecommendationAuditEntry> _recommendationEntries = [];
  final List<ContentGenerationAuditEntry> _contentEntries = [];

  List<MasteryAuditEntry> get masteryEntries =>
      List.unmodifiable(_masteryEntries);
  List<RecommendationAuditEntry> get recommendationEntries =>
      List.unmodifiable(_recommendationEntries);
  List<ContentGenerationAuditEntry> get contentEntries =>
      List.unmodifiable(_contentEntries);
}

abstract class AIAuditEntry {
  DateTime get timestamp;
  String get modelId;
  String get action;
  Map<String, dynamic> toJson();
}

class MasteryAuditEntry implements AIAuditEntry {
  const MasteryAuditEntry({
    required this.timestamp,
    required this.modelId,
    required this.childId,
    required this.skillId,
    required this.action,
    required this.inputHash,
    required this.outputHash,
    required this.reasonCodes,
  });

  @override
  final DateTime timestamp;
  @override
  final String modelId;
  final String childId;
  final String skillId;
  @override
  final String action;
  final String inputHash;
  final String outputHash;
  final List<String> reasonCodes;

  @override
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'modelId': modelId,
        'childId': childId,
        'skillId': skillId,
        'action': action,
        'inputHash': inputHash,
        'outputHash': outputHash,
        'reasonCodes': reasonCodes,
        'auditType': 'mastery',
      };
}

class RecommendationAuditEntry implements AIAuditEntry {
  const RecommendationAuditEntry({
    required this.timestamp,
    required this.modelId,
    required this.childId,
    required this.action,
    required this.targetId,
    required this.reasonCodes,
    required this.engineVersion,
    this.fallbackUsed = false,
    this.latencyMs,
  });

  @override
  final DateTime timestamp;
  @override
  final String modelId;
  final String childId;
  @override
  final String action;
  final String targetId;
  final List<String> reasonCodes;
  final String engineVersion;
  final bool fallbackUsed;
  final int? latencyMs;

  @override
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'modelId': modelId,
        'childId': childId,
        'action': action,
        'targetId': targetId,
        'reasonCodes': reasonCodes,
        'engineVersion': engineVersion,
        'fallbackUsed': fallbackUsed,
        if (latencyMs != null) 'latencyMs': latencyMs,
        'auditType': 'recommendation',
      };
}

class ContentGenerationAuditEntry implements AIAuditEntry {
  const ContentGenerationAuditEntry({
    required this.timestamp,
    required this.modelId,
    required this.action,
    required this.promptVersion,
    required this.contentId,
    required this.lifecycleStatus,
    required this.validationPassed,
    this.humanReviewRequired = true,
    this.humanApproved = false,
  });

  @override
  final DateTime timestamp;
  @override
  final String modelId;
  @override
  final String action;
  final String promptVersion;
  final String contentId;
  final String lifecycleStatus;
  final bool validationPassed;
  final bool humanReviewRequired;
  final bool humanApproved;

  @override
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'modelId': modelId,
        'action': action,
        'promptVersion': promptVersion,
        'contentId': contentId,
        'lifecycleStatus': lifecycleStatus,
        'validationPassed': validationPassed,
        'humanReviewRequired': humanReviewRequired,
        'humanApproved': humanApproved,
        'auditType': 'content_generation',
      };
}
