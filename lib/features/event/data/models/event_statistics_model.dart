class EventStatistics {
  final String? eventId;
  final String? eventName;
  final int? totalQuota;
  final int? totalTicketsSold;
  final int? grossRevenue;
  final int? totalRefundCount;
  final int? totalRefundAmount;
  final int? netRevenue;
  final double? percentageSold;
  final int? refundPercentage;
  final List<EventStatisticsCategory>? categories;

  EventStatistics({
    this.eventId,
    this.eventName,
    this.totalQuota,
    this.totalTicketsSold,
    this.grossRevenue,
    this.totalRefundCount,
    this.totalRefundAmount,
    this.netRevenue,
    this.percentageSold,
    this.refundPercentage,
    this.categories,
  });

  factory EventStatistics.fromJson(Map<String, dynamic> json) {
    return EventStatistics(
      eventId: json['eventId']?.toString(),
      eventName: json['eventName']?.toString(),
      totalQuota: _parseInt(json['totalQuota']),
      totalTicketsSold: _parseInt(json['totalTicketsSold']),
      grossRevenue: _parseInt(json['grossRevenue']),
      totalRefundCount: _parseInt(json['totalRefundCount']),
      totalRefundAmount: _parseInt(json['totalRefundAmount']),
      netRevenue: _parseInt(json['netRevenue']),
      percentageSold: (json['percentageSold'] as num?)?.toDouble(),
      refundPercentage: _parseInt(json['refundPercentage']),
      categories: (json['categories'] as List<dynamic>?)
          ?.map(
            (e) => EventStatisticsCategory.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class EventStatisticsCategory {
  final String? categoryId;
  final String? categoryName;
  final int? price;
  final int? totalQuota;
  final int? ticketsSold;
  final int? grossRevenue;
  final int? refundCount;
  final int? totalRefundAmount;
  final int? refundPercentage;

  EventStatisticsCategory({
    this.categoryId,
    this.categoryName,
    this.price,
    this.totalQuota,
    this.ticketsSold,
    this.grossRevenue,
    this.refundCount,
    this.totalRefundAmount,
    this.refundPercentage,
  });

  factory EventStatisticsCategory.fromJson(Map<String, dynamic> json) {
    return EventStatisticsCategory(
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      price: _parseInt(json['price']),
      totalQuota: _parseInt(json['totalQuota']),
      ticketsSold: _parseInt(json['ticketsSold']),
      grossRevenue: _parseInt(json['grossRevenue']),
      refundCount: _parseInt(json['refundCount']),
      totalRefundAmount: _parseInt(json['totalRefundAmount']),
      refundPercentage: _parseInt(json['refundPercentage']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
