class CustomerTicket {
  final String id;
  final String ticketCode;
  final String eventName;
  final String categoryName;
  final DateTime eventDate;
  final String eventTimeRange;
  final String venueName;
  final String venueAddress;
  final String attendeeName;
  final String ticketType;
  final String qrData;
  final String status;
  final String? imageUrl;
  final double price;

  CustomerTicket({
    required this.id,
    required this.ticketCode,
    required this.eventName,
    required this.categoryName,
    required this.eventDate,
    required this.eventTimeRange,
    required this.venueName,
    required this.venueAddress,
    required this.attendeeName,
    required this.ticketType,
    required this.qrData,
    required this.status,
    this.imageUrl,
    this.price = 0.0,
  });

  factory CustomerTicket.fromJson(Map<String, dynamic> json) {
    return CustomerTicket(
      id: json['id']?.toString() ?? '',
      ticketCode: json['ticketCode']?.toString() ?? '#NJF-2491',
      eventName: json['eventName']?.toString() ?? 'Neon Jungle Festival',
      categoryName: json['categoryName']?.toString() ?? 'VIP PASS',
      eventDate: json['eventDate'] != null
          ? DateTime.tryParse(json['eventDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      eventTimeRange: json['eventTimeRange']?.toString() ?? '8:00 PM - 4:00 AM',
      venueName: json['venueName']?.toString() ?? 'The Grand Warehouse',
      venueAddress:
          json['venueAddress']?.toString() ?? '124 Industrial Ave, Metro City',
      attendeeName: json['attendeeName']?.toString() ?? 'Alex Chen',
      ticketType: json['ticketType']?.toString() ?? 'All Access',
      qrData:
          json['qrData']?.toString() ??
          'DIGITAL TICKET | VELOCE\nNeon Jungle Festival\nNJF-2491',
      status: json['status']?.toString() ?? 'UPCOMING',
      imageUrl: json['imageUrl']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 150.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketCode': ticketCode,
      'eventName': eventName,
      'categoryName': categoryName,
      'eventDate': eventDate.toIso8601String(),
      'eventTimeRange': eventTimeRange,
      'venueName': venueName,
      'venueAddress': venueAddress,
      'attendeeName': attendeeName,
      'ticketType': ticketType,
      'qrData': qrData,
      'status': status,
      'imageUrl': imageUrl,
      'price': price,
    };
  }
}
