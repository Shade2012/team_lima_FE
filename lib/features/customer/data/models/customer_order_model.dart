class CustomerOrderItem {
  final String id;
  final String status;
  final String? categoryName;
  final double? price;
  final String? seatCode;

  CustomerOrderItem({
    required this.id,
    required this.status,
    this.categoryName,
    this.price,
    this.seatCode,
  });

  factory CustomerOrderItem.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final seat = json['seat'] as Map<String, dynamic>?;

    return CustomerOrderItem(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'AVAILABLE',
      categoryName: category?['name']?.toString(),
      price: category?['price'] is num
          ? (category!['price'] as num).toDouble()
          : double.tryParse(category?['price']?.toString() ?? ''),
      seatCode: seat?['seatCode']?.toString(),
    );
  }
}

class CustomerOrderModel {
  final String id;
  final String customerId;
  final String eventId;
  final String? eventName;
  final DateTime? eventDate;
  final double totalAmount;
  final String status; // HELD | PAYMENT_PENDING | PAID | CANCELLED | FULL_REFUND | PARTIAL_REFUND
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final List<CustomerOrderItem> tickets;

  CustomerOrderModel({
    required this.id,
    required this.customerId,
    required this.eventId,
    this.eventName,
    this.eventDate,
    required this.totalAmount,
    required this.status,
    this.expiresAt,
    this.createdAt,
    this.tickets = const [],
  });

  factory CustomerOrderModel.fromJson(Map<String, dynamic> json) {
    final event = json['event'] as Map<String, dynamic>?;
    final ticketsList = json['tickets'] as List<dynamic>? ?? [];

    return CustomerOrderModel(
      id: json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      eventId: json['eventId']?.toString() ?? '',
      eventName: event?['name']?.toString(),
      eventDate: event?['eventDate'] != null
          ? DateTime.tryParse(event!['eventDate'].toString())
          : null,
      totalAmount: json['totalAmount'] is num
          ? (json['totalAmount'] as num).toDouble()
          : double.tryParse(json['totalAmount']?.toString() ?? '') ?? 0.0,
      status: json['status']?.toString() ?? 'HELD',
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      tickets: ticketsList
          .map((t) => CustomerOrderItem.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
