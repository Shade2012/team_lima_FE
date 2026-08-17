import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:team_five_fe/core/theme/app_colors.dart';
import 'package:team_five_fe/core/theme/app_text_styles.dart';
import 'package:team_five_fe/features/admin/data/models/refund_model.dart';
import 'package:team_five_fe/features/admin/presentation/providers/admin_refund_provider.dart';

class AdminRefundDetailPage extends ConsumerStatefulWidget {
  final RefundRequest refund;

  const AdminRefundDetailPage({super.key, required this.refund});

  @override
  ConsumerState<AdminRefundDetailPage> createState() =>
      _AdminRefundDetailPageState();
}

class _AdminRefundDetailPageState extends ConsumerState<AdminRefundDetailPage> {
  final TextEditingController _noteController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _noteController.dispose();
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

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('MMM dd, yyyy • HH:mm').format(date);
  }

  Future<void> _approveRefund() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Refund'),
        content: const Text('Are you sure you want to approve this refund?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve', style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    final success = await ref
        .read(refundListProvider.notifier)
        .approveRefund(widget.refund.id!);
    setState(() => _isProcessing = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refund approved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(refundListProvider).error ?? 'Failed to approve'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _rejectRefund() async {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for rejection'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Refund'),
        content: const Text('Are you sure you want to reject this refund?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    final success = await ref
        .read(refundListProvider.notifier)
        .rejectRefund(widget.refund.id!, reason: _noteController.text);
    setState(() => _isProcessing = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refund rejected'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(refundListProvider).error ?? 'Failed to reject'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final refund = widget.refund;
    final statusConfig = _getStatusConfig(refund.status);
    final isPending = refund.status?.toUpperCase() == 'PENDING';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [
          _buildHeader(refund, statusConfig),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDetailCard(refund),
                  const SizedBox(height: 16),
                  _buildReasonCard(refund),
                  const SizedBox(height: 16),
                  _buildNoteInput(),
                  if (isPending) ...[
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(RefundRequest refund, _StatusConfig statusConfig) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B0096), AppColors.primary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Refund Detail',
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: statusConfig.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusConfig.label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            refund.customerName ?? '-',
            style: AppTextStyles.title.copyWith(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            refund.eventName ?? '-',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(RefundRequest refund) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Refund Details',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Customer', refund.customerName ?? '-'),
          _buildDetailRow('Event', refund.eventName ?? '-'),
          if (refund.ticketCategoryName != null)
            _buildDetailRow('Category', refund.ticketCategoryName!),
          if (refund.seatCode != null)
            _buildDetailRow('Seat', refund.seatCode!),
          _buildDetailRow('Ticket Status', refund.ticketStatus ?? '-'),
          _buildDetailRow('Order Status', refund.orderStatus ?? '-'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Refund Amount',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              Text(
                refund.amount != null ? _formatCurrency(refund.amount!) : '-',
                style: AppTextStyles.title.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonCard(RefundRequest refund) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE8B8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFFD97706),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Reason for Refund',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: const Color(0xFFB45309),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            refund.reason ?? 'No reason provided',
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF78350F),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Requested: ${_formatDate(refund.createdAt)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInput() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Notes (optional)',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add notes about this refund decision...',
              hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.greyLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isProcessing ? null : _rejectRefund,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Reject',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _approveRefund,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text('Approve', style: AppTextStyles.button),
          ),
        ),
      ],
    );
  }

  _StatusConfig _getStatusConfig(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return _StatusConfig('Pending', AppColors.primary);
      case 'PROCESSING':
        return _StatusConfig('Processing', AppColors.warning);
      case 'APPROVED':
      case 'RESOLVED':
        return _StatusConfig('Approved', AppColors.success);
      case 'REJECTED':
        return _StatusConfig('Rejected', AppColors.danger);
      default:
        return _StatusConfig(status ?? '-', AppColors.grey);
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  _StatusConfig(this.label, this.color);
}
