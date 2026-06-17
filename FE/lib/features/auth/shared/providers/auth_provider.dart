import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_models.dart';
import '../repositories/auth_repository.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthUserModel?>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

final currentUserProvider = FutureProvider<AuthUserModel?>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  if (!await repository.hasAccessToken()) return null;
  return repository.me();
});

final activeUserProvider = Provider<AsyncValue<AuthUserModel?>>((ref) {
  final loginState = ref.watch(authControllerProvider);
  final loggedInUser = loginState.valueOrNull;
  if (loggedInUser != null) return AsyncData(loggedInUser);
  return ref.watch(currentUserProvider);
});

class AuthController extends StateNotifier<AsyncValue<AuthUserModel?>> {
  AuthController(this._repository) : super(const AsyncData(null));

  final AuthRepository _repository;

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.login(email: email, password: password),
    );
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    await _repository.logout();
    state = const AsyncData(null);
  }
}
