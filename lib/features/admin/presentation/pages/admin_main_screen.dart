import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'admin_refund_management_page.dart';
import 'package:team_five_fe/features/customer/presentation/pages/customer_explore_page.dart';
import 'package:team_five_fe/features/customer/presentation/pages/customer_profile_page.dart';

class AdminMainScreen extends StatefulWidget {
  final int initialIndex;

  const AdminMainScreen({super.key, this.initialIndex = 0});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    CustomerExplorePage(),
    AdminRefundManagementPage(),
    CustomerProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.event_outlined,
                  Icons.event,
                  'Events',
                ),
                _buildNavItem(
                  1,
                  Icons.receipt_long_outlined,
                  Icons.receipt_long,
                  'Refunds',
                ),
                _buildNavItem(
                  2,
                  Icons.person_outline,
                  Icons.person,
                  'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData unselectedIcon,
    IconData selectedIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(isSelected ? 8 : 4),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? Colors.white : Colors.black45,
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isSelected ? AppColors.primary : Colors.black45,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
