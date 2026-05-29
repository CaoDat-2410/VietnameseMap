import 'package:dio/dio.dart';

import '../errors/failures.dart';
import '../network/api_exception.dart';

Failure mapExceptionToFailure(Object error) {
  if (error is DioException) {
    final inner = error.error;
    if (inner is ApiException) {
      return ServerFailure(inner.message, statusCode: inner.statusCode);
    }
    return NetworkFailure(error.message ?? 'Network error.');
  }
  if (error is ApiException) {
    return ServerFailure(error.message, statusCode: error.statusCode);
  }
  return UnknownFailure(error.toString());
}
