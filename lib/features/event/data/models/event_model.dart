class Event {
  final String id;
  final String organizerId;
  final String name;
  final String? imageUrl;
  final String? description;
  final bool isSeated;
  final DateTime salesStartTime;
  final DateTime salesEndTime;
  final DateTime eventDate;
  final DateTime? refundEndDate;
  final String? refundPolicy;
  final int? refundPercentage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Event({
    required this.id,
    required this.organizerId,
    required this.name,
    this.imageUrl,
    this.description,
    this.isSeated = false,
    required this.salesStartTime,
    required this.salesEndTime,
    required this.eventDate,
    this.refundEndDate,
    this.refundPolicy,
    this.refundPercentage,
    this.createdAt,
    this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      final str = val.toString();
      final dt = DateTime.tryParse(str);
      if (dt == null) return DateTime.now();

      // If the string contains no timezone offset (naive ISO string from backend),
      // parse it as local time rather than assuming UTC.
      if (!str.contains('Z') && !str.contains('+') && !str.contains('-')) {
        return DateTime(
          dt.year,
          dt.month,
          dt.day,
          dt.hour,
          dt.minute,
          dt.second,
          dt.millisecond,
          dt.microsecond,
        );
      }
      return dt.toLocal();
    }

    return Event(
      id: json['id']?.toString() ?? '',
      organizerId: json['organizerId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      description: json['description']?.toString(),
      isSeated: json['isSeated'] == true,
      salesStartTime: parseDate(json['salesStartTime']),
      salesEndTime: parseDate(json['salesEndTime']),
      eventDate: parseDate(json['eventDate']),
      refundEndDate: json['refundEndDate'] != null ? parseDate(json['refundEndDate']) : null,
      refundPolicy: json['refundPolicy']?.toString(),
      refundPercentage: json['refundPercentage'] is int
          ? json['refundPercentage']
          : int.tryParse(json['refundPercentage']?.toString() ?? ''),
      createdAt: json['createdAt'] != null ? parseDate(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? parseDate(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizerId': organizerId,
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'isSeated': isSeated,
      'salesStartTime': salesStartTime.toIso8601String(),
      'salesEndTime': salesEndTime.toIso8601String(),
      'eventDate': eventDate.toIso8601String(),
      'refundEndDate': refundEndDate?.toIso8601String(),
      'refundPolicy': refundPolicy,
      'refundPercentage': refundPercentage,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
