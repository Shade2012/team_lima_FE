import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/customer_provider.dart';
import '../../data/models/customer_refund_model.dart';

class CustomerRefundsPage extends ConsumerWidget {
  const CustomerRefundsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refundsState = ref.watch(customerRefundsProvider);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'My Refunds',
          style: AppTextStyles.title.copyWith(
            color: AppColors.black,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(customerRefundsProvider.notifier).loadRefunds(),
        color: AppColors.primary,
        child: refundsState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : refundsState.refunds.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    itemCount: refundsState.refunds.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final refund = refundsState.refunds[index];
                      return _buildRefundCard(refund, formatter);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_return_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Refund Requests',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'You have not submitted any ticket refund requests.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundCard(CustomerRefundModel refund, NumberFormat formatter) {
    final statusConfig = _getRefundStatusConfig(refund.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                refund.eventName ?? 'Ticket Refund Request',
                style: AppTextStyles.title.copyWith(fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusConfig.bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusConfig.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: statusConfig.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (refund.categoryName != null || refund.seatCode != null) ...[
            const SizedBox(height: 4),
            Text(
              '${refund.categoryName ?? ''} ${refund.seatCode != null ? '(${refund.seatCode})' : ''}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (refund.createdAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Requested on ${DateFormat('dd MMM yyyy, HH:mm').format(refund.createdAt!)}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
            ),
          ],
          if (refund.reason != null && refund.reason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Reason: "${refund.reason}"',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.black,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          if (refund.status == 'REJECTED' && refund.rejectReason != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE8E6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Rejection Reason: ${refund.rejectReason}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFFC5221F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const Divider(height: 20, color: Color(0xFFF0F0F5)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Refund Amount',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey,
                ),
              ),
              Text(
                refund.amount != null
                    ? formatter.format(refund.amount!)
                    : 'Pending Calculation',
                style: AppTextStyles.title.copyWith(
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _RefundStatusConfig _getRefundStatusConfig(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return _RefundStatusConfig(
          'APPROVED',
          const Color(0xFFE6F4EA),
          const Color(0xFF137333),
        );
      case 'REJECTED':
        return _RefundStatusConfig(
          'REJECTED',
          const Color(0xFFFCE8E6),
          const Color(0xFFC5221F),
        );
      case 'PENDING':
      default:
        return _RefundStatusConfig(
          'PENDING',
          const Color(0xFFFEF7E0),
          const Color(0xFFB06000),
        );
    }
  }
}

class _RefundStatusConfig {
  final String label;
  final Color bgColor;
  final Color textColor;

  _RefundStatusConfig(this.label, this.bgColor, this.textColor);
}
