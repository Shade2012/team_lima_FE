class EventStatistics {
  final String eventId;
  final String eventName;
  final int totalQuota;
  final int totalTicketsSold;
  final int grossRevenue;
  final int totalRefundCount;
  final int totalRefundAmount;
  final int netRevenue;
  final double percentageSold;
  final int refundPercentage;
  final List<EventStatisticsCategory> categories;

  EventStatistics({
    required this.eventId,
    required this.eventName,
    required this.totalQuota,
    required this.totalTicketsSold,
    required this.grossRevenue,
    required this.totalRefundCount,
    required this.totalRefundAmount,
    required this.netRevenue,
    required this.percentageSold,
    required this.refundPercentage,
    required this.categories,
  });

  factory EventStatistics.fromJson(Map<String, dynamic> json) {
    return EventStatistics(
      eventId: json['eventId']?.toString() ?? '',
      eventName: json['eventName']?.toString() ?? '',
      totalQuota: json['totalQuota'] ?? 0,
      totalTicketsSold: json['totalTicketsSold'] ?? 0,
      grossRevenue: json['grossRevenue'] ?? 0,
      totalRefundCount: json['totalRefundCount'] ?? 0,
      totalRefundAmount: json['totalRefundAmount'] ?? 0,
      netRevenue: json['netRevenue'] ?? 0,
      percentageSold: (json['percentageSold'] ?? 0).toDouble(),
      refundPercentage: json['refundPercentage'] ?? 0,
      categories: (json['categories'] as List?)
              ?.map((e) => EventStatisticsCategory.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class EventStatisticsCategory {
  final String categoryId;
  final String categoryName;
  final int price;
  final int totalQuota;
  final int ticketsSold;
  final int grossRevenue;
  final int refundCount;
  final int totalRefundAmount;
  final int refundPercentage;

  EventStatisticsCategory({
    required this.categoryId,
    required this.categoryName,
    required this.price,
    required this.totalQuota,
    required this.ticketsSold,
    required this.grossRevenue,
    required this.refundCount,
    required this.totalRefundAmount,
    required this.refundPercentage,
  });

  factory EventStatisticsCategory.fromJson(Map<String, dynamic> json) {
    return EventStatisticsCategory(
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      price: json['price'] ?? 0,
      totalQuota: json['totalQuota'] ?? 0,
      ticketsSold: json['ticketsSold'] ?? 0,
      grossRevenue: json['grossRevenue'] ?? 0,
      refundCount: json['refundCount'] ?? 0,
      totalRefundAmount: json['totalRefundAmount'] ?? 0,
      refundPercentage: json['refundPercentage'] ?? 0,
    );
  }
}
