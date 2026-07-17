import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// API service — handles all HTTP communication with the FastAPI backend.
/// Stores tokens securely using flutter_secure_storage.
class ApiService {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  String? _accessToken;
  String? _refreshToken;

  /// Base URL for the API.
  ///
  /// Empty by default so the child-facing app remains offline-first unless a
  /// parent/sync backend is explicitly enabled with a build-time value.
  final String baseUrl;

  ApiService({
    this.baseUrl = const String.fromEnvironment('MI_ACADEMY_API_BASE_URL'),
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Interceptor for automatic token refresh
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && _refreshToken != null) {
          final refreshed = await _refreshAccessToken();
          if (refreshed) {
            error.requestOptions.headers['Authorization'] =
                'Bearer $_accessToken';
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
        }
        handler.next(error);
      },
    ));
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String displayName,
    String language = 'vi',
  }) async {
    final response = await _dio.post('/api/v1/auth/register', data: {
      'email': email,
      'password': password,
      'display_name': displayName,
      'language': language,
    });
    await _saveTokens(response.data);
    return response.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/api/v1/auth/login', data: {
      'email': email,
      'password': password,
    });
    await _saveTokens(response.data);
    return response.data;
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/v1/auth/logout');
    } catch (_) {
      // Stateless logout — ignore errors
    }
    await _clearTokens();
  }

  Future<bool> _refreshAccessToken() async {
    try {
      final response = await _dio.post('/api/v1/auth/refresh', data: {
        'refresh_token': _refreshToken,
      });
      await _saveTokens(response.data);
      return true;
    } catch (e) {
      await _clearTokens();
      return false;
    }
  }

  // ─── Parent ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/api/v1/parent/profile');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? language,
    String? timezone,
  }) async {
    final response = await _dio.put('/api/v1/parent/profile', data: {
      if (displayName != null) 'display_name': displayName,
      if (language != null) 'language': language,
      if (timezone != null) 'timezone': timezone,
    });
    return response.data;
  }

  Future<void> setPin(String pin) async {
    await _dio.put('/api/v1/parent/pin', data: {'pin': pin});
  }

  Future<Map<String, dynamic>> verifyPin(String pin) async {
    final response =
        await _dio.post('/api/v1/parent/pin/verify', data: {'pin': pin});
    return response.data;
  }

  Future<Map<String, dynamic>> getReports() async {
    final response = await _dio.get('/api/v1/parent/reports');
    return response.data;
  }

  Future<List<dynamic>> getWeeklyReport(String childId) async {
    final response = await _dio.get(
      '/api/v1/parent/reports/weekly',
      queryParameters: {'child_id': childId},
    );
    return response.data;
  }

  // ─── Children ──────────────────────────────────────────────────────────────

  Future<List<dynamic>> getChildren() async {
    final response = await _dio.get('/api/v1/parent/children');
    return response.data;
  }

  Future<Map<String, dynamic>> createChild({
    required String nickname,
    required String ageGroup,
    String? birthYear,
    String? gradeLevel,
    String? avatarId,
    String preferredLanguage = 'vi',
    int? dailyTimeLimit,
  }) async {
    final response = await _dio.post('/api/v1/parent/children', data: {
      'nickname': nickname,
      'age_group': ageGroup,
      if (birthYear != null) 'birth_year': birthYear,
      if (gradeLevel != null) 'grade_level': gradeLevel,
      if (avatarId != null) 'avatar_id': avatarId,
      'preferred_language': preferredLanguage,
      if (dailyTimeLimit != null) 'daily_time_limit': dailyTimeLimit,
    });
    return response.data;
  }

  Future<void> deleteChild(String childId) async {
    await _dio.delete('/api/v1/parent/children/$childId');
  }

  // ─── Lessons ───────────────────────────────────────────────────────────────

  Future<List<dynamic>> getLessons({
    String? ageGroup,
    String? subjectId,
  }) async {
    final response = await _dio.get('/api/v1/lessons', queryParameters: {
      if (ageGroup != null) 'age_group': ageGroup,
      if (subjectId != null) 'subject_id': subjectId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getLesson(String lessonId) async {
    final response = await _dio.get('/api/v1/lessons/$lessonId');
    return response.data;
  }

  // ─── Games ─────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getGames() async {
    final response = await _dio.get('/api/v1/games');
    return response.data;
  }

  // ─── Progress ──────────────────────────────────────────────────────────────

  Future<List<dynamic>> getChildProgress(String childId) async {
    final response =
        await _dio.get('/api/v1/progress/children/$childId/progress');
    return response.data;
  }

  Future<List<dynamic>> getChildSkills(String childId) async {
    final response =
        await _dio.get('/api/v1/progress/children/$childId/skills');
    return response.data;
  }

  Future<List<dynamic>> getDailyPlan(String childId) async {
    final response =
        await _dio.get('/api/v1/progress/children/$childId/daily-plan');
    return response.data;
  }

  Future<void> submitGameResult(Map<String, dynamic> result) async {
    await _dio.post('/api/v1/progress/game-result', data: result);
  }

  // ─── Rewards ───────────────────────────────────────────────────────────────

  Future<List<dynamic>> getChildRewards(String childId) async {
    final response = await _dio.get('/api/v1/rewards/children/$childId');
    return response.data;
  }

  Future<Map<String, dynamic>> checkRewards(String childId) async {
    final response = await _dio.post('/api/v1/rewards/children/$childId/check');
    return response.data;
  }

  // ─── Sync ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSyncStatus() async {
    final response = await _dio.get('/api/v1/sync/status');
    return response.data;
  }

  Future<Map<String, dynamic>> syncProgress(List<dynamic> items) async {
    final response = await _dio.post('/api/v1/sync/progress', data: items);
    return response.data;
  }

  Future<Map<String, dynamic>> syncAttempts(List<dynamic> items) async {
    final response = await _dio.post('/api/v1/sync/attempts', data: items);
    return response.data;
  }

  Future<Map<String, dynamic>> syncSessions(List<dynamic> items) async {
    final response = await _dio.post('/api/v1/sync/sessions', data: items);
    return response.data;
  }

  Future<Map<String, dynamic>> syncContent({
    required String contentType,
    int sinceVersion = 0,
  }) async {
    final response = await _dio.get('/api/v1/sync/content', queryParameters: {
      'content_type': contentType,
      'since_version': sinceVersion,
    });
    return response.data;
  }

  // ─── Token management ──────────────────────────────────────────────────────

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    _accessToken = data['access_token'];
    _refreshToken = data['refresh_token'];
    await _storage.write(key: 'access_token', value: _accessToken);
    await _storage.write(key: 'refresh_token', value: _refreshToken);
  }

  Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<void> restoreTokens() async {
    _accessToken = await _storage.read(key: 'access_token');
    _refreshToken = await _storage.read(key: 'refresh_token');
  }

  bool get isAuthenticated => _accessToken != null;

  /// Make an unauthenticated Dio request (for public endpoints).
  Future<Response> publicGet(String path, {Map<String, dynamic>? params}) {
    return _dio.get(path, queryParameters: params);
  }
}
