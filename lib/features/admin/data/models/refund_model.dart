class RefundRequest {
  final String? id;
  final String? orderId;
  final String? customerName;
  final String? eventName;
  final String? status;
  final int? amount;
  final DateTime? requestedAt;
  final String? reason;
  final String? rejectReason;
  final String? ticketCategoryId;
  final String? ticketCategoryName;

  RefundRequest({
    this.id,
    this.orderId,
    this.customerName,
    this.eventName,
    this.status,
    this.amount,
    this.requestedAt,
    this.reason,
    this.rejectReason,
    this.ticketCategoryId,
    this.ticketCategoryName,
  });

  factory RefundRequest.fromJson(Map<String, dynamic> json) {
    final ticket = json['ticket'] as Map<String, dynamic>?;
    final category = ticket?['category'] as Map<String, dynamic>?;
    final event = category?['event'] as Map<String, dynamic>?;
    final order = json['order'] as Map<String, dynamic>?;
    final customer = json['customer'] as Map<String, dynamic>?;

    return RefundRequest(
      id: json['id']?.toString(),
      orderId: order?['orderId']?.toString() ?? ticket?['orderId']?.toString(),
      customerName: customer?['username']?.toString() ?? json['customerName']?.toString(),
      eventName: event?['name']?.toString() ?? json['eventName']?.toString(),
      status: json['status']?.toString(),
      amount: json['amount'] as int?,
      requestedAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      reason: json['reason']?.toString(),
      rejectReason: json['rejectReason']?.toString(),
      ticketCategoryId: category?['id']?.toString(),
      ticketCategoryName: category?['name']?.toString(),
    );
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
  final int pendingCount;
  final int totalRefunded;
  final int totalRefundAmount;

  const RefundStats({
    this.pendingCount = 0,
    this.totalRefunded = 0,
    this.totalRefundAmount = 0,
  });

  factory RefundStats.fromRefunds(List<RefundRequest> refunds) {
    final pending = refunds.where((r) => r.status == 'PENDING').length;
    final approved = refunds.where((r) => r.status == 'APPROVED');
    final totalAmount = approved.fold<int>(0, (sum, r) => sum + (r.amount ?? 0));
    return RefundStats(
      pendingCount: pending,
      totalRefunded: approved.length,
      totalRefundAmount: totalAmount,
    );
  }
}
