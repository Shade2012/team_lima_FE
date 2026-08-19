import 'package:flutter_test/flutter_test.dart';
import 'package:team_five_fe/features/event/data/models/event_model.dart';
import 'package:team_five_fe/features/event/data/models/create_event_request.dart';
import 'package:team_five_fe/features/event/data/models/update_event_request.dart';
import 'package:team_five_fe/features/event/data/models/event_statistics_model.dart';

void main() {
  group('Event Model Tests', () {
    test('Happy Path: Should parse Event from JSON correctly', () {
      final json = {
        'id': 'event-001',
        'organizerId': 'org-001',
        'name': 'Neon Jungle Festival',
        'isSeated': true,
        'salesStartTime': '2026-08-01T00:00:00.000Z',
        'salesEndTime': '2026-08-30T23:59:59.000Z',
        'eventDate': '2026-09-01T18:00:00.000Z',
        'refundEndDate': '2026-08-25T23:59:59.000Z',
        'refundPolicy': 'Full refund before event',
        'refundPercentage': 100,
        'createdAt': '2026-07-01T10:00:00.000Z',
        'updatedAt': '2026-07-15T12:00:00.000Z',
      };

      final event = Event.fromJson(json);

      expect(event.id, 'event-001');
      expect(event.organizerId, 'org-001');
      expect(event.name, 'Neon Jungle Festival');
      expect(event.isSeated, true);
      expect(event.salesStartTime, DateTime.parse('2026-08-01T00:00:00.000Z'));
      expect(event.salesEndTime, DateTime.parse('2026-08-30T23:59:59.000Z'));
      expect(event.eventDate, DateTime.parse('2026-09-01T18:00:00.000Z'));
      expect(event.refundEndDate, DateTime.parse('2026-08-25T23:59:59.000Z'));
      expect(event.refundPolicy, 'Full refund before event');
      expect(event.refundPercentage, 100);
    });

    test('Unhappy Path: Should handle missing JSON fields gracefully', () {
      final json = <String, dynamic>{};

      final event = Event.fromJson(json);

      expect(event.id, '');
      expect(event.organizerId, '');
      expect(event.name, '');
      expect(event.isSeated, false);
      expect(event.refundEndDate, isNull);
      expect(event.refundPolicy, isNull);
      expect(event.refundPercentage, isNull);
    });

    test('Happy Path: Should serialize Event to JSON Map', () {
      final event = Event(
        id: 'event-002',
        organizerId: 'org-002',
        name: 'Sonic Resonance',
        isSeated: false,
        salesStartTime: DateTime(2026, 8, 1),
        salesEndTime: DateTime(2026, 8, 30),
        eventDate: DateTime(2026, 9, 5),
        refundPercentage: 50,
      );

      final json = event.toJson();

      expect(json['id'], 'event-002');
      expect(json['organizerId'], 'org-002');
      expect(json['name'], 'Sonic Resonance');
      expect(json['isSeated'], false);
      expect(json['refundPercentage'], 50);
      expect(json['refundEndDate'], isNull);
      expect(json['refundPolicy'], isNull);
    });

    test('Happy Path: Should handle isSeated as false in JSON', () {
      final json = {
        'id': 'event-003',
        'organizerId': 'org-003',
        'name': 'Standing Event',
        'isSeated': false,
        'salesStartTime': '2026-08-01T00:00:00.000Z',
        'salesEndTime': '2026-08-30T23:59:59.000Z',
        'eventDate': '2026-09-01T18:00:00.000Z',
      };

      final event = Event.fromJson(json);

      expect(event.isSeated, false);
    });
  });

  group('CreateEventRequest Model Tests', () {
    test('Happy Path: Should serialize CreateEventRequest to JSON', () {
      final request = CreateEventRequest(
        name: 'New Festival',
        description: 'A great festival',
        isSeated: true,
        salesStartTime: DateTime(2026, 8, 1),
        salesEndTime: DateTime(2026, 8, 30),
        eventDate: DateTime(2026, 9, 1),
        refundEndDate: DateTime(2026, 8, 25),
        refundPolicy: 'Full refund',
        refundPercentage: 100,
      );

      final json = request.toJson();

      expect(json['name'], 'New Festival');
      expect(json['description'], 'A great festival');
      expect(json['isSeated'], true);
      expect(json['refundEndDate'], isNotNull);
      expect(json['refundPolicy'], 'Full refund');
      expect(json['refundPercentage'], 100);
    });

    test('Happy Path: Should serialize with all required fields', () {
      final request = CreateEventRequest(
        name: 'Minimal Event',
        description: 'Minimal description',
        isSeated: false,
        salesStartTime: DateTime(2026, 8, 1),
        salesEndTime: DateTime(2026, 8, 30),
        eventDate: DateTime(2026, 9, 1),
        refundEndDate: DateTime(2026, 8, 25),
        refundPolicy: 'No refund',
        refundPercentage: 0,
      );

      final json = request.toJson();

      expect(json['name'], 'Minimal Event');
      expect(json['description'], 'Minimal description');
      expect(json['isSeated'], false);
      expect(json['refundEndDate'], isNotNull);
      expect(json['refundPolicy'], 'No refund');
      expect(json['refundPercentage'], 0);
    });
  });

  group('UpdateEventRequest Model Tests', () {
    test('Happy Path: Should serialize only non-null fields', () {
      final request = UpdateEventRequest(
        name: 'Updated Event',
        refundPercentage: 75,
      );

      final json = request.toJson();

      expect(json['name'], 'Updated Event');
      expect(json['refundPercentage'], 75);
      expect(json.containsKey('isSeated'), false);
      expect(json.containsKey('salesStartTime'), false);
    });

    test('Unhappy Path: Should return empty map for empty request', () {
      final request = UpdateEventRequest();

      final json = request.toJson();

      expect(json.isEmpty, true);
    });

    test('Unhappy Path: Should omit empty name string', () {
      final request = UpdateEventRequest(name: '');

      final json = request.toJson();

      expect(json.containsKey('name'), false);
    });
  });

  group('EventStatistics Model Tests', () {
    test('Happy Path: Should parse EventStatistics from JSON', () {
      final json = {
        'eventId': 'event-001',
        'eventName': 'Neon Festival',
        'totalQuota': 500,
        'totalTicketsSold': 350,
        'grossRevenue': 52500000,
        'totalRefundCount': 10,
        'totalRefundAmount': 1500000,
        'netRevenue': 51000000,
        'percentageSold': 70.0,
        'refundPercentage': 100,
        'categories': [
          {
            'categoryId': 'cat-001',
            'categoryName': 'VIP',
            'price': 200000,
            'totalQuota': 100,
            'ticketsSold': 80,
            'grossRevenue': 16000000,
            'refundCount': 5,
            'totalRefundAmount': 1000000,
            'refundPercentage': 100,
          },
        ],
      };

      final stats = EventStatistics.fromJson(json);

      expect(stats.eventId, 'event-001');
      expect(stats.eventName, 'Neon Festival');
      expect(stats.totalQuota, 500);
      expect(stats.totalTicketsSold, 350);
      expect(stats.grossRevenue, 52500000);
      expect(stats.netRevenue, 51000000);
      expect(stats.percentageSold, 70.0);
      expect(stats.categories?.length, 1);
      expect(stats.categories?.first.categoryName, 'VIP');
    });

    test('Unhappy Path: Should handle missing fields gracefully', () {
      final json = <String, dynamic>{};

      final stats = EventStatistics.fromJson(json);

      expect(stats.eventId, isNull);
      expect(stats.totalQuota, isNull);
      expect(stats.categories, isNull);
    });

    test('Happy Path: Should parse int from double value', () {
      final json = {'totalQuota': 500.0};

      final stats = EventStatistics.fromJson(json);

      expect(stats.totalQuota, 500);
    });

    test('Happy Path: Should parse int from string value', () {
      final json = {'totalQuota': '500'};

      final stats = EventStatistics.fromJson(json);

      expect(stats.totalQuota, 500);
    });
  });
}
