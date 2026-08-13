class CreateTicketCategoryRequest {
  final String eventId;
  final String name;
  final int price;
  final int totalQuota;

  CreateTicketCategoryRequest({
    required this.eventId,
    required this.name,
    required this.price,
    required this.totalQuota,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'name': name,
      'price': price,
      'totalQuota': totalQuota,
    };
  }
}
