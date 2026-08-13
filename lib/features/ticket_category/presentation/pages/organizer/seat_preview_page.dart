import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:team_five_fe/core/theme/app_colors.dart';
import 'package:team_five_fe/core/theme/app_text_styles.dart';
import 'package:team_five_fe/features/ticket_category/presentation/providers/ticket_category_provider.dart';
import 'package:team_five_fe/features/seat/presentation/providers/seat_provider.dart';

class SeatPreviewPage extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;
  final DateTime? eventDate;

  const SeatPreviewPage({
    super.key,
    required this.eventId,
    required this.eventName,
    this.eventDate,
  });

  @override
  ConsumerState<SeatPreviewPage> createState() => _SeatPreviewPageState();
}

class _SeatPreviewPageState extends ConsumerState<SeatPreviewPage> {
  Timer? _countdownTimer;
  Duration _countdown = Duration.zero;
  bool _seatsLoaded = false;

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
        ref.read(categoriesProvider.notifier).setEventId(widget.eventId);
      }
    });
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    if (widget.eventDate == null) return;
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (widget.eventDate == null) return;
    final now = DateTime.now();
    final diff = widget.eventDate!.difference(now);
    if (diff.isNegative) {
      _countdownTimer?.cancel();
      setState(() => _countdown = Duration.zero);
    } else {
      setState(() => _countdown = diff);
    }
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

  String _countdownText() {
    if (widget.eventDate == null) return '';
    final d = _countdown;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final seatsListState = ref.watch(seatsListProvider);

    _loadAllSeatsIfReady();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: categoriesState.isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : categoriesState.categories.isEmpty
                    ? _buildEmptyState()
                    : _buildSeatArea(
                        categoriesState.categories, seatsListState),
          ),
          _buildLegendBar(),
        ],
      ),
    );
  }

  // ==================== App Bar ====================

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          4, MediaQuery.of(context).padding.top + 4, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back,
                  color: AppColors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Seat Preview',
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.white,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.eventName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.eventDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined,
                      size: 14,
                      color: _countdown.inSeconds > 0
                          ? AppColors.white
                          : AppColors.white.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(
                    _countdown.inSeconds > 0 ? _countdownText() : 'ENDED',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [ui.FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ==================== Seat Area ====================

  Widget _buildSeatArea(List categories, SeatsListState seatsListState) {
    final reversed = categories.reversed.toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          for (var i = 0; i < reversed.length; i++)
            _buildCategorySection(
              category: reversed[i],
              seats: seatsListState.seatsByCategory[reversed[i].id] ?? [],
              color: _getCategoryColor(categories.length - 1 - i),
              isVip: i == reversed.length - 1,
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
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(40),
        ),
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
    required dynamic category,
    required List<dynamic> seats,
    required Color color,
    required bool isVip,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
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
                'No seats generated',
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
              ),
            )
          else if (isVip)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _buildArcSeats(seats, color),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _buildStraightSeats(seats, color),
            ),
        ],
      ),
    );
  }

  // ==================== Arc Seats (VIP) ====================

  Widget _buildArcSeats(List<dynamic> seats, Color color) {
    final seatsPerRow = seats.length <= 10
        ? seats.length
        : seats.length <= 20
            ? 10
            : 15;
    final totalRows = (seats.length / seatsPerRow).ceil();
    final seatSize = 28.0;
    final rowSpacing = 32.0;
    final spacing = seatSize + 4;
    final totalWidth = seatsPerRow * spacing;

    return SizedBox(
      height: 10 + totalRows * rowSpacing + 20,
      width: totalWidth,
      child: CustomPaint(
        size: Size(totalWidth, 10 + totalRows * rowSpacing + 20),
        painter: _SeatsPainter(
          seats: seats,
          seatsPerRow: seatsPerRow,
          totalRows: totalRows,
          seatSize: seatSize,
          rowSpacing: rowSpacing,
          spacing: spacing,
          color: color,
          isArc: true,
        ),
      ),
    );
  }

  // ==================== Straight Seats ====================

  Widget _buildStraightSeats(List<dynamic> seats, Color color) {
    final seatsPerRow = seats.length <= 10
        ? seats.length
        : seats.length <= 20
            ? 10
            : 15;
    final totalRows = (seats.length / seatsPerRow).ceil();
    final seatSize = 28.0;
    final rowSpacing = 32.0;
    final spacing = seatSize + 4;
    final totalWidth = seatsPerRow * spacing;

    return SizedBox(
      height: 10 + totalRows * rowSpacing + 20,
      width: totalWidth,
      child: CustomPaint(
        size: Size(totalWidth, 10 + totalRows * rowSpacing + 20),
        painter: _SeatsPainter(
          seats: seats,
          seatsPerRow: seatsPerRow,
          totalRows: totalRows,
          seatSize: seatSize,
          rowSpacing: rowSpacing,
          spacing: spacing,
          color: color,
          isArc: false,
        ),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(
                color: AppColors.success, label: 'Available', filled: true),
            const SizedBox(width: 20),
            _buildLegendItem(
                color: AppColors.warning, label: 'Held', filled: true),
            const SizedBox(width: 20),
            _buildLegendItem(
                color: AppColors.danger, label: 'Sold', filled: true),
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

  // ==================== Empty State ====================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_seat,
                size: 48, color: AppColors.grey.withValues(alpha: 0.4)),
            const SizedBox(height: 24),
            Text(
              'No Seats Available',
              style: AppTextStyles.title.copyWith(
                fontSize: 18,
                color: AppColors.black.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add ticket categories with seats to see the preview.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Seats Painter ====================

class _SeatsPainter extends CustomPainter {
  final List<dynamic> seats;
  final int seatsPerRow;
  final int totalRows;
  final double seatSize;
  final double rowSpacing;
  final double spacing;
  final Color color;
  final bool isArc;

  _SeatsPainter({
    required this.seats,
    required this.seatsPerRow,
    required this.totalRows,
    required this.seatSize,
    required this.rowSpacing,
    required this.spacing,
    required this.color,
    required this.isArc,
  });

  double _arcY(int index, int total, double arcStrength) {
    if (total <= 1) return 0;
    final center = (total - 1) / 2.0;
    final normalized = (index - center) / center;
    return arcStrength * (1 - normalized * normalized);
  }

  String _seatNumber(String seatCode) {
    final parts = seatCode.split('-');
    return parts.last;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final seatPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    for (var rowIdx = 0; rowIdx < totalRows; rowIdx++) {
      final startIdx = rowIdx * seatsPerRow;
      final endIdx = min(startIdx + seatsPerRow, seats.length);
      final rowSeats = seats.sublist(startIdx, endIdx);
      final rowCount = rowSeats.length;
      final y = 10.0 + rowIdx * rowSpacing;
      final centerX = (seatsPerRow - 1) * spacing / 2 + seatSize / 2;
      final arcStrength = 8.0 + rowIdx * 3.0;

      for (var i = 0; i < rowCount; i++) {
        final x =
            centerX + (i - (rowCount - 1) / 2) * spacing;
        final seatY = isArc
            ? y + _arcY(i, rowCount, arcStrength)
            : y;

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, seatY, seatSize, seatSize),
          const Radius.circular(6),
        );

        canvas.drawRRect(rect, seatPaint);
        canvas.drawRRect(rect, borderPaint);

        final number = _seatNumber(rowSeats[i].seatCode);
        textPainter.text = TextSpan(
          text: number,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x + (seatSize - textPainter.width) / 2,
              seatY + (seatSize - textPainter.height) / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SeatsPainter oldDelegate) {
    return oldDelegate.seats != seats || oldDelegate.color != color;
  }
}
