class CreateEventRequest {
  final String name;
  final String description;
  final bool isSeated;
  final DateTime salesStartTime;
  final DateTime salesEndTime;
  final DateTime eventDate;
  final DateTime refundEndDate;
  final String refundPolicy;
  final int refundPercentage;

  CreateEventRequest({
    required this.name,
    required this.description,
    required this.isSeated,
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
      'isSeated': isSeated,
      'salesStartTime': salesStartTime.toIso8601String(),
      'salesEndTime': salesEndTime.toIso8601String(),
      'eventDate': eventDate.toIso8601String(),
      'refundEndDate': refundEndDate.toIso8601String(),
      'refundPolicy': refundPolicy,
      'refundPercentage': refundPercentage,
    };
  }
}
