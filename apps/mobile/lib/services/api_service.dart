import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token persistence, abstracted so tests can supply an in-memory store
/// instead of `FlutterSecureStorage` (which needs a real platform channel
/// -- unavailable in plain `flutter_test`, and not reliably mockable since
/// the concrete backend packages don't expose a stable raw MethodChannel).
abstract class TokenStore {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}

class SecureTokenStore implements TokenStore {
  final _storage = const FlutterSecureStorage();

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Test-only in-memory [TokenStore].
class InMemoryTokenStore implements TokenStore {
  final Map<String, String> _values = {};

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}

class ApiPaths {
  static const authRegister = '/api/v1/auth/register';
  static const authLogin = '/api/v1/auth/login';
  static const authLogout = '/api/v1/auth/logout';
  static const authRefresh = '/api/v1/auth/refresh';
  static const parentProfile = '/api/v1/parent/profile';
  static const parentPin = '/api/v1/parent/pin';
  static const parentPinVerify = '/api/v1/parent/pin/verify';
  static const parentReports = '/api/v1/parent/reports';
  static const parentWeeklyReports = '/api/v1/parent/reports/weekly';
  static const children = '/api/v1/children';
  static const lessons = '/api/v1/lessons';
  static const games = '/api/v1/games';
  static const syncStatus = '/api/v1/sync/status';
  static const syncProgress = '/api/v1/sync/progress';
  static const syncAttempts = '/api/v1/sync/attempts';
  static const syncSessions = '/api/v1/sync/sessions';
  static const syncContent = '/api/v1/sync/content';

  static String child(String childId) => '$children/$childId';
  static String lesson(String lessonId) => '$lessons/$lessonId';
  static String gameResult(String gameId) => '$games/$gameId/result';
  static String childProgress(String childId) =>
      '/api/v1/progress/children/$childId/progress';
  static String childSkills(String childId) =>
      '/api/v1/progress/children/$childId/skills';
  static String dailyPlan(String childId) =>
      '/api/v1/progress/children/$childId/daily-plan';
  static String childRewards(String childId) =>
      '/api/v1/rewards/children/$childId/rewards';
}

/// API service — handles all HTTP communication with the FastAPI backend.
/// Stores tokens securely using flutter_secure_storage.
class ApiService {
  late final Dio _dio;
  final TokenStore _tokenStore;

  String? _accessToken;
  String? _refreshToken;

  /// Fired when a request fails auth (401) and there's no way to recover
  /// the session -- either the refresh token itself was rejected, or there
  /// was no refresh token to try. Without this, a screen's request just
  /// errors silently and the app is left showing stale authenticated UI
  /// with a dead session until the user manually navigates. Set once from
  /// `main()`/provider wiring to reset auth state and redirect to /login.
  /// Never fires for requests that were never authenticated in the first
  /// place (e.g. offline-child gameplay), since that's not a session loss.
  void Function()? onSessionExpired;

  /// Base URL for the API.
  ///
  /// Empty by default so the child-facing app remains offline-first unless a
  /// parent/sync backend is explicitly enabled with a build-time value.
  final String baseUrl;

