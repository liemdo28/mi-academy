import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/services/api_service.dart';

void main() {
  test('child profile paths match FastAPI children router', () {
    expect(ApiPaths.children, '/api/v1/children');
    expect(ApiPaths.child('child-1'), '/api/v1/children/child-1');
  });

  test('reward paths match FastAPI rewards router', () {
    expect(
      ApiPaths.childRewards('child-1'),
      '/api/v1/rewards/children/child-1/rewards',
    );
  });

  test('sync paths match FastAPI sync router', () {
    expect(ApiPaths.syncProgress, '/api/v1/sync/progress');
    expect(ApiPaths.syncAttempts, '/api/v1/sync/attempts');
    expect(ApiPaths.syncSessions, '/api/v1/sync/sessions');
    expect(ApiPaths.syncContent, '/api/v1/sync/content');
  });
}
