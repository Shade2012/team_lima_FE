class GateOperatorData {
  final String username;
  final String email;
  final String password;
  final String eventId;
  final String gateId;

  GateOperatorData({
    required this.username,
    required this.email,
    required this.password,
    required this.eventId,
    required this.gateId,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'eventId': eventId,
      'gateId': gateId,
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
    required String gateId,
  }) {
    return GateOperatorRequest(
      operators: [
        GateOperatorData(
          username: username,
          email: email,
          password: password,
          eventId: eventId,
          gateId: gateId,
        ),
      ],
    );
  }

  dynamic toJson() {
    return operators.map((op) => op.toJson()).toList();
  }
}
