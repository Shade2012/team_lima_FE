import 'package:flutter_test/flutter_test.dart';
import 'package:team_five_fe/features/customer/data/models/customer_ticket_model.dart';

void main() {
  group('CustomerTicket Model Unit Tests', () {
    test('Happy Path: Should parse CustomerTicket from JSON correctly', () {
      final json = {
        'id': 'ticket-123',
        'ticketCode': '#NJF-2491',
        'eventName': 'Neon Jungle Festival',
        'categoryName': 'VIP PASS',
        'eventDate': '2024-08-24T20:00:00.000Z',
        'eventTimeRange': '8:00 PM - 4:00 AM',
        'venueName': 'The Grand Warehouse',
        'venueAddress': '124 Industrial Ave, Metro City',
        'attendeeName': 'Alex Chen',
        'ticketType': 'All Access',
        'qrData': 'DIGITAL TICKET | VELOCE\nNeon Jungle Festival',
        'status': 'UPCOMING',
        'price': 150.0,
      };

      final ticket = CustomerTicket.fromJson(json);

      expect(ticket.id, 'ticket-123');
      expect(ticket.ticketCode, '#NJF-2491');
      expect(ticket.eventName, 'Neon Jungle Festival');
      expect(ticket.categoryName, 'VIP PASS');
      expect(ticket.attendeeName, 'Alex Chen');
      expect(ticket.status, 'UPCOMING');
      expect(ticket.price, 150.0);
    });

    test('Unhappy Path: Should handle null or empty JSON fields gracefully', () {
      final json = <String, dynamic>{};

      final ticket = CustomerTicket.fromJson(json);

      expect(ticket.id, '');
      expect(ticket.ticketCode, '#NJF-2491');
      expect(ticket.eventName, 'Neon Jungle Festival');
      expect(ticket.categoryName, 'VIP PASS');
      expect(ticket.status, 'UPCOMING');
    });

    test('Happy Path: Should serialize CustomerTicket to JSON Map', () {
      final ticket = CustomerTicket(
        id: 't-1',
        ticketCode: '#CODE-1',
        eventName: 'Event A',
        categoryName: 'General',
        eventDate: DateTime(2024, 10, 10),
        eventTimeRange: '7:00 PM',
        venueName: 'Venue A',
        venueAddress: 'Address A',
        attendeeName: 'User A',
        ticketType: 'Regular',
        qrData: 'QR-1',
        status: 'UPCOMING',
        price: 50.0,
      );

      final map = ticket.toJson();

      expect(map['id'], 't-1');
      expect(map['ticketCode'], '#CODE-1');
      expect(map['eventName'], 'Event A');
      expect(map['price'], 50.0);
    });
  });
}
