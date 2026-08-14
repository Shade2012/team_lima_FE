import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_five_fe/features/customer/presentation/providers/customer_provider.dart';

void main() {
  group('Customer Providers Unit Tests', () {
    test('CustomerExploreNotifier toggles saved event IDs', () {
      final container = ProviderContainer();
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

    test('CheckoutNotifier calculates discount and total on promo code VELOCE10', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(checkoutProvider.notifier);
      final initialState = container.read(checkoutProvider);

      expect(initialState.total, 177.50); // 150 + 15 + 12.50

      notifier.setPromoCode('VELOCE10');
      final success = notifier.applyPromoCode();

      expect(success, true);
      final updatedState = container.read(checkoutProvider);
      expect(updatedState.isPromoApplied, true);
      expect(updatedState.discount, 15.0);
      expect(updatedState.total, 162.50); // 177.50 - 15.0
    });
  });
}
