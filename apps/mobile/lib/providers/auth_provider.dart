import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'providers.dart';

/// Auth state.
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? parentProfile;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.parentProfile,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    Map<String, dynamic>? user,
    Map<String, dynamic>? parentProfile,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      parentProfile: parentProfile ?? this.parentProfile,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final ApiService _api;

  @override
  AuthState build() {
    _api = ref.read(apiServiceProvider);
    return const AuthState();
  }

  /// Initialize — restore tokens from secure storage.
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      await _api.restoreTokens();
      if (_api.isAuthenticated) {
        final profile = await _api.getProfile();
        state = state.copyWith(
          isAuthenticated: true,
          parentProfile: profile,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.login(email: email, password: password);
      state = state.copyWith(
        isAuthenticated: true,
        user: data['user'] as Map<String, dynamic>?,
        parentProfile: data['parent_profile'] as Map<String, dynamic>?,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    String language = 'vi',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.register(
        email: email,
        password: password,
        displayName: displayName,
        language: language,
      );
      state = state.copyWith(
        isAuthenticated: true,
        user: data['user'] as Map<String, dynamic>?,
        parentProfile: data['parent_profile'] as Map<String, dynamic>?,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    // Best-effort: try to flush the offline sync queue while the access
    // token is still valid, so pending game results/progress don't sit
    // queued any longer than necessary. Never lose data on logout either
    // way -- items that don't sync stay queued (scoped to their child) and
    // will sync on a future login; nothing is deleted here.
    try {
      await ref.read(syncServiceProvider).sync();
    } catch (_) {
      // Offline, or the sync attempt didn't go through -- proceed with
      // logout anyway.
    }
    await _api.logout();
    state = const AuthState();
    // Re-lock the parent area so a fresh sign-in (possibly a different
    // parent, on a shared device) must re-verify the PIN.
    ref.read(parentGateProvider.notifier).state = false;
  }

  String _extractError(Object e) {
    final str = e.toString();
    if (str.contains('EMAIL_EXISTS')) return 'Email đã được đăng ký';
    if (str.contains('INVALID_CREDENTIALS')) return 'Sai email hoặc mật khẩu';
    return 'Có lỗi xảy ra, vui lòng thử lại';
  }
}