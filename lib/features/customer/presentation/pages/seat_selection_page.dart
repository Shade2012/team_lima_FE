import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../seat/data/models/seat_model.dart';
import '../../../seat/data/repositories/seat_repository.dart';
import 'checkout_page.dart';

final customerSeatRepositoryProvider = Provider<SeatRepository>((ref) {
  return SeatRepository();
});

final customerSeatsByCategoryProvider =
    FutureProvider.family<List<Seat>, String>((ref, categoryId) async {
  final repo = ref.watch(customerSeatRepositoryProvider);
  try {
    return await repo.getSeatsByCategory(categoryId);
  } catch (_) {
    // Generate fallback interactive seats if mock server returns empty
    return List.generate(20, (index) {
      final code = 'VIP-${(index + 1).toString().padLeft(3, '0')}';
      return Seat(
        id: 'seat_$index',
        categoryId: categoryId,
        seatCode: code,
      );
    });
  }
});

class SeatSelectionPage extends ConsumerStatefulWidget {
  final String eventName;
  final String categoryName;
  final String categoryId;
  final double price;

  const SeatSelectionPage({
    super.key,
    this.eventName = 'Sonic Resonance Festival 2024',
    this.categoryName = 'VIP PASS',
    this.categoryId = 'cat_vip',
    this.price = 150.0,
  });

  @override
  ConsumerState<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends ConsumerState<SeatSelectionPage> {
  String? _selectedSeatCode;

  @override
  Widget build(BuildContext context) {
    final seatsAsync = ref.watch(customerSeatsByCategoryProvider(widget.categoryId));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(context),
            // Stage Indicator
            _buildStageBanner(),
            const SizedBox(height: 16),

            // Seat Status Legend Row
            _buildLegendRow(),
            const SizedBox(height: 20),

            // Scrollable Seat Grid Container
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    seatsAsync.when(
                      data: (seats) => _buildSeatGrid(seats),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      error: (_, __) => _buildFallbackSeatGrid(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            _buildBottomBar(context),
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
            'Select Seat',
            style: AppTextStyles.title.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildStageBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8A00CC), Color(0xFFAF06FF)],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'STAGE / MAIN PAVILION',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          color: Colors.white,
          borderColor: const Color(0xFFD1D1D6),
          label: 'Available',
        ),
        const SizedBox(width: 20),
        _buildLegendItem(
          color: AppColors.primary,
          borderColor: AppColors.primary,
          label: 'Selected',
          textColor: Colors.white,
        ),
        const SizedBox(width: 20),
        _buildLegendItem(
          color: const Color(0xFFE5E5EA),
          borderColor: const Color(0xFFE5E5EA),
          label: 'Booked',
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required Color borderColor,
    required String label,
    Color? textColor,
  }) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSeatGrid(List<Seat> seats) {
    final effectiveSeats = seats.isNotEmpty
        ? seats
        : List.generate(
            20,
            (index) => Seat(
              id: 's_$index',
              categoryId: widget.categoryId,
              seatCode: 'VIP-${(index + 1).toString().padLeft(3, '0')}',
            ),
          );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: effectiveSeats.length,
      itemBuilder: (context, index) {
        final seat = effectiveSeats[index];
        final isSelected = seat.seatCode == _selectedSeatCode;
        final isBooked = index == 2 || index == 7; // Sample booked seats

        return GestureDetector(
          onTap: isBooked
              ? null
              : () {
                  setState(() {
                    if (isSelected) {
                      _selectedSeatCode = null;
                    } else {
                      _selectedSeatCode = seat.seatCode;
                    }
                  });
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isBooked
                  ? const Color(0xFFE5E5EA)
                  : (isSelected ? AppColors.primary : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isBooked
                    ? const Color(0xFFD1D1D6)
                    : (isSelected ? AppColors.primary : const Color(0xFFD1D1D6)),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: isBooked
                  ? const Icon(Icons.lock_outline, size: 16, color: Colors.black38)
                  : Text(
                      seat.seatCode,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? Colors.white : AppColors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackSeatGrid() {
    final fallbackSeats = List.generate(
      20,
      (i) => 'VIP-${(i + 1).toString().padLeft(3, '0')}',
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: fallbackSeats.length,
      itemBuilder: (context, index) {
        final seatCode = fallbackSeats[index];
        final isSelected = seatCode == _selectedSeatCode;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSeatCode = isSelected ? null : seatCode;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : const Color(0xFFD1D1D6),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                seatCode,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final hasSelection = _selectedSeatCode != null;

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
                  hasSelection
                      ? 'Seat: $_selectedSeatCode'
                      : 'No seat selected',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '\$${widget.price.toInt()}',
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
                          eventName: widget.eventName,
                          eventCategory:
                              '${widget.categoryName} ($_selectedSeatCode)',
                          price: widget.price,
                          location: 'Main Stage Pavilion',
                        ),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Confirm & Checkout',
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
