import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../models/auth_models.dart';
import '../token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(DioClient(), ref.watch(tokenStorageProvider));
});

class AuthRepository {
  const AuthRepository(this._client, this._storage);

  final DioClient _client;
  final TokenStorage _storage;

  Future<AuthUserModel> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/v1/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = res.data!['data'] as Map<String, dynamic>;
    final auth = AuthResponseModel.fromJson(data);
    await _storage.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );
    return auth.user;
  }

  Future<AuthUserModel> me() async {
    final res = await _client.get<Map<String, dynamic>>('/api/v1/auth/me');
    return AuthUserModel.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final refreshToken = await _storage.readRefreshToken();
    try {
      await _client.post<Map<String, dynamic>>(
        '/api/v1/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } on DioException {
      // Local logout still wins if the server token is already invalid.
    } finally {
      await _storage.clear();
    }
  }

  Future<AuthUserModel> googleSignIn(String idToken) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/v1/auth/google',
      data: {'idToken': idToken},
    );
    final data = res.data!['data'] as Map<String, dynamic>;
    final auth = AuthResponseModel.fromJson(data);
    await _storage.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );
    return auth.user;
  }

  Future<bool> hasAccessToken() async {
    final token = await _storage.readAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<AuthUserModel> registerWithPassword({
    required String email,
    required String password,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/v1/auth/register',
      data: {'email': email, 'password': password},
    );
    final data = res.data!['data'] as Map<String, dynamic>;
    final auth = AuthResponseModel.fromJson(data);
    await _storage.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );
    return auth.user;
  }
}
