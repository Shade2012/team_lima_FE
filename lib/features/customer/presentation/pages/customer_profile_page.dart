import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/pages/auth_wrapper.dart';
import '../providers/customer_provider.dart';
import 'ticket_detail_page.dart';
import 'my_tickets_page.dart';

class CustomerProfilePage extends ConsumerWidget {
  const CustomerProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;
    final ticketsState = ref.watch(customerTicketsProvider);
    final latestTicket =
        ticketsState.tickets.isNotEmpty ? ticketsState.tickets.first : null;

    final userName = user?.username.isNotEmpty == true ? user!.username : 'Alex Chen';
    final userEmail =
        user?.email.isNotEmpty == true ? user!.email : 'alex.chen@example.com';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildAppBar(context, userName),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    // Profile Header Card
                    _buildProfileCard(context, ref, userName, userEmail),
                    const SizedBox(height: 16),
                    // My Tickets Card Section
                    _buildMyTicketsSection(context, latestTicket),
                    const SizedBox(height: 16),
                    // Settings Options Cards
                    _buildSettingsSection(context, ref),
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

  // ==================== Top App Bar ====================

  Widget _buildAppBar(BuildContext context, String userName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEFEFEF))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.equalizer,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ],
          ),
          Flexible(
            child: Text(
              'VELOCE',
              style: AppTextStyles.title.copyWith(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Profile Header Card ====================

  Widget _buildProfileCard(
    BuildContext context,
    WidgetRef ref,
    String name,
    String email,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar Container with Edit Pencil Badge Icon
          Stack(
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: const Color(0xFFF0F0F5),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: AppColors.primary.withValues(alpha: 0.8),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // User Name
          Text(
            name,
            style: AppTextStyles.title.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          // User Email
          Text(
            email,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          // Badges Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Customer Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 14, color: Colors.black87),
                    const SizedBox(width: 4),
                    Text(
                      'Customer',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Premium Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6E8FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Premium',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
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
    );
  }

  // ==================== "My Tickets" Section Card ====================

  Widget _buildMyTicketsSection(BuildContext context, dynamic latestTicket) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.confirmation_number_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'My Tickets',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyTicketsPage()),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All',
                  style: AppTextStyles.link.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Ticket Item Box
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketDetailPage(ticket: latestTicket),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEFEFEF)),
              ),
              child: Row(
                children: [
                  // Ticket Icon Box
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8A00CC), Color(0xFFAF06FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.headphones,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Ticket Text Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          latestTicket?.status ?? 'UPCOMING',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          latestTicket?.eventName ?? 'Neon Waves Festival',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${latestTicket?.eventTimeRange ?? 'Oct 24'} • ${latestTicket?.categoryName ?? 'VIP Pass'}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.black38,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Settings Options Cards ====================

  Widget _buildSettingsSection(BuildContext context, WidgetRef ref) {
    final settingsList = [
      {
        'icon': Icons.credit_card_outlined,
        'title': 'Payment Methods',
        'isDanger': false,
        'onTap': () => _showFeatureDialog(context, 'Payment Methods'),
      },
      {
        'icon': Icons.notifications_outlined,
        'title': 'Notification Settings',
        'isDanger': false,
        'onTap': () => _showFeatureDialog(context, 'Notification Settings'),
      },
      {
        'icon': Icons.help_outline,
        'title': 'Help & Support',
        'isDanger': false,
        'onTap': () => _showFeatureDialog(context, 'Help & Support'),
      },
      {
        'icon': Icons.lock_outline,
        'title': 'Privacy & Security',
        'isDanger': false,
        'onTap': () => _showFeatureDialog(context, 'Privacy & Security'),
      },
      {
        'icon': Icons.logout,
        'title': 'Logout',
        'isDanger': true,
        'onTap': () => _showLogoutDialog(context, ref),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(settingsList.length, (index) {
          final item = settingsList[index];
          final isLast = index == settingsList.length - 1;
          final isDanger = item['isDanger'] as bool;

          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDanger
                          ? AppColors.danger.withValues(alpha: 0.1)
                          : const Color(0xFFF2F2F7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: isDanger ? AppColors.danger : Colors.black87,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item['title'] as String,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDanger ? AppColors.danger : AppColors.black,
                    ),
                  ),
                  trailing: isDanger
                      ? null
                      : const Icon(
                          Icons.chevron_right,
                          color: Colors.black38,
                          size: 20,
                        ),
                  onTap: item['onTap'] as VoidCallback,
                ),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 60, color: Color(0xFFF0F0F5)),
            ],
          );
        }),
      ),
    );
  }

  void _showFeatureDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: AppTextStyles.title.copyWith(fontSize: 18)),
        content: Text(
          '$title feature is ready in VELOCE.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: AppTextStyles.title.copyWith(fontSize: 18)),
        content: Text(
          'Are you sure you want to logout from VELOCE?',
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
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthWrapper()),
                  (route) => false,
                );
              }
            },
            child: Text(
              'Logout',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
