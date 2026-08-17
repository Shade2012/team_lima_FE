import 'package:flutter_test/flutter_test.dart';
import 'package:team_five_fe/features/ticket_category/data/models/ticket_category_model.dart';
import 'package:team_five_fe/features/ticket_category/data/models/create_ticket_category_request.dart';

void main() {
  group('TicketCategory & Request Model Tests', () {
    test(
      'TicketCategory.fromJson parses rows, columns, and posIndex correctly',
      () {
        final json = {
          'id': 'cat-123',
          'eventId': 'event-456',
          'name': 'VIP Front',
          'price': 1500000,
          'totalQuota': 100,
          'posIndex': 1,
          'rows': 10,
          'columns': 10,
          'availableQuota': 95,
          'isAvailable': true,
        };

        final category = TicketCategory.fromJson(json);

        expect(category.id, 'cat-123');
        expect(category.eventId, 'event-456');
        expect(category.name, 'VIP Front');
        expect(category.price, 1500000);
        expect(category.totalQuota, 100);
        expect(category.posIndex, 1);
        expect(category.rows, 10);
        expect(category.columns, 10);
        expect(category.availableQuota, 95);
        expect(category.isAvailable, true);
      },
    );

    test(
      'CreateTicketCategoryRequest.toJson serializes rows and columns correctly',
      () {
        final request = CreateTicketCategoryRequest(
          eventId: 'event-456',
          name: 'VIP Front',
          price: 1500000,
          totalQuota: 100,
          posIndex: 2,
          rows: 10,
          columns: 10,
        );

        final map = request.toJson();

        expect(map['eventId'], 'event-456');
        expect(map['name'], 'VIP Front');
        expect(map['price'], 1500000);
        expect(map['totalQuota'], 100);
        expect(map['posIndex'], 2);
        expect(map['rows'], 10);
        expect(map['columns'], 10);
      },
    );
  });
}
