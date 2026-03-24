import 'package:dio/dio.dart';
import '../error/app_exception.dart';
import 'api_client.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import '../storage/secure_storage.dart';

class RestClient implements ApiClient {
  final Dio _dio;

  RestClient({required String baseUrl, required SecureStorage secureStorage})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    _dio.interceptors.addAll([
      AuthInterceptor(secureStorage: secureStorage),
      ErrorInterceptor(),
      LoggingInterceptor(),
    ]);
  }

  // Expose Dio instance for ApiService
  Dio get dio => _dio;
  @override
  Future<T> get<T>({
    required String endpoint,
    required T Function(dynamic json) parser,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
      return parser(_extractData(response.data));
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<T> post<T>({
    required String endpoint,
    required T Function(dynamic json) parser,
    dynamic data,
  }) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return parser(_extractData(response.data));
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<T> put<T>({
    required String endpoint,
    required T Function(dynamic json) parser,
    dynamic data,
  }) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return parser(_extractData(response.data));
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<T> patch<T>({
    required String endpoint,
    required T Function(dynamic json) parser,
    dynamic data,
  }) async {
    try {
      final response = await _dio.patch(endpoint, data: data);
      return parser(_extractData(response.data));
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> delete({required String endpoint}) async {
    try {
      await _dio.delete(endpoint);
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<int>> downloadBytes({required String endpoint}) async {
    try {
      final response = await _dio.get<List<int>>(
        endpoint,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? [];
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  /// Backend wraps responses in {success, message, data}.
  /// Extract data field if present, otherwise return raw response.
  dynamic _extractData(dynamic responseBody) {
    if (responseBody is Map<String, dynamic> &&
        responseBody.containsKey('data')) {
      return responseBody['data'];
    }
    return responseBody;
  }
}
