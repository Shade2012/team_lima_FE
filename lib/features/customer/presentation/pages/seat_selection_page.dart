import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/features/seat/data/models/seat_model.dart';
import 'package:veloce/features/seat/presentation/providers/seat_provider.dart';
import 'package:veloce/features/ticket_category/data/models/ticket_category_model.dart';
import 'package:veloce/features/ticket_category/presentation/providers/ticket_category_provider.dart';
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

  String _getRowLabel(int rowIndex) {
    return String.fromCharCode(65 + rowIndex); // 0 -> 'A', 1 -> 'B', etc.
  }

  bool _isSeatBlocked(
    TicketCategory category,
    String rowLabel,
    int colIndex,
    int totalSeatIndex,
  ) {
    final blockList = category.blockedSeats
        .map((s) => s.toUpperCase())
        .toList();
    final coord1 = '$rowLabel-$colIndex'.toUpperCase();
    final coord2 = '$rowLabel$colIndex'.toUpperCase();
    final coord3 = '${category.name}-$rowLabel-$colIndex'.toUpperCase();
    final coord4 = '${category.name}-$rowLabel$colIndex'.toUpperCase();

    if (blockList.contains(coord1) ||
        blockList.contains(coord2) ||
        blockList.contains(coord3) ||
        blockList.contains(coord4)) {
      return true;
    }

    return false;
  }

  Seat? _findSeatByPosition(List<Seat> seats, String rowLabel, int colIndex) {
    for (final s in seats) {
      if (s.row?.toUpperCase() == rowLabel.toUpperCase() &&
          s.column == colIndex) {
        return s;
      }
      final searchPattern1 = '$rowLabel-$colIndex'.toUpperCase();
      final searchPattern2 = '$rowLabel$colIndex'.toUpperCase();
      if (s.seatCode.toUpperCase().contains(searchPattern1) ||
          s.seatCode.toUpperCase().contains(searchPattern2)) {
        return s;
      }
    }
    return null;
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
        price: 1500000,
        totalQuota: 30,
        isSeated: true,
        rows: 5,
        columns: 6,
        blockedSeats: ['A-5', 'A-6'],
      ),
      TicketCategory(
        id: 'cat_vip2',
        eventId: widget.eventId ?? '019146a0-event',
        name: 'VIP-2',
        price: 1000000,
        totalQuota: 40,
        isSeated: true,
        rows: 5,
        columns: 8,
        blockedSeats: ['B-1'],
      ),
      TicketCategory(
        id: 'cat_fest',
        eventId: widget.eventId ?? '019146a0-event',
        name: 'FESTIVAL ZONE',
        price: 750000,
        totalQuota: 200,
        isSeated: false,
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

    // Determine currently active category (matching _selectedCategoryId or widget.categoryId/categoryName)
    final activeCategoryId =
        _selectedCategoryId ??
        categories
            .firstWhere(
              (c) =>
                  c.id == widget.categoryId ||
                  c.name.toUpperCase() == widget.categoryName.toUpperCase(),
              orElse: () => categories.first,
            )
            .id;

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
                    seats: seatsListState.seatsByCategory[reversed[i].id] ?? [],
                    color: _getCategoryColor(categories.length - 1 - i),
                    isSelectedCategory: reversed[i].id == activeCategoryId,
                    onSelectCategory: () {
                      setState(() {
                        _selectedCategoryId = reversed[i].id;
                        _selectedCategoryName = reversed[i].name;
                        _selectedPrice = reversed[i].price.toDouble();
                        _selectedSeatCode = null;
                        _selectedSeatDisplayNum = null;
                      });
                    },
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
    required bool isSelectedCategory,
    required VoidCallback onSelectCategory,
  }) {
    final rowsCount = (category.rows != null && category.rows! > 0)
        ? category.rows!
        : (category.totalQuota > 0 ? (category.totalQuota / 10).ceil() : 3);
    final colsCount = (category.columns != null && category.columns! > 0)
        ? category.columns!
        : (category.totalQuota > 0
              ? (category.totalQuota / rowsCount).ceil()
              : 10);

    final totalGridSeats = rowsCount * colsCount;

    if (!category.isSeated) {
      // Non-seated Category static zone placeholder (e.g. Festival / Standing Area)
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F9ED),
          border: Border.all(
            color: const Color(0xFF00A86B).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A86B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.stadium,
                      size: 18,
                      color: Color(0xFF00A86B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Standing Zone • Free Standing',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.black54,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00A86B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatPrice(category.price),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF00A86B),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!isSelectedCategory) {
      // Inactive / Unselected Category placeholder card
      return InkWell(
        onTap: onSelectCategory,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          color: color.withValues(alpha: 0.04),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Seated Category • $totalGridSeats Seats',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.grey,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatPrice(category.price),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app, size: 12, color: color),
                        const SizedBox(width: 4),
                        Text(
                          'Switch',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Active selected category with full seat grid
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: color.withValues(alpha: 0.12),
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
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        category.name,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SELECTED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_formatPrice(category.price)} • $totalGridSeats seats (${category.blockedSeats.length} blocked)',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: _buildCategorySeatGrid(
            category: category,
            seats: seats,
            rowsCount: rowsCount,
            colsCount: colsCount,
            color: color,
          ),
        ),
      ],
    );
  }

  // ==================== Category Seat Grid ====================

  Widget _buildCategorySeatGrid({
    required TicketCategory category,
    required List<Seat> seats,
    required int rowsCount,
    required int colsCount,
    required Color color,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header coordinates (1, 2, 3, ...)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 26),
                for (var c = 0; c < colsCount; c++) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: SizedBox(
                      width: 36,
                      child: Text(
                        '${c + 1}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...List.generate(rowsCount, (r) {
            final rowLabel = _getRowLabel(r);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row label indicator on left
                  SizedBox(
                    width: 20,
                    child: Text(
                      rowLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Seats in this row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(colsCount, (c) {
                      final colIndex = c + 1;
                      final totalSeatIndex = r * colsCount + c;
                      final fullSeatCode =
                          '${category.name}-$rowLabel-$colIndex';
                      final shortSeatCode = '$rowLabel-$colIndex';

                      // 1. Check if Blocked
                      final isBlocked = _isSeatBlocked(
                        category,
                        rowLabel,
                        colIndex,
                        totalSeatIndex,
                      );

                      // 2. Check API status for Held or Booked
                      final apiSeat = _findSeatByPosition(
                        seats,
                        rowLabel,
                        colIndex,
                      );
                      final isHeld = !isBlocked && apiSeat?.status == 'HELD';
                      final isBooked =
                          !isBlocked && apiSeat?.status == 'BOOKED';

                      // 3. Selectable check
                      final isAvailable = !isBlocked && !isHeld && !isBooked;

                      final isSelected =
                          _selectedSeatCode == fullSeatCode ||
                          _selectedSeatCode == shortSeatCode ||
                          (_selectedCategoryName == category.name &&
                              _selectedSeatDisplayNum == shortSeatCode);

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
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
                                      _selectedSeatCode = fullSeatCode;
                                      _selectedCategoryName = category.name;
                                      _selectedCategoryId = category.id;
                                      _selectedSeatDisplayNum = shortSeatCode;
                                      _selectedPrice = category.price
                                          .toDouble();
                                    }
                                  });
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 36,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color
                                  : isBlocked
                                  ? const Color(0xFFE5E5EA)
                                  : isHeld
                                  ? AppColors.warning.withValues(alpha: 0.15)
                                  : isBooked
                                  ? AppColors.danger.withValues(alpha: 0.15)
                                  : color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? color
                                    : isBlocked
                                    ? const Color(0xFFD1D1D6)
                                    : isHeld
                                    ? AppColors.warning
                                    : isBooked
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
                              child: isBlocked
                                  ? const Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.black38,
                                    )
                                  : Text(
                                      '$colIndex',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? AppColors.white
                                            : isHeld
                                            ? AppColors.warning
                                            : isBooked
                                            ? AppColors.danger
                                            : color,
                                        height: 1,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
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
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem(
              color: AppColors.primary,
              label: 'Available',
              filled: true,
            ),
            _buildLegendItem(
              color: AppColors.warning,
              label: 'Held',
              filled: true,
            ),
            _buildLegendItem(
              color: AppColors.danger,
              label: 'Booked',
              filled: true,
            ),
            _buildLegendItem(
              color: const Color(0xFF9E9E9E),
              label: 'Blocked',
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
    final seatNumLabel = _selectedSeatDisplayNum ?? 'A-1';

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
