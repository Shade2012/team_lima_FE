class RefundRequest {
  final String? id;
  final String? orderId;
  final String? customerName;
  final String? customerEmail;
  final String? eventName;
  final String? eventNameFull;
  final String? status;
  final int? amount;
  final DateTime? requestedAt;
  final String? reason;
  final String? notes;
  final String? ticketCategoryId;
  final String? ticketCategoryName;

  RefundRequest({
    this.id,
    this.orderId,
    this.customerName,
    this.customerEmail,
    this.eventName,
    this.eventNameFull,
    this.status,
    this.amount,
    this.requestedAt,
    this.reason,
    this.notes,
    this.ticketCategoryId,
    this.ticketCategoryName,
  });

  factory RefundRequest.fromJson(Map<String, dynamic> json) {
    return RefundRequest(
      id: json['id']?.toString(),
      orderId: json['orderId']?.toString() ?? json['order_id']?.toString(),
      customerName: json['customerName']?.toString() ?? json['customer_name']?.toString(),
      customerEmail: json['customerEmail']?.toString() ?? json['customer_email']?.toString(),
      eventName: json['eventName']?.toString() ?? json['event_name']?.toString(),
      eventNameFull: json['eventNameFull']?.toString(),
      status: json['status']?.toString(),
      amount: json['amount'] as int?,
      requestedAt: json['requestedAt'] != null
          ? DateTime.tryParse(json['requestedAt'].toString())
          : null,
      reason: json['reason']?.toString(),
      notes: json['notes']?.toString(),
      ticketCategoryId: json['ticketCategoryId']?.toString(),
      ticketCategoryName: json['ticketCategoryName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'eventName': eventName,
      'status': status,
      'amount': amount,
      'requestedAt': requestedAt?.toIso8601String(),
      'reason': reason,
      'notes': notes,
    };
  }

  String get initials {
    if (customerName == null || customerName!.isEmpty) return '??';
    final parts = customerName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length > 2 ? 2 : parts[0].length).toUpperCase();
  }
}

class RefundStats {
  final int? pendingCount;
  final int? totalRefunded;
  final int? activeDisputes;

  RefundStats({
    this.pendingCount,
    this.totalRefunded,
    this.activeDisputes,
  });

  factory RefundStats.fromJson(Map<String, dynamic> json) {
    return RefundStats(
      pendingCount: json['pendingCount'] as int? ?? json['pending_count'] as int?,
      totalRefunded: json['totalRefunded'] as int? ?? json['total_refunded'] as int?,
      activeDisputes: json['activeDisputes'] as int? ?? json['active_disputes'] as int?,
    );
  }
}
