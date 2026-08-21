import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../event/data/models/event_model.dart';
import '../providers/customer_provider.dart';
import '../widgets/top_up_dialog.dart';
import 'customer_event_detail_page.dart';

class CustomerExplorePage extends ConsumerWidget {
  const CustomerExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exploreState = ref.watch(customerExploreProvider);
    final exploreNotifier = ref.read(customerExploreProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildAppBar(context, exploreState.searchQuery, exploreNotifier),
            // Body Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    exploreNotifier.loadPublicEvents(forceRefresh: true),
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      // Customer Wallet Card Section
                      _buildWalletCard(context, ref),
                      const SizedBox(height: 20),
                      // "For You" Section
                      _buildForYouSection(
                        context,
                        ref,
                        exploreState,
                        exploreNotifier,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Top App Bar ====================

  Widget _buildAppBar(
    BuildContext context,
    String searchQuery,
    CustomerExploreNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back, color: AppColors.black),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Flexible(
            child: Text(
              'VELOCE',
              style: AppTextStyles.title.copyWith(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => _showSearchDialog(context, searchQuery, notifier),
            icon: const Icon(Icons.search, color: AppColors.black, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(
    BuildContext context,
    String currentQuery,
    CustomerExploreNotifier notifier,
  ) {
    final controller = TextEditingController(text: currentQuery);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Search Events',
          style: AppTextStyles.title.copyWith(fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter event title...',
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) => notifier.setSearchQuery(val),
        ),
        actions: [
          TextButton(
            onPressed: () {
              notifier.setSearchQuery('');
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  // ==================== "For You" Section ====================

  // ==================== "For You" Section ====================

  Widget _buildForYouSection(
    BuildContext context,
    WidgetRef ref,
    CustomerExploreState state,
    CustomerExploreNotifier notifier,
  ) {
    if (state.isLoading && state.events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (state.error != null && state.events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Text(
              'Failed to load events: ${state.error}',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => notifier.loadPublicEvents(forceRefresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.filteredEvents.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'For You',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      notifier.loadPublicEvents(forceRefresh: true),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Refresh',
                    style: AppTextStyles.link.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event_busy,
                      size: 36,
                      color: AppColors.primary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No events found',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.searchQuery.isNotEmpty
                        ? 'Try searching with a different keyword'
                        : 'No public events available at this time',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final gradients = [
      [AppColors.primary, AppColors.primaryDark],
      [const Color(0xFF7C3AED), const Color(0xFF5B21B6)],
      [const Color(0xFF6366F1), const Color(0xFF4338CA)],
      [const Color(0xFFEC4899), const Color(0xFFBE185D)],
    ];

    final cardItems = state.filteredEvents.map((e) {
      final index = state.events.indexOf(e);
      final dateBadge = DateFormat('MMM dd').format(e.eventDate);
      return {
        'id': e.id,
        'event': e,
        'category': 'EVENT',
        'timeBadge': dateBadge,
        'title': e.name.length > 18 ? '${e.name.substring(0, 15)}...' : e.name,
        'fullTitle': e.name,
        'venue': 'Main Venue',
        'gradient': gradients[index % gradients.length],
      };
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'For You',
                style: AppTextStyles.title.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              TextButton(
                onPressed: () => notifier.loadPublicEvents(forceRefresh: true),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Refresh',
                  style: AppTextStyles.link.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Horizontal Scroll Cards List
        SizedBox(
          height: 325,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cardItems.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = cardItems[index];

              return _buildEventCard(
                context,
                id: item['id'] as String,
                event: item['event'] as Event?,
                category: item['category'] as String,
                timeBadge: item['timeBadge'] as String,
                title: item['title'] as String,
                fullTitle: item['fullTitle'] as String,
                venue: item['venue'] as String,
                gradientColors: item['gradient'] as List<Color>,
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== Individual Event Card ====================

  Widget _buildCardFallbackBanner(List<Color> gradientColors) {
    return Container(
      height: 135,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.confirmation_number_outlined,
          color: Colors.white38,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context, {
    required String id,
    Event? event,
    required String category,
    required String timeBadge,
    required String title,
    required String fullTitle,
    required String venue,
    required List<Color> gradientColors,
  }) {
    final imageUrl = event?.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      width: 210,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header (Network Image or Brand Fallback)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: hasImage
                ? Image.network(
                    imageUrl,
                    height: 135,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildCardFallbackBanner(gradientColors),
                  )
                : _buildCardFallbackBanner(gradientColors),
          ),
          // Content Area
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Time Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        category,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeBadge,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Title
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Venue
                Text(
                  venue,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Dedicated Price Range Row (between venue & Get Tickets button)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final categoriesAsync = ref.watch(
                        customerCategoriesByEventProvider(id),
                      );
                      final formatter = NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      );

                      return categoriesAsync.when(
                        data: (cats) {
                          if (cats.isEmpty) {
                            return Text(
                              'Rp 0',
                              style: AppTextStyles.title.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            );
                          }
                          final prices = cats.map((c) => c.price).toList();
                          final minP = prices.reduce((a, b) => a < b ? a : b);
                          final maxP = prices.reduce((a, b) => a > b ? a : b);
                          final text = minP == maxP
                              ? formatter.format(minP)
                              : '${formatter.format(minP)} - ${formatter.format(maxP)}';
                          return Text(
                            text,
                            style: AppTextStyles.title.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          );
                        },
                        loading: () => Text(
                          'Loading...',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        error: (_, _) => Text(
                          'Rp 500.000 - Rp 1.500.000',
                          style: AppTextStyles.title.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                // Get Tickets Button Row (Aligned right)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerEventDetailPage(
                            event: event,
                            eventId: id,
                            eventName: fullTitle,
                            categoryName: category,
                            location: venue,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF6E8FF),
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Get Tickets',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(customerWalletProvider);

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final formattedBalance = formatter.format(walletState.balance);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF4A00E0)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Veloce E-Wallet',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Wallet Balance',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formattedBalance,
            style: AppTextStyles.title.copyWith(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => TopUpDialog.show(context),
                  icon: const Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Top Up',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veloce QR Pay coming soon!'),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.qr_code_scanner,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'QR Pay',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
