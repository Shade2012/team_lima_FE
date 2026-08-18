import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/customer_ticket_model.dart';
import '../providers/customer_provider.dart';

class TicketDetailPage extends ConsumerWidget {
  final CustomerTicket? ticket;

  const TicketDetailPage({super.key, this.ticket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsState = ref.watch(customerTicketsProvider);
    final currentTicket =
        ticket ??
        (ticketsState.tickets.isNotEmpty
            ? ticketsState.tickets.first
            : CustomerTicket(
                id: '019146a0-fallback',
                ticketCode: '#NJF-2491',
                eventName: 'Neon Jungle Festival',
                categoryName: 'VIP PASS',
                eventDate: DateTime(2024, 8, 24),
                eventTimeRange: '8:00 PM - 4:00 AM',
                venueName: 'The Grand Warehouse',
                venueAddress: '124 Industrial Ave, Metro City',
                attendeeName: 'Alex Chen',
                ticketType: 'All Access',
                qrData:
                    'DIGITAL TICKET | VELOCE\nNeon Jungle Festival\nNJF-2491',
                status: 'UPCOMING',
              ));

    final isRefunded = currentTicket.status == 'REFUNDED';
    final dateFormat = DateFormat('EEE, MMM dd, yyyy');
    final formattedDate = dateFormat.format(currentTicket.eventDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            _buildAppBar(context),
            // Body Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    // Main Ticket Pass Stub Card
                    _buildTicketStub(
                      context,
                      currentTicket,
                      formattedDate,
                      isRefunded,
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    _buildActionButtons(
                      context,
                      ref,
                      currentTicket,
                      isRefunded,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Header Bar ====================

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Circular Back Button
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
          Expanded(
            child: Text(
              'My Tickets',
              style: AppTextStyles.title.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ==================== Ticket Pass Stub Card ====================

  Widget _buildTicketStub(
    BuildContext context,
    CustomerTicket ticket,
    String formattedDate,
    bool isRefunded,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Ticket Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category Badge & Ticket Code
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7ECFF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.confirmation_number_outlined,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ticket.categoryName.toUpperCase(),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      ticket.ticketCode,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Huge Event Title
                Text(
                  ticket.eventName,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 20),

                // Date & Time Tile
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7ECFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_month_outlined,
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
                            formattedDate,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticket.eventTimeRange,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location Tile
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7ECFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
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
                            ticket.venueName,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticket.venueAddress,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.black54,
                              fontSize: 12,
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

          // Cutout Dashed Notch Line
          _buildDashedNotchDivider(),

          // Bottom Ticket Section (QR Code & Attendee)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Scan at entrance',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                // QR Code Container Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (isRefunded)
                        Container(
                          width: 180,
                          height: 180,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cancel,
                                  size: 40,
                                  color: AppColors.danger,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'TICKET REFUNDED',
                                  style: TextStyle(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        QrImageView(
                          data: ticket.qrData,
                          version: QrVersions.auto,
                          size: 180.0,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.black,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.black,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Attendee Info Box
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendee',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticket.attendeeName,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Ticket Type',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticket.ticketType,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Cutout Dashed Divider ====================

  Widget _buildDashedNotchDivider() {
    return SizedBox(
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dashed Line
          LayoutBuilder(
            builder: (context, constraints) {
              const dashWidth = 5.0;
              const dashSpace = 4.0;
              final count = (constraints.maxWidth / (dashWidth + dashSpace))
                  .floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(count, (_) {
                  return SizedBox(
                    width: dashWidth,
                    height: 1,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(color: Color(0xFFD1D1D6)),
                    ),
                  );
                }),
              );
            },
          ),
          // Left Notch
          Positioned(
            left: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFC),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Right Notch
          Positioned(
            right: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFC),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Action Buttons ====================

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    CustomerTicket ticket,
    bool isRefunded,
  ) {
    return Column(
      children: [
        // Save to Wallet Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isRefunded
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ticket saved to Apple / Google Wallet!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Save to Wallet',
                  style: AppTextStyles.button.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Request Refund Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isRefunded
                ? null
                : () => _showRefundDialog(context, ref, ticket),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFFE5E5EA), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              isRefunded ? 'Refunded' : 'Request Refund',
              style: AppTextStyles.button.copyWith(
                color: isRefunded ? Colors.black38 : AppColors.black,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showRefundDialog(
    BuildContext pageContext,
    WidgetRef ref,
    CustomerTicket ticket,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Request Refund',
          style: AppTextStyles.title.copyWith(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to request a refund for ${ticket.eventName}?',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Enter reason for refund (e.g. Schedule conflict)',
                hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              final finalReason = reason.isNotEmpty ? reason : 'Requested by customer';
              Navigator.pop(dialogContext);
              final success = await ref
                  .read(customerRefundsProvider.notifier)
                  .submitRefund(ticketId: ticket.id, reason: finalReason);

              if (pageContext.mounted) {
                if (success) {
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    const SnackBar(
                      content: Text('Refund request submitted successfully.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  final error = ref.read(customerRefundsProvider).error;
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(
                      content: Text(error ?? 'Failed to submit refund request.'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Confirm Refund',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
