import 'user_model.dart';

class RegisterResponse {
  final String message;
  final UserModel? user;

  RegisterResponse({
    required this.message,
    this.user,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    // Backend API contract: { "message": "Success", "data": { "id": "...", "email": "...", ... } }
    UserModel? extractedUser;
    if (json['data'] is Map<String, dynamic>) {
      extractedUser = UserModel.fromJson(json['data']);
    } else if (json['user'] is Map<String, dynamic>) {
      extractedUser = UserModel.fromJson(json['user']);
    }

    return RegisterResponse(
      message: json['message']?.toString() ?? 'Success',
      user: extractedUser,
    );
  }
}
