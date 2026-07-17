import 'package:http/http.dart' as http;

import 'package:game_sdk/game_sdk.dart' as game_sdk;
import 'package:content_sdk/content_sdk.dart' as content_sdk;
import 'package:analytics_sdk/analytics_sdk.dart' as analytics_sdk;
import 'package:adaptive_sdk/adaptive_sdk.dart' as adaptive_sdk;

import 'mi_api_config.dart';

/// Unified MI Academy API client.
///
/// Provides a single entry point that wraps all sub-SDKs:
/// - [games] — Game launch, results, snapshots
/// - [content] — Curriculum, lessons, levels, localization
/// - [analytics] — Event tracking, reports, engagement
/// - [adaptive] — Difficulty, spaced repetition, learning paths
///
/// All sub-clients share a single HTTP client and auth configuration.
class MiApiClient {
  final MiApiConfig config;
  final http.Client _httpClient;

  late final game_sdk.GameClient games;
  late final content_sdk.ContentClient content;
  late final analytics_sdk.AnalyticsClient analytics;
  late final adaptive_sdk.AdaptiveClient adaptive;

  MiApiClient({
    required this.config,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client() {
    games = game_sdk.GameClient(
      baseUrl: config.baseUrl,
      httpClient: _httpClient,
      authToken: config.authToken,
    );
    content = content_sdk.ContentClient(
      baseUrl: config.baseUrl,
      httpClient: _httpClient,
      authToken: config.authToken,
    );
    analytics = analytics_sdk.AnalyticsClient(
      baseUrl: config.baseUrl,
      httpClient: _httpClient,
      authToken: config.authToken,
    );
    adaptive = adaptive_sdk.AdaptiveClient(
      baseUrl: config.baseUrl,
      httpClient: _httpClient,
      authToken: config.authToken,
    );
  }

  /// Health check against the API.
  Future<bool> healthCheck() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('${config.baseUrl}/health'),
        headers: {
          'Accept': 'application/json',
          if (config.authToken != null)
            'Authorization': 'Bearer ${config.authToken}',
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Validate configuration before use.
  List<String> validateConfig() => config.validate();

  /// Dispose all underlying resources.
  void dispose() {
    _httpClient.close();
  }
}
