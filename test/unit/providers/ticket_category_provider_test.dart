import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloce/features/ticket_category/presentation/providers/ticket_category_provider.dart';
import 'package:veloce/features/ticket_category/data/models/ticket_category_model.dart';

class MockCategoriesNotifier extends CategoriesNotifier {
  @override
  CategoriesState build() {
    return CategoriesState();
  }

  @override
  Future<void> loadCategories() async {
    state = state.copyWith(
      isLoading: false,
      categories: [
        TicketCategory(
          id: 'cat-1',
          eventId: 'evt-1',
          name: 'VIP',
          price: 200000,
          totalQuota: 100,
          posIndex: 0,
          rows: 10,
          columns: 10,
          availableQuota: 80,
          isAvailable: true,
        ),
        TicketCategory(
          id: 'cat-2',
          eventId: 'evt-1',
          name: 'General',
          price: 100000,
          totalQuota: 200,
          posIndex: 1,
          availableQuota: 150,
          isAvailable: true,
        ),
      ],
    );
  }

  @override
  Future<bool> deleteCategory(String id) async {
    state = state.copyWith(
      categories: state.categories.where((c) => c.id != id).toList(),
    );
    return true;
  }
}

void main() {
  group('TicketCategory Provider Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('CategoriesState initializes with empty state', () {
      final state = container.read(categoriesProvider);

      expect(state.categories, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('CategoriesState copyWith preserves categories', () {
      final categories = [
        TicketCategory(
          id: 'cat-1',
          eventId: 'evt-1',
          name: 'VIP',
          price: 200000,
          totalQuota: 100,
        ),
      ];

      final state = CategoriesState(categories: categories);
      final updated = state.copyWith(isLoading: true);

      expect(updated.categories.length, 1);
      expect(updated.isLoading, true);
    });

    test('CategoriesState copyWith clears error when not provided', () {
      final state = CategoriesState(error: 'Some error');
      final updated = state.copyWith(isLoading: true);

      expect(updated.error, isNull);
      expect(updated.isLoading, true);
    });

    test('CategoriesState copyWith preserves error when provided', () {
      final state = CategoriesState();
      final updated = state.copyWith(error: 'New error');

      expect(updated.error, 'New error');
    });

    test('CategoriesNotifier setEventId triggers loadCategories', () async {
      final container2 = ProviderContainer(
        overrides: [
          categoriesProvider.overrideWith(() => MockCategoriesNotifier()),
        ],
      );
      addTearDown(container2.dispose);

      final notifier = container2.read(categoriesProvider.notifier);
      notifier.setEventId('evt-1');

      // Wait for microtask to complete
      await Future.delayed(Duration.zero);

      final state = container2.read(categoriesProvider);
      expect(state.categories.length, 2);
      expect(state.categories.first.name, 'VIP');
    });

    test(
      'CategoriesNotifier deleteCategory removes category from list',
      () async {
        final container2 = ProviderContainer(
          overrides: [
            categoriesProvider.overrideWith(() => MockCategoriesNotifier()),
          ],
        );
        addTearDown(container2.dispose);

        final notifier = container2.read(categoriesProvider.notifier);
        notifier.setEventId('evt-1');

        await Future.delayed(Duration.zero);

        final success = await notifier.deleteCategory('cat-1');

        expect(success, true);
        final state = container2.read(categoriesProvider);
        expect(state.categories.length, 1);
        expect(state.categories.first.id, 'cat-2');
      },
    );
  });
}
