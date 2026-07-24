import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/lesson.dart';
import 'models/level.dart';
import 'models/curriculum.dart';
import 'models/localization_entry.dart';
import 'contracts/content_contracts.dart';

/// HTTP client for content management operations.
/// Handles curriculum, lessons, levels, and localization.
class ContentClient {
  final String baseUrl;
  final http.Client _httpClient;
  final String? authToken;

  ContentClient({
    required this.baseUrl,
    http.Client? httpClient,
    this.authToken,
  }) : _httpClient = httpClient ?? http.Client();

  /// Fetch a curriculum by ID.
  /// GET /api/v2/content/curricula/{id}
  Future<Curriculum> getCurriculum(String id) async {
    final response = await _get('/api/v2/content/curricula/$id');
    return Curriculum.fromJson(jsonDecode(response.body));
  }

  /// Fetch a lesson by ID.
  /// GET /api/v2/content/lessons/{id}
  Future<Lesson> getLesson(String id) async {
    final response = await _get('/api/v2/content/lessons/$id');
    return Lesson.fromJson(jsonDecode(response.body));
  }

  /// Fetch a level by ID.
  /// GET /api/v2/content/levels/{id}
  Future<Level> getLevel(String id) async {
    final response = await _get('/api/v2/content/levels/$id');
    return Level.fromJson(jsonDecode(response.body));
  }

  /// List lessons for a curriculum.
  /// GET /api/v2/content/curricula/{id}/lessons
  Future<List<Lesson>> listLessons(String curriculumId) async {
    final response = await _get(
      '/api/v2/content/curricula/$curriculumId/lessons',
    );
    final list = jsonDecode(response.body) as List;
    return list.map((e) => Lesson.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// List levels for a lesson.
  /// GET /api/v2/content/lessons/{id}/levels
  Future<List<Level>> listLevels(String lessonId) async {
    final response = await _get('/api/v2/content/lessons/$lessonId/levels');
    final list = jsonDecode(response.body) as List;
    return list.map((e) => Level.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get localized strings for a language.
  /// GET /api/v2/content/localization/{language}
  Future<List<LocalizationEntry>> getLocalizations(String language) async {
    final response = await _get('/api/v2/content/localization/$language');
    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => LocalizationEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Search content by query.
  /// GET /api/v2/content/search?q={query}&subject={subject}
  Future<Map<String, dynamic>> searchContent({
    String? query,
    String? subject,
    String? ageGroup,
    int? limit,
  }) async {
    final params = <String, String>{};
    if (query != null) params['q'] = query;
    if (subject != null) params['subject'] = subject;
    if (ageGroup != null) params['ageGroup'] = ageGroup;
    if (limit != null) params['limit'] = limit.toString();

    final uri = Uri.parse(
      '$baseUrl/api/v2/content/search',
    ).replace(queryParameters: params);
    final response = await _getUri(uri);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<http.Response> _get(String path) async {
    final headers = _buildHeaders();
    final response = await _httpClient.get(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );
    _checkStatus(response);
    return response;
  }

  Future<http.Response> _getUri(Uri uri) async {
    final headers = _buildHeaders();
    final response = await _httpClient.get(uri, headers: headers);
    _checkStatus(response);
    return response;
  }

  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'X-Contract-Version': 'mi.content/v1',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode >= 400) {
      throw ContentApiException(
        statusCode: response.statusCode,
        message: 'Content API error: ${response.statusCode} ${response.body}',
      );
    }
  }

  void dispose() => _httpClient.close();
}

class ContentApiException implements Exception {
  final int statusCode;
  final String message;
  ContentApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ContentApiException[$statusCode]: $message';
}
