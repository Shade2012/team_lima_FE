class RegisterResponse {
  final String message;
  final String? userId;

  RegisterResponse({
    required this.message,
    this.userId,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      message: json['message'] ?? '',
      userId: json['userId'],
    );
  }
}
