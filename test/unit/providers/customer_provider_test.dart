import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_five_fe/features/customer/presentation/providers/customer_provider.dart';

class MockCustomerExploreNotifier extends CustomerExploreNotifier {
  @override
  CustomerExploreState build() {
    return CustomerExploreState(events: []);
  }

  @override
  Future<void> loadPublicEvents() async {
    // Mock override to bypass network request during unit testing
  }
}

void main() {
  group('Customer Providers Unit Tests', () {
    // ==================== CUSTOMER WALLET UNIT TESTS ====================
    group('CustomerWalletNotifier Unit Tests', () {
      test('Happy Path: Initial balance is 0.0', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final walletState = container.read(customerWalletProvider);
        expect(walletState.balance, 0.0);
      });

      test('Happy Path: topUp increases wallet balance correctly', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(customerWalletProvider.notifier);
        notifier.topUp(100000.0);

        expect(container.read(customerWalletProvider).balance, 100000.0);
      });

      test(
        'Happy Path: deduct decreases wallet balance when funds are sufficient',
        () {
          final container = ProviderContainer();
          addTearDown(container.dispose);

          final notifier = container.read(customerWalletProvider.notifier);
          notifier.topUp(150000.0);
          final success = notifier.deduct(50000.0, 'Ticket Purchase');

          expect(success, true);
          expect(container.read(customerWalletProvider).balance, 100000.0);
        },
      );

      test(
        'Unhappy Path: topUp with zero or negative amount does not alter balance',
        () {
          final container = ProviderContainer();
          addTearDown(container.dispose);

          final notifier = container.read(customerWalletProvider.notifier);
          notifier.topUp(-50000.0);
          expect(container.read(customerWalletProvider).balance, 0.0);

          notifier.topUp(0.0);
          expect(container.read(customerWalletProvider).balance, 0.0);
        },
      );

      test('Unhappy Path: deduct fails when balance is insufficient', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(customerWalletProvider.notifier);
        notifier.topUp(50000.0);
        final success = notifier.deduct(100000.0, 'Ticket Purchase');

        expect(success, false);
        // Balance remains unchanged
        expect(container.read(customerWalletProvider).balance, 50000.0);
      });
    });

    // ==================== CHECKOUT NOTIFIER UNIT TESTS ====================
    group('CheckoutNotifier Unit Tests', () {
      test('Happy Path: CustomerExploreNotifier toggles saved event IDs', () {
        final container = ProviderContainer(
          overrides: [
            customerExploreProvider.overrideWith(
              () => MockCustomerExploreNotifier(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(customerExploreProvider.notifier);

        expect(container.read(customerExploreProvider).savedEventIds, isEmpty);

        notifier.toggleSaveEvent('evt_1');
        expect(
          container.read(customerExploreProvider).savedEventIds,
          contains('evt_1'),
        );

        notifier.toggleSaveEvent('evt_1');
        expect(container.read(customerExploreProvider).savedEventIds, isEmpty);
      });

      test('Happy Path: setPaymentMethod updates selected method', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(checkoutProvider.notifier);
        notifier.setPaymentMethod('QRIS');

        expect(container.read(checkoutProvider).paymentMethod, 'QRIS');
      });

      test('Happy Path: applyPromoCode with VELOCE10 applies 10% discount', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(checkoutProvider.notifier);

        notifier.setPromoCode('VELOCE10');
        final success = notifier.applyPromoCode();

        expect(success, true);
        final state = container.read(checkoutProvider);
        expect(state.isPromoApplied, true);
        expect(state.discount, 15.0);
      });

      test(
        'Unhappy Path: applyPromoCode with invalid code returns false and sets error',
        () {
          final container = ProviderContainer();
          addTearDown(container.dispose);

          final notifier = container.read(checkoutProvider.notifier);

          notifier.setPromoCode('INVALID_CODE');
          final success = notifier.applyPromoCode();

          expect(success, false);
          final state = container.read(checkoutProvider);
          expect(state.isPromoApplied, false);
          expect(state.error, 'Invalid promo code');
        },
      );

      test(
        'Unhappy Path: completePayment with E_WALLET fails when wallet balance is insufficient',
        () async {
          final container = ProviderContainer();
          addTearDown(container.dispose);

          final checkoutNotifier = container.read(checkoutProvider.notifier);
          checkoutNotifier.setPaymentMethod('E_WALLET');

          // Wallet balance is 0.0, payment requires total > 0
          final ticket = await checkoutNotifier.completePayment(
            eventName: 'Festival Concert',
            attendeeName: 'Alex Chen',
          );

          expect(ticket, isNull);
          final checkoutState = container.read(checkoutProvider);
          expect(checkoutState.error, contains('Insufficient Wallet Balance'));
        },
      );
    });
  });
}
