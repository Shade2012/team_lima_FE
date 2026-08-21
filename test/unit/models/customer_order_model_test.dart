import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/features/customer/data/models/customer_order_model.dart';

void main() {
  group('CustomerOrderModel Unit Tests', () {
    test(
      'Happy Path: Should parse CustomerOrderModel and CustomerOrderItem from JSON correctly',
      () {
        final json = {
          'id': 'ord-12345',
          'customerId': 'usr-001',
          'eventId': 'evt-001',
          'totalAmount': 250000,
          'status': 'PAID',
          'createdAt': '2026-08-18T10:00:00.000Z',
          'event': {
            'name': 'Sonic Resonance Festival',
            'eventDate': '2026-09-01T12:00:00.000Z',
          },
          'tickets': [
            {
              'id': 'tkt-001',
              'status': 'BOOKED',
              'category': {'name': 'VIP Pass', 'price': 250000},
              'seat': {'seatCode': 'A-1'},
            },
          ],
        };

        final order = CustomerOrderModel.fromJson(json);

        expect(order.id, equals('ord-12345'));
        expect(order.customerId, equals('usr-001'));
        expect(order.eventId, equals('evt-001'));
        expect(order.eventName, equals('Sonic Resonance Festival'));
        expect(order.status, equals('PAID'));
        expect(order.totalAmount, equals(250000.0));
        expect(order.tickets.length, equals(1));
        expect(order.tickets[0].categoryName, equals('VIP Pass'));
        expect(order.tickets[0].seatCode, equals('A-1'));
      },
    );

    test(
      'Unhappy Path: Should handle null or empty JSON fields gracefully',
      () {
        final json = <String, dynamic>{};

        final order = CustomerOrderModel.fromJson(json);

        expect(order.id, isEmpty);
        expect(order.eventName, isNull);
        expect(order.status, equals('HELD'));
        expect(order.totalAmount, equals(0.0));
        expect(order.tickets, isEmpty);
      },
    );

    test('Happy Path: Should parse CustomerOrderItem from JSON', () {
      final itemJson = {
        'id': 'item-001',
        'status': 'AVAILABLE',
        'category': {'name': 'Regular Pass', 'price': 100000},
        'seat': {'seatCode': 'B-5'},
      };

      final item = CustomerOrderItem.fromJson(itemJson);

      expect(item.id, equals('item-001'));
      expect(item.status, equals('AVAILABLE'));
      expect(item.categoryName, equals('Regular Pass'));
      expect(item.price, equals(100000.0));
      expect(item.seatCode, equals('B-5'));
    });
  });
}
