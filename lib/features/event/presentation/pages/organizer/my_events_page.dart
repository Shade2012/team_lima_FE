import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:team_five_fe/core/theme/app_colors.dart';
import 'package:team_five_fe/core/theme/app_text_styles.dart';
import 'package:team_five_fe/features/event/data/models/event_model.dart';
import 'package:team_five_fe/features/event/presentation/providers/event_provider.dart';
import 'package:team_five_fe/features/event/presentation/pages/organizer/create_event_page.dart';
import 'package:team_five_fe/features/event/presentation/pages/organizer/event_detail_page.dart';

enum EventFilter { active, upcoming, ended }

class MyEventsPage extends ConsumerStatefulWidget {
  const MyEventsPage({super.key});

  @override
  ConsumerState<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends ConsumerState<MyEventsPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  EventFilter _selectedFilter = EventFilter.active;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedFilter = EventFilter.values[_tabController.index];
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

  List<Event> _filterEvents(List<Event> events) {
    final now = DateTime.now();
    return events.where((e) {
      final isOnSale =
          now.isAfter(e.salesStartTime) && now.isBefore(e.salesEndTime);
      final isUpcoming = now.isBefore(e.salesStartTime);
      final isEnded = now.isAfter(e.salesEndTime);

      switch (_selectedFilter) {
        case EventFilter.active:
          return isOnSale;
        case EventFilter.upcoming:
          return isUpcoming;
        case EventFilter.ended:
          return isEnded;
      }
    }).where((e) {
      if (_searchQuery.isEmpty) return true;
      return e.name.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(myEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(child: _buildEventList(eventsState)),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ==================== Header ====================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Events',
                  style: AppTextStyles.title.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage your events',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
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
        onChanged: (value) =>
            setState(() => _searchQuery = value.toLowerCase()),
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search events...',
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

  // ==================== Tab Bar ====================

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
          Tab(text: 'Active'),
          Tab(text: 'Upcoming'),
          Tab(text: 'Ended'),
        ],
      ),
    );
  }

  // ==================== Event List ====================

  Widget _buildEventList(MyEventsState state) {
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
              onPressed: () =>
                  ref.read(myEventsProvider.notifier).loadMyEvents(),
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

    final filteredEvents = _filterEvents(state.events);

    if (filteredEvents.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(myEventsProvider.notifier).loadMyEvents(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        itemCount: filteredEvents.length,
        itemBuilder: (context, index) {
          final event = filteredEvents[index];
          return _buildEventCard(event, index);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case EventFilter.active:
        title = 'No active events';
        subtitle = 'Events on sale will appear here.';
        icon = Icons.event_available;
        break;
      case EventFilter.upcoming:
        title = 'No upcoming events';
        subtitle = 'Events that haven\'t started yet.';
        icon = Icons.upcoming;
        break;
      case EventFilter.ended:
        title = 'No ended events';
        subtitle = 'Past events will appear here.';
        icon = Icons.event_busy;
        break;
    }

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
              icon,
              size: 40,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  // ==================== Event Card ====================

  Widget _buildEventCard(Event event, int index) {
    final now = DateTime.now();
    final isOnSale =
        now.isAfter(event.salesStartTime) && now.isBefore(event.salesEndTime);
    final isDraft = now.isBefore(event.salesStartTime);
    final isSoldOut = now.isAfter(event.salesEndTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailPage(eventId: event.id),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(event, index, isOnSale, isDraft, isSoldOut),
              _buildCardContent(event, isOnSale, isDraft, isSoldOut),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== Banner (tanpa foto) ====================

  Widget _buildBanner(
    Event event,
    int index,
    bool isOnSale,
    bool isDraft,
    bool isSoldOut,
  ) {
    final gradient = _getGradient(isOnSale, isDraft, isSoldOut);
    final icon = _getIcon(index);
    final initials = _getInitials(event.name);

    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          // Icon di pojok kanan atas
          Positioned(
            top: 16,
            right: 16,
            child: Icon(
              icon,
              size: 32,
              color: AppColors.white.withValues(alpha: 0.4),
            ),
          ),

          // Badge status
          Positioned(
            top: 12,
            left: 12,
            child: _buildStatusBadge(isOnSale, isDraft, isSoldOut),
          ),

          // Inisial nama event di tengah
          Center(
            child: Text(
              initials,
              style: AppTextStyles.logo.copyWith(
                fontSize: 48,
                color: AppColors.white.withValues(alpha: 0.2),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getGradient(bool isOnSale, bool isDraft, bool isSoldOut) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.primary, AppColors.pink],
    );
  }

  IconData _getIcon(int index) {
    final icons = [
      Icons.celebration,
      Icons.mic,
      Icons.star,
      Icons.local_activity,
      Icons.headphones,
      Icons.piano,
      Icons.sports_esports,
      Icons.school,
      Icons.palette,
      Icons.restaurant,
    ];
    return icons[index % icons.length];
  }

  String _getInitials(String name) {
    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].substring(0, min(2, words[0].length)).toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  Widget _buildStatusBadge(bool isOnSale, bool isDraft, bool isSoldOut) {
    if (isDraft) return const SizedBox.shrink();

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

  // ==================== Card Content ====================

  Widget _buildCardContent(
    Event event,
    bool isOnSale,
    bool isDraft,
    bool isSoldOut,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final type = event.isSeated ? 'Seated' : 'Standing';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date + type
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '${dateFormat.format(event.eventDate)} • ${timeFormat.format(event.eventDate)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: event.isSeated
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      event.isSeated ? Icons.event_seat : Icons.person,
                      size: 12,
                      color: event.isSeated
                          ? AppColors.primary
                          : AppColors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      type,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: event.isSeated
                            ? AppColors.primary
                            : AppColors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Event name
          Text(
            event.name,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Refund info (jika ada)
          if (event.refundPercentage != null &&
              event.refundPercentage! > 0) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.replay, size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Refund ${event.refundPercentage}% until ${DateFormat('MMM dd').format(event.refundEndDate!)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons
          Row(
            children: [
              _buildStatusText(isOnSale, isDraft, isSoldOut),
              const Spacer(),
              _buildActionButtons(event),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText(bool isOnSale, bool isDraft, bool isSoldOut) {
    String text;
    Color color;

    if (isOnSale) {
      text = 'Active';
      color = AppColors.success;
    } else if (isDraft) {
      text = 'Upcoming';
      color = AppColors.warning;
    } else {
      text = 'Ended';
      color = AppColors.grey;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Event event) {
    return Row(
      children: [
        _buildIconButton(
          icon: Icons.edit_outlined,
          color: AppColors.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailPage(eventId: event.id),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        _buildIconButton(
          icon: Icons.delete_outline,
          color: AppColors.danger,
          onTap: () => _showDeleteConfirmation(event),
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  // ==================== FAB ====================

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEventPage()),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: AppColors.white, size: 28),
      ),
    );
  }

  // ==================== Delete Confirmation ====================

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
