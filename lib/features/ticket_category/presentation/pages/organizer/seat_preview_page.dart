import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/features/ticket_category/presentation/providers/ticket_category_provider.dart';
import 'package:veloce/features/seat/presentation/providers/seat_provider.dart';

class SeatPreviewPage extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;
  final DateTime? eventDate;
  final String? categoryId;

  const SeatPreviewPage({
    super.key,
    required this.eventId,
    required this.eventName,
    this.eventDate,
    this.categoryId,
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

    dynamic targetCategory;
    if (widget.categoryId != null && categoriesState.categories.isNotEmpty) {
      try {
        targetCategory = categoriesState.categories.firstWhere(
          (c) => c.id == widget.categoryId,
        );
      } catch (_) {
        targetCategory = null;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildAppBar(targetCategory?.name),
          Expanded(
            child: categoriesState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : categoriesState.categories.isEmpty
                ? _buildEmptyState()
                : widget.categoryId != null
                ? (targetCategory == null
                      ? _buildEmptyState()
                      : _buildSingleCategorySeatArea(
                          targetCategory,
                          seatsListState.seatsByCategory[targetCategory.id] ??
                              [],
                          _getCategoryColor(0),
                        ))
                : _buildSeatArea(categoriesState.categories, seatsListState),
          ),
          _buildLegendBar(),
        ],
      ),
    );
  }

  // ==================== App Bar ====================

  Widget _buildAppBar(String? categoryName) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        4,
        MediaQuery.of(context).padding.top + 4,
        16,
        12,
      ),
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
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  categoryName != null
                      ? 'Seat Preview: $categoryName'
                      : 'Seat Preview',
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
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: _countdown.inSeconds > 0
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.6),
                  ),
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

  // ==================== Single Category Seat Area ====================

  Widget _buildSingleCategorySeatArea(
    dynamic category,
    List<dynamic> seats,
    Color color,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.greyLight),
            ),
            child: _buildCategorySection(
              category: category,
              seats: seats,
              color: color,
            ),
          ),
          const SizedBox(height: 30),
          _buildStageVisual(),
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
    required dynamic category,
    required List<dynamic> seats,
    required Color color,
  }) {
    final rows = category.rows as int?;
    final columns = category.columns as int?;
    final totalQuota = category.totalQuota as int;
    final blockedSeats = category.blockedSeats as List<dynamic>? ?? [];
    final hasGrid = rows != null && columns != null && rows > 0 && columns > 0;

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
                '${_formatPrice(category.price)}  •  ${seats.length}/$totalQuota seats${blockedSeats.isNotEmpty ? ' (${blockedSeats.length} blocked)' : ''}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (!hasGrid)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'No grid layout configured',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
          )
        else if (seats.isEmpty && blockedSeats.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'No seats generated',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: _buildGridSeats(
              seats: seats,
              rows: rows,
              columns: columns,
              totalQuota: totalQuota,
              color: color,
              blockedSeats: blockedSeats,
            ),
          ),
      ],
    );
  }

  // ==================== Grid Seats ====================

  Widget _buildGridSeats({
    required List<dynamic> seats,
    required int rows,
    required int columns,
    required int totalQuota,
    required Color color,
    required List<dynamic> blockedSeats,
  }) {
    final seatSize = 28.0;
    final spacing = 4.0;
    final totalWidth = columns * (seatSize + spacing);
    final totalHeight = rows * (seatSize + spacing);

    return SizedBox(
      height: totalHeight,
      width: totalWidth,
      child: CustomPaint(
        size: Size(totalWidth, totalHeight),
        painter: _GridSeatsPainter(
          rows: rows,
          columns: columns,
          seatSize: seatSize,
          spacing: spacing,
          color: color,
          blockedSeats: blockedSeats,
          seats: seats,
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
              color: AppColors.success,
              label: 'Available',
              filled: true,
            ),
            const SizedBox(width: 20),
            _buildLegendItem(
              color: AppColors.grey,
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

  // ==================== Empty State ====================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_seat,
              size: 48,
              color: AppColors.grey.withValues(alpha: 0.4),
            ),
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

// ==================== Grid Seats Painter ====================

class _GridSeatsPainter extends CustomPainter {
  final int rows;
  final int columns;
  final double seatSize;
  final double spacing;
  final Color color;
  final List<dynamic> blockedSeats;
  final List<dynamic> seats;

  _GridSeatsPainter({
    required this.rows,
    required this.columns,
    required this.seatSize,
    required this.spacing,
    required this.color,
    required this.blockedSeats,
    required this.seats,
  });

  String _getSeatLabel(int row, int col) {
    final rowLetter = String.fromCharCode(65 + row);
    return '$rowLetter-${col + 1}';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final availablePaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final availableBorderPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final blockedPaint = Paint()
      ..color = const Color(0xFFBDBDBD).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final blockedBorderPaint = Paint()
      ..color = const Color(0xFFBDBDBD).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    int seatIndex = 0;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final x = col * (seatSize + spacing);
        final y = row * (seatSize + spacing);

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, seatSize, seatSize),
          const Radius.circular(5),
        );

        final seatLabel = _getSeatLabel(row, col);
        final isBlocked = blockedSeats.contains(seatLabel);

        if (isBlocked) {
          canvas.drawRRect(rect, blockedPaint);
          canvas.drawRRect(rect, blockedBorderPaint);
        } else {
          canvas.drawRRect(rect, availablePaint);
          canvas.drawRRect(rect, availableBorderPaint);

          if (seatIndex < seats.length) {
            final seatCode = seats[seatIndex].seatCode as String;
            final prefixParts = seatCode.split('-');
            final number = prefixParts.length >= 3
                ? '${prefixParts[prefixParts.length - 2]}-${prefixParts.last}'
                : prefixParts.last;

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
              Offset(
                x + (seatSize - textPainter.width) / 2,
                y + (seatSize - textPainter.height) / 2,
              ),
            );
            seatIndex++;
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridSeatsPainter oldDelegate) {
    return oldDelegate.seats != seats ||
        oldDelegate.color != color ||
        oldDelegate.blockedSeats != blockedSeats;
  }
}
