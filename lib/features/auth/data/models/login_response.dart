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
    return LoginResponse(
      token: json['token'] ?? '',
      message: json['message'] ?? '',
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}
