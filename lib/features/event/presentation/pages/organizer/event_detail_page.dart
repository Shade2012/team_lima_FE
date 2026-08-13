import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:team_five_fe/core/theme/app_colors.dart';
import 'package:team_five_fe/core/theme/app_text_styles.dart';
import 'package:team_five_fe/features/event/data/models/event_model.dart';
import 'package:team_five_fe/features/event/presentation/providers/event_provider.dart';
import 'package:team_five_fe/features/event/presentation/pages/organizer/edit_event_page.dart';
import 'package:team_five_fe/features/ticket_category/presentation/providers/ticket_category_provider.dart';
import 'package:team_five_fe/features/ticket_category/presentation/pages/organizer/ticket_category_page.dart';
import 'package:team_five_fe/features/ticket_category/presentation/pages/organizer/seat_preview_page.dart';
import 'package:team_five_fe/features/seat/presentation/providers/seat_provider.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _categoryColors = [
    AppColors.primary,
    AppColors.pink,
    AppColors.success,
    AppColors.warning,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(eventDetailProvider.notifier).loadEvent(widget.eventId);
        ref.read(categoriesProvider.notifier).setEventId(widget.eventId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  Color _getCategoryColor(int index) {
    return _categoryColors[index % _categoryColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(eventDetailProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(detailState),
    );
  }

  Widget _buildBody(EventDetailState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.grey),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(eventDetailProvider.notifier)
                  .loadEvent(widget.eventId),
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
    final event = state.event;
    if (event == null) {
      return const Center(child: Text('Event not found'));
    }

    return _buildEventDetail(event);
  }

  // ==================== Event Detail with Tabs ====================

  Widget _buildEventDetail(Event event) {
    final now = DateTime.now();
    final isOnSale =
        now.isAfter(event.salesStartTime) && now.isBefore(event.salesEndTime);
    final isDraft = now.isBefore(event.salesStartTime);
    final isSoldOut = now.isAfter(event.salesEndTime);
    final initials = _getInitials(event.name);

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        // Custom App Bar with Gradient
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppColors.primary,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.white),
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditEventPage(
                      eventId: event.id,
                      eventName: event.name,
                      isSeated: event.isSeated,
                      salesStartTime: event.salesStartTime,
                      salesEndTime: event.salesEndTime,
                      eventDate: event.eventDate,
                      refundEndDate: event.refundEndDate,
                      refundPolicy: event.refundPolicy,
                      refundPercentage: event.refundPercentage,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: AppColors.white),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.pink],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    left: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    right: 24,
                    child: Icon(
                      event.isSeated ? Icons.event_seat : Icons.mic,
                      size: 48,
                      color: AppColors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Text(
                        initials,
                        style: AppTextStyles.logo.copyWith(
                          fontSize: 64,
                          color: AppColors.white.withValues(alpha: 0.2),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isDraft) _buildStatusBadge(isOnSale, isSoldOut),
                        const SizedBox(height: 8),
                        Text(
                          event.name,
                          style: AppTextStyles.title.copyWith(
                            color: AppColors.white,
                            fontSize: 20,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Tab Bar
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.grey,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              dividerColor: AppColors.greyLight,
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTextStyles.bodyMedium,
              tabs: const [
                Tab(text: 'Event'),
                Tab(text: 'Ticket Category'),
              ],
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [_buildDataEventTab(event), _buildTicketCategoryTab(event)],
      ),
    );
  }
  // ==================== Tab 1: Data Event ====================

  Widget _buildDataEventTab(Event event) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Event Date + Event Type (side by side)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.greyLight, width: 1),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Event Date',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dateFormat.format(event.eventDate),
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('HH:mm').format(event.eventDate),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Divider
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: AppColors.greyLight,
                  ),
                  // Event Type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Event Type',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: event.isSeated
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            event.isSeated ? 'Seated' : 'Standing',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: event.isSeated
                                  ? AppColors.primary
                                  : AppColors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sales Period
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.greyLight, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales Period',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${dateFormat.format(event.salesStartTime)} - ${dateFormat.format(event.salesEndTime)}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Refund Policy (if available)
          if (event.refundEndDate != null ||
              event.refundPercentage != null ||
              (event.refundPolicy != null && event.refundPolicy!.isNotEmpty))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.greyLight, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Refund Policy',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (event.refundEndDate != null)
                    _buildRefundRow(
                      'Refund Until',
                      dateFormat.format(event.refundEndDate!),
                    ),
                  if (event.refundPercentage != null &&
                      event.refundPercentage! > 0)
                    _buildRefundRow(
                      'Refund Percentage',
                      '${event.refundPercentage}%',
                    ),
                  if (event.refundPolicy != null &&
                      event.refundPolicy!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      event.refundPolicy!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(event),
        ],
      ),
    );
  }

  Widget _buildRefundRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Tab 2: Ticket Category ====================

  Widget _buildTicketCategoryTab(Event event) {
    final categoriesState = ref.watch(categoriesProvider);
    final seatsCountState = ref.watch(seatsCountProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: categoriesState.isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          : categoriesState.categories.isEmpty
          ? _buildEmptyCategories(event)
          : _buildCategoriesContent(
              event: event,
              categories: categoriesState.categories,
              seatsCountState: seatsCountState,
            ),
    );
  }

  Widget _buildEmptyCategories(Event event) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.confirmation_number_outlined,
            size: 32,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'No Categories Yet',
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Add ticket categories to start selling tickets.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketCategoryPage(
                    eventId: event.id,
                    eventName: event.name,
                    isSeated: event.isSeated,
                    eventDate: event.eventDate,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'Add Category',
              style: AppTextStyles.button.copyWith(fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesContent({
    required Event event,
    required List categories,
    required SeatsCountState seatsCountState,
  }) {
    return Column(
      children: [
        // Category List
        ...List.generate(categories.length, (index) {
          final category = categories[index];
          final seatsCount = seatsCountState.counts[category.id];
          final color = _getCategoryColor(index);
          return _buildCategoryItem(
            category: category,
            seatsCount: seatsCount,
            color: color,
            isSeated: event.isSeated,
          );
        }),
        const SizedBox(height: 16),

        // Preview button (only for seated events)
        if (event.isSeated) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeatPreviewPage(
                      eventId: widget.eventId,
                      eventName: event.name,
                      eventDate: event.eventDate,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.preview, size: 18),
              label: Text(
                'Preview All Seats',
                style: AppTextStyles.button.copyWith(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Manage categories button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketCategoryPage(
                    eventId: widget.eventId,
                    eventName: event.name,
                    isSeated: event.isSeated,
                    eventDate: event.eventDate,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined, size: 18),
            label: Text(
              'Manage Categories',
              style: AppTextStyles.button.copyWith(fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== Shared Widgets ====================

  Widget _buildCategoryItem({
    required dynamic category,
    required int? seatsCount,
    required Color color,
    required bool isSeated,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.confirmation_number, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatPrice(category.price),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatChip(
                icon: Icons.people_outline,
                value: '${category.totalQuota}',
                color: AppColors.warning,
              ),
              if (isSeated && seatsCount != null) ...[
                const SizedBox(height: 4),
                _buildStatChip(
                  icon: Icons.event_seat,
                  value: '$seatsCount',
                  color: AppColors.success,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isOnSale, bool isSoldOut) {
    final label = isOnSale ? 'ON SALE' : 'SOLD OUT';
    final color = isOnSale ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOnSale) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Event event) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditEventPage(
                    eventId: event.id,
                    eventName: event.name,
                    isSeated: event.isSeated,
                    salesStartTime: event.salesStartTime,
                    salesEndTime: event.salesEndTime,
                    eventDate: event.eventDate,
                    refundEndDate: event.refundEndDate,
                    refundPolicy: event.refundPolicy,
                    refundPercentage: event.refundPercentage,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit, size: 20),
            label: Text('Edit', style: AppTextStyles.button),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteConfirmation(event),
            icon: const Icon(Icons.delete_outline, size: 20),
            label: Text('Delete', style: AppTextStyles.button),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].substring(0, min(2, words[0].length)).toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  void _showDeleteConfirmation(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Event', style: AppTextStyles.title),
        content: Text(
          'Are you sure you want to delete "${event.name}"?',
          style: AppTextStyles.bodyMedium,
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
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(myEventsProvider.notifier)
                  .deleteEvent(event.id);
              if (success && mounted) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Event deleted successfully!',
                        style: AppTextStyles.snackbar,
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text(
              'Delete',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Tab Bar Delegate ====================

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.background, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
