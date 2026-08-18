import 'package:flutter_test/flutter_test.dart';
import 'package:team_five_fe/features/admin/data/models/refund_model.dart';

void main() {
  group('RefundRequest Model Tests', () {
    test('Happy Path: Should parse RefundRequest from JSON correctly', () {
      final json = {
        'id': 'refund-123',
        'reason': 'Event cancelled',
        'amount': 150000,
        'ticketId': 'ticket-456',
        'status': 'PENDING',
        'rejectReason': null,
        'adminId': null,
        'providerRefundId': null,
        'processedAt': null,
        'createdAt': '2026-08-12T10:00:00.000Z',
        'updatedAt': '2026-08-12T10:00:00.000Z',
        'customerName': 'John Doe',
        'ticket': {
          'id': 'ticket-456',
          'status': 'ACTIVE',
          'category': {
            'id': 'cat-789',
            'name': 'VIP Pass',
            'price': 150000,
            'event': {
              'id': 'event-001',
              'name': 'Neon Jungle Festival',
              'eventDate': '2026-09-01T18:00:00.000Z',
            },
          },
          'seat': {'id': 'seat-001', 'seatCode': 'A1'},
          'order': {
            'id': 'order-001',
            'customerId': 'cust-001',
            'status': 'PAID',
          },
        },
      };

      final refund = RefundRequest.fromJson(json);

      expect(refund.id, 'refund-123');
      expect(refund.reason, 'Event cancelled');
      expect(refund.amount, 150000);
      expect(refund.ticketId, 'ticket-456');
      expect(refund.status, 'PENDING');
      expect(refund.customerName, 'John Doe');
      expect(refund.createdAt, DateTime.parse('2026-08-12T10:00:00.000Z'));
    });

    test('Happy Path: Should resolve nested getters correctly', () {
      final json = {
        'id': 'refund-123',
        'status': 'PENDING',
        'amount': 100000,
        'ticket': {
          'id': 'ticket-456',
          'status': 'ACTIVE',
          'category': {
            'id': 'cat-789',
            'name': 'VIP Pass',
            'price': 100000,
            'event': {
              'id': 'event-001',
              'name': 'Sonic Festival',
              'eventDate': '2026-09-01T18:00:00.000Z',
            },
          },
          'seat': {'id': 'seat-001', 'seatCode': 'B2'},
          'order': {
            'id': 'order-001',
            'customerId': 'cust-001',
            'status': 'PAID',
          },
        },
      };

      final refund = RefundRequest.fromJson(json);

      expect(refund.orderId, 'order-001');
      expect(refund.eventName, 'Sonic Festival');
      expect(refund.eventDate, DateTime.parse('2026-09-01T18:00:00.000Z'));
      expect(refund.ticketCategoryName, 'VIP Pass');
      expect(refund.ticketCategoryPrice, 100000);
      expect(refund.ticketStatus, 'ACTIVE');
      expect(refund.seatCode, 'B2');
      expect(refund.orderStatus, 'PAID');
    });

    test('Unhappy Path: Should handle empty JSON gracefully', () {
      final json = <String, dynamic>{};

      final refund = RefundRequest.fromJson(json);

      expect(refund.id, isNull);
      expect(refund.reason, isNull);
      expect(refund.amount, isNull);
      expect(refund.status, isNull);
      expect(refund.customerName, isNull);
      expect(refund.ticket, isNull);
      expect(refund.orderId, isNull);
      expect(refund.eventName, isNull);
    });

    test('Happy Path: Should compute initials from customerName', () {
      final refund = RefundRequest(customerName: 'John Doe');
      expect(refund.initials, 'JD');
    });

    test('Happy Path: Should compute single-word initials', () {
      final refund = RefundRequest(customerName: 'Alice');
      expect(refund.initials, 'AL');
    });

    test('Unhappy Path: Should return ?? for null or empty customerName', () {
      expect(RefundRequest(customerName: null).initials, '??');
      expect(RefundRequest(customerName: '').initials, '??');
    });
  });

  group('RefundStats Tests', () {
    test('Happy Path: Should compute stats from refund list', () {
      final refunds = [
        RefundRequest(status: 'PENDING', amount: 50000),
        RefundRequest(status: 'PENDING', amount: 30000),
        RefundRequest(status: 'APPROVED', amount: 100000),
        RefundRequest(status: 'APPROVED', amount: 200000),
        RefundRequest(status: 'REJECTED', amount: 50000),
      ];

      final stats = RefundStats.fromRefunds(refunds);

      expect(stats.pendingCount, 2);
      expect(stats.totalRefunded, 2);
      expect(stats.totalRefundAmount, 300000);
    });

    test('Unhappy Path: Should handle empty refund list', () {
      final stats = RefundStats.fromRefunds([]);

      expect(stats.pendingCount, 0);
      expect(stats.totalRefunded, 0);
      expect(stats.totalRefundAmount, 0);
    });

    test('Happy Path: Default constructor should use zero defaults', () {
      const stats = RefundStats();

      expect(stats.pendingCount, 0);
      expect(stats.totalRefunded, 0);
      expect(stats.totalRefundAmount, 0);
    });
  });

  group('RefundTicket Model Tests', () {
    test('Happy Path: Should parse RefundTicket from JSON', () {
      final json = {
        'id': 'ticket-001',
        'status': 'ACTIVE',
        'category': {'id': 'cat-001', 'name': 'General'},
        'seat': {'id': 'seat-001', 'seatCode': 'C3'},
        'order': {'id': 'order-001', 'status': 'PAID'},
      };

      final ticket = RefundTicket.fromJson(json);

      expect(ticket.id, 'ticket-001');
      expect(ticket.status, 'ACTIVE');
      expect(ticket.category?.name, 'General');
      expect(ticket.seat?.seatCode, 'C3');
      expect(ticket.order?.status, 'PAID');
    });

    test('Unhappy Path: Should handle null nested fields', () {
      final json = <String, dynamic>{'id': 'ticket-002', 'status': 'CANCELLED'};

      final ticket = RefundTicket.fromJson(json);

      expect(ticket.id, 'ticket-002');
      expect(ticket.category, isNull);
      expect(ticket.seat, isNull);
      expect(ticket.order, isNull);
    });
  });
}
