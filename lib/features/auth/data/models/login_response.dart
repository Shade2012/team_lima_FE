import 'user_model.dart';

class LoginResponse {
  final String token;
  final String message;
  final UserModel? user;

  LoginResponse({
    required this.token,
    required this.message,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Backend API contract: { "message": "Success", "data": "<jwt_access_token>" }
    String extractedToken = '';
    if (json['data'] is String) {
      extractedToken = json['data'];
    } else if (json['token'] is String) {
      extractedToken = json['token'];
    }

    UserModel? extractedUser;
    if (json['data'] is Map<String, dynamic>) {
      extractedUser = UserModel.fromJson(json['data']);
    } else if (json['user'] is Map<String, dynamic>) {
      extractedUser = UserModel.fromJson(json['user']);
    }

    return LoginResponse(
      token: extractedToken,
      message: json['message']?.toString() ?? 'Success',
      user: extractedUser,
    );
  }
}
