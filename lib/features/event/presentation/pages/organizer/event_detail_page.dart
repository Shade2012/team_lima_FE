import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:team_five_fe/core/theme/app_colors.dart';
import 'package:team_five_fe/core/theme/app_text_styles.dart';
import 'package:team_five_fe/features/event/data/models/event_model.dart';
import 'package:team_five_fe/features/event/presentation/providers/event_provider.dart';
import 'package:team_five_fe/features/event/presentation/pages/organizer/edit_event_page.dart';

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
      }
    });
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

  Widget _buildEventDetail(Event event) {
    final now = DateTime.now();
    final isOnSale =
        now.isAfter(event.salesStartTime) && now.isBefore(event.salesEndTime);
    final isDraft = now.isBefore(event.salesStartTime);
    final isSoldOut = now.isAfter(event.salesEndTime);
    final initials = _getInitials(event.name);
    final dateFormat = DateFormat('dd MMMM yyyy');
    final timeFormat = DateFormat('HH:mm');

    return CustomScrollView(
      slivers: [
        // Custom App Bar with Gradient
        SliverAppBar(
          expandedHeight: 220,
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
                  // Decorative circles
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

                  // Icon
                  Positioned(
                    top: 60,
                    right: 24,
                    child: Icon(
                      event.isSeated ? Icons.event_seat : Icons.mic,
                      size: 48,
                      color: AppColors.white.withValues(alpha: 0.3),
                    ),
                  ),

                  // Initials
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

                  // Bottom info
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge status
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

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date & Time Card
                _buildInfoCard(
                  icon: Icons.calendar_today,
                  title: 'Event Date',
                  child: Column(
                    children: [
                      _buildDetailRow(
                        Icons.date_range,
                        'Date',
                        dateFormat.format(event.eventDate),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        Icons.access_time,
                        'Time',
                        timeFormat.format(event.eventDate),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Event Type Card
                _buildInfoCard(
                  icon: event.isSeated ? Icons.event_seat : Icons.person,
                  title: 'Event Type',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: event.isSeated
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          event.isSeated ? Icons.event_seat : Icons.person,
                          size: 20,
                          color: event.isSeated
                              ? AppColors.primary
                              : AppColors.grey,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          event.isSeated ? 'Seated' : 'Standing',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: event.isSeated
                                ? AppColors.primary
                                : AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sales Period Card
                _buildInfoCard(
                  icon: Icons.sell,
                  title: 'Sales Period',
                  child: Column(
                    children: [
                      _buildDetailRow(
                        Icons.play_circle_outline,
                        'Start',
                        dateFormat.format(event.salesStartTime),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        Icons.stop_circle_outlined,
                        'End',
                        dateFormat.format(event.salesEndTime),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Refund Card (if available)
                if (event.refundEndDate != null ||
                    event.refundPercentage != null) ...[
                  _buildInfoCard(
                    icon: Icons.replay,
                    title: 'Refund Policy',
                    child: Column(
                      children: [
                        if (event.refundEndDate != null)
                          _buildDetailRow(
                            Icons.calendar_today,
                            'Refund Until',
                            dateFormat.format(event.refundEndDate!),
                          ),
                        if (event.refundPercentage != null &&
                            event.refundPercentage! > 0) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            Icons.percent,
                            'Refund Percentage',
                            '${event.refundPercentage}%',
                          ),
                        ],
                        if (event.refundPolicy != null &&
                            event.refundPolicy!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event.refundPolicy!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                _buildActionButtons(event),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
