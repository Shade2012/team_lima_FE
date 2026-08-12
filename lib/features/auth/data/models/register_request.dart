class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String role;
  final String? eventId;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    this.role = 'CUSTOMER',
    this.eventId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'username': username,
      'email': email,
      'password': password,
      'role': role,
    };
    if (eventId != null && eventId!.isNotEmpty) {
      map['eventId'] = eventId;
    }
    return map;
  }

  factory RegisterRequest.fromJson(Map<String, dynamic> json) {
    return RegisterRequest(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? 'CUSTOMER',
      eventId: json['eventId'],
    );
  }
}
