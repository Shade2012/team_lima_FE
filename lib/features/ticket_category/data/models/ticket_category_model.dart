class TicketCategory {
  final String id;
  final String eventId;
  final String name;
  final int price;
  final int totalQuota;

  TicketCategory({
    required this.id,
    required this.eventId,
    required this.name,
    required this.price,
    required this.totalQuota,
  });

  factory TicketCategory.fromJson(Map<String, dynamic> json) {
    return TicketCategory(
      id: json['id']?.toString() ?? '',
      eventId: json['eventId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: json['price'] is int
          ? json['price']
          : int.tryParse(json['price']?.toString() ?? '') ?? 0,
      totalQuota: json['totalQuota'] is int
          ? json['totalQuota']
          : int.tryParse(json['totalQuota']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'name': name,
      'price': price,
      'totalQuota': totalQuota,
    };
  }
}
