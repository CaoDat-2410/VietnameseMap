import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exception.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('→ ${options.method} ${options.uri}');
      if (options.queryParameters.isNotEmpty) {
        debugPrint('  query: ${options.queryParameters}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('✗ ${err.requestOptions.uri}: ${err.message}');
    }
    handler.next(err);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _mapToApiException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: exception,
        message: exception.message,
      ),
    );
  }

  ApiException _mapToApiException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(message: 'Request timed out. Please try again.');

      case DioExceptionType.connectionError:
        return const ApiException(message: 'No internet connection.');

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final serverMessage = _extractServerMessage(err.response);
        return ApiException(
          message: serverMessage ?? _defaultMessageFor(statusCode),
          statusCode: statusCode,
          data: err.response?.data,
        );

      default:
        return ApiException(
          message: err.message ?? 'An unexpected error occurred.',
        );
    }
  }

  String? _extractServerMessage(Response? response) {
    try {
      final data = response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String?;
      }
    } catch (_) {}
    return null;
  }

  String _defaultMessageFor(int? statusCode) => switch (statusCode) {
        400 => 'Bad request.',
        401 => 'Unauthorized.',
        403 => 'Forbidden.',
        404 => 'Resource not found.',
        500 => 'Internal server error.',
        502 || 503 => 'Service unavailable. Please try again later.',
        _ => 'Server error (code $statusCode).',
      };
}
