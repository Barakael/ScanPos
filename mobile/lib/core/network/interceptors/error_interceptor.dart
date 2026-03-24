import 'package:dio/dio.dart';
import '../../error/app_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        throw NetworkException(message: 'Connection timed out');

      case DioExceptionType.connectionError:
        throw NetworkException(message: 'No internet connection');

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final responseData = err.response?.data;
        final message = _extractMessage(responseData) ?? 'Server error';

        if (statusCode == 401) {
          throw UnauthorizedException(message: message);
        }
        throw ServerException(message: message, statusCode: statusCode);

      default:
        throw ServerException(
          message: err.message ?? 'An unexpected error occurred',
        );
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? data['error'] as String?;
    }
    return null;
  }
}
