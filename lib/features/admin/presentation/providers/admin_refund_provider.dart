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
  final RefundStats stats;

  RefundListState({
    this.refunds = const [],
    this.isLoading = false,
    this.error,
    this.stats = const RefundStats(),
  });

  RefundListState copyWith({
    List<RefundRequest>? refunds,
    bool? isLoading,
    String? error,
    RefundStats? stats,
  }) {
    return RefundListState(
      refunds: refunds ?? this.refunds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
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
      final refunds = await repository.getRefundRequests();
      final stats = RefundStats.fromRefunds(refunds);
      state = state.copyWith(refunds: refunds, stats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> approveRefund(String id) async {
    try {
      final repository = ref.read(adminRefundRepositoryProvider);
      await repository.approveRefund(id);
      await loadRefunds();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> rejectRefund(String id, {required String reason}) async {
    try {
      final repository = ref.read(adminRefundRepositoryProvider);
      await repository.rejectRefund(id, reason: reason);
      await loadRefunds();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final refundListProvider =
    NotifierProvider<RefundListNotifier, RefundListState>(() {
      return RefundListNotifier();
    });
