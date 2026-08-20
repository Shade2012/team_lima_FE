import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'mock_interceptor.dart';

class DioClient {
  static final DioClient _instance = DioClient._();
  late final Dio _dio;

  factory DioClient() {
    return _instance;
  }

  DioClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 90),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Optional mock interceptor (disabled by default, uses Node.js mock server at baseUrl)
    _dio.interceptors.add(MockInterceptor(enabled: false));

    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
      ),
    );
  }

  Dio get dio => _dio;

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }
}
