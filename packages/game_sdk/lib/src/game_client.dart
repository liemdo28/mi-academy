import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/game_launch_request.dart';
import 'models/game_result.dart';
import 'models/game_snapshot.dart';
import 'contracts/game_contracts.dart';

/// HTTP client for game lifecycle operations.
/// Handles launch, result submission, snapshot save/resume.
class GameClient {
  final String baseUrl;
  final http.Client _httpClient;
  final String? authToken;

  GameClient({
    required this.baseUrl,
    http.Client? httpClient,
    this.authToken,
  }) : _httpClient = httpClient ?? http.Client();

  /// Launch a game session.
  /// POST /api/v2/games/launch
  Future<http.Response> launchGame(GameLaunchRequest request) async {
    final errors = request.validate();
    if (errors.isNotEmpty) {
      throw GameContractException(
        'GameLaunchRequest validation failed: ${errors.join("; ")}',
      );
    }

    final body = request.toJson();
    final forbidden = GameContracts.checkForbiddenFields(body);
    if (forbidden.isNotEmpty) {
      throw GameSecurityException(
        'Forbidden fields detected: ${forbidden.join(", ")}',
      );
    }

    final headers = {
      'Content-Type': 'application/json',
      'X-Contract-Version': 'mi.game.launch-request/v2',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    final response = await _httpClient.post(
      Uri.parse('$baseUrl/api/v2/games/launch'),
      headers: headers,
      body: jsonEncode(body),
    );

    _checkResponseStatus(response, 'launchGame');
    return response;
  }

  /// Submit a game result.
  /// POST /api/v2/games/result
  Future<http.Response> submitResult(GameResult result) async {
    final errors = result.validate();
    if (errors.isNotEmpty) {
      throw GameContractException(
        'GameResult validation failed: ${errors.join("; ")}',
      );
    }

    final body = result.toJson();
    final forbidden = GameContracts.checkForbiddenFields(body);
    if (forbidden.isNotEmpty) {
      throw GameSecurityException(
        'Forbidden fields detected: ${forbidden.join(", ")}',
      );
    }

    final headers = {
      'Content-Type': 'application/json',
      'X-Contract-Version': 'mi.game.result/v2',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    final response = await _httpClient.post(
      Uri.parse('$baseUrl/api/v2/games/result'),
      headers: headers,
      body: jsonEncode(body),
    );

    _checkResponseStatus(response, 'submitResult');
    return response;
  }

  /// Save a game snapshot.
  /// PUT /api/v2/games/snapshot
  Future<http.Response> saveSnapshot(GameSnapshot snapshot) async {
    final errors = snapshot.validate();
    if (errors.isNotEmpty) {
      throw GameContractException(
        'GameSnapshot validation failed: ${errors.join("; ")}',
      );
    }

    final body = snapshot.toJson();
    final headers = {
      'Content-Type': 'application/json',
      'X-Contract-Version': 'mi.game.snapshot/v2',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    final response = await _httpClient.put(
      Uri.parse('$baseUrl/api/v2/games/snapshot'),
      headers: headers,
      body: jsonEncode(body),
    );

    _checkResponseStatus(response, 'saveSnapshot');
    return response;
  }

  /// Resume a game from a snapshot.
  /// GET /api/v2/games/snapshot/{childProfileId}/{gameId}
  Future<GameSnapshot> resumeSnapshot({
    required String childProfileId,
    required String gameId,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'X-Contract-Version': 'mi.game.snapshot/v2',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    final response = await _httpClient.get(
      Uri.parse('$baseUrl/api/v2/games/snapshot/$childProfileId/$gameId'),
      headers: headers,
    );

    _checkResponseStatus(response, 'resumeSnapshot');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return GameSnapshot.fromJson(body);
  }

  void _checkResponseStatus(http.Response response, String operation) {
    if (response.statusCode >= 400) {
      throw GameApiException(
        operation: operation,
        statusCode: response.statusCode,
        message: 'Game API error: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Dispose the underlying HTTP client.
  void dispose() {
    _httpClient.close();
  }
}

/// Exception for contract validation failures.
class GameContractException implements Exception {
  final String message;
  GameContractException(this.message);

  @override
  String toString() => 'GameContractException: $message';
}

/// Exception for security violations (forbidden fields).
class GameSecurityException implements Exception {
  final String message;
  GameSecurityException(this.message);

  @override
  String toString() => 'GameSecurityException: $message';
}

/// Exception for API communication errors.
class GameApiException implements Exception {
  final String operation;
  final int statusCode;
  final String message;

  GameApiException({
    required this.operation,
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'GameApiException[$operation]: $message';
}
