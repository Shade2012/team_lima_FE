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
    final code =
        json['ticketCode']?.toString() ??
        json['seatCode']?.toString() ??
        json['code']?.toString() ??
        '';
    final event =
        json['eventName']?.toString() ??
        json['event']?['name']?.toString() ??
        json['title']?.toString() ??
        'Event Ticket';
    final category =
        json['categoryName']?.toString() ??
        json['category']?['name']?.toString() ??
        'General Admission';

    return CustomerTicket(
      id: json['id']?.toString() ?? '',
      ticketCode: code.isNotEmpty
          ? code
          : '#TKN-${json['id']?.toString().substring(0, 6) ?? "0000"}',
      eventName: event,
      categoryName: category,
      eventDate: json['eventDate'] != null
          ? DateTime.tryParse(json['eventDate'].toString()) ?? DateTime.now()
          : (json['date'] != null
                ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
                : DateTime.now()),
      eventTimeRange:
          json['eventTimeRange']?.toString() ??
          json['timeRange']?.toString() ??
          'TBA',
      venueName:
          json['venueName']?.toString() ??
          json['location']?.toString() ??
          'Main Arena',
      venueAddress:
          json['venueAddress']?.toString() ??
          json['address']?.toString() ??
          'Main Sector',
      attendeeName:
          json['attendeeName']?.toString() ??
          json['userName']?.toString() ??
          'Customer',
      ticketType: json['ticketType']?.toString() ?? 'E-Ticket',
      qrData: json['qrData']?.toString() ?? 'VELOCE TICKET | $event | $code',
      status: json['status']?.toString() ?? 'UPCOMING',
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
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
