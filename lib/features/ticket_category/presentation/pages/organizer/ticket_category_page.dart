import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/custom_text_field.dart';
import 'package:veloce/features/ticket_category/data/models/ticket_category_model.dart';
import 'package:veloce/features/ticket_category/data/models/create_ticket_category_request.dart';
import 'package:veloce/features/ticket_category/data/models/update_ticket_category_request.dart';
import 'package:veloce/features/ticket_category/presentation/providers/ticket_category_provider.dart';
import 'package:veloce/features/ticket_category/presentation/pages/organizer/seat_preview_page.dart';
import 'package:veloce/features/ticket_category/presentation/pages/organizer/blocked_seat_picker_page.dart';
import 'package:veloce/features/seat/presentation/providers/seat_provider.dart';

class TicketCategoryPage extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;
  final DateTime? eventDate;

  const TicketCategoryPage({
    super.key,
    required this.eventId,
    required this.eventName,
    this.eventDate,
  });

  @override
  ConsumerState<TicketCategoryPage> createState() => _TicketCategoryPageState();
}

class _TicketCategoryPageState extends ConsumerState<TicketCategoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(categoriesProvider.notifier).setEventId(widget.eventId);
      }
    });
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final seatsCountState = ref.watch(seatsCountProvider);

    //print('=== TicketCategoryPage build ===');
    //print('isLoading: ${categoriesState.isLoading}');
    //print('categories count: ${categoriesState.categories.length}');
    //print('error: ${categoriesState.error}');
    //print('seatsCount: ${seatsCountState.counts}');

    // Load seats count when categories are loaded
    if (!categoriesState.isLoading && categoriesState.categories.isNotEmpty) {
      for (final cat in categoriesState.categories) {
        final catId = cat.id.toString();
        if (!seatsCountState.counts.containsKey(catId)) {
          debugPrint('Loading seats count for: $catId');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(seatsCountProvider.notifier).loadSeatsCount(catId);
            }
          });
        }
      }
    }

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
              'Ticket Categories',
              style: AppTextStyles.title.copyWith(
                color: AppColors.white,
                fontSize: 18,
              ),
            ),
            Text(
              widget.eventName,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: categoriesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : categoriesState.categories.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: categoriesState.categories.length,
                    itemBuilder: (context, index) {
                      try {
                        final category = categoriesState.categories[index];
                        final categoryId = category.id.toString();
                        final seatsCount = seatsCountState.counts[categoryId];
                        debugPrint(
                          'Building card for: ${category.name} (id: $categoryId)',
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildCategoryCard(category, seatsCount),
                        );
                      } catch (e, stack) {
                        debugPrint('Error building card at index $index: $e');
                        debugPrint('Stack: $stack');
                        return const SizedBox();
                      }
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
        icon: const Icon(Icons.add, size: 22),
        label: Text(
          'Add Category',
          style: AppTextStyles.button.copyWith(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.confirmation_number_outlined,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Categories Yet',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first ticket category to start selling tickets for this event.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddCategoryDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: Text('Add Category', style: AppTextStyles.button),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(TicketCategory category, int? seatsCount) {
    try {
      return GestureDetector(
        onTap: category.isSeated
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeatPreviewPage(
                      eventId: widget.eventId,
                      eventName: widget.eventName,
                      eventDate: widget.eventDate,
                      categoryId: category.id.toString(),
                    ),
                  ),
                );
              }
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top section with gradient accent
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.06),
                      AppColors.pink.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.confirmation_number,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category.name,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (category.isSeated)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Preview Seats',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.chevron_right,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatPrice(category.price),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _showEditCategoryDialog(category),
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.primary.withValues(alpha: 0.7),
                          ),
                          tooltip: 'Edit category',
                        ),
                        IconButton(
                          onPressed: () => _showDeleteConfirmation(category),
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.danger.withValues(alpha: 0.7),
                          ),
                          tooltip: 'Delete category',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Stats row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatChip(
                        icon: Icons.people_outline,
                        label: 'Quota',
                        value: '${category.totalQuota}',
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      if (category.isSeated) ...[
                        if (category.rows != null &&
                            category.columns != null) ...[
                          _buildStatChip(
                            icon: Icons.grid_view,
                            label: 'Grid',
                            value: '${category.rows} × ${category.columns}',
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                        ],
                        _buildStatChip(
                          icon: Icons.event_seat,
                          label: 'Seats',
                          value: seatsCount != null ? '$seatsCount' : '-',
                          color: seatsCount != null
                              ? AppColors.success
                              : AppColors.grey,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint('Error in _buildCategoryCard: $e');
      debugPrint('Stack: $stack');
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $e', style: TextStyle(color: Colors.red)),
      );
    }
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.grey,
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quotaController = TextEditingController();
    final rowsController = TextEditingController();
    final columnsController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    List<String> blockedSeats = [];
    bool isSeated = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Container(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.greyLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.add_circle_outline,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Add Category',
                          style: AppTextStyles.title.copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      controller: nameController,
                      hintText: 'Category Name (e.g. VIP Front Row)',
                      prefixIcon: Icons.label_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Category name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      controller: priceController,
                      hintText: 'Price (Rp)',
                      prefixIcon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Price is required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Must be a number';
                        }
                        if (int.parse(value) < 0) {
                          return 'Price cannot be negative';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSeated
                            ? AppColors.primary.withValues(alpha: 0.06)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSeated
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : AppColors.greyLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSeated
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : AppColors.grey.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isSeated ? Icons.event_seat : Icons.stadium,
                              size: 18,
                              color: isSeated
                                  ? AppColors.primary
                                  : AppColors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Seated Category',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isSeated
                                      ? 'Seats will be generated'
                                      : 'Standing / general admission',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isSeated,
                            onChanged: (value) =>
                                setStateModal(() => isSeated = value),
                            activeThumbColor: AppColors.white,
                            activeTrackColor: AppColors.primary,
                            inactiveThumbColor: AppColors.white,
                            inactiveTrackColor: AppColors.greyLight,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (isSeated) ...[
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: rowsController,
                              hintText: 'Rows (e.g. 10)',
                              prefixIcon: Icons.view_headline_outlined,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setStateModal(() {}),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Rows required';
                                }
                                if (int.tryParse(value) == null ||
                                    int.parse(value) <= 0) {
                                  return 'Invalid rows';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              controller: columnsController,
                              hintText: 'Columns (e.g. 10)',
                              prefixIcon: Icons.view_column_outlined,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setStateModal(() {}),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Columns required';
                                }
                                if (int.tryParse(value) == null ||
                                    int.parse(value) <= 0) {
                                  return 'Invalid columns';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: quotaController,
                        hintText: 'Total Quota (Capacity)',
                        prefixIcon: Icons.inventory_2_outlined,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Quota is required';
                          }
                          final q = int.tryParse(value);
                          if (q == null || q <= 0) return 'Must be at least 1';
                          final r = int.tryParse(rowsController.text) ?? 0;
                          final c = int.tryParse(columnsController.text) ?? 0;
                          if (r > 0 && c > 0 && q > (r * c)) {
                            return 'Quota cannot exceed total seats (${r * c})';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final r = int.tryParse(rowsController.text) ?? 0;
                          final c = int.tryParse(columnsController.text) ?? 0;
                          final q = int.tryParse(quotaController.text) ?? 0;
                          final totalSeats = r * c;
                          if (totalSeats > 0 && q > 0 && q < totalSeats) {
                            final blockedCount = totalSeats - q;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                'Note: $blockedCount remaining seats (top-left) will be marked as blocked seats.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          final r = int.tryParse(rowsController.text) ?? 0;
                          final c = int.tryParse(columnsController.text) ?? 0;
                          if (r <= 0 || c <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter valid rows and columns first',
                                ),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                            return;
                          }
                          final result = await Navigator.push<List<String>>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlockedSeatPickerPage(
                                rows: r,
                                columns: c,
                                totalQuota:
                                    int.tryParse(quotaController.text.trim()) ??
                                    (r * c),
                                initialBlockedSeats: blockedSeats,
                                categoryName: nameController.text.isNotEmpty
                                    ? nameController.text
                                    : 'Category',
                              ),
                            ),
                          );
                          if (result != null) {
                            setStateModal(() {
                              blockedSeats = result;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: blockedSeats.isNotEmpty
                                ? AppColors.danger.withValues(alpha: 0.05)
                                : AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: blockedSeats.isNotEmpty
                                  ? AppColors.danger.withValues(alpha: 0.3)
                                  : AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                blockedSeats.isNotEmpty
                                    ? Icons.grid_off_outlined
                                    : Icons.grid_view_outlined,
                                size: 20,
                                color: blockedSeats.isNotEmpty
                                    ? AppColors.danger
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      blockedSeats.isNotEmpty
                                          ? '${blockedSeats.length} blocked seats selected'
                                          : 'Select Blocked Seats',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: blockedSeats.isNotEmpty
                                            ? AppColors.danger
                                            : AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      blockedSeats.isNotEmpty
                                          ? 'Tap to modify blocked seats'
                                          : 'Choose seats to block',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: blockedSeats.isNotEmpty
                                    ? AppColors.danger
                                    : AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      CustomTextField(
                        controller: quotaController,
                        hintText: 'Total Quota',
                        prefixIcon: Icons.inventory_2_outlined,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Quota is required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Must be a number';
                          }
                          if (int.parse(value) <= 0) {
                            return 'Quota must be at least 1';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: AppTextStyles.button.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;

                              int? rows;
                              int? columns;
                              int? totalQuota;

                              if (isSeated) {
                                rows = int.parse(rowsController.text.trim());
                                columns = int.parse(
                                  columnsController.text.trim(),
                                );
                                totalQuota = int.parse(
                                  quotaController.text.trim(),
                                );
                              } else {
                                totalQuota = int.parse(
                                  quotaController.text.trim(),
                                );
                              }

                              final request = CreateTicketCategoryRequest(
                                eventId: widget.eventId,
                                name: nameController.text.trim(),
                                price: int.parse(priceController.text.trim()),
                                totalQuota: totalQuota,
                                isSeated: isSeated,
                                rows: rows,
                                columns: columns,
                                blockedSeats: blockedSeats.isNotEmpty
                                    ? blockedSeats
                                    : null,
                              );
                              final success = await ref
                                  .read(categoriesProvider.notifier)
                                  .createCategory(request);
                              if (!context.mounted) return;
                              if (success) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Category added!',
                                      style: AppTextStyles.snackbar,
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text('Add', style: AppTextStyles.button),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(dynamic category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Delete Category',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Delete "${category.name}"? This action cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(categoriesProvider.notifier)
                  .deleteCategory(category.id.toString());
              if (!context.mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Category deleted',
                      style: AppTextStyles.snackbar,
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(TicketCategory category) {
    final nameController = TextEditingController(text: category.name);
    final priceController = TextEditingController(
      text: category.price.toString(),
    );
    final quotaController = TextEditingController(
      text: category.totalQuota.toString(),
    );
    final rowsController = TextEditingController(
      text: category.rows?.toString() ?? '',
    );
    final columnsController = TextEditingController(
      text: category.columns?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    List<String> blockedSeats = List.from(category.blockedSeats);
    bool isSeated = category.isSeated;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Container(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.greyLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Edit Category',
                          style: AppTextStyles.title.copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      controller: nameController,
                      hintText: 'Category Name',
                      prefixIcon: Icons.label_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Category name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      controller: priceController,
                      hintText: 'Price (Rp)',
                      prefixIcon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Price is required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Must be a number';
                        }
                        if (int.parse(value) < 0) {
                          return 'Price cannot be negative';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSeated
                            ? AppColors.primary.withValues(alpha: 0.06)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSeated
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : AppColors.greyLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSeated
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : AppColors.grey.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isSeated ? Icons.event_seat : Icons.stadium,
                              size: 18,
                              color: isSeated
                                  ? AppColors.primary
                                  : AppColors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Seated Category',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isSeated
                                      ? 'Seats will be generated'
                                      : 'Standing / general admission',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isSeated,
                            onChanged: (value) =>
                                setStateModal(() => isSeated = value),
                            activeThumbColor: AppColors.white,
                            activeTrackColor: AppColors.primary,
                            inactiveThumbColor: AppColors.white,
                            inactiveTrackColor: AppColors.greyLight,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (isSeated) ...[
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: rowsController,
                              hintText: 'Rows (e.g. 10)',
                              prefixIcon: Icons.view_headline_outlined,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setStateModal(() {}),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Rows required';
                                }
                                if (int.tryParse(value) == null ||
                                    int.parse(value) <= 0) {
                                  return 'Invalid rows';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              controller: columnsController,
                              hintText: 'Columns (e.g. 10)',
                              prefixIcon: Icons.view_column_outlined,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setStateModal(() {}),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Columns required';
                                }
                                if (int.tryParse(value) == null ||
                                    int.parse(value) <= 0) {
                                  return 'Invalid columns';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: quotaController,
                        hintText: 'Total Quota (Capacity)',
                        prefixIcon: Icons.inventory_2_outlined,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Quota is required';
                          }
                          final q = int.tryParse(value);
                          if (q == null || q <= 0) return 'Must be at least 1';
                          final r = int.tryParse(rowsController.text) ?? 0;
                          final c = int.tryParse(columnsController.text) ?? 0;
                          if (r > 0 && c > 0 && q > (r * c)) {
                            return 'Quota cannot exceed total seats (${r * c})';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final r = int.tryParse(rowsController.text) ?? 0;
                          final c = int.tryParse(columnsController.text) ?? 0;
                          final q = int.tryParse(quotaController.text) ?? 0;
                          final totalSeats = r * c;
                          if (totalSeats > 0 && q > 0 && q < totalSeats) {
                            final blockedCount = totalSeats - q;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                'Note: $blockedCount remaining seats (top-left) will be marked as blocked seats.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          final r = int.tryParse(rowsController.text) ?? 0;
                          final c = int.tryParse(columnsController.text) ?? 0;
                          if (r <= 0 || c <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter valid rows and columns first',
                                ),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                            return;
                          }
                          final result = await Navigator.push<List<String>>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlockedSeatPickerPage(
                                rows: r,
                                columns: c,
                                totalQuota:
                                    int.tryParse(quotaController.text.trim()) ??
                                    (r * c),
                                initialBlockedSeats: blockedSeats,
                                categoryName: nameController.text.isNotEmpty
                                    ? nameController.text
                                    : 'Category',
                              ),
                            ),
                          );
                          if (result != null) {
                            setStateModal(() {
                              blockedSeats = result;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: blockedSeats.isNotEmpty
                                ? AppColors.danger.withValues(alpha: 0.05)
                                : AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: blockedSeats.isNotEmpty
                                  ? AppColors.danger.withValues(alpha: 0.3)
                                  : AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                blockedSeats.isNotEmpty
                                    ? Icons.grid_off_outlined
                                    : Icons.grid_view_outlined,
                                size: 20,
                                color: blockedSeats.isNotEmpty
                                    ? AppColors.danger
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      blockedSeats.isNotEmpty
                                          ? '${blockedSeats.length} blocked seats selected'
                                          : 'Select Blocked Seats',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: blockedSeats.isNotEmpty
                                            ? AppColors.danger
                                            : AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      blockedSeats.isNotEmpty
                                          ? 'Tap to modify blocked seats'
                                          : 'Choose seats to block',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: blockedSeats.isNotEmpty
                                    ? AppColors.danger
                                    : AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      CustomTextField(
                        controller: quotaController,
                        hintText: 'Total Quota',
                        prefixIcon: Icons.inventory_2_outlined,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Quota is required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Must be a number';
                          }
                          if (int.parse(value) <= 0) {
                            return 'Quota must be at least 1';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: AppTextStyles.button.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;

                              int? rows;
                              int? columns;
                              int? totalQuota;

                              if (isSeated) {
                                final rText = rowsController.text.trim();
                                final cText = columnsController.text.trim();
                                if (rText.isNotEmpty && cText.isNotEmpty) {
                                  rows = int.parse(rText);
                                  columns = int.parse(cText);
                                }
                                totalQuota = int.parse(
                                  quotaController.text.trim(),
                                );
                              } else {
                                totalQuota = int.parse(
                                  quotaController.text.trim(),
                                );
                              }

                              final request = UpdateTicketCategoryRequest(
                                name: nameController.text.trim(),
                                price: int.parse(priceController.text.trim()),
                                totalQuota: totalQuota,
                                rows: rows,
                                columns: columns,
                                blockedSeats: blockedSeats.isNotEmpty
                                    ? blockedSeats
                                    : null,
                              );

                              final success = await ref
                                  .read(categoriesProvider.notifier)
                                  .updateCategory(category.id, request);

                              if (!context.mounted) return;
                              if (success) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Category updated!',
                                      style: AppTextStyles.snackbar,
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } else {
                                final error = ref
                                    .read(categoriesProvider)
                                    .error;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      error ?? 'Failed to update',
                                      style: AppTextStyles.snackbar,
                                    ),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text('Save', style: AppTextStyles.button),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
