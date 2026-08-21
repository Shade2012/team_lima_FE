class CreateEventRequest {
  final String name;
  final String description;
  final DateTime salesStartTime;
  final DateTime salesEndTime;
  final DateTime eventDate;
  final DateTime refundEndDate;
  final String refundPolicy;
  final int refundPercentage;

  CreateEventRequest({
    required this.name,
    required this.description,
    required this.salesStartTime,
    required this.salesEndTime,
    required this.eventDate,
    required this.refundEndDate,
    required this.refundPolicy,
    required this.refundPercentage,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'salesStartTime': salesStartTime.toUtc().toIso8601String(),
      'salesEndTime': salesEndTime.toUtc().toIso8601String(),
      'eventDate': eventDate.toUtc().toIso8601String(),
      'refundEndDate': refundEndDate.toUtc().toIso8601String(),
      'refundPolicy': refundPolicy,
      'refundPercentage': refundPercentage,
    };
  }
}
