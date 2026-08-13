import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bulk_seats_request.dart';
import '../../data/models/seat_model.dart';
import '../../data/repositories/seat_repository.dart';

final seatRepositoryProvider = Provider<SeatRepository>((ref) {
  return SeatRepository();
});

// ==================== Bulk Generate Seats State ====================

class BulkSeatsState {
  final bool isLoading;
  final String? error;
  final BulkSeatsResponse? response;

  BulkSeatsState({this.isLoading = false, this.error, this.response});

  BulkSeatsState copyWith({
    bool? isLoading,
    String? error,
    BulkSeatsResponse? response,
  }) {
    return BulkSeatsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      response: response ?? this.response,
    );
  }
}

class BulkSeatsNotifier extends Notifier<BulkSeatsState> {
  @override
  BulkSeatsState build() {
    return BulkSeatsState();
  }

  Future<bool> generateSeats(BulkSeatsRequest request) async {
    state = state.copyWith(isLoading: true, error: null, response: null);
    try {
      final repository = ref.read(seatRepositoryProvider);
      final response = await repository.bulkGenerateSeats(request);
      state = state.copyWith(isLoading: false, response: response);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteSeatsByCategory(String categoryId) async {
    try {
      final repository = ref.read(seatRepositoryProvider);
      await repository.deleteSeatsByCategory(categoryId);
      return true;
    } catch (e) {
      return false;
    }
  }

  void reset() {
    state = BulkSeatsState();
  }
}

final bulkSeatsProvider = NotifierProvider<BulkSeatsNotifier, BulkSeatsState>(
  () {
    return BulkSeatsNotifier();
  },
);

// ==================== Seats Count State ====================

class SeatsCountState {
  final Map<String, int> counts;
  final bool isLoading;

  SeatsCountState({this.counts = const {}, this.isLoading = false});

  SeatsCountState copyWith({Map<String, int>? counts, bool? isLoading}) {
    return SeatsCountState(
      counts: counts ?? this.counts,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SeatsCountNotifier extends Notifier<SeatsCountState> {
  @override
  SeatsCountState build() {
    return SeatsCountState();
  }

  Future<void> loadSeatsCount(String categoryId) async {
    try {
      final repository = ref.read(seatRepositoryProvider);
      final count = await repository.getSeatsCountByCategory(categoryId);
      state = state.copyWith(counts: {...state.counts, categoryId: count});
    } catch (_) {}
  }
}

final seatsCountProvider =
    NotifierProvider<SeatsCountNotifier, SeatsCountState>(() {
      return SeatsCountNotifier();
    });

// ==================== Seats List State (for preview) ====================

class SeatsListState {
  final Map<String, List<Seat>> seatsByCategory;
  final bool isLoading;
  final String? error;

  SeatsListState({
    this.seatsByCategory = const {},
    this.isLoading = false,
    this.error,
  });

  SeatsListState copyWith({
    Map<String, List<Seat>>? seatsByCategory,
    bool? isLoading,
    String? error,
  }) {
    return SeatsListState(
      seatsByCategory: seatsByCategory ?? this.seatsByCategory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SeatsListNotifier extends Notifier<SeatsListState> {
  @override
  SeatsListState build() {
    return SeatsListState();
  }

  Future<void> loadSeats(String categoryId) async {
    if (state.seatsByCategory.containsKey(categoryId)) return;
    try {
      final repository = ref.read(seatRepositoryProvider);
      final seats = await repository.getSeatsByCategory(categoryId);
      state = state.copyWith(
        seatsByCategory: {...state.seatsByCategory, categoryId: seats},
      );
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  void clear() {
    state = SeatsListState();
  }
}

final seatsListProvider = NotifierProvider<SeatsListNotifier, SeatsListState>(
  () {
    return SeatsListNotifier();
  },
);
