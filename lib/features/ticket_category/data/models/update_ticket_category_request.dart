class UpdateTicketCategoryRequest {
  final String? name;
  final int? price;
  final int? totalQuota;
  final int? posIndex;
  final int? rows;
  final int? columns;
  final List<String>? blockedSeats;

  UpdateTicketCategoryRequest({
    this.name,
    this.price,
    this.totalQuota,
    this.posIndex,
    this.rows,
    this.columns,
    this.blockedSeats,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (price != null) map['price'] = price;
    if (totalQuota != null) map['totalQuota'] = totalQuota;
    if (posIndex != null) map['posIndex'] = posIndex;
    if (rows != null) map['rows'] = rows;
    if (columns != null) map['columns'] = columns;
    if (blockedSeats != null && blockedSeats!.isNotEmpty) {
      map['blockedSeats'] = blockedSeats;
    }
    return map;
  }
}
