class Seat {
  final String id;
  final String categoryId;
  final String seatCode;
  final String? row;
  final int? column;
  final String status; // AVAILABLE | HELD | BOOKED

  Seat({
    required this.id,
    required this.categoryId,
    required this.seatCode,
    this.row,
    this.column,
    this.status = 'AVAILABLE',
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['id']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      seatCode: json['seatCode']?.toString() ?? '',
      row: json['row']?.toString(),
      column: json['column'] is int
          ? json['column']
          : int.tryParse(json['column']?.toString() ?? ''),
      status: json['status']?.toString().toUpperCase() ?? 'AVAILABLE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'seatCode': seatCode,
      if (row != null) 'row': row,
      if (column != null) 'column': column,
      'status': status,
    };
  }
}
