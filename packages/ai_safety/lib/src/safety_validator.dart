/// Safety validator for AI outputs and inputs.
///
/// Per blueprint §27: Required safety controls.
class SafetyValidator {
  const SafetyValidator();

  /// Prohibited content patterns that must never appear in AI outputs for children.
  static const prohibitedPatterns = [
    'violence',
    'blood',
    'death',
    'weapon',
    'drug',
    'alcohol',
    'tobacco',
    'gambling',
    'sex',
    'nude',
    'hate',
    'racism',
    'discrimination',
    'politics',
    'religion',
    'death',
    'war',
    'firearm',
    'suicide',
    'self-harm',
    'iq',
    'smart',
    'stupid',
    'dumb',
    'slow learner',
    'low iq',
    'retarded',
  ];

  /// Validate content before it can reach a child.
  ValidationResult validateContent({
    required String content,
    required ContentValidationContext context,
  }) {
    final issues = <String>[];

    // Check for prohibited patterns
    final lowerContent = content.toLowerCase();
    for (final pattern in prohibitedPatterns) {
      if (lowerContent.contains(pattern)) {
        issues.add('PROHIBITED_PATTERN: $pattern');
      }
    }

    // Check for child PII
    if (_containsPII(content)) {
      issues.add('PII_DETECTED');
    }

    // Check for harmful language
    if (_containsHarmfulLanguage(content)) {
      issues.add('HARMFUL_LANGUAGE');
    }

    if (issues.isNotEmpty) {
      return ValidationResult(
        passed: false,
        issues: issues,
        context: context,
        timestamp: DateTime.now(),
      );
    }

    return ValidationResult(
      passed: true,
      issues: const [],
      context: context,
      timestamp: DateTime.now(),
    );
  }

  bool _containsPII(String content) {
    // Simple patterns — not exhaustive
    final emailRegex = RegExp(r'[\w.-]+@[\w.-]+\.\w+');
    final phoneRegex = RegExp(r'\d{9,11}');
    return emailRegex.hasMatch(content) || phoneRegex.hasMatch(content);
  }

  bool _containsHarmfulLanguage(String content) {
    final lower = content.toLowerCase();
    final harmfulPhrases = [
      'you are stupid',
      'you are dumb',
      'you are slow',
      'you are bad',
      'you failed',
      'you are wrong',
      'your iq',
      'below average',
      'not good enough',
    ];
    return harmfulPhrases.any((p) => lower.contains(p));
  }
}

class ValidationResult {
  const ValidationResult({
    required this.passed,
    required this.issues,
    required this.context,
    required this.timestamp,
  });

  final bool passed;
  final List<String> issues;
  final ContentValidationContext context;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'passed': passed,
        'issues': issues,
        'context': context.toJson(),
        'timestamp': timestamp.toIso8601String(),
      };
}

class ContentValidationContext {
  const ContentValidationContext({
    required this.contentId,
    required this.contentType,
    this.targetAgeGroup,
    this.generatorModelId,
    this.promptVersion,
  });

  final String contentId;
  final String contentType;
  final String? targetAgeGroup;
  final String? generatorModelId;
  final String? promptVersion;

  Map<String, dynamic> toJson() => {
        'contentId': contentId,
        'contentType': contentType,
        if (targetAgeGroup != null) 'targetAgeGroup': targetAgeGroup,
        if (generatorModelId != null) 'generatorModelId': generatorModelId,
        if (promptVersion != null) 'promptVersion': promptVersion,
      };
}
