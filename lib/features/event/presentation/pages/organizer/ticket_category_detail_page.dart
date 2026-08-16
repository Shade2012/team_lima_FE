import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:team_five_fe/core/theme/app_colors.dart';
import 'package:team_five_fe/core/theme/app_text_styles.dart';
import 'package:team_five_fe/features/event/presentation/providers/event_provider.dart';

class TicketCategoryDetailPage extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;
  final String eventName;
  final DateTime eventDate;
  final bool isSeated;

  const TicketCategoryDetailPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.eventName,
    required this.eventDate,
    required this.isSeated,
  });

  @override
  ConsumerState<TicketCategoryDetailPage> createState() =>
      _TicketCategoryDetailPageState();
}

class _TicketCategoryDetailPageState
    extends ConsumerState<TicketCategoryDetailPage> {
  String _formatPrice(int price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  // Dummy data for testing
  dynamic _getDummyCategory() {
    return {
      'categoryId': widget.categoryId,
      'categoryName': widget.categoryName.isNotEmpty
          ? widget.categoryName
          : 'VIP Front Row',
      'price': 1500000,
      'totalQuota': 100,
      'ticketsSold': 42,
      'grossRevenue': 63000000,
      'refundCount': 3,
      'totalRefundAmount': 4500000,
      'refundPercentage': 80,
    };
  }

  @override
  Widget build(BuildContext context) {
    final statsState = ref.watch(eventStatisticsProvider);
    final statistics = statsState.statistics;

    dynamic category;
    if (statistics != null && statistics.categories.isNotEmpty) {
      try {
        category = statistics.categories.firstWhere(
          (c) => c.categoryId == widget.categoryId,
        );
      } catch (_) {
        category = null;
      }
    }

    // Use dummy data if category not found
    final displayCategory = category ?? _getDummyCategory();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: _buildBody(displayCategory),
    );
  }

  Widget _buildBody(dynamic category) {
    return Column(
      children: [
        _buildPurpleHeader(category),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildSalesOverviewCard(category),
                const SizedBox(height: 16),
                _buildRefundInfoCard(category),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurpleHeader(dynamic category) {
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
          // Back Button
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
          const SizedBox(height: 20),
          // Category Name
          Text(
            category.categoryName,
            style: AppTextStyles.title.copyWith(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          // Event Name
          Row(
            children: [
              const Icon(
                Icons.event,
                color: Colors.white70,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.eventName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Price
          Row(
            children: [
              const Icon(
                Icons.attach_money,
                color: Colors.white70,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                _formatPrice(category.price),
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesOverviewCard(dynamic category) {
    final soldPercentage = category.totalQuota > 0
        ? (category.ticketsSold / category.totalQuota * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
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
              'Sales Overview',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 20),
            // Stats Grid
            Row(
              children: [
                _buildStatItem(
                  'Tickets Sold',
                  '${category.ticketsSold}',
                  AppColors.primary,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  'Total Quota',
                  '${category.totalQuota}',
                  AppColors.grey,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem(
                  'Gross Revenue',
                  _formatPrice(category.grossRevenue),
                  AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sold Out',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$soldPercentage%',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: soldPercentage / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.grey,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.title.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundInfoCard(dynamic category) {
    if (category.refundPercentage <= 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
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
                  Icons.shield_outlined,
                  color: Color(0xFFD97706),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Refund Information',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFFB45309),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${category.refundPercentage}%',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRefundStatRow(
              'Total Refunds',
              '${category.refundCount}',
            ),
            const SizedBox(height: 8),
            _buildRefundStatRow(
              'Refund Amount',
              _formatPrice(category.totalRefundAmount),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: const Color(0xFF78350F),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF78350F),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
