import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/providers/providers.dart';
import 'package:mi_academy/services/api_service.dart';
import 'package:mi_academy/services/child_profile_store.dart';

void main() {
  test('first launch with no backend shows local-empty profile state',
      () async {
    final store = MemoryChildProfileStore();
    final container = _container(
      api: _FakeProfileApi(baseUrl: ''),
      store: store,
    );
    addTearDown(container.dispose);

    await container.read(activeChildProvider.notifier).loadChildren();

    final state = container.read(activeChildProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.children, isEmpty);
  });

  test('local profile creation persists and is selected after restart',
      () async {
    final store = MemoryChildProfileStore();
    final firstLaunch = _container(
      api: _FakeProfileApi(baseUrl: ''),
      store: store,
    );
    addTearDown(firstLaunch.dispose);

    final created = await firstLaunch
        .read(activeChildProvider.notifier)
        .createChild(nickname: 'Mi', ageGroup: 'junior');

    expect(created, isTrue);
    expect(firstLaunch.read(activeChildProvider).child?['nickname'], 'Mi');

    final secondLaunch = _container(
      api: _FakeProfileApi(baseUrl: ''),
      store: store,
    );
    addTearDown(secondLaunch.dispose);

    await secondLaunch.read(activeChildProvider.notifier).loadChildren();

    final restored = secondLaunch.read(activeChildProvider);
    expect(restored.children, hasLength(1));
    expect(restored.child?['nickname'], 'Mi');
    expect(restored.childId, restored.children.single['id']);
  });

  test('offline profile screen keeps local profiles when backend times out',
      () async {
    final local = _profile(id: 'local-child', nickname: 'Mi');
    final store = MemoryChildProfileStore(profiles: [local]);
    await store.saveSelectedProfile(local);
    final container = _container(
      api: _FakeProfileApi(
        baseUrl: 'https://api.example.test',
        getChildrenError: TimeoutException('backend timeout'),
      ),
      store: store,
    );
    addTearDown(container.dispose);

    await container.read(activeChildProvider.notifier).loadChildren();

    final state = container.read(activeChildProvider);
    expect(state.error, isNull);
    expect(state.children, [local]);
    expect(state.childId, 'local-child');
  });

  test('malformed remote response does not delete local profiles', () async {
    final local = _profile(id: 'local-child', nickname: 'Mi');
    final store = MemoryChildProfileStore(profiles: [local]);
    final container = _container(
      api: _FakeProfileApi(
        baseUrl: 'https://api.example.test',
        remoteChildren: ['not-a-profile'],
      ),
      store: store,
    );
    addTearDown(container.dispose);

    await container.read(activeChildProvider.notifier).loadChildren();

    final state = container.read(activeChildProvider);
    expect(state.error, isNull);
    expect(state.children, [local]);
    expect(await store.loadProfiles(), [local]);
  });

  test('optional sync uses backend profiles when backend is available',
      () async {
    final remote = _profile(id: 'remote-child', nickname: 'Bo');
    final store = MemoryChildProfileStore();
    final container = _container(
      api: _FakeProfileApi(
        baseUrl: 'https://api.example.test',
        remoteChildren: [remote],
      ),
      store: store,
    );
    addTearDown(container.dispose);

    await container.read(activeChildProvider.notifier).loadChildren();

    final state = container.read(activeChildProvider);
    expect(state.error, isNull);
    expect(state.children, [remote]);
    expect(state.childId, 'remote-child');
    expect(await store.loadProfiles(), [remote]);
  });

  test('local creation falls back when configured backend is unavailable',
      () async {
    final store = MemoryChildProfileStore();
    final container = _container(
      api: _FakeProfileApi(
        baseUrl: 'https://api.example.test',
        createChildError: TimeoutException('backend timeout'),
      ),
      store: store,
    );
    addTearDown(container.dispose);

    final ok = await container
        .read(activeChildProvider.notifier)
        .createChild(nickname: 'Mi', ageGroup: 'explorer');

    final state = container.read(activeChildProvider);
    expect(ok, isTrue);
    expect(state.childId, startsWith('local-'));
    expect(state.children.single['local_only'], isTrue);
    expect((await store.loadSelectedProfile())?['nickname'], 'Mi');
  });

  test('daily plan stays usable with a local child and no backend', () async {
    final store = MemoryChildProfileStore();
    final container = _container(
      api: _FakeProfileApi(baseUrl: ''),
      store: store,
    );
    addTearDown(container.dispose);

    await container
        .read(activeChildProvider.notifier)
        .createChild(nickname: 'Mi', ageGroup: 'junior');

    await expectLater(container.read(dailyPlanProvider.future), completion([]));
  });
}

ProviderContainer _container({
  required ApiService api,
  required ChildProfileStore store,
}) {
  return ProviderContainer(
    overrides: [
      apiServiceProvider.overrideWithValue(api),
      childProfileStoreProvider.overrideWithValue(store),
    ],
  );
}

Map<String, dynamic> _profile({required String id, required String nickname}) {
  return {
    'id': id,
    'nickname': nickname,
    'birth_year': null,
    'age_group': 'junior',
    'grade_level': null,
    'avatar_id': 'avatar_01',
    'preferred_language': 'vi',
    'daily_time_limit': null,
    'created_at': '2026-07-20T00:00:00.000Z',
  };
}

class _FakeProfileApi extends ApiService {
  _FakeProfileApi({
    required super.baseUrl,
    this.remoteChildren = const [],
    this.getChildrenError,
    this.createChildError,
  }) : super(tokenStore: InMemoryTokenStore());

  final List<dynamic> remoteChildren;
  final Object? getChildrenError;
  final Object? createChildError;

  @override
  Future<List<dynamic>> getChildren() async {
    final error = getChildrenError;
    if (error != null) throw error;
    return remoteChildren;
  }

  @override
  Future<Map<String, dynamic>> createChild({
    required String nickname,
    required String ageGroup,
    String? birthYear,
    String? gradeLevel,
    String? avatarId,
    String preferredLanguage = 'vi',
    int? dailyTimeLimit,
  }) async {
    final error = createChildError;
    if (error != null) throw error;
    return _profile(id: 'remote-created-child', nickname: nickname)
      ..['age_group'] = ageGroup;
  }
}
