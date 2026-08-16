import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_five_fe/features/customer/presentation/pages/customer_main_screen.dart';
import 'package:team_five_fe/features/customer/presentation/pages/checkout_page.dart';
import 'package:team_five_fe/features/customer/presentation/pages/customer_event_detail_page.dart';
import 'package:team_five_fe/features/customer/presentation/pages/seat_selection_page.dart';
import 'package:team_five_fe/features/customer/presentation/providers/customer_provider.dart';

class MockCustomerExploreNotifier extends CustomerExploreNotifier {
  @override
  CustomerExploreState build() {
    return CustomerExploreState(events: []);
  }

  @override
  Future<void> loadPublicEvents() async {
    // Mock override to bypass network request during widget testing
  }
}

void main() {
  group('Customer Pages Widget Tests', () {
    testWidgets('CustomerMainScreen renders VELOCE app bar and bottom tabs', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerExploreProvider.overrideWith(
              () => MockCustomerExploreNotifier(),
            ),
          ],
          child: const MaterialApp(home: CustomerMainScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('VELOCE'), findsOneWidget);
      expect(find.text('Explore'), findsWidgets);
      expect(find.text('Tickets'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets(
      'CustomerEventDetailPage renders details and category selection',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: CustomerEventDetailPage(
                eventName: 'Sonic Resonance Festival 2024',
                categoryName: 'ELECTRONIC',
                price: 150.0,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Event Details'), findsOneWidget);
        expect(find.text('Sonic Resonance Festival 2024'), findsOneWidget);
        expect(find.text('Select Ticket Category'), findsOneWidget);
      },
    );

    testWidgets('SeatSelectionPage renders stage indicator and seat grid', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SeatSelectionPage(
              eventName: 'Sonic Resonance Festival 2024',
              categoryName: 'VIP PASS',
              categoryId: 'cat_vip',
              price: 150.0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Select Seat'), findsOneWidget);
      expect(find.text('S  T  A  G  E'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Held'), findsOneWidget);
      expect(find.text('Sold'), findsOneWidget);
      expect(find.text('Confirm & Checkout'), findsOneWidget);
    });

    testWidgets('CheckoutPage renders order summary and payment methods', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CheckoutPage(
              eventName: 'Neon Jungle Festival',
              eventCategory: 'LIVE EVENT',
              price: 150.0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Secure Checkout'), findsOneWidget);
      expect(find.text('Credit or Debit Card'), findsOneWidget);
      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text('Complete Payment'), findsOneWidget);
    });
  });
}
