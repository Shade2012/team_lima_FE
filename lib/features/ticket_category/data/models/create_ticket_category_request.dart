class CreateTicketCategoryRequest {
  final String eventId;
  final String name;
  final int price;
  final int? totalQuota;
  final int posIndex;
  final int? rows;
  final int? columns;
  final List<String>? blockedSeats;

  CreateTicketCategoryRequest({
    required this.eventId,
    required this.name,
    required this.price,
    this.totalQuota,
    this.posIndex = 0,
    this.rows,
    this.columns,
    this.blockedSeats,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'eventId': eventId,
      'name': name,
      'price': price,
      'posIndex': posIndex,
    };
    if (totalQuota != null) {
      map['totalQuota'] = totalQuota;
    }
    if (rows != null) {
      map['rows'] = rows;
    }
    if (columns != null) {
      map['columns'] = columns;
    }
    if (blockedSeats != null && blockedSeats!.isNotEmpty) {
      map['blockedSeats'] = blockedSeats;
    }
    return map;
  }
}
