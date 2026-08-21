import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_five_fe/features/customer/data/models/customer_wallet_model.dart';
import 'package:team_five_fe/features/customer/data/repositories/customer_wallet_repository.dart';
import 'package:team_five_fe/features/customer/presentation/providers/customer_provider.dart';

class MockCustomerExploreNotifier extends CustomerExploreNotifier {
  @override
  CustomerExploreState build() {
    return CustomerExploreState(events: []);
  }

  @override
  Future<void> loadPublicEvents({bool forceRefresh = false}) async {
    // Mock override to bypass network request during unit testing
  }
}

class MockCustomerWalletRepository implements CustomerWalletRepository {
  double balance;
  List<CustomerWalletTransactionModel> trxs;

  MockCustomerWalletRepository({
    this.balance = 0.0,
    List<CustomerWalletTransactionModel>? trxs,
  }) : trxs = trxs ?? [];

  @override
  Future<CustomerWalletModel> getWallet() async {
    return CustomerWalletModel(id: 'w1', userId: 'u1', balance: balance);
  }

  @override
  Future<CustomerWalletModel> topUpWallet(int amount) async {
    if (amount <= 0) {
      throw Exception('amount must be a positive integer');
    }
    if (amount > 10000000) {
      throw Exception('Maximum top up amount is 10,000,000');
    }
    balance += amount;
    final tx = CustomerWalletTransactionModel(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      walletId: 'w1',
      amount: amount.toDouble(),
      type: 'TOPUP',
      note: 'Wallet Top Up',
    );
    trxs = [tx, ...trxs];
    return CustomerWalletModel(id: 'w1', userId: 'u1', balance: balance);
  }

  @override
  Future<List<CustomerWalletTransactionModel>> getWalletTransactions() async {
    return trxs;
  }
}

void main() {
  group('Customer Providers Unit Tests', () {
    // ==================== CUSTOMER WALLET UNIT TESTS ====================
    group('CustomerWalletNotifier Unit Tests', () {
      test('Happy Path: Initial balance is 0.0', () async {
        final mockRepo = MockCustomerWalletRepository(balance: 0.0);
        final container = ProviderContainer(
          overrides: [
            customerWalletRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );
        addTearDown(container.dispose);

        // Wait for build microtask loadWallet
        await Future.delayed(Duration.zero);

        final walletState = container.read(customerWalletProvider);
        expect(walletState.balance, 0.0);
      });

      test('Happy Path: topUp increases wallet balance correctly', () async {
        final mockRepo = MockCustomerWalletRepository(balance: 0.0);
        final container = ProviderContainer(
          overrides: [
            customerWalletRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );
        addTearDown(container.dispose);

        await Future.delayed(Duration.zero);
        final notifier = container.read(customerWalletProvider.notifier);
        await notifier.topUp(100000.0);

        expect(container.read(customerWalletProvider).balance, 100000.0);
      });

      test(
        'Happy Path: deduct decreases wallet balance when funds are sufficient',
        () async {
          final mockRepo = MockCustomerWalletRepository(balance: 150000.0);
          final container = ProviderContainer(
            overrides: [
              customerWalletRepositoryProvider.overrideWithValue(mockRepo),
            ],
          );
          addTearDown(container.dispose);

          await Future.delayed(Duration.zero);
          final notifier = container.read(customerWalletProvider.notifier);
          await notifier.loadWallet();
          final success = notifier.deduct(50000.0, 'Ticket Purchase');

          expect(success, true);
          expect(container.read(customerWalletProvider).balance, 100000.0);
        },
      );

      test(
        'Unhappy Path: topUp with zero or negative amount does not alter balance',
        () async {
          final mockRepo = MockCustomerWalletRepository(balance: 0.0);
          final container = ProviderContainer(
            overrides: [
              customerWalletRepositoryProvider.overrideWithValue(mockRepo),
            ],
          );
          addTearDown(container.dispose);

          await Future.delayed(Duration.zero);
          final notifier = container.read(customerWalletProvider.notifier);
          final res1 = await notifier.topUp(-50000.0);
          expect(res1, false);
          expect(container.read(customerWalletProvider).balance, 0.0);

          final res2 = await notifier.topUp(0.0);
          expect(res2, false);
          expect(container.read(customerWalletProvider).balance, 0.0);
        },
      );

      test('Unhappy Path: deduct fails when balance is insufficient', () async {
        final mockRepo = MockCustomerWalletRepository(balance: 50000.0);
        final container = ProviderContainer(
          overrides: [
            customerWalletRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );
        addTearDown(container.dispose);

        await Future.delayed(Duration.zero);
        final notifier = container.read(customerWalletProvider.notifier);
        await notifier.loadWallet();
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
        'Unhappy Path: completePayment with VELOCE_PAY fails when wallet balance is insufficient',
        () async {
          final mockRepo = MockCustomerWalletRepository(balance: 0.0);
          final container = ProviderContainer(
            overrides: [
              customerWalletRepositoryProvider.overrideWithValue(mockRepo),
            ],
          );
          addTearDown(container.dispose);

          await Future.delayed(Duration.zero);
          final checkoutNotifier = container.read(checkoutProvider.notifier);
          checkoutNotifier.setPaymentMethod('VELOCE_PAY');

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
