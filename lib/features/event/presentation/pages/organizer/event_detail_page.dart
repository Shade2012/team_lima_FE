import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:team_five_fe/core/theme/app_colors.dart';
import 'package:team_five_fe/core/theme/app_text_styles.dart';
import 'package:team_five_fe/features/event/data/models/event_model.dart';
import 'package:team_five_fe/features/event/data/models/event_statistics_model.dart';
import 'package:team_five_fe/features/event/presentation/providers/event_provider.dart';
import 'package:team_five_fe/features/event/presentation/providers/event_sse_provider.dart';
import 'package:team_five_fe/features/event/data/repositories/event_sse_repository.dart';
import 'package:team_five_fe/features/event/presentation/pages/organizer/edit_event_page.dart';
import 'package:team_five_fe/features/event/presentation/pages/organizer/ticket_category_detail_page.dart';
import 'package:team_five_fe/features/ticket_category/presentation/providers/ticket_category_provider.dart';
import 'package:team_five_fe/features/ticket_category/presentation/pages/organizer/ticket_category_page.dart';
import 'package:team_five_fe/features/gate/presentation/providers/gate_provider.dart';
import 'package:team_five_fe/features/gate/presentation/pages/organizer/gate_management_page.dart';
import 'package:team_five_fe/features/seat/presentation/providers/seat_sse_provider.dart';
import 'package:team_five_fe/features/seat/data/repositories/seat_sse_repository.dart';
import 'package:team_five_fe/features/seat/presentation/providers/seat_provider.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage>
    with WidgetsBindingObserver {
  StreamSubscription<SeatUpdateEvent>? _seatSubscription;
  StreamSubscription<DashboardUpdateEvent>? _dashboardSubscription;
  ProviderSubscription<AsyncValue<SeatUpdateEvent>>? _seatListener;
  ProviderSubscription<AsyncValue<DashboardUpdateEvent>>? _dashboardListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _seatListener = ref.listenManual<AsyncValue<SeatUpdateEvent>>(
      seatSseProvider(widget.eventId),
      (previous, next) {
        next.whenData((update) {
          if (update.categoryId.isNotEmpty) {
            ref
                .read(seatsCountProvider.notifier)
                .loadSeatsCount(update.categoryId);
            ref.read(seatsListProvider.notifier).loadSeats(update.categoryId);
          }
        });
      },
    );

    _dashboardListener = ref.listenManual<AsyncValue<DashboardUpdateEvent>>(
      dashboardSseProvider(widget.eventId),
      (previous, next) {
        next.whenData((update) {
          ref
              .read(eventStatisticsProvider.notifier)
              .loadStatistics(widget.eventId);
        });
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(eventDetailProvider.notifier).loadEvent(widget.eventId);
        ref
            .read(eventStatisticsProvider.notifier)
            .loadStatistics(widget.eventId);
        ref.read(categoriesProvider.notifier).setEventId(widget.eventId);
        ref.read(gatesProvider.notifier).setEventId(widget.eventId);
        _startSeatSse();
        _startDashboardSse();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _startSeatSse();
      _startDashboardSse();
    } else if (state == AppLifecycleState.paused) {
      _seatSubscription?.cancel();
      _seatSubscription = null;
      _dashboardSubscription?.cancel();
      _dashboardSubscription = null;
    }
  }

  void _startSeatSse() {
    _seatSubscription?.cancel();
    _seatSubscription = ref
        .read(seatSseProvider(widget.eventId).future)
        .asStream()
        .listen((_) {});
  }

  void _startDashboardSse() {
    _dashboardSubscription?.cancel();
    _dashboardSubscription = ref
        .read(dashboardSseProvider(widget.eventId).future)
        .asStream()
        .listen((_) {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _seatListener?.close();
    _dashboardListener?.close();
    _seatSubscription?.cancel();
    _dashboardSubscription?.cancel();
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
    final statsState = ref.watch(eventStatisticsProvider);

    // Show statistics error as snackbar
    if (statsState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Statistics: ${statsState.error}',
                style: AppTextStyles.snackbar,
              ),
              backgroundColor: AppColors.danger,
              action: SnackBarAction(
                label: 'Retry',
                textColor: AppColors.white,
                onPressed: () {
                  ref
                      .read(eventStatisticsProvider.notifier)
                      .loadStatistics(widget.eventId);
                },
              ),
            ),
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: _buildBody(detailState, statsState),
    );
  }

  Widget _buildBody(EventDetailState state, EventStatisticsState statsState) {
    if (state.isLoading || (statsState.isLoading && statsState.statistics == null)) {
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
              onPressed: () {
                ref
                    .read(eventDetailProvider.notifier)
                    .loadEvent(widget.eventId);
                ref
                    .read(eventStatisticsProvider.notifier)
                    .loadStatistics(widget.eventId);
              },
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

    return _buildEventDetail(event, statsState.statistics);
  }

  // ==================== Event Detail ====================

  Widget _buildEventDetail(Event event, EventStatistics? statistics) {
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
                _buildRevenueCard(statistics),
                const SizedBox(height: 16),
                // Ticket Distribution
                _buildTicketDistribution(statistics, event),
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
    Event event,
    bool isOnSale,
    bool isDraft,
    bool isEnded,
  ) {
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
              const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
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

  Widget _buildRevenueCard(EventStatistics? statistics) {
    final netRevenue = statistics?.netRevenue;
    final grossRevenue = statistics?.grossRevenue;
    final totalRefundAmount = statistics?.totalRefundAmount;
    final totalRefundCount = statistics?.totalRefundCount;

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
              'Revenue',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 16),
            // Net Revenue - Large & Bold
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net Revenue',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    netRevenue != null ? _formatPrice(netRevenue) : '-',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Gross Revenue - Full Width
            _buildRevenueStatMedium(
              'Gross Revenue',
              grossRevenue != null ? _formatPrice(grossRevenue) : '-',
              AppColors.success,
            ),
            const SizedBox(height: 8),
            // Refund Amount & Total Refunds - Side by side
            Row(
              children: [
                Expanded(
                  child: _buildRevenueStatMedium(
                    'Refund Amount',
                    totalRefundAmount != null
                        ? _formatPrice(totalRefundAmount)
                        : '-',
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRevenueStatMedium(
                    'Total Refunds',
                    totalRefundCount != null ? '$totalRefundCount' : '-',
                    AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueStatMedium(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==================== Ticket Distribution ====================

  Widget _buildTicketDistribution(EventStatistics? statistics, Event event) {
    final categories = statistics?.categories;
    final totalSold = statistics?.totalTicketsSold;
    final totalQuota = statistics?.totalQuota;
    final soldPercentage = statistics?.percentageSold;

    final List<Color> categoryColors = [
      AppColors.primary,
      AppColors.warning,
      AppColors.grey,
      const Color(0xFFCD7F32),
      AppColors.success,
      AppColors.danger,
    ];

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
                if (soldPercentage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${soldPercentage.toStringAsFixed(1)}% Sold Out',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              totalSold != null && totalQuota != null
                  ? '$totalSold / $totalQuota tickets'
                  : '-',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            if (categories == null || categories.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No ticket categories yet',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ),
              )
            else
              ...categories.asMap().entries.map((entry) {
                final index = entry.key;
                final cat = entry.value;
                final color = categoryColors[index % categoryColors.length];
                return _buildCategoryBar(
                  category: cat,
                  color: color,
                  eventName: event.name,
                  eventDate: event.eventDate,
                  isSeated: event.isSeated,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar({
    required EventStatisticsCategory category,
    required Color color,
    required String eventName,
    required DateTime eventDate,
    required bool isSeated,
  }) {
    final totalQuota = category.totalQuota ?? 0;
    final ticketsSold = category.ticketsSold ?? 0;
    final progress = totalQuota > 0 ? ticketsSold / totalQuota : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TicketCategoryDetailPage(
              eventId: widget.eventId,
              categoryId: category.categoryId ?? '',
              categoryName: category.categoryName ?? '-',
              eventName: eventName,
              eventDate: eventDate,
              isSeated: isSeated,
            ),
          ),
        );
      },
      child: Padding(
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
                      category.categoryName ?? '-',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '$ticketsSold / $totalQuota',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: AppColors.grey, size: 18),
                  ],
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
      ),
    );
  }

  // ==================== Sales Timeline ====================

  Widget _buildSalesTimeline(Event event) {
    final now = DateTime.now();

    final isBeforeSales = now.isBefore(event.salesStartTime);
    final isDuringSales =
        now.isAfter(event.salesStartTime) && now.isBefore(event.salesEndTime);
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
                  date: _safeDateFormat(
                    event.salesStartTime,
                    pattern: 'MMM dd',
                  ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
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
                  if (mounted) {
                    ref
                        .read(eventStatisticsProvider.notifier)
                        .loadStatistics(widget.eventId);
                    ref.read(categoriesProvider.notifier).loadCategories();
                  }
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
