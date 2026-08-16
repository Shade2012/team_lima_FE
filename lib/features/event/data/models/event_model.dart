class Event {
  final String id;
  final String organizerId;
  final String name;
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
    required this.isSeated,
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
    return Event(
      id: json['id']?.toString() ?? '',
      organizerId: json['organizerId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isSeated: json['isSeated'] == true,
      salesStartTime: json['salesStartTime'] != null
          ? DateTime.tryParse(json['salesStartTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      salesEndTime: json['salesEndTime'] != null
          ? DateTime.tryParse(json['salesEndTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      eventDate: json['eventDate'] != null
          ? DateTime.tryParse(json['eventDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      refundEndDate: json['refundEndDate'] != null
          ? DateTime.tryParse(json['refundEndDate'].toString())
          : null,
      refundPolicy: json['refundPolicy']?.toString(),
      refundPercentage: json['refundPercentage'] is int
          ? json['refundPercentage']
          : int.tryParse(json['refundPercentage']?.toString() ?? ''),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizerId': organizerId,
      'name': name,
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
