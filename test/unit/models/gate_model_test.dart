import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/features/gate/data/models/gate_model.dart';

void main() {
  group('Gate Model Tests', () {
    test('Happy Path: Should parse Gate from JSON correctly', () {
      final json = {
        'id': 'gate-001',
        'name': 'North Gate',
        'eventId': 'event-001',
        'createdAt': '2026-08-01T10:00:00.000Z',
        'updatedAt': '2026-08-01T10:00:00.000Z',
        'scans': [
          {
            'id': 'scan-001',
            'scannedAt': '2026-09-01T18:05:00.000Z',
            'ticketId': 'ticket-001',
            'gateOperatorId': 'op-001',
            'gateId': 'gate-001',
          },
          {
            'id': 'scan-002',
            'scannedAt': '2026-09-01T18:10:00.000Z',
            'ticketId': 'ticket-002',
            'gateOperatorId': 'op-001',
            'gateId': 'gate-001',
          },
        ],
        'operators': [
          {
            'id': 'user-001',
            'email': 'operator@veloce.com',
            'username': 'gate_op1',
            'role': 'GATE_OPERATOR',
          },
        ],
      };

      final gate = Gate.fromJson(json);

      expect(gate.id, 'gate-001');
      expect(gate.name, 'North Gate');
      expect(gate.eventId, 'event-001');
      expect(gate.scans.length, 2);
      expect(gate.operators.length, 1);
      expect(gate.operators.first.username, 'gate_op1');
    });

    test('Happy Path: scannedCount should return scans length', () {
      final gate = Gate(
        id: 'gate-002',
        name: 'South Gate',
        scans: [
          AdmissionScan(id: 's1', scannedAt: DateTime.now()),
          AdmissionScan(id: 's2', scannedAt: DateTime.now()),
          AdmissionScan(id: 's3', scannedAt: DateTime.now()),
        ],
      );

      expect(gate.scannedCount, 3);
    });

    test('Unhappy Path: Should handle empty scans and operators', () {
      final json = <String, dynamic>{'id': 'gate-003', 'name': 'Empty Gate'};

      final gate = Gate.fromJson(json);

      expect(gate.id, 'gate-003');
      expect(gate.name, 'Empty Gate');
      expect(gate.eventId, isNull);
      expect(gate.scans, isEmpty);
      expect(gate.operators, isEmpty);
      expect(gate.scannedCount, 0);
    });

    test('Happy Path: Should serialize Gate to JSON Map', () {
      final gate = Gate(
        id: 'gate-004',
        name: 'East Gate',
        eventId: 'event-002',
      );

      final json = gate.toJson();

      expect(json['id'], 'gate-004');
      expect(json['name'], 'East Gate');
      expect(json['eventId'], 'event-002');
      expect(json.containsKey('scans'), false);
      expect(json.containsKey('operators'), false);
    });
  });

  group('AdmissionScan Model Tests', () {
    test('Happy Path: Should parse AdmissionScan from JSON', () {
      final json = {
        'id': 'scan-001',
        'scannedAt': '2026-09-01T18:05:00.000Z',
        'ticketId': 'ticket-001',
        'gateOperatorId': 'op-001',
        'gateId': 'gate-001',
      };

      final scan = AdmissionScan.fromJson(json);

      expect(scan.id, 'scan-001');
      expect(scan.scannedAt, DateTime.parse('2026-09-01T18:05:00.000Z'));
      expect(scan.ticketId, 'ticket-001');
      expect(scan.gateOperatorId, 'op-001');
      expect(scan.gateId, 'gate-001');
    });

    test('Unhappy Path: Should handle missing fields gracefully', () {
      final json = <String, dynamic>{
        'id': 'scan-002',
        'scannedAt': '2026-09-01T18:10:00.000Z',
      };

      final scan = AdmissionScan.fromJson(json);

      expect(scan.id, 'scan-002');
      expect(scan.ticketId, isNull);
      expect(scan.gateOperatorId, isNull);
      expect(scan.gateId, isNull);
    });

    test('Happy Path: Should serialize AdmissionScan to JSON Map', () {
      final scan = AdmissionScan(
        id: 'scan-003',
        scannedAt: DateTime(2026, 9, 1, 18, 15),
        ticketId: 'ticket-003',
        gateId: 'gate-001',
      );

      final json = scan.toJson();

      expect(json['id'], 'scan-003');
      expect(json['ticketId'], 'ticket-003');
      expect(json['gateId'], 'gate-001');
      expect(json['gateOperatorId'], isNull);
    });
  });
}
