import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/services/api_service.dart';

/// Fake Dio transport -- lets tests script exactly what each HTTP call
/// returns without a real network or platform channel. Responses are
/// consumed in order per path, so a test can make the 2nd call to the same
/// path behave differently from the 1st (e.g. refresh succeeds once, then
/// later is rejected).
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.script);

  final Map<String, List<ResponseBody Function()>> script;
  final Map<String, int> _callIndex = {};

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final responses = script[options.path];
    if (responses == null) {
      throw StateError('No scripted response for ${options.path}');
    }
    final index = _callIndex[options.path] ?? 0;
    _callIndex[options.path] = index + 1;
    if (index >= responses.length) {
      throw StateError(
        'Scripted responses for ${options.path} exhausted at call ${index + 1}',
      );
    }
    return responses[index]();
  }
}

ResponseBody _jsonResponse(Map<String, dynamic> data, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

ApiService _apiWith(Map<String, List<ResponseBody Function()>> script) {
  final api = ApiService(
    baseUrl: 'http://test.local',
    tokenStore: InMemoryTokenStore(),
  );
  api.dioForTesting.httpClientAdapter = _ScriptedAdapter(script);
  return api;
}

void main() {
  test(
    'onSessionExpired fires when the refresh token itself is rejected',
    () async {
      final api = _apiWith({
        ApiPaths.authLogin: [
          () => _jsonResponse({
                'access_token': 'access-1',
                'refresh_token': 'refresh-1',
              }, 200),
        ],
        ApiPaths.parentProfile: [
          () => _jsonResponse({'error': 'unauthorized'}, 401),
        ],
        ApiPaths.authRefresh: [
          () => _jsonResponse({'error': 'invalid_refresh_token'}, 401),
        ],
      });
      var expiredFired = false;
      api.onSessionExpired = () => expiredFired = true;

      await api.login(email: 'a@b.com', password: 'x');
      expect(expiredFired, isFalse);

      await expectLater(api.getProfile(), throwsA(anything));
      expect(
        expiredFired,
        isTrue,
        reason:
            'a 401 that survives a failed refresh means the session is truly over',
      );
    },
  );

  test(
    'onSessionExpired does not fire for a 401 on a request that was never authenticated',
    () async {
      final api = _apiWith({
        ApiPaths.parentProfile: [
          () => _jsonResponse({'error': 'unauthorized'}, 401),
        ],
      });
      var expiredFired = false;
      api.onSessionExpired = () => expiredFired = true;

      // No login() call -- there is no session to expire.
      await expectLater(api.getProfile(), throwsA(anything));
      expect(expiredFired, isFalse);
    },
  );

  test(
    'a successful refresh retries the request and never fires onSessionExpired',
    () async {
      final api = _apiWith({
        ApiPaths.authLogin: [
          () => _jsonResponse({
                'access_token': 'access-1',
                'refresh_token': 'refresh-1',
              }, 200),
        ],
        ApiPaths.parentProfile: [
          () => _jsonResponse({'error': 'unauthorized'}, 401),
          () => _jsonResponse({'display_name': 'Parent'}, 200),
        ],
        ApiPaths.authRefresh: [
          () => _jsonResponse({
                'access_token': 'access-2',
                'refresh_token': 'refresh-2',
              }, 200),
        ],
      });
      var expiredFired = false;
      api.onSessionExpired = () => expiredFired = true;

      await api.login(email: 'a@b.com', password: 'x');
      final profile = await api.getProfile();

      expect(profile['display_name'], 'Parent');
      expect(expiredFired, isFalse);
    },
  );

  test(
    'a refresh token rejected by the refresh endpoint does not recurse infinitely',
    () async {
      // Regression test: the refresh POST itself used to go through the same
      // 401 interceptor, so a rejected refresh token triggered another
      // refresh attempt with the same known-bad token, forever.
      final api = _apiWith({
        ApiPaths.authLogin: [
          () => _jsonResponse({
                'access_token': 'access-1',
                'refresh_token': 'refresh-1',
              }, 200),
        ],
        ApiPaths.parentProfile: [
          () => _jsonResponse({'error': 'unauthorized'}, 401),
        ],
        ApiPaths.authRefresh: [
          () => _jsonResponse({'error': 'invalid_refresh_token'}, 401),
        ],
      });

      await api.login(email: 'a@b.com', password: 'x');
      await expectLater(api.getProfile(), throwsA(anything));
    },
  );

  test(
    'concurrent 401s share one refresh instead of each rotating the token and forcing the others to fail',
    () async {
      // Regression test (internal-beta hardening audit): refresh tokens are
      // single-use/rotated server-side. Without serializing concurrent
      // refresh attempts, several screens hitting 401 at the same moment
      // (the normal case right when an access token expires) would each
      // call _refreshAccessToken() independently -- only the first actually
      // succeeds, and the rest present an already-redeemed token, fail, and
      // force a full logout via onSessionExpired even though the session
      // was valid a moment earlier.
      var refreshCallCount = 0;
      final api = _apiWith({
        ApiPaths.authLogin: [
          () => _jsonResponse({
                'access_token': 'access-1',
                'refresh_token': 'refresh-1',
              }, 200),
        ],
        ApiPaths.parentProfile: [
          () => _jsonResponse({'error': 'unauthorized'}, 401),
          () => _jsonResponse({'display_name': 'Parent'}, 200),
        ],
        ApiPaths.parentReports: [
          () => _jsonResponse({'error': 'unauthorized'}, 401),
          () => _jsonResponse({'reports': []}, 200),
        ],
        ApiPaths.authRefresh: [
          () {
            refreshCallCount++;
            return _jsonResponse({
              'access_token': 'access-2',
              'refresh_token': 'refresh-2',
            }, 200);
          },
        ],
      });
      var expiredFired = false;
      api.onSessionExpired = () => expiredFired = true;

      await api.login(email: 'a@b.com', password: 'x');

      // Two different endpoints both 401 at nearly the same moment, as they
      // would right when a shared access token expires mid-session.
      final results = await Future.wait([api.getProfile(), api.getReports()]);

      expect(
        refreshCallCount,
        1,
        reason:
            'both concurrent 401s should share a single in-flight refresh, not each trigger their own',
      );
      expect(results[0]['display_name'], 'Parent');
      expect(results[1]['reports'], isNotNull);
      expect(expiredFired, isFalse);
    },
  );
}
