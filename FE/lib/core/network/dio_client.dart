import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../../features/auth/shared/models/auth_models.dart';
import '../../features/auth/shared/token_storage.dart';
import 'api_interceptors.dart';

class DioClient {
  DioClient() : _dio = _buildDio();

  final Dio _dio;

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    dio.interceptors.addAll([
      AuthTokenInterceptor(dio),
      LoggingInterceptor(),
      RetryInterceptor(dio, maxRetries: 1),
      ErrorInterceptor(),
    ]);
    return dio;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.post<T>(path, data: data, options: options);

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.put<T>(path, data: data, options: options);

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
}

class AuthTokenInterceptor extends Interceptor {
  AuthTokenInterceptor(this._dio);

  final Dio _dio;
  final TokenStorage _storage = TokenStorage();
  static Future<bool>? _refreshFuture;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;
    final alreadyRetried = err.requestOptions.extra['_authRetried'] == true;
    final isAuthPath = path.contains('/api/v1/auth/login') ||
        path.contains('/api/v1/auth/refresh');

    if (status != 401 || alreadyRetried || isAuthPath) {
      handler.next(err);
      return;
    }

    final refreshed = await _refreshOnce();
    if (!refreshed) {
      handler.next(err);
      return;
    }

    try {
      final token = await _storage.readAccessToken();
      final options = err.requestOptions;
      options.extra['_authRetried'] = true;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.resolve(await _dio.fetch(options));
    } catch (_) {
      handler.next(err);
    }
  }

  Future<bool> _refreshOnce() {
    _refreshFuture ??= _refresh().whenComplete(() => _refreshFuture = null);
    return _refreshFuture!;
  }

  Future<bool> _refresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
      final res = await dio.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = res.data?['data'] as Map<String, dynamic>?;
      if (data == null) return false;
      final auth = AuthResponseModel.fromJson(data);
      await _storage.saveTokens(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
      );
      return true;
    } catch (_) {
      await _storage.clear();
      return false;
    }
  }
}

/// Retries requests up to [maxRetries] times on 5xx server errors.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio, {required this.maxRetries});

  final Dio _dio;
  final int maxRetries;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isServerError =
        err.response?.statusCode != null && err.response!.statusCode! >= 500;

    final retryCount = err.requestOptions.extra['_retryCount'] as int? ?? 0;
    if (!isServerError || retryCount >= maxRetries) {
      handler.next(err);
      return;
    }

    err.requestOptions.extra['_retryCount'] = retryCount + 1;

    try {
      final response = await _dio.fetch(err.requestOptions);
      handler.resolve(response);
    } catch (e) {
      if (e is DioException) {
        handler.next(e);
      } else {
        handler.next(err);
      }
    }
  }
}
