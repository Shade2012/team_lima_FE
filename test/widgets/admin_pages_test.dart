import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_five_fe/features/admin/presentation/pages/admin_main_screen.dart';
import 'package:team_five_fe/features/admin/presentation/pages/admin_refund_request_page.dart';
import 'package:team_five_fe/features/admin/presentation/providers/admin_refund_provider.dart';
import 'package:team_five_fe/features/admin/data/models/refund_model.dart';
import 'package:team_five_fe/features/event/presentation/providers/event_provider.dart';
import 'package:team_five_fe/features/event/data/models/event_model.dart';

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
        RefundRequest(
          id: 'refund-2',
          customerName: 'Jane Smith',
          amount: 200000,
          status: 'PENDING',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ticket: RefundTicket(
            category: RefundCategory(
              event: RefundEvent(name: 'Sonic Resonance'),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Future<void> loadRefunds() async {
    // Mock override to bypass network request
  }

  @override
  Future<bool> approveRefund(String id) async {
    return true;
  }

  @override
  Future<bool> rejectRefund(String id, {required String reason}) async {
    return true;
  }
}

class EmptyRefundListNotifier extends RefundListNotifier {
  @override
  RefundListState build() {
    return RefundListState(refunds: []);
  }

  @override
  Future<void> loadRefunds() async {}
}

class MockAllEventsNotifier extends AllEventsNotifier {
  @override
  AllEventsState build() {
    return AllEventsState(
      events: [
        Event(
          id: 'evt-1',
          organizerId: 'org-1',
          name: 'Test Event',
          isSeated: true,
          salesStartTime: DateTime.now().subtract(const Duration(days: 10)),
          salesEndTime: DateTime.now().add(const Duration(days: 20)),
          eventDate: DateTime.now().add(const Duration(days: 30)),
        ),
      ],
    );
  }

  @override
  Future<void> loadAllEvents() async {}
}

void main() {
  group('Admin Pages Widget Tests', () {
    testWidgets('AdminMainScreen renders bottom navigation with correct tabs', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allEventsProvider.overrideWith(() => MockAllEventsNotifier()),
            refundListProvider.overrideWith(() => MockRefundListNotifier()),
          ],
          child: MaterialApp(home: const AdminMainScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Request'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('AdminMainScreen starts on Events tab (initialIndex = 0)', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allEventsProvider.overrideWith(() => MockAllEventsNotifier()),
            refundListProvider.overrideWith(() => MockRefundListNotifier()),
          ],
          child: MaterialApp(home: const AdminMainScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Events'), findsOneWidget);
    });

    testWidgets('AdminMainScreen can switch between tabs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allEventsProvider.overrideWith(() => MockAllEventsNotifier()),
            refundListProvider.overrideWith(() => MockRefundListNotifier()),
          ],
          child: MaterialApp(home: const AdminMainScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Request'));
      await tester.pumpAndSettle();

      expect(find.text('Refund Requests'), findsOneWidget);
    });

    testWidgets('AdminRefundRequestPage renders header and search bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            refundListProvider.overrideWith(() => MockRefundListNotifier()),
          ],
          child: const MaterialApp(home: AdminRefundRequestPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Refund Requests'), findsOneWidget);
      expect(
        find.text('Approve or reject customer refund requests'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('AdminRefundRequestPage displays refund cards', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            refundListProvider.overrideWith(() => MockRefundListNotifier()),
          ],
          child: const MaterialApp(home: AdminRefundRequestPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Neon Festival'), findsOneWidget);
      expect(find.text('Sonic Resonance'), findsOneWidget);
    });

    testWidgets(
      'AdminRefundRequestPage shows empty state when no pending requests',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              refundListProvider.overrideWith(() => EmptyRefundListNotifier()),
            ],
            child: const MaterialApp(home: AdminRefundRequestPage()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('No pending requests'), findsOneWidget);
        expect(
          find.text('All refund requests have been processed.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('AdminRefundRequestPage shows Approve and Reject buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            refundListProvider.overrideWith(() => MockRefundListNotifier()),
          ],
          child: const MaterialApp(home: AdminRefundRequestPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Approve'), findsWidgets);
      expect(find.text('Reject'), findsWidgets);
    });
  });
}
