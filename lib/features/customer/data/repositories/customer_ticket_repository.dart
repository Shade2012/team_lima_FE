import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/customer_ticket_model.dart';

class CustomerTicketRepository {
  final DioClient _dioClient = DioClient();

  /// GET /tickets/my-tickets
  Future<List<CustomerTicket>> getMyTickets() async {
    try {
      final response = await _dioClient.dio.get('/tickets/my-tickets');
      final data = response.data['data'];
      if (data is List) {
        return data
            .map((e) => _parseTicket(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to load tickets'),
      );
    }
  }

  /// GET /tickets/:id
  Future<CustomerTicket> getTicketDetail(String ticketId) async {
    try {
      final response = await _dioClient.dio.get('/tickets/$ticketId');
      final data = response.data['data'];
      return _parseTicket(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to load ticket detail'),
      );
    }
  }

  CustomerTicket _parseTicket(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final event = category?['event'] as Map<String, dynamic>? ?? json['event'] as Map<String, dynamic>?;
    final seat = json['seat'] as Map<String, dynamic>?;

    final id = json['id']?.toString() ?? '';
    final seatCode = seat?['seatCode']?.toString() ?? json['ticketCode']?.toString() ?? id.substring(0, id.length > 8 ? 8 : id.length);
    final eventName = event?['name']?.toString() ?? json['eventName']?.toString() ?? 'Event';
    final categoryName = category?['name']?.toString() ?? json['categoryName']?.toString() ?? 'General';
    final eventDateStr = event?['eventDate']?.toString() ?? json['eventDate']?.toString();
    final eventDate = eventDateStr != null ? (DateTime.tryParse(eventDateStr) ?? DateTime.now()) : DateTime.now();
    final status = json['status']?.toString() ?? 'AVAILABLE';
    final price = category?['price'] is num
        ? (category!['price'] as num).toDouble()
        : (json['price'] is num ? (json['price'] as num).toDouble() : 0.0);

    return CustomerTicket(
      id: id,
      ticketCode: seatCode.startsWith('#') ? seatCode : '#$seatCode',
      eventName: eventName,
      categoryName: categoryName,
      eventDate: eventDate,
      eventTimeRange: '7:00 PM - 11:00 PM',
      venueName: 'Main Arena',
      venueAddress: 'Jakarta, Indonesia',
      attendeeName: json['attendeeName']?.toString() ?? 'Customer',
      ticketType: 'Digital Ticket',
      qrData: 'DIGITAL TICKET | VELOCE\n$eventName\n$seatCode\nID: $id',
      status: status == 'SEATED' ? 'SCANNED' : status,
      price: price,
    );
  }

  String _extractErrorMessage(DioException e, {required String fallback}) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String) return message;
        if (message is List) return message.map((m) => m.toString()).join('\n');
      }
    }
    return e.message ?? fallback;
  }
}
