import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
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
  late final ApiService _api;

  @override
  ActiveChildState build() {
    _api = ref.read(apiServiceProvider);
    return const ActiveChildState();
  }

  /// Load all children from API.
  Future<void> loadChildren() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.getChildren();
      final children = data.cast<Map<String, dynamic>>();
      state = state.copyWith(children: children, isLoading: false);

      // Auto-select first child if only one
      if (children.length == 1) {
        await selectChild(children[0]);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Select a child profile.
  Future<void> selectChild(Map<String, dynamic> child) async {
    state = state.copyWith(
      childId: child['id'] as String,
      child: child,
    );
  }

  /// Create a new child profile, then select it.
  Future<bool> createChild({
    required String nickname,
    required String ageGroup,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final created = await _api.createChild(
        nickname: nickname,
        ageGroup: ageGroup,
      );
      final children = [...state.children, created];
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
    state = const ActiveChildState();
  }
}
