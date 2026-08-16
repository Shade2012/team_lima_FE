import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/refund_model.dart';
import '../../data/repositories/admin_refund_repository.dart';

final adminRefundRepositoryProvider = Provider<AdminRefundRepository>((ref) {
  return AdminRefundRepository();
});

// ==================== Refund List State ====================

class RefundListState {
  final List<RefundRequest> refunds;
  final bool isLoading;
  final String? error;
  final String selectedFilter;

  RefundListState({
    this.refunds = const [],
    this.isLoading = false,
    this.error,
    this.selectedFilter = 'ALL',
  });

  RefundListState copyWith({
    List<RefundRequest>? refunds,
    bool? isLoading,
    String? error,
    String? selectedFilter,
  }) {
    return RefundListState(
      refunds: refunds ?? this.refunds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

class RefundListNotifier extends Notifier<RefundListState> {
  @override
  RefundListState build() {
    Future.microtask(() => loadRefunds());
    return RefundListState();
  }

  Future<void> loadRefunds() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(adminRefundRepositoryProvider);
      final statusFilter = state.selectedFilter == 'ALL'
          ? null
          : state.selectedFilter;
      final refunds = await repository.getRefundRequests(status: statusFilter);
      state = state.copyWith(refunds: refunds, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> setFilter(String filter) async {
    state = state.copyWith(selectedFilter: filter);
    await loadRefunds();
  }

  Future<bool> approveRefund(String id, {String? notes}) async {
    try {
      final repository = ref.read(adminRefundRepositoryProvider);
      await repository.approveRefund(id, notes: notes);
      await loadRefunds();
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> rejectRefund(String id, {String? reason}) async {
    try {
      final repository = ref.read(adminRefundRepositoryProvider);
      await repository.rejectRefund(id, reason: reason);
      await loadRefunds();
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final refundListProvider =
    NotifierProvider<RefundListNotifier, RefundListState>(() {
  return RefundListNotifier();
});

// ==================== Refund Stats State ====================

class RefundStatsState {
  final RefundStats? stats;
  final bool isLoading;
  final String? error;

  RefundStatsState({this.stats, this.isLoading = false, this.error});

  RefundStatsState copyWith({
    RefundStats? stats,
    bool? isLoading,
    String? error,
  }) {
    return RefundStatsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RefundStatsNotifier extends Notifier<RefundStatsState> {
  @override
  RefundStatsState build() {
    Future.microtask(() => loadStats());
    return RefundStatsState();
  }

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(adminRefundRepositoryProvider);
      final stats = await repository.getRefundStats();
      state = state.copyWith(stats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final refundStatsProvider =
    NotifierProvider<RefundStatsNotifier, RefundStatsState>(() {
  return RefundStatsNotifier();
});
