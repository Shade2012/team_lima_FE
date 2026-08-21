import 'package:flutter/material.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

class BlockedSeatPickerPage extends StatefulWidget {
  final int rows;
  final int columns;
  final int totalQuota;
  final List<String> initialBlockedSeats;
  final String categoryName;

  const BlockedSeatPickerPage({
    super.key,
    required this.rows,
    required this.columns,
    required this.totalQuota,
    required this.initialBlockedSeats,
    required this.categoryName,
  });

  @override
  State<BlockedSeatPickerPage> createState() => _BlockedSeatPickerPageState();
}

class _BlockedSeatPickerPageState extends State<BlockedSeatPickerPage> {
  late Set<String> _blockedSeats;

  int get _totalCells => widget.rows * widget.columns;
  int get _maxBlocked => _totalCells - widget.totalQuota;

  @override
  void initState() {
    super.initState();
    _blockedSeats = Set<String>.from(widget.initialBlockedSeats);
  }

  String _getSeatLabel(int row, int col) {
    final rowLetter = String.fromCharCode(65 + row);
    return '$rowLetter-${col + 1}';
  }

  void _toggleSeat(int row, int col) {
    final label = _getSeatLabel(row, col);
    setState(() {
      if (_blockedSeats.contains(label)) {
        _blockedSeats.remove(label);
      } else {
        if (_blockedSeats.length < _maxBlocked) {
          _blockedSeats.add(label);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Blocked Seats',
              style: AppTextStyles.title.copyWith(
                color: AppColors.white,
                fontSize: 17,
              ),
            ),
            Text(
              widget.categoryName,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _blockedSeats.toList());
            },
            child: Text(
              'Done',
              style: AppTextStyles.button.copyWith(
                color: AppColors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInfoBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildLegend(),
                  const SizedBox(height: 16),
                  _buildSeatGrid(),
                  const SizedBox(height: 30),
                  _buildStageVisual(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    final totalSeats = widget.rows * widget.columns;
    final blockedCount = _blockedSeats.length;
    final availableCount = totalSeats - blockedCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.white,
      child: Column(
        children: [
          Row(
            children: [
              _buildStatChip('Total', '$totalSeats', AppColors.primary),
              const SizedBox(width: 8),
              _buildStatChip('Available', '$availableCount', AppColors.success),
              const SizedBox(width: 8),
              _buildStatChip(
                'Blocked',
                '$blockedCount/$_maxBlocked',
                AppColors.danger,
              ),
            ],
          ),
          if (_maxBlocked > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Max $_maxBlocked blocked seats allowed (Total cells - Quota)',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(AppColors.primary, 'Available'),
        const SizedBox(width: 20),
        _buildLegendItem(AppColors.danger, 'Blocked'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

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

  Widget _buildSeatGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: List.generate(widget.rows, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List.generate(widget.columns, (col) {
                  final label = _getSeatLabel(row, col);
                  final isBlocked = _blockedSeats.contains(label);

                  return Padding(
                    padding: const EdgeInsets.all(2),
                    child: GestureDetector(
                      onTap: () => _toggleSeat(row, col),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isBlocked
                              ? AppColors.danger.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isBlocked
                                ? AppColors.danger
                                : AppColors.primary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isBlocked
                                  ? AppColors.danger
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}
