class GateOperatorData {
  final String username;
  final String email;
  final String password;
  final String eventId;

  GateOperatorData({
    required this.username,
    required this.email,
    required this.password,
    required this.eventId,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'eventId': eventId,
    };
  }
}

class GateOperatorRequest {
  final List<GateOperatorData> operators;

  GateOperatorRequest({required this.operators});

  factory GateOperatorRequest.single({
    required String username,
    required String email,
    required String password,
    required String eventId,
  }) {
    return GateOperatorRequest(
      operators: [
        GateOperatorData(
          username: username,
          email: email,
          password: password,
          eventId: eventId,
        ),
      ],
    );
  }

  dynamic toJson() {
    if (operators.length == 1) {
      return operators.first.toJson();
    }
    return operators.map((op) => op.toJson()).toList();
  }
}
