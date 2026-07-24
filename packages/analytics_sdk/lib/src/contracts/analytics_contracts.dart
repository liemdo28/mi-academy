/// Analytics contract registry.
///
/// Defines all analytics-related contracts with version tracking
/// and forbidden field enforcement for child data protection.
class AnalyticsContractMeta {
  final String contractId;
  final String name;
  final String semanticVersion;
  final String schemaVersion;
  final String owner;
  final String compatibility;
  final String description;
  final List<String> requiredFields;
  final List<String> forbiddenFields;

  const AnalyticsContractMeta({
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

/// Central registry of all analytics contracts.
class AnalyticsContracts {
  static const _contracts = <AnalyticsContractMeta>[
    AnalyticsContractMeta(
      contractId: 'analytics.event',
      name: 'AnalyticsEvent',
      semanticVersion: '1.0.0',
      schemaVersion: '1.0.0',
      owner: 'analytics_sdk',
      compatibility: 'backward',
      description: 'Core analytics event tracked across the platform.',
      requiredFields: [
        'eventId',
        'eventType',
        'childProfileId',
        'sessionId',
        'timestamp',
      ],
      forbiddenFields: [
        'password',
        'token',
        'secret',
        'ssn',
        'credit_card',
        'email',
        'phone',
      ],
    ),
    AnalyticsContractMeta(
      contractId: 'analytics.session_summary',
      name: 'SessionSummary',
      semanticVersion: '1.0.0',
      schemaVersion: '1.0.0',
      owner: 'analytics_sdk',
      compatibility: 'backward',
      description: 'Aggregated session summary for reporting.',
      requiredFields: ['sessionId', 'childProfileId', 'startedAt', 'endedAt'],
      forbiddenFields: ['password', 'token', 'secret', 'email'],
    ),
    AnalyticsContractMeta(
      contractId: 'analytics.performance_report',
      name: 'PerformanceReport',
      semanticVersion: '1.0.0',
      schemaVersion: '1.0.0',
      owner: 'analytics_sdk',
      compatibility: 'backward',
      description: 'Period-based performance report for a child.',
      requiredFields: [
        'reportId',
        'childProfileId',
        'periodStart',
        'periodEnd',
        'periodType',
      ],
      forbiddenFields: ['password', 'token', 'secret', 'email'],
    ),
    AnalyticsContractMeta(
      contractId: 'analytics.engagement_metrics',
      name: 'EngagementMetrics',
      semanticVersion: '1.0.0',
      schemaVersion: '1.0.0',
      owner: 'analytics_sdk',
      compatibility: 'backward',
      description: 'Engagement and activity metrics for a child profile.',
      requiredFields: ['childProfileId', 'measuredAt'],
      forbiddenFields: ['password', 'token', 'secret', 'email'],
    ),
    AnalyticsContractMeta(
      contractId: 'analytics.skill_performance',
      name: 'SkillPerformance',
      semanticVersion: '1.0.0',
      schemaVersion: '1.0.0',
      owner: 'analytics_sdk',
      compatibility: 'backward',
      description: 'Per-skill performance metrics.',
      requiredFields: [
        'skillId',
        'skillName',
        'accuracy',
        'masteryLevel',
        'attemptsTotal',
        'attemptsCorrect',
      ],
      forbiddenFields: ['password', 'token', 'secret', 'email'],
    ),
  ];

  /// All registered analytics contracts.
  static List<AnalyticsContractMeta> get all => List.unmodifiable(_contracts);

  /// Look up a contract by contractId.
  static AnalyticsContractMeta? lookup(String contractId) {
    try {
      return _contracts.firstWhere((c) => c.contractId == contractId);
    } catch (_) {
      return null;
    }
  }

  /// Check if data contains any forbidden fields for the given contract.
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
