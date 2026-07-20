import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../services/api_service.dart';
import '../services/child_profile_store.dart';
import 'providers.dart';

/// Active child state.
class ActiveChildState {
  final String? childId;
  final Map<String, dynamic>? child;
  final List<Map<String, dynamic>> children;
  final bool isLoading;
  final String? error;

  const ActiveChildState({
    this.childId,
    this.child,
    this.children = const [],
    this.isLoading = false,
    this.error,
  });

  ActiveChildState copyWith({
    String? childId,
    Map<String, dynamic>? child,
    List<Map<String, dynamic>>? children,
    bool? isLoading,
    String? error,
  }) {
    return ActiveChildState(
      childId: childId ?? this.childId,
      child: child ?? this.child,
      children: children ?? this.children,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ActiveChildNotifier extends Notifier<ActiveChildState> {
  ApiService? _api;
  ChildProfileStore? _store;

  ApiService get _profileApi {
    final current = _api;
    if (current != null) return current;
    final api = ref.read(apiServiceProvider);
    _api = api;
    return api;
  }

  ChildProfileStore get _profileStore {
    final current = _store;
    if (current != null) return current;
    final store = ref.read(childProfileStoreProvider);
    _store = store;
    return store;
  }

  @override
  ActiveChildState build() {
    _api = ref.read(apiServiceProvider);
    _store = ref.read(childProfileStoreProvider);
    return const ActiveChildState();
  }

  /// Load locally persisted children first, then best-effort sync remote data.
  Future<void> loadChildren() async {
    state = state.copyWith(isLoading: true, error: null);
    var localChildren = const <Map<String, dynamic>>[];
    try {
      localChildren = await _profileStore.loadProfiles();
      final selected = await _profileStore.loadSelectedProfile();
      state = state.copyWith(
        childId: selected?['id'] as String?,
        child: selected,
        children: localChildren,
        isLoading: _profileApi.hasConfiguredBackend,
      );

      if (!_profileApi.hasConfiguredBackend) {
        await _autoSelectSingleLocalChild(localChildren);
        state = state.copyWith(isLoading: false);
        return;
      }

      try {
        final data = await _profileApi.getChildren();
        final remoteChildren = data.cast<Map<String, dynamic>>();
        await _profileStore.saveProfiles(remoteChildren);
        final selectedAfterSync = await _selectedOrStored(remoteChildren);
        state = state.copyWith(
          childId: selectedAfterSync?['id'] as String?,
          child: selectedAfterSync,
          children: remoteChildren,
          isLoading: false,
        );
        await _autoSelectSingleLocalChild(remoteChildren);
      } catch (e) {
        await _autoSelectSingleLocalChild(localChildren);
        state = state.copyWith(
          children: localChildren,
          isLoading: false,
          error: localChildren.isEmpty ? e.toString() : null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        children: localChildren,
        isLoading: false,
        error: localChildren.isEmpty ? e.toString() : null,
      );
    }
  }

  /// Select a child profile.
  Future<void> selectChild(Map<String, dynamic> child) async {
    await _profileStore.saveSelectedProfile(child);
    state = state.copyWith(childId: child['id'] as String, child: child);
  }

  /// Create a new child profile, then select it.
  Future<bool> createChild({
    required String nickname,
    required String ageGroup,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    Map<String, dynamic>? created;
    if (_profileApi.hasConfiguredBackend) {
      try {
        created = await _profileApi.createChild(
          nickname: nickname,
          ageGroup: ageGroup,
        );
      } catch (_) {
        created = null;
      }
    }
    created ??= _createLocalChild(nickname: nickname, ageGroup: ageGroup);
    try {
      final children = [...state.children, created];
      await _profileStore.saveProfiles(children);
      state = state.copyWith(children: children, isLoading: false);
      await selectChild(created);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Clear selection (logout or switch).
  void clearSelection() {
    _profileStore.clearSelection();
    state = const ActiveChildState();
  }

  Future<void> _autoSelectSingleLocalChild(
    List<Map<String, dynamic>> children,
  ) async {
    if (children.length == 1 && state.childId == null) {
      await selectChild(children[0]);
    }
  }

  Future<Map<String, dynamic>?> _selectedOrStored(
    List<Map<String, dynamic>> children,
  ) async {
    final currentId = state.childId;
    if (currentId != null) {
      for (final child in children) {
        if (child['id'] == currentId) {
          await _profileStore.saveSelectedProfile(child);
          return child;
        }
      }
    }
    if (children.length == 1) {
      await _profileStore.saveSelectedProfile(children[0]);
      return children[0];
    }
    return null;
  }

  Map<String, dynamic> _createLocalChild({
    required String nickname,
    required String ageGroup,
  }) {
    return {
      'id': 'local-${const Uuid().v4()}',
      'nickname': nickname,
      'birth_year': null,
      'age_group': ageGroup,
      'grade_level': null,
      'avatar_id': 'avatar_01',
      'preferred_language': 'vi',
      'daily_time_limit': null,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'local_only': true,
    };
  }
}
