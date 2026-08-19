import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_five_fe/features/customer/presentation/pages/customer_orders_page.dart';
import 'package:team_five_fe/features/customer/presentation/pages/customer_refunds_page.dart';
import 'package:team_five_fe/features/customer/presentation/providers/customer_provider.dart';
import 'package:team_five_fe/features/customer/data/models/customer_order_model.dart';
import 'package:team_five_fe/features/customer/data/models/customer_refund_model.dart';

class MockCustomerOrdersNotifier extends CustomerOrdersNotifier {
  final List<CustomerOrderModel> mockOrders;
  MockCustomerOrdersNotifier(this.mockOrders);

  @override
  CustomerOrdersState build() {
    return CustomerOrdersState(orders: mockOrders, isLoading: false);
  }

  @override
  Future<void> loadOrders({bool forceRefresh = false}) async {}
}

class MockCustomerRefundsNotifier extends CustomerRefundsNotifier {
  final List<CustomerRefundModel> mockRefunds;
  MockCustomerRefundsNotifier(this.mockRefunds);

  @override
  CustomerRefundsState build() {
    return CustomerRefundsState(refunds: mockRefunds, isLoading: false);
  }

  @override
  Future<void> loadRefunds({bool forceRefresh = false}) async {}
}

void main() {
  group('Customer Orders & Refunds Widget Tests', () {
    // ==================== CUSTOMER ORDERS PAGE ====================
    testWidgets(
      'Happy Path: CustomerOrdersPage renders orders list and status badges',
      (tester) async {
        final sampleOrders = [
          CustomerOrderModel(
            id: 'ORD-1001-TEST',
            customerId: 'usr-001',
            eventId: 'evt-001',
            eventName: 'Sonic Festival 2026',
            status: 'PAID',
            totalAmount: 200000.0,
            createdAt: DateTime(2026, 8, 18),
            tickets: [
              CustomerOrderItem(
                id: 'item-1',
                status: 'BOOKED',
                categoryName: 'VIP Category',
                price: 200000.0,
                seatCode: 'A-1',
              ),
            ],
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              customerOrdersProvider.overrideWith(
                () => MockCustomerOrdersNotifier(sampleOrders),
              ),
            ],
            child: const MaterialApp(home: CustomerOrdersPage()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('My Orders'), findsOneWidget);
        expect(find.text('Sonic Festival 2026'), findsOneWidget);
        expect(find.text('PAID'), findsOneWidget);
      },
    );

    testWidgets(
      'Unhappy Path: CustomerOrdersPage renders empty state when orders list is empty',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              customerOrdersProvider.overrideWith(
                () => MockCustomerOrdersNotifier([]),
              ),
            ],
            child: const MaterialApp(home: CustomerOrdersPage()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('My Orders'), findsOneWidget);
        expect(find.text('No Orders Yet'), findsOneWidget);
        expect(
          find.text(
            'Your ticket booking history will appear here once you make an order.',
          ),
          findsOneWidget,
        );
      },
    );

    // ==================== CUSTOMER REFUNDS PAGE ====================
    testWidgets(
      'Happy Path: CustomerRefundsPage renders refund requests and status badge',
      (tester) async {
        final sampleRefunds = [
          CustomerRefundModel(
            id: 'REF-5001-TEST',
            ticketId: 'tkt-001',
            reason: 'Duplicate payment made by accident',
            status: 'PENDING',
            amount: 150000.0,
            eventName: 'Neon Waves Festival',
            categoryName: 'Regular Pass',
            createdAt: DateTime(2026, 8, 18),
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              customerRefundsProvider.overrideWith(
                () => MockCustomerRefundsNotifier(sampleRefunds),
              ),
            ],
            child: const MaterialApp(home: CustomerRefundsPage()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('My Refunds'), findsOneWidget);
        expect(find.text('Neon Waves Festival'), findsOneWidget);
        expect(find.text('PENDING'), findsOneWidget);
        expect(find.textContaining('Duplicate payment'), findsOneWidget);
      },
    );

    testWidgets(
      'Unhappy Path: CustomerRefundsPage renders empty state when refund requests list is empty',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              customerRefundsProvider.overrideWith(
                () => MockCustomerRefundsNotifier([]),
              ),
            ],
            child: const MaterialApp(home: CustomerRefundsPage()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('My Refunds'), findsOneWidget);
        expect(find.text('No Refund Requests'), findsOneWidget);
        expect(
          find.text('You have not submitted any ticket refund requests.'),
          findsOneWidget,
        );
      },
    );
  });
}
