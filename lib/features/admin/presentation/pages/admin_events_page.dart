import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/features/event/data/models/event_model.dart';
import 'package:veloce/features/event/presentation/providers/event_provider.dart';

enum EventFilter { active, upcoming, ended }

class AdminEventsPage extends ConsumerStatefulWidget {
  const AdminEventsPage({super.key});

  @override
  ConsumerState<AdminEventsPage> createState() => _AdminEventsPageState();
}

class _AdminEventsPageState extends ConsumerState<AdminEventsPage>
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
    return events
        .where((e) {
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
        })
        .where((e) {
          if (_searchQuery.isEmpty) return true;
          return e.name.toLowerCase().contains(_searchQuery);
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(allEventsProvider);

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
                  'All Events',
                  style: AppTextStyles.title.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 2),
                Text(
                  'View all events across organizers',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
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

  Widget _buildEventList(AllEventsState state) {
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
                  ref.read(allEventsProvider.notifier).loadAllEvents(),
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
      onRefresh: () => ref.read(allEventsProvider.notifier).loadAllEvents(),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
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
          children: [
            Row(
              children: [
                _buildEventIcon(event, index, isOnSale, isDraft, isSoldOut),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEventInfo(event, isOnSale, isDraft, isSoldOut),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDivider(),
            const SizedBox(height: 12),
            _buildEventFooter(event),
          ],
        ),
      ),
    );
  }

  // ==================== Event Icon ====================

  Widget _buildEventIcon(
    Event event,
    int index,
    bool isOnSale,
    bool isDraft,
    bool isSoldOut,
  ) {
    final hasImage = event.imageUrl != null && event.imageUrl!.isNotEmpty;

    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          event.imageUrl!,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackIcon(event, index),
        ),
      );
    }

    return _buildFallbackIcon(event, index);
  }

  Widget _buildFallbackIcon(Event event, int index) {
    final icon = _getIcon(index);
    final initials = _getInitials(event.name);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            initials,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Icon(
              icon,
              size: 14,
              color: AppColors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
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

  // ==================== Event Info ====================

  Widget _buildEventInfo(
    Event event,
    bool isOnSale,
    bool isDraft,
    bool isSoldOut,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusText(isOnSale, isDraft, isSoldOut),
        const SizedBox(height: 4),
        Text(
          event.name,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        _buildEventMeta(event),
      ],
    );
  }

  Widget _buildEventMeta(Event event) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final type = event.isSeated ? 'Seated' : 'Standing';

    return Row(
      children: [
        Icon(Icons.calendar_today, size: 12, color: AppColors.grey),
        const SizedBox(width: 4),
        Text(
          '${dateFormat.format(event.eventDate)} • ${timeFormat.format(event.eventDate)}',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.greyLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                event.isSeated ? Icons.event_seat : Icons.person,
                size: 10,
                color: AppColors.grey,
              ),
              const SizedBox(width: 3),
              Text(
                type,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 10,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== Status Text ====================

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
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ==================== Divider ====================

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        color: AppColors.greyLight.withValues(alpha: 0.6),
      ),
    );
  }

  // ==================== Event Footer ====================

  Widget _buildEventFooter(Event event) {
    return Row(
      children: [
        if (event.refundPercentage != null && event.refundPercentage! > 0) ...[
          Icon(Icons.replay, size: 12, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            'Refund ${event.refundPercentage}%',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ] else ...[
          Icon(Icons.event, size: 12, color: AppColors.grey),
          const SizedBox(width: 4),
          Text(
            'Event #${event.id.substring(0, min(8, event.id.length))}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
