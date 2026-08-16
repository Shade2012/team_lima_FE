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
      totalQuota: json['totalQuota'] as int?,
      totalTicketsSold: json['totalTicketsSold'] as int?,
      grossRevenue: json['grossRevenue'] as int?,
      totalRefundCount: json['totalRefundCount'] as int?,
      totalRefundAmount: json['totalRefundAmount'] as int?,
      netRevenue: json['netRevenue'] as int?,
      percentageSold: (json['percentageSold'] as num?)?.toDouble(),
      refundPercentage: json['refundPercentage'] as int?,
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => EventStatisticsCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
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
      price: json['price'] as int?,
      totalQuota: json['totalQuota'] as int?,
      ticketsSold: json['ticketsSold'] as int?,
      grossRevenue: json['grossRevenue'] as int?,
      refundCount: json['refundCount'] as int?,
      totalRefundAmount: json['totalRefundAmount'] as int?,
      refundPercentage: json['refundPercentage'] as int?,
    );
  }
}
