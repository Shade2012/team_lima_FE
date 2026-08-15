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
import 'package:team_five_fe/features/gate/presentation/providers/gate_provider.dart';
import 'package:team_five_fe/features/gate/presentation/pages/organizer/gate_management_page.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(eventDetailProvider.notifier).loadEvent(widget.eventId);
        ref.read(categoriesProvider.notifier).setEventId(widget.eventId);
        ref.read(gatesProvider.notifier).setEventId(widget.eventId);
      }
    });
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  String _safeDateFormat(DateTime? date, {String pattern = 'MMM dd, yyyy'}) {
    if (date == null) return '-';
    return DateFormat(pattern).format(date);
  }

  String _safeString(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(eventDetailProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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

  // ==================== Event Detail ====================

  Widget _buildEventDetail(Event event) {
    final now = DateTime.now();
    final isOnSale =
        now.isAfter(event.salesStartTime) && now.isBefore(event.salesEndTime);
    final isDraft = now.isBefore(event.salesStartTime);
    final isEnded = now.isAfter(event.salesEndTime);

    return Column(
      children: [
        // Purple Header
        _buildPurpleHeader(event, isOnSale, isDraft, isEnded),
        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Action Buttons (Edit + Share)
                _buildActionButtons(event),
                const SizedBox(height: 16),
                // Revenue Card
                _buildRevenueCard(),
                const SizedBox(height: 16),
                // Ticket Distribution
                _buildTicketDistribution(),
                const SizedBox(height: 16),
                // Sales Timeline
                _buildSalesTimeline(event),
                const SizedBox(height: 16),
                // Refund Policy
                _buildRefundPolicy(event),
                const SizedBox(height: 16),
                // Manage Buttons
                _buildManageButtons(event),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== Purple Header ====================

  Widget _buildPurpleHeader(
      Event event, bool isOnSale, bool isDraft, bool isEnded) {
    String statusText;
    Color statusColor;

    if (isDraft) {
      statusText = 'UPCOMING';
      statusColor = AppColors.warning;
    } else if (isEnded) {
      statusText = 'ENDED';
      statusColor = AppColors.grey;
    } else {
      statusText = 'ACTIVE';
      statusColor = AppColors.success;
    }

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
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Event Name
          Text(
            _safeString(event.name),
            style: AppTextStyles.title.copyWith(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          // Date
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.white70,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                _safeDateFormat(event.eventDate),
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

  // ==================== Action Buttons ====================

  Widget _buildActionButtons(Event event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
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
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(
            'Edit Event',
            style: AppTextStyles.button.copyWith(fontSize: 13),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Revenue Card ====================

  Widget _buildRevenueCard() {
    // Dummy data
    final totalRevenue = 37500000;

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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Revenue',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatPrice(totalRevenue),
                    style: AppTextStyles.title.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.attach_money,
                color: AppColors.success,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Ticket Distribution ====================

  Widget _buildTicketDistribution() {
    // Dummy data
    final categories = [
      {'name': 'Platinum VIP', 'sold': 450, 'total': 500, 'color': AppColors.primary},
      {'name': 'Gold Premium', 'sold': 800, 'total': 1000, 'color': AppColors.warning},
      {'name': 'Silver General', 'sold': 200, 'total': 2500, 'color': AppColors.grey},
      {'name': 'Bronze Early Bird', 'sold': 100, 'total': 1000, 'color': const Color(0xFFCD7F32)},
    ];

    final totalSold = categories.fold(0, (sum, c) => sum + (c['sold'] as int));
    final totalCapacity = categories.fold(0, (sum, c) => sum + (c['total'] as int));
    final soldPercentage = totalCapacity > 0 ? (totalSold / totalCapacity * 100).round() : 0;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ticket Distribution',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$soldPercentage% Sold Out',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...categories.map((cat) => _buildCategoryBar(
                  name: cat['name'] as String,
                  sold: cat['sold'] as int,
                  total: cat['total'] as int,
                  color: cat['color'] as Color,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar({
    required String name,
    required int sold,
    required int total,
    required Color color,
  }) {
    final progress = total > 0 ? sold / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              Text(
                '$sold / $total',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Sales Timeline ====================

  Widget _buildSalesTimeline(Event event) {
    final now = DateTime.now();

    final isBeforeSales = now.isBefore(event.salesStartTime);
    final isDuringSales = now.isAfter(event.salesStartTime) && now.isBefore(event.salesEndTime);
    final isAfterSales = now.isAfter(event.salesEndTime);
    final isBeforeEvent = now.isBefore(event.eventDate);

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
              'Sales Timeline',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 20),
            // Timeline
            Row(
              children: [
                _buildTimelineDot(
                  label: 'Sales Start',
                  date: _safeDateFormat(event.salesStartTime, pattern: 'MMM dd'),
                  isActive: !isBeforeSales,
                  isCurrent: isDuringSales,
                ),
                _buildTimelineLine(isActive: !isBeforeSales),
                _buildTimelineDot(
                  label: 'Sales End',
                  date: _safeDateFormat(event.salesEndTime, pattern: 'MMM dd'),
                  isActive: isAfterSales,
                  isCurrent: isDuringSales,
                ),
                _buildTimelineLine(
                  isActive: isAfterSales,
                  isDotted: !isAfterSales,
                ),
                _buildTimelineDot(
                  label: 'Event Day',
                  date: _safeDateFormat(event.eventDate, pattern: 'MMM dd'),
                  isActive: !isBeforeEvent,
                  isEventDay: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineDot({
    required String label,
    required String date,
    required bool isActive,
    bool isCurrent = false,
    bool isEventDay = false,
  }) {
    final Color dotColor;
    if (!isActive && !isCurrent) {
      dotColor = AppColors.greyLight;
    } else if (isEventDay) {
      dotColor = AppColors.danger;
    } else if (isCurrent) {
      dotColor = AppColors.primary;
    } else {
      dotColor = AppColors.success;
    }

    final bool showGlow = isActive || isCurrent;
    final bool showBorder = isEventDay || isCurrent;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: showBorder
                  ? Border.all(color: AppColors.white, width: 2)
                  : null,
              boxShadow: showGlow
                  ? [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 10,
              color: showGlow ? dotColor : AppColors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            date,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 9,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine({bool isActive = false, bool isDotted = false}) {
    final color = isActive ? AppColors.success : AppColors.greyLight;

    if (isDotted) {
      return Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.only(bottom: 30),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: color,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 30),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  // ==================== Refund Policy ====================

  Widget _buildRefundPolicy(Event event) {
    final policy = _safeString(event.refundPolicy);
    final refundPercentage = event.refundPercentage;

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
                  'Refund Policy',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFFB45309),
                  ),
                ),
                const Spacer(),
                if (refundPercentage != null && refundPercentage > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$refundPercentage%',
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
            Text(
              policy,
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF78350F),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Manage Buttons ====================

  Widget _buildManageButtons(Event event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Management',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          // Manage Ticket Category
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  await Navigator.push(
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
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.confirmation_number_outlined, size: 20),
              label: Text(
                'Manage Ticket Category',
                style: AppTextStyles.button.copyWith(fontSize: 14),
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
          const SizedBox(height: 10),
          // Manage Gates
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GateManagementPage(
                        eventId: widget.eventId,
                        eventName: event.name,
                      ),
                    ),
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.door_front_door_outlined, size: 20),
              label: Text(
                'Manage Gates',
                style: AppTextStyles.button.copyWith(fontSize: 14),
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
      ),
    );
  }
}
