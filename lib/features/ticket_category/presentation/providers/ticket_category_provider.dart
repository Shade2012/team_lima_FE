import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ticket_category_model.dart';
import '../../data/models/create_ticket_category_request.dart';
import '../../data/repositories/ticket_category_repository.dart';
import '../../../seat/data/models/bulk_seats_request.dart';
import '../../../seat/presentation/providers/seat_provider.dart';

final ticketCategoryRepositoryProvider = Provider<TicketCategoryRepository>((
  ref,
) {
  return TicketCategoryRepository();
});

// ==================== Categories List State ====================

class CategoriesState {
  final List<TicketCategory> categories;
  final bool isLoading;
  final String? error;

  CategoriesState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  CategoriesState copyWith({
    List<TicketCategory>? categories,
    bool? isLoading,
    String? error,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CategoriesNotifier extends Notifier<CategoriesState> {
  String _eventId = '';

  @override
  CategoriesState build() {
    return CategoriesState();
  }

  void setEventId(String eventId) {
    _eventId = eventId;
    loadCategories();
  }

  Future<void> loadCategories() async {
    if (_eventId.isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(ticketCategoryRepositoryProvider);
      final categories = await repository.getCategoriesByEvent(_eventId);
      state = state.copyWith(categories: categories, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> createCategory(
    CreateTicketCategoryRequest request, {
    required bool isSeated,
  }) async {
    state = state.copyWith(error: null);
    try {
      final repository = ref.read(ticketCategoryRepositoryProvider);
      final category = await repository.createCategory(request);
      state = state.copyWith(categories: [...state.categories, category]);

      if (isSeated) {
        final prefix = request.name.split(' ').first.toUpperCase();
        final seatRepo = ref.read(seatRepositoryProvider);
        await seatRepo.bulkGenerateSeats(
          BulkSeatsRequest(categoryId: category.id, prefix: prefix),
        );
        ref.read(seatsCountProvider.notifier).loadSeatsCount(category.id);
      }

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    state = state.copyWith(error: null);
    try {
      final repository = ref.read(ticketCategoryRepositoryProvider);
      await repository.deleteCategory(id);
      state = state.copyWith(
        categories: state.categories.where((c) => c.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final categoriesProvider =
    NotifierProvider<CategoriesNotifier, CategoriesState>(() {
      return CategoriesNotifier();
    });
