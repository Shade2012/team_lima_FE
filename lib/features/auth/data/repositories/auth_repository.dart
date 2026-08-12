import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../models/user_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class AuthRepository {
  final DioClient _dioClient = DioClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'jwt_access_token';

  /// Returns currently stored token if any.
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Saves token in secure storage and attaches to Dio client headers.
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    _dioClient.setToken(token);
  }

  /// Clears token from storage and Dio headers.
  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    _dioClient.clearToken();
  }

  /// Initialize token on app startup if stored.
  Future<String?> initToken() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      _dioClient.setToken(token);
    }
    return token;
  }

  /// POST /users/login
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.login,
        data: request.toJson(),
      );
      final loginResponse = LoginResponse.fromJson(response.data);
      if (loginResponse.token.isNotEmpty) {
        await saveToken(loginResponse.token);
      }
      return loginResponse;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Login failed'));
    }
  }

  /// POST /users/register
  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.register,
        data: request.toJson(),
      );
      return RegisterResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Registration failed'));
    }
  }

  /// GET /users/profile
  Future<UserModel> getProfile() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.profile);
      final data = response.data['data'];
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to fetch user profile'),
      );
    }
  }

  /// POST /users/logout
  Future<bool> logout() async {
    try {
      final response = await _dioClient.dio.post(ApiConstants.logout);
      await clearToken();
      return response.data['data'] == true;
    } on DioException catch (e) {
      // Even if network call fails, clear local token
      await clearToken();
      throw Exception(_extractErrorMessage(e, fallback: 'Logout failed'));
    }
  }

  /// PATCH /users/profile
  Future<UserModel> updateProfile({String? username, String? email}) async {
    try {
      final body = <String, dynamic>{};
      if (username != null && username.isNotEmpty) body['username'] = username;
      if (email != null && email.isNotEmpty) body['email'] = email;

      final response = await _dioClient.dio.patch(
        ApiConstants.profile,
        data: body,
      );
      return UserModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Update profile failed'),
      );
    }
  }

  /// DELETE /users
  Future<bool> deleteAccount() async {
    try {
      final response = await _dioClient.dio.delete(ApiConstants.deleteUser);
      await clearToken();
      return response.data['data'] == true;
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Delete account failed'),
      );
    }
  }

  /// Helper to extract clean error message from NestJS HttpExceptionFilter response:
  /// { "status_code": 400, "message": "..." or ["error1", "error2"] }
  String _extractErrorMessage(DioException e, {required String fallback}) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String) {
          return message;
        } else if (message is List) {
          return message.map((m) => m.toString()).join('\n');
        }
      }
    }
    return e.message ?? fallback;
  }
}
