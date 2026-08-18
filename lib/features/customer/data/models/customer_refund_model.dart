class CustomerRefundModel {
  final String id;
  final String ticketId;
  final String status; // PENDING | APPROVED | REJECTED
  final double? amount;
  final String? reason;
  final String? rejectReason;
  final DateTime? createdAt;
  final String? eventName;
  final String? categoryName;
  final String? seatCode;

  CustomerRefundModel({
    required this.id,
    required this.ticketId,
    required this.status,
    this.amount,
    this.reason,
    this.rejectReason,
    this.createdAt,
    this.eventName,
    this.categoryName,
    this.seatCode,
  });

  factory CustomerRefundModel.fromJson(Map<String, dynamic> json) {
    final ticket = json['ticket'] as Map<String, dynamic>?;
    final category = ticket?['category'] as Map<String, dynamic>?;
    final event = category?['event'] as Map<String, dynamic>? ?? ticket?['event'] as Map<String, dynamic>?;
    final seat = ticket?['seat'] as Map<String, dynamic>?;

    return CustomerRefundModel(
      id: json['id']?.toString() ?? '',
      ticketId: json['ticketId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      amount: json['amount'] is num
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? ''),
      reason: json['reason']?.toString(),
      rejectReason: json['rejectReason']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      eventName: event?['name']?.toString() ?? json['eventName']?.toString(),
      categoryName: category?['name']?.toString() ?? json['ticketCategoryName']?.toString(),
      seatCode: seat?['seatCode']?.toString() ?? json['seatCode']?.toString(),
    );
  }
}
