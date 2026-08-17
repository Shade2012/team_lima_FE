import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:team_five_fe/core/theme/app_colors.dart';
import 'package:team_five_fe/core/theme/app_text_styles.dart';
import 'package:team_five_fe/features/gate/presentation/providers/gate_operator_dashboard_provider.dart';
import 'package:team_five_fe/features/auth/presentation/pages/profile_page.dart';
import 'package:team_five_fe/features/gate/presentation/pages/gate_operator/scanner_page.dart';

class GateOperatorDashboardPage extends ConsumerStatefulWidget {
  const GateOperatorDashboardPage({super.key});

  @override
  ConsumerState<GateOperatorDashboardPage> createState() =>
      _GateOperatorDashboardPageState();
}

class _GateOperatorDashboardPageState
    extends ConsumerState<GateOperatorDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(gateOperatorDashboardProvider.notifier).loadAssignedGate();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gateOperatorDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(child: _buildBody(context, ref, state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, GateOperatorDashboardState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _buildErrorState(state.error!);
    }

    return Column(
      children: [
        if (state.events.isNotEmpty) _buildScanStatsCard(state),
        Expanded(child: _buildEventList(context, ref, state)),
      ],
    );
  }

  Widget _buildScanStatsCard(GateOperatorDashboardState state) {
    final progress = state.scanProgress;
    final percentage = (progress * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scan Progress',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$percentage%',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem(
                  'Scanned',
                  '${state.scannedCount}',
                  AppColors.success,
                ),
                const SizedBox(width: 12),
                _buildStatItem(
                  'Total',
                  '${state.totalScans}',
                  AppColors.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
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
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: AppColors.danger.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(gateOperatorDashboardProvider.notifier).loadAssignedGate();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text('Retry', style: AppTextStyles.button),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Header ====================

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Gate Operator',
            style: AppTextStyles.title.copyWith(
              color: AppColors.primary,
              fontSize: 22,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: AppColors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Tab Bar ====================

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.grey,
        labelStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.bodyMedium,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        dividerColor: AppColors.greyLight,
        dividerHeight: 1,
        tabs: const [
          Tab(text: 'Active'),
          Tab(text: 'Upcoming'),
        ],
      ),
    );
  }

  // ==================== Event List ====================

  Widget _buildEventList(
      BuildContext context, WidgetRef ref, GateOperatorDashboardState state) {
    final activeEvents = state.events.where((e) => e.isActive).toList();
    final upcomingEvents = state.events.where((e) => !e.isActive).toList();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildEventListView(context, ref, activeEvents, isEmpty: activeEvents.isEmpty, isEmptyMessage: 'No active events'),
        _buildEventListView(context, ref, upcomingEvents, isEmpty: upcomingEvents.isEmpty, isEmptyMessage: 'No upcoming events'),
      ],
    );
  }

  Widget _buildEventListView(
    BuildContext context,
    WidgetRef ref,
    List<GateOperatorEvent> events, {
    required bool isEmpty,
    required String isEmptyMessage,
  }) {
    if (isEmpty) {
      return _buildEmptyState(isEmptyMessage);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(gateOperatorDashboardProvider.notifier).loadAssignedGate();
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return _buildEventCard(context, ref, events[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
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
              Icons.event_busy,
              size: 40,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  // ==================== Event Card ====================

  Widget _buildEventCard(
      BuildContext context, WidgetRef ref, GateOperatorEvent event) {
    final isSelected = event.isSelected;
    final dateFormat = DateFormat('MMMM dd, yyyy');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
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
            _buildPoster(event),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.eventName,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateFormat.format(event.eventDate),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildEventIcon(event),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSelectButton(context, ref, event, isSelected),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster(GateOperatorEvent event) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: event.isActive
              ? [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)]
              : [AppColors.greyLight, AppColors.greyLight.withValues(alpha: 0.7)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: event.isActive
              ? AppColors.white.withValues(alpha: 0.7)
              : AppColors.grey.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildEventIcon(GateOperatorEvent event) {
    if (event.isActive) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.celebration,
          color: AppColors.primary,
          size: 22,
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.greyLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.calendar_today,
        color: AppColors.grey,
        size: 22,
      ),
    );
  }

  Widget _buildSelectButton(
    BuildContext context,
    WidgetRef ref,
    GateOperatorEvent event,
    bool isSelected,
  ) {
    if (!event.isActive) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AppColors.greyLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Coming Soon',
            style: AppTextStyles.button.copyWith(color: AppColors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (isSelected) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScannerPage(
                  gateName: event.gateName,
                  eventName: event.eventName,
                ),
              ),
            );
          } else {
            ref.read(gateOperatorDashboardProvider.notifier).selectEvent(event.id);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Text(
          isSelected ? 'Scan Tickets' : 'Select to Scan',
          style: AppTextStyles.button.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
