import 'package:dio/dio.dart';

import '../config/app_config.dart';
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
    Options? options,
  }) =>
      _dio.delete<T>(path, data: data, options: options);
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
    final isSafeToRetry = err.requestOptions.method == 'GET';

    final retryCount = err.requestOptions.extra['_retryCount'] as int? ?? 0;
    if (!isServerError || !isSafeToRetry || retryCount >= maxRetries) {
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
