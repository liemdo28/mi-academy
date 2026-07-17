import 'dart:convert';
import 'package:http/http.dart' as http;

import 'models/difficulty_adjustment.dart';
import 'models/spaced_repetition_item.dart';
import 'models/learning_path.dart';
import 'models/personalization_profile.dart';
import 'contracts/adaptive_contracts.dart';

/// Exception thrown when adaptive contract validation fails.
class AdaptiveContractException implements Exception {
  final String message;
  AdaptiveContractException(this.message);
  @override
  String toString() => 'AdaptiveContractException: $message';
}

/// Exception thrown when adaptive API calls fail.
class AdaptiveApiException implements Exception {
  final int statusCode;
  final String message;
  AdaptiveApiException(this.statusCode, this.message);
  @override
  String toString() => 'AdaptiveApiException($statusCode): $message';
}

/// HTTP client for the MI Academy adaptive learning API.
///
/// Manages difficulty adjustments, spaced repetition scheduling,
/// learning paths, and personalization profiles.
class AdaptiveClient {
  final String baseUrl;
  final http.Client _httpClient;
  final String? authToken;

  static const String contractVersion = '1.0.0';

  AdaptiveClient({
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

  // --- Difficulty Adjustment ---

  /// Get the latest difficulty adjustment for a child in a game.
  Future<DifficultyAdjustment> getDifficultyAdjustment({
    required String childProfileId,
    required String gameId,
    required String levelId,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/v1/adaptive/difficulty')
          .replace(queryParameters: {
            'child_profile_id': childProfileId,
            'game_id': gameId,
            'level_id': levelId,
          }),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw AdaptiveApiException(
          response.statusCode, 'Failed to get difficulty: ${response.body}');
    }
    return DifficultyAdjustment.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Submit a manual difficulty override (parent/teacher).
  Future<void> overrideDifficulty(DifficultyAdjustment adjustment) async {
    final errors = adjustment.validate();
    if (errors.isNotEmpty) {
      throw AdaptiveContractException(
          'Invalid adjustment: ${errors.join("; ")}');
    }

    final response = await _httpClient.post(
      Uri.parse('$baseUrl/v1/adaptive/difficulty/override'),
      headers: _headers,
      body: jsonEncode(adjustment.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AdaptiveApiException(
          response.statusCode, 'Override failed: ${response.body}');
    }
  }

  // --- Spaced Repetition ---

  /// Get due items for review.
  Future<List<SpacedRepetitionItem>> getDueReviews({
    required String childProfileId,
    int limit = 20,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/v1/adaptive/spaced-repetition/due')
          .replace(queryParameters: {
            'child_profile_id': childProfileId,
            'limit': limit.toString(),
          }),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw AdaptiveApiException(
          response.statusCode, 'Failed to get due reviews: ${response.body}');
    }

    final list = jsonDecode(response.body) as List;
    return list
        .map((e) =>
            SpacedRepetitionItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Submit a review result.
  Future<SpacedRepetitionItem> submitReview({
    required String itemId,
    required double quality,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/v1/adaptive/spaced-repetition/review'),
      headers: _headers,
      body: jsonEncode({'item_id': itemId, 'quality': quality}),
    );

    if (response.statusCode != 200) {
      throw AdaptiveApiException(
          response.statusCode, 'Review failed: ${response.body}');
    }
    return SpacedRepetitionItem.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // --- Learning Path ---

  /// Get the active learning path for a child.
  Future<LearningPath> getLearningPath({
    required String childProfileId,
    String? subject,
  }) async {
    final queryParams = <String, String>{
      'child_profile_id': childProfileId,
      if (subject != null) 'subject': subject,
    };

    final response = await _httpClient.get(
      Uri.parse('$baseUrl/v1/adaptive/learning-paths')
          .replace(queryParameters: queryParams),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw AdaptiveApiException(
          response.statusCode, 'Failed to get path: ${response.body}');
    }
    return LearningPath.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Generate a new learning path.
  Future<LearningPath> generateLearningPath({
    required String childProfileId,
    required String subject,
    required String ageGroup,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/v1/adaptive/learning-paths/generate'),
      headers: _headers,
      body: jsonEncode({
        'child_profile_id': childProfileId,
        'subject': subject,
        'age_group': ageGroup,
      }),
    );

    if (response.statusCode != 201) {
      throw AdaptiveApiException(
          response.statusCode, 'Generation failed: ${response.body}');
    }
    return LearningPath.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // --- Personalization ---

  /// Get personalization profile for a child.
  Future<PersonalizationProfile> getPersonalizationProfile({
    required String childProfileId,
  }) async {
    final response = await _httpClient.get(
      Uri.parse(
          '$baseUrl/v1/adaptive/personalization/$childProfileId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw AdaptiveApiException(
          response.statusCode, 'Failed to get profile: ${response.body}');
    }
    return PersonalizationProfile.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Update personalization profile with new signals.
  Future<PersonalizationProfile> updatePersonalizationProfile(
    PersonalizationProfile profile,
  ) async {
    final errors = profile.validate();
    if (errors.isNotEmpty) {
      throw AdaptiveContractException(
          'Invalid profile: ${errors.join("; ")}');
    }

    final forbiddenViolations = AdaptiveContracts.checkForbiddenFields(
      'adaptive.personalization_profile',
      profile.toJson(),
    );
    if (forbiddenViolations.isNotEmpty) {
      throw AdaptiveContractException(
          'Security: ${forbiddenViolations.join("; ")}');
    }

    final response = await _httpClient.put(
      Uri.parse(
          '$baseUrl/v1/adaptive/personalization/${profile.childProfileId}'),
      headers: _headers,
      body: jsonEncode(profile.toJson()),
    );

    if (response.statusCode != 200) {
      throw AdaptiveApiException(
          response.statusCode, 'Update failed: ${response.body}');
    }
    return PersonalizationProfile.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  void dispose() {
    _httpClient.close();
  }
}
