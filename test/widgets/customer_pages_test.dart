import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_five_fe/features/customer/presentation/pages/customer_main_screen.dart';
import 'package:team_five_fe/features/customer/presentation/pages/checkout_page.dart';
import 'package:team_five_fe/features/customer/presentation/pages/customer_event_detail_page.dart';
import 'package:team_five_fe/features/customer/presentation/pages/customer_explore_page.dart';
import 'package:team_five_fe/features/customer/presentation/pages/customer_profile_page.dart';
import 'package:team_five_fe/features/customer/presentation/pages/seat_selection_page.dart';
import 'package:team_five_fe/features/customer/presentation/widgets/top_up_dialog.dart';
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
    // ==================== MAIN SCREEN & NAVIGATION ====================
    testWidgets(
      'Happy Path: CustomerMainScreen renders VELOCE app bar and bottom tabs',
      (tester) async {
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
        expect(find.text('Orders'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
      },
    );

    // ==================== EVENT DETAIL PAGE ====================
    testWidgets(
      'Happy Path: CustomerEventDetailPage renders details and category selection',
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

    // ==================== SEAT SELECTION PAGE ====================
    testWidgets(
      'Happy Path: SeatSelectionPage renders stage indicator and seat grid',
      (tester) async {
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
        expect(find.text('Booked'), findsOneWidget);
        expect(find.text('Confirm & Checkout'), findsOneWidget);
      },
    );

    // ==================== CHECKOUT PAGE ====================
    testWidgets(
      'Happy Path: CheckoutPage renders order summary and payment methods',
      (tester) async {
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
      },
    );

    testWidgets(
      'Unhappy Path: CheckoutPage displays wallet warning when balance is insufficient',
      (tester) async {
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

        // Default payment method is E_WALLET and balance is Rp 0
        expect(
          find.textContaining('Insufficient wallet balance'),
          findsOneWidget,
        );
        expect(find.text('+ Top Up'), findsOneWidget);
      },
    );

    // ==================== TOP UP DIALOG WIDGET TESTS ====================
    testWidgets(
      'Happy Path: TopUpDialog populates text when preset chip is tapped',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: TopUpDialog())),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Top Up Veloce Wallet'), findsOneWidget);
        expect(find.text('Rp 100k'), findsOneWidget);

        // Tap preset 250k chip
        await tester.tap(find.text('Rp 250k'));
        await tester.pump();

        expect(find.text('250000'), findsOneWidget);
      },
    );

    testWidgets(
      'Unhappy Path: TopUpDialog shows error when top up amount is zero',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: TopUpDialog())),
          ),
        );

        await tester.pumpAndSettle();

        // Clear input text
        await tester.enterText(find.byType(TextField), '0');
        await tester.tap(find.text('Top Up Now'));
        await tester.pump();

        expect(find.text('Please enter a valid top up amount'), findsOneWidget);
      },
    );

    // ==================== DASHBOARD & PROFILE WALLET CARD ====================
    testWidgets(
      'Happy Path: CustomerExplorePage renders Veloce E-Wallet card banner',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              customerExploreProvider.overrideWith(
                () => MockCustomerExploreNotifier(),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(body: CustomerExplorePage()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Veloce E-Wallet'), findsOneWidget);
        expect(find.text('Wallet Balance'), findsOneWidget);
        expect(find.text('Top Up'), findsOneWidget);
      },
    );

    testWidgets(
      'Happy Path: CustomerProfilePage renders Veloce E-Wallet section',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: CustomerProfilePage())),
        );

        await tester.pumpAndSettle();

        expect(find.text('Veloce E-Wallet'), findsOneWidget);
        expect(find.text('Available Balance'), findsOneWidget);
        expect(find.text('Top Up'), findsOneWidget);
      },
    );
  });
}
