// ignore_for_file: unawaited_futures
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/auth_models.dart';
import '../../shared/repositories/auth_repository.dart';
import '../../../../core/analytics/analytics_service.dart';
import 'auth_view_state.dart';

/// Provider for [AuthViewModel].
final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthViewState>((ref) {
  return AuthViewModel(ref.watch(authRepositoryProvider));
});

/// Bridge provider that converts MVVM [AuthViewState] to [AsyncValue<AuthUserModel?>]
/// for use by the rest of the app (router, _RoleGate, sidebar).
final activeUserProvider = Provider<AsyncValue<AuthUserModel?>>((ref) {
  final state = ref.watch(authViewModelProvider);
  return switch (state) {
    AuthViewStateLoading() => const AsyncLoading(),
    AuthViewStateError() => const AsyncData(null),
    AuthViewStateData(:final user) => AsyncData(user),
  };
});

/// MVVM ViewModel for the Auth feature.
///
/// Manages login, logout, and Google Sign-In state via [AuthViewState].
/// All analytics calls are made here — never in widgets.
class AuthViewModel extends StateNotifier<AuthViewState> {
  AuthViewModel(this._repository) : super(const AuthViewStateLoading()) {
    _loadCurrentUser();
  }

  final AuthRepository _repository;

  Future<void> loginWithPassword(String email, String password) async {
    state = const AuthViewStateLoading();
    try {
      final user = await _repository.login(email: email, password: password);
      state = AuthViewStateData(user, loginMethod: 'password');
      AnalyticsService.logEvent('login', {'method': 'password'});
    } catch (e) {
      state = const AuthViewStateError('Email hoặc mật khẩu không đúng');
    }
  }

  /// Initiates Google Sign-In and exchanges the ID token with the backend.
  /// Backend endpoint will be added in Phase 4.
  Future<void> loginWithGoogle(String idToken) async {
    state = const AuthViewStateLoading();
    try {
      final user = await _repository.googleSignIn(idToken);
      state = AuthViewStateData(user, loginMethod: 'google');
      AnalyticsService.logEvent('login', {'method': 'google'});
    } catch (e) {
      state = const AuthViewStateError('Đăng nhập Google thất bại');
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      state = const AuthViewStateData(null);
      AnalyticsService.logEvent('logout');
    }
  }

  Future<void> _loadCurrentUser() async {
    if (!await _repository.hasAccessToken()) {
      state = const AuthViewStateData(null);
      return;
    }
    try {
      final user = await _repository.me();
      state = AuthViewStateData(user);
    } catch (e) {
      state = const AuthViewStateData(null);
    }
  }
}