  ApiService({
    this.baseUrl = const String.fromEnvironment('MI_ACADEMY_API_BASE_URL'),
    TokenStore? tokenStore,
  }) : _tokenStore = tokenStore ?? SecureTokenStore() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor for automatic token refresh
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // The refresh call itself goes through this same interceptor. If it
          // returns 401 (the refresh token was rejected) and this branch
          // didn't exclude it, _refreshAccessToken would try to refresh again
          // with the same known-bad token -- an unbounded recursive retry
          // loop, not just a missed edge case.
          final isRefreshCall =
              error.requestOptions.path == ApiPaths.authRefresh;
          if (error.response?.statusCode == 401 && !isRefreshCall) {
            final wasAuthenticated =
                _accessToken != null || _refreshToken != null;
            if (_refreshToken != null) {
              final refreshed = await _refreshAccessToken();
              if (refreshed) {
                error.requestOptions.headers['Authorization'] =
                    'Bearer $_accessToken';
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              }
              // _refreshAccessToken already cleared tokens on failure.
            } else if (wasAuthenticated) {
              // Had an access token but no refresh token to try -- an
              // inconsistent state, but still means this session is over.
              await _clearTokens();
            }
            if (wasAuthenticated) onSessionExpired?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String displayName,
    String language = 'vi',
  }) async {
    final response = await _dio.post(
      ApiPaths.authRegister,
      data: {
        'email': email,
        'password': password,
        'display_name': displayName,
        'language': language,
      },
    );
    await _saveTokens(response.data);
    return response.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiPaths.authLogin,
      data: {'email': email, 'password': password},
    );
    await _saveTokens(response.data);
    return response.data;
  }

  Future<void> logout() async {
    try {
      // Revokes every refresh token the backend has issued for this user
      // (see apps/api/routes/auth.py's logout). Best-effort: even if this
      // call fails (offline, expired access token, etc.), still clear the
      // local tokens below so the device stops presenting as signed in.
      await _dio.post(ApiPaths.authLogout);
    } catch (_) {
      // Ignore -- the server-side revocation is a nice-to-have here since
      // local tokens are cleared regardless; going offline shouldn't block
      // a local sign-out.
    }
    await _clearTokens();
  }

  Future<bool>? _inFlightRefresh;

  /// Serializes concurrent refresh attempts behind one in-flight [Future].
  ///
  /// Without this, several screens hitting 401 at nearly the same moment
  /// (the normal case right when an access token expires) would each call
  /// this independently. Since refresh tokens are single-use/rotated
  /// server-side, only the first of those calls actually succeeds; the
  /// rest would present an already-redeemed token, get rejected, clear
  /// tokens, and force a full logout via onSessionExpired -- even though
  /// the session was, a moment earlier, perfectly valid. Sharing one
  /// in-flight refresh means every concurrent caller gets the same
  /// (successful) result.
  Future<bool> _refreshAccessToken() {
    return _inFlightRefresh ??= _doRefreshAccessToken().whenComplete(() {
      _inFlightRefresh = null;
    });
  }

  Future<bool> _doRefreshAccessToken() async {
    try {
      final response = await _dio.post(
        ApiPaths.authRefresh,
        data: {'refresh_token': _refreshToken},
      );
      await _saveTokens(response.data);
      return true;
    } catch (e) {
      await _clearTokens();
      return false;
    }
  }

  // ─── Parent ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get(ApiPaths.parentProfile);
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? language,
    String? timezone,
  }) async {
    final response = await _dio.put(
      ApiPaths.parentProfile,
      data: {
        if (displayName != null) 'display_name': displayName,
        if (language != null) 'language': language,
        if (timezone != null) 'timezone': timezone,
      },
    );
    return response.data;
  }

  Future<void> setPin(String pin) async {
    await _dio.put(ApiPaths.parentPin, data: {'pin': pin});
  }

  Future<Map<String, dynamic>> verifyPin(String pin) async {
    final response = await _dio.post(
      ApiPaths.parentPinVerify,
      data: {'pin': pin},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getReports() async {
    final response = await _dio.get(ApiPaths.parentReports);
    return response.data;
  }

  Future<List<dynamic>> getWeeklyReport(String childId) async {
    final response = await _dio.get(
      ApiPaths.parentWeeklyReports,
      queryParameters: {'child_id': childId},
    );
    return response.data;
  }

  // ─── Children ──────────────────────────────────────────────────────────────

  Future<List<dynamic>> getChildren() async {
    final response = await _dio.get(ApiPaths.children);
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
    final response = await _dio.post(
      ApiPaths.children,
      data: {
        'nickname': nickname,
        'age_group': ageGroup,
        if (birthYear != null) 'birth_year': birthYear,
        if (gradeLevel != null) 'grade_level': gradeLevel,
        if (avatarId != null) 'avatar_id': avatarId,
        'preferred_language': preferredLanguage,
        if (dailyTimeLimit != null) 'daily_time_limit': dailyTimeLimit,
      },
    );
    return response.data;
  }

  Future<void> deleteChild(String childId) async {
    await _dio.delete(ApiPaths.child(childId));
  }

  // ─── Lessons ───────────────────────────────────────────────────────────────

  Future<List<dynamic>> getLessons({
    String? ageGroup,
    String? subjectId,
  }) async {
    final response = await _dio.get(
      ApiPaths.lessons,
      queryParameters: {
        if (ageGroup != null) 'age_group': ageGroup,
        if (subjectId != null) 'subject_id': subjectId,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getLesson(String lessonId) async {
    final response = await _dio.get(ApiPaths.lesson(lessonId));
    return response.data;
  }

  // ─── Games ─────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getGames() async {
    final response = await _dio.get(ApiPaths.games);
    return response.data;
  }

  // ─── Progress ──────────────────────────────────────────────────────────────

  Future<List<dynamic>> getChildProgress(String childId) async {
    final response = await _dio.get(ApiPaths.childProgress(childId));
    return response.data;
  }

  Future<List<dynamic>> getChildSkills(String childId) async {
    final response = await _dio.get(ApiPaths.childSkills(childId));
    return response.data;
  }

  Future<List<dynamic>> getDailyPlan(String childId) async {
    final response = await _dio.get(ApiPaths.dailyPlan(childId));
    return response.data;
  }

  /// Save a MiGameResult (as JSON, snake_case per the contract) for the
  /// given game. `result['game_id']` must match [gameId].
  Future<Map<String, dynamic>> submitGameResult(
    String gameId,
    Map<String, dynamic> result,
  ) async {
    final response = await _dio.post(ApiPaths.gameResult(gameId), data: result);
    return response.data as Map<String, dynamic>;
  }

  // ─── Rewards ───────────────────────────────────────────────────────────────

  Future<List<dynamic>> getChildRewards(String childId) async {
    final response = await _dio.get(ApiPaths.childRewards(childId));
    return response.data;
  }

  Future<Map<String, dynamic>> checkRewards(String childId) async {
    final rewards = await getChildRewards(childId);
    return {'rewards': rewards};
  }

  // ─── Sync ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSyncStatus() async {
    final response = await _dio.get(ApiPaths.syncStatus);
    return response.data;
  }

  Future<Map<String, dynamic>> syncProgress(List<dynamic> items) async {
    final response = await _dio.post(ApiPaths.syncProgress, data: items);
    return response.data;
  }

  Future<Map<String, dynamic>> syncAttempts(List<dynamic> items) async {
    final response = await _dio.post(ApiPaths.syncAttempts, data: items);
    return response.data;
  }

  Future<Map<String, dynamic>> syncSessions(List<dynamic> items) async {
    final response = await _dio.post(ApiPaths.syncSessions, data: items);
    return response.data;
  }

  Future<Map<String, dynamic>> syncContent({
    required String contentType,
    int sinceVersion = 0,
  }) async {
    final response = await _dio.get(
      ApiPaths.syncContent,
      queryParameters: {
        'content_type': contentType,
        'since_version': sinceVersion,
      },
    );
    return response.data;
  }

  // ─── Token management ──────────────────────────────────────────────────────

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    _accessToken = data['access_token'];
    _refreshToken = data['refresh_token'];
    await _tokenStore.write('access_token', _accessToken!);
    await _tokenStore.write('refresh_token', _refreshToken!);
  }

  Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _tokenStore.delete('access_token');
    await _tokenStore.delete('refresh_token');
  }

  Future<void> restoreTokens() async {
    _accessToken = await _tokenStore.read('access_token');
    _refreshToken = await _tokenStore.read('refresh_token');
  }

  bool get isAuthenticated => _accessToken != null;

  /// Test-only seam for substituting a fake `HttpClientAdapter` instead of
  /// hitting a real network -- see api_service_session_expiry_test.dart.
  Dio get dioForTesting => _dio;

  /// Make an unauthenticated Dio request (for public endpoints).
  Future<Response> publicGet(String path, {Map<String, dynamic>? params}) {
    return _dio.get(path, queryParameters: params);
  }
}
