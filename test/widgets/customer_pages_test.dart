import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_five_fe/features/customer/presentation/pages/customer_main_screen.dart';
import 'package:team_five_fe/features/customer/presentation/pages/checkout_page.dart';
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
    testWidgets('CustomerMainScreen renders VELOCE app bar and bottom tabs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerExploreProvider.overrideWith(() => MockCustomerExploreNotifier()),
          ],
          child: const MaterialApp(
            home: CustomerMainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('VELOCE'), findsOneWidget);
      expect(find.text('Explore'), findsWidgets);
      expect(find.text('Tickets'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('CheckoutPage renders order summary and payment methods', (tester) async {
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
