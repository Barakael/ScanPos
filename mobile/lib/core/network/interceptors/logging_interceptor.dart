import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('[API] ${options.method} ${options.path}');
    if (options.data != null) {
      print('[API] Request data: ${options.data}');
    }
    if (options.headers.containsKey('Authorization')) {
      print('[API] Auth: Bearer ${options.headers['Authorization'].toString().substring(0, 20)}...');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('[API] ${response.statusCode} ${response.requestOptions.path}');
    print('[API] Response data: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('[API ERROR] ${err.message} ${err.requestOptions.path}');
    print('[API ERROR] Type: ${err.type}');
    print('[API ERROR] Response: ${err.response?.data}');
    print('[API ERROR] Status: ${err.response?.statusCode}');
    handler.next(err);
  }
}
