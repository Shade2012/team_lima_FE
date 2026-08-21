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
            isSeated: true,
          ),
          TicketCategory(
            id: 'cat_reg',
            eventId: eventId,
            name: 'Regular Admission',
            price: 750000,
            totalQuota: 250,
            isSeated: false,
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

  const CustomerEventDetailPage({
    super.key,
    this.event,
    this.eventId,
    this.eventName = 'Sonic Resonance Festival 2024',
    this.categoryName = 'ELECTRONIC',
    this.price = 1500000.0,
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
                    _buildCoverBanner(widget.categoryName, widget.event),
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Category / Admission Tags
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
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
                              if (widget.event != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.event!.isSeated
                                        ? const Color(0xFFF3E8FF)
                                        : const Color(0xFFEFEFEF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        widget.event!.isSeated
                                            ? Icons.event_seat
                                            : Icons.groups_outlined,
                                        size: 13,
                                        color: widget.event!.isSeated
                                            ? AppColors.primary
                                            : Colors.black87,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.event!.isSeated
                                            ? 'Numbered Seating'
                                            : 'Free Standing',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: widget.event!.isSeated
                                              ? AppColors.primary
                                              : Colors.black87,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
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

                          // Date & Time Details Card (with Sales Period Range)
                          _buildDetailsCard(eventDateStr, widget.event),
                          const SizedBox(height: 20),

                          // Sales Status Warning / Info Banner (if Sales Closed or Upcoming)
                          _buildSalesStatusBanner(widget.event),

                          // Event Description Card (ONLY if present & non-empty)
                          if (widget.event?.description != null &&
                              widget.event!.description!.trim().isNotEmpty) ...[
                            _buildDescriptionCard(
                              widget.event!.description!.trim(),
                            ),
                            const SizedBox(height: 20),
                          ],

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
                size: 18,
              ),
            ),
          ),
          Text(
            'Event Details',
            style: AppTextStyles.title.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildCoverBanner(String category, Event? event) {
    final imageUrl = event?.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    if (hasImage) {
      return SizedBox(
        height: 200,
        width: double.infinity,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildCoverFallbackBanner(),
        ),
      );
    }

    return _buildCoverFallbackBanner();
  }

  Widget _buildCoverFallbackBanner() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.confirmation_number_outlined,
          color: Colors.white30,
          size: 64,
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'About Event',
                style: AppTextStyles.title.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(String dateStr, Event? event) {
    String? salesPeriodStr;
    if (event != null) {
      final start = DateFormat('dd MMM yyyy, HH:mm').format(event.salesStartTime);
      final end = DateFormat('dd MMM yyyy, HH:mm').format(event.salesEndTime);
      salesPeriodStr = '$start - $end';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                  size: 18,
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
          if (salesPeriodStr != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF0F0F0)),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.access_time_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ticket Sales Period',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.black45,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        salesPeriodStr,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSalesStatusBanner(Event? event) {
    if (event == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final isUpcoming = now.isBefore(event.salesStartTime);
    final isEnded = now.isAfter(event.salesEndTime);

    if (!isUpcoming && !isEnded) return const SizedBox.shrink();

    final bannerColor = isEnded
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFEFF6FF);
    final borderColor = isEnded
        ? const Color(0xFFFCA5A5)
        : const Color(0xFF93C5FD);
    final iconColor = isEnded
        ? const Color(0xFFDC2626)
        : const Color(0xFF2563EB);
    final titleText = isEnded
        ? 'Ticket Sales Closed'
        : 'Ticket Sales Opening Soon';
    final endStr = DateFormat('dd MMM yyyy, HH:mm').format(event.salesEndTime);
    final startStr = DateFormat('dd MMM yyyy, HH:mm').format(event.salesStartTime);
    final subtitleText = isEnded
        ? 'Penjualan tiket untuk event ini telah resmi berakhir pada $endStr.'
        : 'Penjualan tiket untuk event ini baru akan dibuka pada $startStr.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bannerColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isEnded
                  ? Icons.remove_shopping_cart_outlined
                  : Icons.hourglass_top_outlined,
              color: iconColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.black87,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade400,
                        width: isSelected ? 6 : 2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              category.name,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.black,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: category.isSeated
                                    ? const Color(0xFFF6E8FF)
                                    : const Color(0xFFE6F9ED),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    category.isSeated
                                        ? Icons.event_seat
                                        : Icons.stadium,
                                    size: 11,
                                    color: category.isSeated
                                        ? AppColors.primaryDark
                                        : const Color(0xFF00A86B),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    category.isSeated ? 'Seated' : 'Standing',
                                    style: TextStyle(
                                      color: category.isSeated
                                          ? AppColors.primaryDark
                                          : const Color(0xFF00A86B),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${category.totalQuota} Quota Available',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.black45,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Rp ${NumberFormat('#,###', 'id_ID').format(category.price)}',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
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
      {
        'name': 'VIP Front Row',
        'price': 1500000,
        'quota': 100,
        'isSeated': true,
      },
      {
        'name': 'Regular Admission',
        'price': 750000,
        'quota': 300,
        'isSeated': false,
      },
    ];

    return Column(
      children: List.generate(fallbackList.length, (index) {
        final item = fallbackList[index];
        final isSelected = index == _selectedCategoryIndex;
        final isSeated = item['isSeated'] as bool;

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
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade400,
                        width: isSelected ? 6 : 2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              item['name'] as String,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.black,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSeated
                                    ? const Color(0xFFF6E8FF)
                                    : const Color(0xFFE6F9ED),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isSeated ? 'Seated' : 'Standing',
                                style: TextStyle(
                                  color: isSeated
                                      ? AppColors.primaryDark
                                      : const Color(0xFF00A86B),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item['quota']} Quota Left',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.black45,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Rp ${NumberFormat('#,###', 'id_ID').format(item['price'] as int)}',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
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
    String title,
  ) {
    final selectedCategory = categories != null && categories.isNotEmpty
        ? categories[_selectedCategoryIndex % categories.length]
        : null;

    final categoryName = selectedCategory?.name ?? 'VIP Front Row';
    final categoryPrice = selectedCategory?.price.toDouble() ?? 1500000.0;
    final categoryId = selectedCategory?.id ?? 'cat_vip';
    final isCategorySeated =
        selectedCategory?.isSeated ?? (_selectedCategoryIndex == 0);

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

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
                    formatter.format(categoryPrice),
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
          Consumer(
            builder: (context, ref, child) {
              final now = DateTime.now();
              final isUpcoming = widget.event != null &&
                  now.isBefore(widget.event!.salesStartTime);
              final isEnded = widget.event != null &&
                  now.isAfter(widget.event!.salesEndTime);
              final isOnSale = !isUpcoming && !isEnded;

              final buttonText = isOnSale
                  ? (isCategorySeated ? 'Select Seat' : 'Checkout Now')
                  : (isEnded ? 'Sales Closed' : 'Sales Not Started');

              return ElevatedButton(
                onPressed: () {
                  if (!isOnSale) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEnded
                              ? 'Ticket sales for this event have closed.'
                              : 'Ticket sales for this event have not started yet.',
                        ),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                    return;
                  }

                  if (isCategorySeated) {
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
                          price: categoryPrice,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutPage(
                          eventId: widget.event?.id ?? widget.eventId,
                          categoryId: categoryId,
                          eventName: title,
                          eventCategory: categoryName,
                          price: categoryPrice,
                          eventDate: widget.event?.eventDate,
                          imageUrl: widget.event?.imageUrl,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOnSale
                      ? AppColors.primary
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  children: [
                    Icon(
                      isOnSale
                          ? (isCategorySeated
                              ? Icons.event_seat
                              : Icons.shopping_bag_outlined)
                          : Icons.block,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      buttonText,
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
