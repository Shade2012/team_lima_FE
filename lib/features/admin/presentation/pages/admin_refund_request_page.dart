import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:team_five_fe/core/theme/app_colors.dart';
import 'package:team_five_fe/core/theme/app_text_styles.dart';
import 'package:team_five_fe/features/admin/data/models/refund_model.dart';
import 'package:team_five_fe/features/admin/presentation/providers/admin_refund_provider.dart';
import 'package:team_five_fe/features/admin/presentation/pages/admin_refund_detail_page.dart';

class AdminRefundRequestPage extends ConsumerStatefulWidget {
  const AdminRefundRequestPage({super.key});

  @override
  ConsumerState<AdminRefundRequestPage> createState() =>
      _AdminRefundRequestPageState();
}

class _AdminRefundRequestPageState
    extends ConsumerState<AdminRefundRequestPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM dd').format(date);
  }

  List<RefundRequest> _filterRefunds(List<RefundRequest> refunds) {
    var filtered = refunds
        .where((r) => r.status?.toUpperCase() == 'PENDING')
        .toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((r) {
        return (r.customerName?.toLowerCase().contains(q) ?? false) ||
            (r.eventName?.toLowerCase().contains(q) ?? false) ||
            (r.ticketCategoryName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(refundListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(child: _buildRefundList(listState)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Refund Requests',
            style: AppTextStyles.title.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 2),
          Text(
            'Approve or reject customer refund requests',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search by name or event...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          prefixIcon: const Icon(Icons.search, color: AppColors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.greyLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.greyLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildRefundList(RefundListState listState) {
    if (listState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (listState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.grey),
            const SizedBox(height: 12),
            Text(
              listState.error!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(refundListProvider.notifier).loadRefunds(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Retry', style: AppTextStyles.button),
            ),
          ],
        ),
      );
    }

    final filteredRefunds = _filterRefunds(listState.refunds);

    if (filteredRefunds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 40,
                color: AppColors.success.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No pending requests',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'All refund requests have been processed.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(refundListProvider.notifier).loadRefunds(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        itemCount: filteredRefunds.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRefundCard(filteredRefunds[index]),
          );
        },
      ),
    );
  }

  Widget _buildRefundCard(RefundRequest refund) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminRefundDetailPage(refund: refund),
                ),
              );
              ref.read(refundListProvider.notifier).loadRefunds();
            },
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      refund.initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              refund.customerName ?? '-',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Pending',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        refund.eventName ?? '-',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Requested ${_timeAgo(refund.createdAt)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  refund.amount != null ? _formatCurrency(refund.amount!) : '-',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showRejectDialog(refund),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Reject',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.danger,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _approveRefund(refund),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Approve',
                    style: AppTextStyles.button.copyWith(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approveRefund(RefundRequest refund) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Approve Refund',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Approve refund for ${refund.customerName ?? '-'}?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Approve',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(refundListProvider.notifier)
        .approveRefund(refund.id!);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refund approved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(refundListProvider).error ?? 'Failed to approve',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showRejectDialog(RefundRequest refund) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.cancel_outlined,
              color: AppColors.danger,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Reject Refund',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject refund for ${refund.customerName ?? '-'}?',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for rejection...',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.greyLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.danger),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _rejectRefund(refund, reasonController.text.trim());
            },
            child: Text(
              'Reject',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectRefund(RefundRequest refund, String reason) async {
    final success = await ref
        .read(refundListProvider.notifier)
        .rejectRefund(refund.id!, reason: reason);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refund rejected'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(refundListProvider).error ?? 'Failed to reject',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
