class CreateGateRequest {
  final String eventId;
  final String name;

  CreateGateRequest({
    required this.eventId,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'name': name,
    };
  }
}
