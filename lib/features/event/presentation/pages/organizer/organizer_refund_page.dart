import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:team_five_fe/core/theme/app_colors.dart';
import 'package:team_five_fe/core/theme/app_text_styles.dart';
import 'package:team_five_fe/features/admin/data/models/refund_model.dart';
import 'package:team_five_fe/features/admin/presentation/providers/admin_refund_provider.dart';
import 'organizer_refund_detail_page.dart';

class OrganizerRefundPage extends ConsumerStatefulWidget {
  const OrganizerRefundPage({super.key});

  @override
  ConsumerState<OrganizerRefundPage> createState() =>
      _OrganizerRefundPageState();
}

class _OrganizerRefundPageState extends ConsumerState<OrganizerRefundPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'ALL';
  late TabController _tabController;

  static const _filters = ['ALL', 'PENDING', 'APPROVED', 'REJECTED'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedFilter = _filters[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
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
            _buildFilterTabs(),
            Expanded(child: _buildRefundList(listState)),
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
            'Refund Requests',
            style: AppTextStyles.title.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 2),
          Text(
            'View refund requests for your events',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  // ==================== Search Bar ====================

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
          hintText: 'Search Order ID, Name, or Event...',
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

  // ==================== Filter Tabs ====================

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.grey,
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.bodyMedium,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        dividerColor: AppColors.greyLight,
        dividerHeight: 1,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Pending'),
          Tab(text: 'Approved'),
          Tab(text: 'Rejected'),
        ],
      ),
    );
  }

  // ==================== Refund List ====================

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
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 40,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'ALL'
                  ? 'No results found'
                  : 'No refund requests',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'ALL'
                  ? 'Try adjusting your filters'
                  : 'Refund requests will appear here.',
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrganizerRefundDetailPage(refund: refund),
          ),
        );
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
