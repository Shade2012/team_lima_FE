import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../event/data/models/event_model.dart';
import '../../../ticket_category/data/models/ticket_category_model.dart';
import '../../../ticket_category/data/repositories/ticket_category_repository.dart';
import 'seat_selection_page.dart';
import 'checkout_page.dart';

final customerCategoryRepositoryProvider = Provider<TicketCategoryRepository>((
  ref,
) {
  return TicketCategoryRepository();
});

final customerCategoriesByEventProvider =
    FutureProvider.family<List<TicketCategory>, String>((ref, eventId) async {
      final repo = ref.watch(customerCategoryRepositoryProvider);
      try {
        return await repo.getCategoriesByEvent(eventId);
      } catch (_) {
        // Return sample categories if mock server is offline or empty
        return [
          TicketCategory(
            id: 'cat_vip',
            eventId: eventId,
            name: 'VIP Front Row',
            price: 1500000,
            totalQuota: 100,
          ),
          TicketCategory(
            id: 'cat_reg',
            eventId: eventId,
            name: 'Regular Admission',
            price: 750000,
            totalQuota: 250,
          ),
        ];
      }
    });

class CustomerEventDetailPage extends ConsumerStatefulWidget {
  final Event? event;
  final String? eventId;
  final String eventName;
  final String categoryName;
  final double price;
  final String location;
  final bool isSeated;

  const CustomerEventDetailPage({
    super.key,
    this.event,
    this.eventId,
    this.eventName = 'Sonic Resonance Festival 2024',
    this.categoryName = 'ELECTRONIC',
    this.price = 150.0,
    this.location = 'Main Stage Pavilion • Oct 15-17',
    this.isSeated = true,
  });

  @override
  ConsumerState<CustomerEventDetailPage> createState() =>
      _CustomerEventDetailPageState();
}

class _CustomerEventDetailPageState
    extends ConsumerState<CustomerEventDetailPage> {
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final targetEventId =
        widget.event?.id ?? widget.eventId ?? '019146a0-event';
    final categoriesAsync = ref.watch(
      customerCategoriesByEventProvider(targetEventId),
    );

    final title = widget.event?.name ?? widget.eventName;
    final isSeated = widget.event?.isSeated ?? widget.isSeated;
    final refundPolicy =
        widget.event?.refundPolicy ??
        'Refund dapat diajukan maksimal 7 hari sebelum event.';
    final refundPercentage = widget.event?.refundPercentage ?? 80;

    final dateFormat = DateFormat('EEE, MMM dd, yyyy');
    final eventDateStr = widget.event?.eventDate != null
        ? dateFormat.format(widget.event!.eventDate)
        : 'Oct 15 - 17, 2024';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildAppBar(context),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover Banner Image Container
                    _buildCoverBanner(widget.categoryName),
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Category Tag
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.categoryName,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isSeated)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6E8FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'SEATED EVENT',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            style: AppTextStyles.title.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.black,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Date & Venue Details Card
                          _buildDetailsCard(eventDateStr, widget.location),
                          const SizedBox(height: 20),

                          // Refund Policy Box
                          _buildRefundPolicyCard(
                            refundPolicy,
                            refundPercentage,
                          ),
                          const SizedBox(height: 24),

                          // Ticket Category List Section
                          Text(
                            'Select Ticket Category',
                            style: AppTextStyles.title.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 12),

                          categoriesAsync.when(
                            data: (categories) =>
                                _buildCategoryList(categories),
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            error: (_, _) => _buildFallbackCategoryList(),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Action Bar
            _buildBottomActionBar(
              context,
              categoriesAsync.asData?.value,
              isSeated,
              title,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.black,
                size: 20,
              ),
            ),
          ),
          Text(
            'Event Details',
            style: AppTextStyles.title.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Sharing event...')));
            },
            icon: const Icon(Icons.share_outlined, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverBanner(String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF2A004E), Color(0xFF6B0096), Color(0xFFAF06FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                category == 'ELECTRONIC' ? Icons.equalizer : Icons.music_note,
                color: Colors.white24,
                size: 70,
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Live Concert',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(String dateStr, String venueStr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7ECFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date & Time',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.black45,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF0F0F5)),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7ECFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location & Venue',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.black45,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      venueStr,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefundPolicyCard(String policy, int percentage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE8B8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Refund Policy ($percentage% Guaranteed)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: const Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  policy,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF78350F),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<TicketCategory> categories) {
    if (categories.isEmpty) return _buildFallbackCategoryList();

    return Column(
      children: List.generate(categories.length, (index) {
        final category = categories[index];
        final isSelected = index == _selectedCategoryIndex;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFE5E5EA),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<int>(
                    value: index,
                    groupValue: _selectedCategoryIndex,
                    activeColor: AppColors.primary,
                    onChanged: (val) =>
                        setState(() => _selectedCategoryIndex = val!),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${category.totalQuota} Seats Quota',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Rp ${NumberFormat('#,###').format(category.price)}',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFallbackCategoryList() {
    final fallbackList = [
      {'name': 'VIP Front Row', 'price': 150.0, 'quota': 100},
      {'name': 'Regular Admission', 'price': 75.0, 'quota': 300},
    ];

    return Column(
      children: List.generate(fallbackList.length, (index) {
        final item = fallbackList[index];
        final isSelected = index == _selectedCategoryIndex;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFE5E5EA),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<int>(
                    value: index,
                    groupValue: _selectedCategoryIndex,
                    activeColor: AppColors.primary,
                    onChanged: (val) =>
                        setState(() => _selectedCategoryIndex = val!),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item['quota']} Quota Left',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${(item['price'] as double).toInt()}',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    List<TicketCategory>? categories,
    bool isSeated,
    String title,
  ) {
    final categoryName = categories != null && categories.isNotEmpty
        ? categories[_selectedCategoryIndex % categories.length].name
        : 'VIP PASS';

    final categoryPrice = categories != null && categories.isNotEmpty
        ? categories[_selectedCategoryIndex % categories.length].price
              .toDouble()
        : widget.price;

    final categoryId = categories != null && categories.isNotEmpty
        ? categories[_selectedCategoryIndex % categories.length].id
        : 'cat_vip';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Price',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.black45,
                    fontSize: 11,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    categoryPrice > 10000
                        ? 'Rp ${NumberFormat('#,###').format(categoryPrice)}'
                        : '\$${categoryPrice.toInt()}',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              if (isSeated) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeatSelectionPage(
                      eventId:
                          widget.event?.id ??
                          widget.eventId ??
                          '019146a0-event',
                      eventName: title,
                      categoryName: categoryName,
                      categoryId: categoryId,
                      price: categoryPrice > 10000 ? 150.0 : categoryPrice,
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutPage(
                      eventName: title,
                      eventCategory: categoryName,
                      price: categoryPrice > 10000 ? 150.0 : categoryPrice,
                      location: widget.location,
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              children: [
                Icon(
                  isSeated ? Icons.event_seat : Icons.shopping_bag_outlined,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  isSeated ? 'Select Seat' : 'Checkout Now',
                  style: AppTextStyles.button.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
