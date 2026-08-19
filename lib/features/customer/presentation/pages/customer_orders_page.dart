import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/customer_provider.dart';
import '../../data/models/customer_order_model.dart';

class CustomerOrdersPage extends ConsumerWidget {
  const CustomerOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(customerOrdersProvider);
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
          'My Orders',
          style: AppTextStyles.title.copyWith(
            color: AppColors.black,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(customerOrdersProvider.notifier).loadOrders(),
        color: AppColors.primary,
        child: ordersState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ordersState.orders.isEmpty
            ? _buildEmptyState(context, ref)
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                itemCount: ordersState.orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = ordersState.orders[index];
                  return _buildOrderCard(context, order, formatter);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
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
                Icons.receipt_long_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Orders Yet',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ticket booking history will appear here once you make an order.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    CustomerOrderModel order,
    NumberFormat formatter,
  ) {
    final statusConfig = _getStatusConfig(order.status);

    return Container(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showOrderDetailDialog(context, order, formatter),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey,
                      ),
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
                const SizedBox(height: 10),
                Text(
                  order.eventName ?? 'Event Ticket Booking',
                  style: AppTextStyles.title.copyWith(fontSize: 16),
                ),
                if (order.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt!),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ],
                const Divider(height: 20, color: Color(0xFFF0F0F5)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${order.tickets.length} Ticket${order.tickets.length > 1 ? 's' : ''}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                    Text(
                      formatter.format(order.totalAmount),
                      style: AppTextStyles.title.copyWith(
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderDetailDialog(
    BuildContext context,
    CustomerOrderModel order,
    NumberFormat formatter,
  ) {
    final statusConfig = _getStatusConfig(order.status);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Order Details',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Order ID', order.id),
              if (order.eventName != null)
                _buildDetailRow('Event', order.eventName!),
              if (order.createdAt != null)
                _buildDetailRow(
                  'Date',
                  DateFormat('dd MMMM yyyy, HH:mm').format(order.createdAt!),
                ),
              const Divider(height: 24),
              Text(
                'Tickets Included',
                style: AppTextStyles.title.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (order.tickets.isEmpty)
                Text(
                  'Standard Admission Ticket',
                  style: AppTextStyles.bodyMedium,
                )
              else
                ...order.tickets.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${t.categoryName ?? 'Ticket'} ${t.seatCode != null ? '(${t.seatCode})' : ''}',
                          style: AppTextStyles.bodyMedium,
                        ),
                        if (t.price != null)
                          Text(
                            formatter.format(t.price!),
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: AppTextStyles.title.copyWith(fontSize: 15),
                  ),
                  Text(
                    formatter.format(order.totalAmount),
                    style: AppTextStyles.title.copyWith(
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _OrderStatusConfig _getStatusConfig(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return _OrderStatusConfig(
          'PAID',
          const Color(0xFFE6F4EA),
          const Color(0xFF137333),
        );
      case 'HELD':
      case 'PAYMENT_PENDING':
        return _OrderStatusConfig(
          'PENDING',
          const Color(0xFFFEF7E0),
          const Color(0xFFB06000),
        );
      case 'CANCELLED':
        return _OrderStatusConfig(
          'CANCELLED',
          const Color(0xFFFCE8E6),
          const Color(0xFFC5221F),
        );
      case 'FULL_REFUND':
      case 'PARTIAL_REFUND':
        return _OrderStatusConfig(
          status,
          const Color(0xFFE8F0FE),
          const Color(0xFF1A73E8),
        );
      default:
        return _OrderStatusConfig(
          status,
          const Color(0xFFF1F3F4),
          const Color(0xFF5F6368),
        );
    }
  }
}

class _OrderStatusConfig {
  final String label;
  final Color bgColor;
  final Color textColor;

  _OrderStatusConfig(this.label, this.bgColor, this.textColor);
}
