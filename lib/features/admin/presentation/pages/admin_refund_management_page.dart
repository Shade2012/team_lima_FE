import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:team_five_fe/core/theme/app_colors.dart';
import 'package:team_five_fe/core/theme/app_text_styles.dart';
import 'package:team_five_fe/features/admin/data/models/refund_model.dart';
import 'package:team_five_fe/features/admin/presentation/providers/admin_refund_provider.dart';
import 'package:team_five_fe/features/admin/presentation/pages/admin_refund_detail_page.dart';

class AdminRefundManagementPage extends ConsumerStatefulWidget {
  const AdminRefundManagementPage({super.key});

  @override
  ConsumerState<AdminRefundManagementPage> createState() =>
      _AdminRefundManagementPageState();
}

class _AdminRefundManagementPageState
    extends ConsumerState<AdminRefundManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'ALL';

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
    var filtered = refunds;

    if (_selectedFilter != 'ALL') {
      filtered = filtered
          .where((r) => r.status?.toUpperCase() == _selectedFilter)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((r) {
        return (r.orderId?.toLowerCase().contains(q) ?? false) ||
            (r.customerName?.toLowerCase().contains(q) ?? false) ||
            (r.eventName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(refundListProvider);
    final stats = listState.stats;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildStatsSection(stats),
                    const SizedBox(height: 20),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    _buildFilterTabs(),
                    const SizedBox(height: 12),
                    _buildRefundList(listState),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Header ====================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Refund Management',
            style: AppTextStyles.title.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 2),
          Text(
            'Manage customer refund requests',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Stats Section ====================

  Widget _buildStatsSection(RefundStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'Pending Refunds',
                  value: stats.pendingCount.toString(),
                  icon: Icons.schedule,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCardGradient(
                  label: 'Total Refunded',
                  value: _formatCurrency(stats.totalRefundAmount),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            label: 'Approved Refunds',
            value: stats.totalRefunded.toString(),
            icon: Icons.check_circle_outline,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.title.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardGradient({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9B00E8), AppColors.magenta],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.title.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Search Bar ====================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
          decoration: InputDecoration(
            hintText: 'Search Order ID, Name, or Event...',
            hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
            prefixIcon: const Icon(Icons.search, color: AppColors.grey, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.grey, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Filter Tabs ====================

  Widget _buildFilterTabs() {
    final filters = ['ALL', 'PENDING', 'APPROVED', 'REJECTED'];
    final labels = ['All', 'Pending', 'Approved', 'Rejected'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(filters.length, (index) {
            final isActive = _selectedFilter == filters[index];
            return Padding(
              padding: EdgeInsets.only(right: index < filters.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedFilter = filters[index]);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppColors.primary : AppColors.greyLight,
                    ),
                  ),
                  child: Text(
                    labels[index],
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isActive ? AppColors.white : AppColors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ==================== Refund List ====================

  Widget _buildRefundList(RefundListState listState) {
    if (listState.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (listState.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Center(
          child: Column(
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
        ),
      );
    }

    final filteredRefunds = _filterRefunds(listState.refunds);

    if (filteredRefunds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: AppColors.grey),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty || _selectedFilter != 'ALL'
                    ? 'No results found'
                    : 'No refund requests',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: filteredRefunds.map((refund) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRefundCard(refund),
          );
        }).toList(),
      ),
    );
  }

  // ==================== Refund Card ====================

  Widget _buildRefundCard(RefundRequest refund) {
    final colors = [
      AppColors.primary,
      AppColors.warning,
      AppColors.success,
      AppColors.danger,
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
    ];
    final colorIndex =
        (refund.customerName ?? '').hashCode.abs() % colors.length;
    final avatarColor = colors[colorIndex];

    final statusConfig = _getStatusConfig(refund.status);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminRefundDetailPage(refund: refund),
          ),
        );
        ref.read(refundListProvider.notifier).loadRefunds();
      },
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: avatarColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  refund.initials,
                  style: TextStyle(
                    color: avatarColor,
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
                  Text(
                    refund.orderId ?? '-',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
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
                          color: statusConfig.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusConfig.label,
                          style: TextStyle(
                            color: statusConfig.color,
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
                    'Requested ${_timeAgo(refund.requestedAt)}',
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
    );
  }

  _StatusConfig _getStatusConfig(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return _StatusConfig('Pending', AppColors.primary);
      case 'APPROVED':
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
