class Seat {
  final String id;
  final String categoryId;
  final String seatCode;

  Seat({
    required this.id,
    required this.categoryId,
    required this.seatCode,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['id']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      seatCode: json['seatCode']?.toString() ?? '',
    );
  }
}
