import 'package:flutter_test/flutter_test.dart';
import 'package:team_five_fe/features/customer/data/models/customer_refund_model.dart';

void main() {
  group('CustomerRefundModel Unit Tests', () {
    test('Happy Path: Should parse CustomerRefundModel from nested JSON correctly', () {
      final json = {
        'id': 'ref-001',
        'ticketId': 'tkt-001',
        'reason': 'Event postponed due to weather',
        'status': 'APPROVED',
        'amount': 180000,
        'createdAt': '2026-08-18T10:00:00.000Z',
        'ticket': {
          'category': {
            'name': 'VIP Pass',
            'event': {
              'name': 'Sonic Resonance Festival',
            },
          },
          'seat': {
            'seatCode': 'A-1',
          },
        },
      };

      final refund = CustomerRefundModel.fromJson(json);

      expect(refund.id, equals('ref-001'));
      expect(refund.ticketId, equals('tkt-001'));
      expect(refund.reason, equals('Event postponed due to weather'));
      expect(refund.status, equals('APPROVED'));
      expect(refund.amount, equals(180000.0));
      expect(refund.eventName, equals('Sonic Resonance Festival'));
      expect(refund.categoryName, equals('VIP Pass'));
      expect(refund.seatCode, equals('A-1'));
    });

    test('Unhappy Path: Should handle null or empty JSON fields gracefully', () {
      final json = <String, dynamic>{};

      final refund = CustomerRefundModel.fromJson(json);

      expect(refund.id, isEmpty);
      expect(refund.reason, isNull);
      expect(refund.status, equals('PENDING'));
      expect(refund.amount, isNull);
    });

    test('Happy Path: Should parse fallback fields when nested objects are absent', () {
      final json = {
        'id': 'ref-002',
        'ticketId': 'tkt-002',
        'status': 'REJECTED',
        'amount': 150000,
        'reason': 'Personal reasons',
        'rejectReason': 'Policy deadline passed',
        'eventName': 'Fallback Event',
        'ticketCategoryName': 'Fallback Category',
        'seatCode': 'B-2',
      };

      final refund = CustomerRefundModel.fromJson(json);

      expect(refund.id, equals('ref-002'));
      expect(refund.status, equals('REJECTED'));
      expect(refund.amount, equals(150000.0));
      expect(refund.rejectReason, equals('Policy deadline passed'));
      expect(refund.eventName, equals('Fallback Event'));
      expect(refund.categoryName, equals('Fallback Category'));
      expect(refund.seatCode, equals('B-2'));
    });
  });
}
