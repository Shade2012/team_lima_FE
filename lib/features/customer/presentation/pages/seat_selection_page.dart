import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:team_five_fe/core/theme/app_colors.dart';
import 'package:team_five_fe/core/theme/app_text_styles.dart';
import 'package:team_five_fe/features/seat/data/models/seat_model.dart';
import 'package:team_five_fe/features/seat/presentation/providers/seat_provider.dart';
import 'package:team_five_fe/features/ticket_category/data/models/ticket_category_model.dart';
import 'package:team_five_fe/features/ticket_category/presentation/providers/ticket_category_provider.dart';
import 'checkout_page.dart';

class SeatSelectionPage extends ConsumerStatefulWidget {
  final String? eventId;
  final String eventName;
  final String categoryName;
  final String categoryId;
  final double price;

  const SeatSelectionPage({
    super.key,
    this.eventId,
    this.eventName = 'Sonic Resonance Festival 2024',
    this.categoryName = 'VIP PASS',
    this.categoryId = 'cat_vip',
    this.price = 150.0,
  });

  @override
  ConsumerState<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends ConsumerState<SeatSelectionPage> {
  bool _seatsLoaded = false;
  String? _selectedCategoryName;
  String? _selectedCategoryId;
  String? _selectedSeatCode;
  String? _selectedSeatDisplayNum;
  double? _selectedPrice;

  static const _categoryColors = [
    Color(0xFF6C63FF),
    Color(0xFFFF6B9D),
    Color(0xFF00D68F),
    Color(0xFFFFB800),
    Color(0xFF00B4D8),
    Color(0xFFFF6347),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final targetEventId = widget.eventId ?? '019146a0-event';
        ref.read(categoriesProvider.notifier).setEventId(targetEventId);
      }
    });
  }

  void _loadAllSeatsIfReady() {
    if (_seatsLoaded) return;
    final cats = ref.read(categoriesProvider).categories;
    if (cats.isEmpty) return;
    _seatsLoaded = true;
    for (final cat in cats) {
      ref.read(seatsListProvider.notifier).loadSeats(cat.id);
    }
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

  String _cleanSeatNumber(String seatCode, int index) {
    final parts = seatCode.split('-');
    if (parts.length > 1) {
      return parts.last;
    }
    return (index + 1).toString().padLeft(3, '0');
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final seatsListState = ref.watch(seatsListProvider);

    _loadAllSeatsIfReady();

    final categories = categoriesState.categories.isNotEmpty
        ? categoriesState.categories
        : _buildFallbackCategories();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: categoriesState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _buildSeatArea(categories, seatsListState),
            ),
            _buildLegendBar(),
            _buildBottomActionBar(context),
          ],
        ),
      ),
    );
  }

  List<TicketCategory> _buildFallbackCategories() {
    return [
      TicketCategory(
        id: 'cat_vip1',
        eventId: widget.eventId ?? '019146a0-event',
        name: 'VIP-1',
        price: 200000,
        totalQuota: 30,
      ),
      TicketCategory(
        id: 'cat_vip2',
        eventId: widget.eventId ?? '019146a0-event',
        name: 'VIP-2',
        price: 180000,
        totalQuota: 40,
      ),
    ];
  }

  // ==================== App Bar ====================

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.greyLight, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.black,
                size: 18,
              ),
            ),
          ),
          Column(
            children: [
              Text(
                'Select Seat',
                style: AppTextStyles.title.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              Text(
                widget.eventName,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  // ==================== Seat Area ====================

  Widget _buildSeatArea(
    List<TicketCategory> categories,
    SeatsListState seatsListState,
  ) {
    // Reverse categories so Index 0 (closest to stage) is rendered at bottom near STAGE banner
    final reversed = categories.reversed.toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.greyLight),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < reversed.length; i++) ...[
                  _buildCategorySection(
                    category: reversed[i],
                    seats:
                        seatsListState.seatsByCategory[reversed[i].id] ??
                        _generateFallbackSeats(reversed[i]),
                    color: _getCategoryColor(categories.length - 1 - i),
                  ),
                  if (i < reversed.length - 1)
                    Container(height: 1, color: AppColors.greyLight),
                ],
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildStageVisual(),
        ],
      ),
    );
  }

  List<Seat> _generateFallbackSeats(TicketCategory category) {
    final count = category.totalQuota > 0 ? category.totalQuota : 30;
    final prefix = category.name.replaceAll(' ', '');
    return List.generate(count, (index) {
      final numStr = (index + 1).toString().padLeft(3, '0');
      return Seat(
        id: '${category.id}_$index',
        categoryId: category.id,
        seatCode: '$prefix-$numStr',
      );
    });
  }

  // ==================== Stage Visual ====================

  Widget _buildStageVisual() {
    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.greyLight, AppColors.background],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: const Center(
        child: Text(
          'S  T  A  G  E',
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }

  // ==================== Category Section ====================

  Widget _buildCategorySection({
    required TicketCategory category,
    required List<Seat> seats,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: color.withValues(alpha: 0.05),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${_formatPrice(category.price)}  •  ${seats.length} seats',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (seats.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'No seats available',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: _buildInteractiveSeatsWrap(seats, category, color),
          ),
      ],
    );
  }

  // ==================== Interactive Seats Wrap ====================

  Widget _buildInteractiveSeatsWrap(
    List<Seat> seats,
    TicketCategory category,
    Color color,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 8,
      children: List.generate(seats.length, (index) {
        final seat = seats[index];
        final numStr = _cleanSeatNumber(seat.seatCode, index);

        // Status Determination (Available, Held, Sold)
        final isHeld = (index == 2 || index == 11);
        final isSold = (index == 5 || index == 18);
        final isAvailable = !isHeld && !isSold;

        final isSelected =
            _selectedSeatCode == seat.seatCode ||
            (_selectedCategoryName == category.name &&
                _selectedSeatDisplayNum == numStr);

        return GestureDetector(
          onTap: !isAvailable
              ? null
              : () {
                  setState(() {
                    if (isSelected) {
                      _selectedSeatCode = null;
                      _selectedCategoryName = null;
                      _selectedCategoryId = null;
                      _selectedSeatDisplayNum = null;
                      _selectedPrice = null;
                    } else {
                      _selectedSeatCode = seat.seatCode;
                      _selectedCategoryName = category.name;
                      _selectedCategoryId = category.id;
                      _selectedSeatDisplayNum = numStr;
                      _selectedPrice = category.price.toDouble();
                    }
                  });
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 30,
            decoration: BoxDecoration(
              color: isSelected
                  ? color
                  : isHeld
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : isSold
                  ? AppColors.danger.withValues(alpha: 0.15)
                  : color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? color
                    : isHeld
                    ? AppColors.warning
                    : isSold
                    ? AppColors.danger
                    : color.withValues(alpha: 0.4),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                numStr,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.white
                      : isHeld
                      ? AppColors.warning
                      : isSold
                      ? AppColors.danger
                      : color,
                  height: 1,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ==================== Legend Bar ====================

  Widget _buildLegendBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.greyLight, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(
              color: AppColors.success,
              label: 'Available',
              filled: true,
            ),
            const SizedBox(width: 20),
            _buildLegendItem(
              color: AppColors.warning,
              label: 'Held',
              filled: true,
            ),
            const SizedBox(width: 20),
            _buildLegendItem(
              color: AppColors.danger,
              label: 'Sold',
              filled: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required bool filled,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: filled ? color.withValues(alpha: 0.6) : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.grey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ==================== Bottom Action Bar ====================

  Widget _buildBottomActionBar(BuildContext context) {
    final hasSelection =
        _selectedSeatCode != null || _selectedSeatDisplayNum != null;
    final priceToDisplay = _selectedPrice ?? widget.price;

    final formattedPrice = priceToDisplay > 10000
        ? _formatPrice(priceToDisplay.toInt())
        : '\$${priceToDisplay.toInt()}';

    final categoryLabel = _selectedCategoryName ?? widget.categoryName;
    final seatNumLabel = _selectedSeatDisplayNum ?? '001';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
                  hasSelection
                      ? '$categoryLabel ($seatNumLabel)'
                      : 'No seat selected',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    hasSelection ? formattedPrice : 'Select a seat',
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
            onPressed: !hasSelection
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutPage(
                          eventId: widget.eventId,
                          categoryId: _selectedCategoryId ?? widget.categoryId,
                          seatCode: _selectedSeatCode,
                          eventName: widget.eventName,
                          eventCategory: '$categoryLabel ($seatNumLabel)',
                          price: priceToDisplay,
                          location: 'Main Stage Pavilion',
                        ),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Confirm & Checkout',
              style: AppTextStyles.button.copyWith(
                color: AppColors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
