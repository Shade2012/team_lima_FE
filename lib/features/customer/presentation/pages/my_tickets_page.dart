import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/customer_provider.dart';
import 'ticket_detail_page.dart';

class MyTicketsPage extends ConsumerWidget {
  const MyTicketsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsState = ref.watch(customerTicketsProvider);
    final tickets = ticketsState.tickets;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(context),
            // Tickets List
            Expanded(
              child: tickets.isEmpty
                  ? Center(
                      child: Text(
                        'No tickets purchased yet.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: tickets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        final dateFormat = DateFormat('MMM dd, yyyy');
                        final formattedDate = dateFormat.format(
                          ticket.eventDate,
                        );

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TicketDetailPage(ticket: ticket),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFEFEFEF),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF8A00CC),
                                        Color(0xFFAF06FF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.confirmation_number_outlined,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            ticket.status,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color:
                                                      ticket.status ==
                                                          'REFUNDED'
                                                      ? AppColors.danger
                                                      : AppColors.primary,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 11,
                                                ),
                                          ),
                                          Text(
                                            ticket.ticketCode,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color: Colors.black54,
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ticket.eventName,
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: AppColors.black,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$formattedDate • ${ticket.categoryName}',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              color: Colors.black54,
                                              fontSize: 12,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.black38,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEFEFEF))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 24),
          Text(
            'My Tickets',
            style: AppTextStyles.title.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}
