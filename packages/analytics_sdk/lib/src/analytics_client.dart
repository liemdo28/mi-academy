import 'dart:convert';
import 'package:http/http.dart' as http;

import 'models/analytics_event.dart';
import 'models/session_summary.dart';
import 'models/performance_report.dart';
import 'models/engagement_metrics.dart';
import 'contracts/analytics_contracts.dart';

/// Exception thrown when analytics contract validation fails.
class AnalyticsContractException implements Exception {
  final String message;
  AnalyticsContractException(this.message);
  @override
  String toString() => 'AnalyticsContractException: $message';
}

/// Exception thrown when analytics API calls fail.
class AnalyticsApiException implements Exception {
  final int statusCode;
  final String message;
  AnalyticsApiException(this.statusCode, this.message);
  @override
  String toString() => 'AnalyticsApiException($statusCode): $message';
}

/// HTTP client for the MI Academy analytics API.
///
/// Tracks events, retrieves reports, and manages engagement data.
/// All payloads are validated against the analytics contract registry
/// before submission. Forbidden fields are always checked.
class AnalyticsClient {
  final String baseUrl;
  final http.Client _httpClient;
  final String? authToken;

  static const String contractVersion = '1.0.0';

  AnalyticsClient({
    required this.baseUrl,
    http.Client? httpClient,
    this.authToken,
  }) : _httpClient = httpClient ?? http.Client();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Contract-Version': contractVersion,
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  /// Track a single analytics event.
  Future<void> trackEvent(AnalyticsEvent event) async {
    final errors = event.validate();
    if (errors.isNotEmpty) {
      throw AnalyticsContractException('Invalid event: ${errors.join("; ")}');
    }

    final forbiddenViolations = AnalyticsContracts.checkForbiddenFields(
      'analytics.event',
      event.toJson(),
    );
    if (forbiddenViolations.isNotEmpty) {
      throw AnalyticsContractException(
        'Security violation: ${forbiddenViolations.join("; ")}',
      );
    }

    final response = await _httpClient.post(
      Uri.parse('$baseUrl/v1/analytics/events'),
      headers: _headers,
      body: jsonEncode(event.toJson()),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw AnalyticsApiException(
        response.statusCode,
        'Failed to track event: ${response.body}',
      );
    }
  }

  /// Batch track multiple events in a single request.
  Future<void> trackEvents(List<AnalyticsEvent> events) async {
    for (final event in events) {
      final errors = event.validate();
      if (errors.isNotEmpty) {
        throw AnalyticsContractException(
          'Invalid event ${event.eventId}: ${errors.join("; ")}',
        );
      }
    }

    final response = await _httpClient.post(
      Uri.parse('$baseUrl/v1/analytics/events/batch'),
      headers: _headers,
      body: jsonEncode({'events': events.map((e) => e.toJson()).toList()}),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw AnalyticsApiException(
        response.statusCode,
        'Failed to batch track events: ${response.body}',
      );
    }
  }

  /// Get session summary for a child.
  Future<SessionSummary> getSessionSummary({required String sessionId}) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/v1/analytics/sessions/$sessionId/summary'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw AnalyticsApiException(
        response.statusCode,
        'Failed to get session summary: ${response.body}',
      );
    }

    return SessionSummary.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Get performance report for a child.
  Future<PerformanceReport> getPerformanceReport({
    required String childProfileId,
    required String periodType,
    DateTime? periodStart,
  }) async {
    final queryParams = <String, String>{
      'period_type': periodType,
      if (periodStart != null) 'period_start': periodStart.toIso8601String(),
    };
    final uri = Uri.parse(
      '$baseUrl/v1/analytics/children/$childProfileId/reports',
    ).replace(queryParameters: queryParams);

    final response = await _httpClient.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw AnalyticsApiException(
        response.statusCode,
        'Failed to get performance report: ${response.body}',
      );
    }

    return PerformanceReport.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Get engagement metrics for a child.
  Future<EngagementMetrics> getEngagementMetrics({
    required String childProfileId,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/v1/analytics/children/$childProfileId/engagement'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw AnalyticsApiException(
        response.statusCode,
        'Failed to get engagement metrics: ${response.body}',
      );
    }

    return EngagementMetrics.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Dispose the underlying HTTP client.
  void dispose() {
    _httpClient.close();
  }
}
