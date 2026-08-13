class CreateEventRequest {
  final String name;
  final bool isSeated;
  final DateTime salesStartTime;
  final DateTime salesEndTime;
  final DateTime eventDate;
  final DateTime? refundEndDate;
  final String? refundPolicy;
  final int? refundPercentage;

  CreateEventRequest({
    required this.name,
    required this.isSeated,
    required this.salesStartTime,
    required this.salesEndTime,
    required this.eventDate,
    this.refundEndDate,
    this.refundPolicy,
    this.refundPercentage,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isSeated': isSeated,
      'salesStartTime': salesStartTime.toIso8601String(),
      'salesEndTime': salesEndTime.toIso8601String(),
      'eventDate': eventDate.toIso8601String(),
      if (refundEndDate != null)
        'refundEndDate': refundEndDate!.toIso8601String(),
      if (refundPolicy != null && refundPolicy!.isNotEmpty)
        'refundPolicy': refundPolicy,
      if (refundPercentage != null) 'refundPercentage': refundPercentage,
    };
  }
}
