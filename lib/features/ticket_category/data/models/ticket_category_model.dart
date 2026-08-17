class TicketCategory {
  final String id;
  final String eventId;
  final String name;
  final int price;
  final int totalQuota;
  final int posIndex;
  final int? rows;
  final int? columns;
  final int? availableQuota;
  final bool? isAvailable;

  TicketCategory({
    required this.id,
    required this.eventId,
    required this.name,
    required this.price,
    required this.totalQuota,
    this.posIndex = 0,
    this.rows,
    this.columns,
    this.availableQuota,
    this.isAvailable,
  });

  factory TicketCategory.fromJson(Map<String, dynamic> json) {
    return TicketCategory(
      id: json['id']?.toString() ?? '',
      eventId: json['eventId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: json['price'] is int
          ? json['price']
          : int.tryParse(json['price']?.toString() ?? '') ?? 0,
      totalQuota: json['totalQuota'] is int
          ? json['totalQuota']
          : int.tryParse(json['totalQuota']?.toString() ?? '') ?? 0,
      posIndex: json['posIndex'] is int
          ? json['posIndex']
          : int.tryParse(json['posIndex']?.toString() ?? '') ?? 0,
      rows: json['rows'] is int
          ? json['rows']
          : int.tryParse(json['rows']?.toString() ?? ''),
      columns: json['columns'] is int
          ? json['columns']
          : int.tryParse(json['columns']?.toString() ?? ''),
      availableQuota: json['availableQuota'] is int
          ? json['availableQuota']
          : int.tryParse(json['availableQuota']?.toString() ?? ''),
      isAvailable: json['isAvailable'] is bool
          ? json['isAvailable']
          : (json['isAvailable'] != null
                ? json['isAvailable'].toString().toLowerCase() == 'true'
                : null),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'eventId': eventId,
      'name': name,
      'price': price,
      'totalQuota': totalQuota,
      'posIndex': posIndex,
    };
    if (rows != null) {
      map['rows'] = rows;
    }
    if (columns != null) {
      map['columns'] = columns;
    }
    if (availableQuota != null) {
      map['availableQuota'] = availableQuota;
    }
    if (isAvailable != null) {
      map['isAvailable'] = isAvailable;
    }
    return map;
  }
}
