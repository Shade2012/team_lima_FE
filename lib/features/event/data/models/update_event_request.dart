class UpdateEventRequest {
  final String? name;
  final String? description;
  final bool? isSeated;
  final DateTime? salesStartTime;
  final DateTime? salesEndTime;
  final DateTime? eventDate;
  final DateTime? refundEndDate;
  final String? refundPolicy;
  final int? refundPercentage;

  UpdateEventRequest({
    this.name,
    this.description,
    this.isSeated,
    this.salesStartTime,
    this.salesEndTime,
    this.eventDate,
    this.refundEndDate,
    this.refundPolicy,
    this.refundPercentage,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (name != null && name!.isNotEmpty) {
      data['name'] = name;
    }
    if (description != null && description!.isNotEmpty) {
      data['description'] = description;
    }
    if (isSeated != null) {
      data['isSeated'] = isSeated;
    }
    if (salesStartTime != null) {
      data['salesStartTime'] = salesStartTime!.toUtc().toIso8601String();
    }
    if (salesEndTime != null) {
      data['salesEndTime'] = salesEndTime!.toUtc().toIso8601String();
    }
    if (eventDate != null) {
      data['eventDate'] = eventDate!.toUtc().toIso8601String();
    }
    if (refundEndDate != null) {
      data['refundEndDate'] = refundEndDate!.toUtc().toIso8601String();
    }
    if (refundPolicy != null) {
      data['refundPolicy'] = refundPolicy;
    }
    if (refundPercentage != null) {
      data['refundPercentage'] = refundPercentage;
    }
    return data;
  }
}
