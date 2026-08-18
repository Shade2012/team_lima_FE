import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_five_fe/features/event/presentation/pages/organizer/organizer_main_screen.dart';
import 'package:team_five_fe/features/event/presentation/pages/organizer/my_events_page.dart';
import 'package:team_five_fe/features/event/presentation/providers/event_provider.dart';
import 'package:team_five_fe/features/event/data/models/event_model.dart';
import 'package:team_five_fe/features/admin/presentation/providers/admin_refund_provider.dart';
import 'package:team_five_fe/features/admin/data/models/refund_model.dart';

class MockMyEventsNotifier extends MyEventsNotifier {
  @override
  MyEventsState build() {
    return MyEventsState(
      events: [
        Event(
          id: 'evt-1',
          organizerId: 'org-1',
          name: 'Active Festival',
          isSeated: true,
          salesStartTime: DateTime.now().subtract(const Duration(days: 10)),
          salesEndTime: DateTime.now().add(const Duration(days: 20)),
          eventDate: DateTime.now().add(const Duration(days: 30)),
          refundPercentage: 100,
        ),
        Event(
          id: 'evt-2',
          organizerId: 'org-1',
          name: 'Upcoming Concert',
          isSeated: false,
          salesStartTime: DateTime.now().add(const Duration(days: 5)),
          salesEndTime: DateTime.now().add(const Duration(days: 25)),
          eventDate: DateTime.now().add(const Duration(days: 35)),
        ),
      ],
    );
  }

  @override
  Future<void> loadMyEvents() async {}

  @override
  Future<bool> deleteEvent(String id) async {
    return true;
  }
}

class EmptyMyEventsNotifier extends MyEventsNotifier {
  @override
  MyEventsState build() {
    return MyEventsState(events: []);
  }

  @override
  Future<void> loadMyEvents() async {}
}

class MockRefundListNotifier extends RefundListNotifier {
  @override
  RefundListState build() {
    return RefundListState(
      refunds: [
        RefundRequest(
          id: 'refund-1',
          customerName: 'John Doe',
          amount: 150000,
          status: 'PENDING',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ticket: RefundTicket(
            category: RefundCategory(event: RefundEvent(name: 'Neon Festival')),
          ),
        ),
      ],
    );
  }

  @override
  Future<void> loadRefunds() async {}
}

void main() {
  group('Organizer Pages Widget Tests', () {
    testWidgets(
      'OrganizerMainScreen renders bottom navigation with correct tabs',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              myEventsProvider.overrideWith(() => MockMyEventsNotifier()),
              refundListProvider.overrideWith(() => MockRefundListNotifier()),
            ],
            child: MaterialApp(home: const OrganizerMainScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Events'), findsOneWidget);
        expect(find.text('Refunds'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
      },
    );

    testWidgets('OrganizerMainScreen starts on Events tab', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myEventsProvider.overrideWith(() => MockMyEventsNotifier()),
            refundListProvider.overrideWith(() => MockRefundListNotifier()),
          ],
          child: MaterialApp(home: const OrganizerMainScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Events'), findsOneWidget);
    });

    testWidgets('OrganizerMainScreen can switch to Refunds tab', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myEventsProvider.overrideWith(() => MockMyEventsNotifier()),
            refundListProvider.overrideWith(() => MockRefundListNotifier()),
          ],
          child: MaterialApp(home: const OrganizerMainScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Refunds'));
      await tester.pumpAndSettle();

      expect(find.text('Refunds'), findsWidgets);
    });

    testWidgets('MyEventsPage renders header and search bar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myEventsProvider.overrideWith(() => MockMyEventsNotifier()),
          ],
          child: const MaterialApp(home: MyEventsPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Events'), findsOneWidget);
      expect(find.text('Manage your events'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('MyEventsPage renders tab bar with Active, Upcoming, Ended', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myEventsProvider.overrideWith(() => MockMyEventsNotifier()),
          ],
          child: const MaterialApp(home: MyEventsPage()),
        ),
      );

      await tester.pumpAndSettle();

      // Tab labels: Active, Upcoming, Ended
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Upcoming'), findsWidgets);
      expect(find.text('Ended'), findsOneWidget);
    });

    testWidgets('MyEventsPage displays event cards when events exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myEventsProvider.overrideWith(() => MockMyEventsNotifier()),
          ],
          child: const MaterialApp(home: MyEventsPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Active Festival'), findsOneWidget);
    });

    testWidgets('MyEventsPage shows empty state when no events', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myEventsProvider.overrideWith(() => EmptyMyEventsNotifier()),
          ],
          child: const MaterialApp(home: MyEventsPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No active events'), findsOneWidget);
      expect(find.text('Events on sale will appear here.'), findsOneWidget);
    });

    testWidgets('MyEventsPage shows FAB for creating events', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myEventsProvider.overrideWith(() => MockMyEventsNotifier()),
          ],
          child: const MaterialApp(home: MyEventsPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
