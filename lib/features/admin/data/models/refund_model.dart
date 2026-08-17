class RefundRequest {
  final String? id;
  final String? reason;
  final int? amount;
  final String? ticketId;
  final String? status;
  final String? rejectReason;
  final String? adminId;
  final String? providerRefundId;
  final DateTime? processedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? customerName;
  final RefundTicket? ticket;

  RefundRequest({
    this.id,
    this.reason,
    this.amount,
    this.ticketId,
    this.status,
    this.rejectReason,
    this.adminId,
    this.providerRefundId,
    this.processedAt,
    this.createdAt,
    this.updatedAt,
    this.customerName,
    this.ticket,
  });

  String? get orderId => ticket?.order?.id;
  String? get eventName => ticket?.category?.event?.name;
  DateTime? get eventDate => ticket?.category?.event?.eventDate;
  String? get ticketCategoryName => ticket?.category?.name;
  int? get ticketCategoryPrice => ticket?.category?.price;
  String? get ticketStatus => ticket?.status;
  String? get seatCode => ticket?.seat?.seatCode;
  String? get orderStatus => ticket?.order?.status;

  factory RefundRequest.fromJson(Map<String, dynamic> json) {
    final ticketData = json['ticket'] as Map<String, dynamic>?;
    final categoryData = ticketData?['category'] as Map<String, dynamic>?;
    final eventData = categoryData?['event'] as Map<String, dynamic>?;
    final seatData = ticketData?['seat'] as Map<String, dynamic>?;
    final orderData = ticketData?['order'] as Map<String, dynamic>?;

    return RefundRequest(
      id: json['id']?.toString(),
      reason: json['reason']?.toString(),
      amount: json['amount'] as int?,
      ticketId: json['ticketId']?.toString(),
      status: json['status']?.toString(),
      rejectReason: json['rejectReason']?.toString(),
      adminId: json['adminId']?.toString(),
      providerRefundId: json['providerRefundId']?.toString(),
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      customerName: json['customerName']?.toString(),
      ticket: ticketData != null
          ? RefundTicket.fromJson(ticketData)
          : null,
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

class RefundTicket {
  final String? id;
  final String? status;
  final RefundCategory? category;
  final RefundSeat? seat;
  final RefundOrder? order;

  RefundTicket({
    this.id,
    this.status,
    this.category,
    this.seat,
    this.order,
  });

  factory RefundTicket.fromJson(Map<String, dynamic> json) {
    return RefundTicket(
      id: json['id']?.toString(),
      status: json['status']?.toString(),
      category: json['category'] != null
          ? RefundCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      seat: json['seat'] != null
          ? RefundSeat.fromJson(json['seat'] as Map<String, dynamic>)
          : null,
      order: json['order'] != null
          ? RefundOrder.fromJson(json['order'] as Map<String, dynamic>)
          : null,
    );
  }
}

class RefundCategory {
  final String? id;
  final String? name;
  final int? price;
  final RefundEvent? event;

  RefundCategory({
    this.id,
    this.name,
    this.price,
    this.event,
  });

  factory RefundCategory.fromJson(Map<String, dynamic> json) {
    return RefundCategory(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      price: json['price'] as int?,
      event: json['event'] != null
          ? RefundEvent.fromJson(json['event'] as Map<String, dynamic>)
          : null,
    );
  }
}

class RefundEvent {
  final String? id;
  final String? name;
  final DateTime? eventDate;

  RefundEvent({
    this.id,
    this.name,
    this.eventDate,
  });

  factory RefundEvent.fromJson(Map<String, dynamic> json) {
    return RefundEvent(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      eventDate: json['eventDate'] != null
          ? DateTime.tryParse(json['eventDate'].toString())
          : null,
    );
  }
}

class RefundSeat {
  final String? id;
  final String? seatCode;

  RefundSeat({
    this.id,
    this.seatCode,
  });

  factory RefundSeat.fromJson(Map<String, dynamic> json) {
    return RefundSeat(
      id: json['id']?.toString(),
      seatCode: json['seatCode']?.toString(),
    );
  }
}

class RefundOrder {
  final String? id;
  final String? customerId;
  final String? status;

  RefundOrder({
    this.id,
    this.customerId,
    this.status,
  });

  factory RefundOrder.fromJson(Map<String, dynamic> json) {
    return RefundOrder(
      id: json['id']?.toString(),
      customerId: json['customerId']?.toString(),
      status: json['status']?.toString(),
    );
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
