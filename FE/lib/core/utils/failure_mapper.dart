import 'package:dio/dio.dart';

import '../errors/failures.dart';
import '../network/api_exception.dart';

Failure mapExceptionToFailure(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 502 || statusCode == 503) {
      return ServerFailure(
        'Service unavailable. Please try again later.',
        statusCode: statusCode,
      );
    }

    final inner = error.error;
    if (inner is ApiException) {
      if (inner.statusCode == 502 ||
          inner.statusCode == 503 ||
          inner.message.toLowerCase().contains('external service')) {
        return ServerFailure(
          'Service unavailable. Please try again later.',
          statusCode: inner.statusCode,
        );
      }
      return ServerFailure(inner.message, statusCode: inner.statusCode);
    }
    return NetworkFailure(error.message ?? 'Network error.');
  }
  if (error is ApiException) {
    return ServerFailure(error.message, statusCode: error.statusCode);
  }
  return UnknownFailure(error.toString());
}
