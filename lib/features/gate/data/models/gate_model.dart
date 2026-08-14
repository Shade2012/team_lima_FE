class Gate {
  final String id;
  final String eventId;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Gate({
    required this.id,
    required this.eventId,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory Gate.fromJson(Map<String, dynamic> json) {
    return Gate(
      id: json['id']?.toString() ?? '',
      eventId: json['eventId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
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
      'eventId': eventId,
      'name': name,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
