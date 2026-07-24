/// Configuration for the unified MI Academy API client.
class MiApiConfig {
  /// Base URL for the MI Academy API.
  final String baseUrl;

  /// Authentication token (JWT or API key).
  final String? authToken;

  /// Timeout for HTTP requests in seconds.
  final int timeoutSeconds;

  /// Maximum retry attempts for failed requests.
  final int maxRetries;

  /// Whether to enable request/response logging.
  final bool enableLogging;

  /// Contract version sent in X-Contract-Version header.
  final String contractVersion;

  /// Custom API key header name (if different from default).
  final String? apiKeyHeader;

  const MiApiConfig({
    required this.baseUrl,
    this.authToken,
    this.timeoutSeconds = 30,
    this.maxRetries = 3,
    this.enableLogging = false,
    this.contractVersion = '1.0.0',
    this.apiKeyHeader,
  });

  /// Creates a copy with overridden fields.
  MiApiConfig copyWith({
    String? baseUrl,
    String? authToken,
    int? timeoutSeconds,
    int? maxRetries,
    bool? enableLogging,
    String? contractVersion,
    String? apiKeyHeader,
  }) {
    return MiApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      authToken: authToken ?? this.authToken,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      maxRetries: maxRetries ?? this.maxRetries,
      enableLogging: enableLogging ?? this.enableLogging,
      contractVersion: contractVersion ?? this.contractVersion,
      apiKeyHeader: apiKeyHeader ?? this.apiKeyHeader,
    );
  }

  /// Development configuration for local testing.
  static MiApiConfig development({String? authToken}) => MiApiConfig(
    baseUrl: 'http://localhost:8000',
    authToken: authToken,
    enableLogging: true,
    timeoutSeconds: 60,
  );

  /// Staging configuration.
  static MiApiConfig staging({String? authToken}) => MiApiConfig(
    baseUrl: 'https://staging-api.mi-academy.app',
    authToken: authToken,
    enableLogging: true,
  );

  /// Production configuration.
  static MiApiConfig production({required String authToken}) => MiApiConfig(
    baseUrl: 'https://api.mi-academy.app',
    authToken: authToken,
    enableLogging: false,
  );

  List<String> validate() {
    final errors = <String>[];
    if (baseUrl.isEmpty) errors.add('baseUrl is required');
    if (!baseUrl.startsWith('http'))
      errors.add('baseUrl must start with http(s)');
    if (timeoutSeconds <= 0) errors.add('timeoutSeconds must be > 0');
    if (maxRetries < 0) errors.add('maxRetries must be >= 0');
    return errors;
  }
}
