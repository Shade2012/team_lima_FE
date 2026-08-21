import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/features/auth/presentation/pages/auth_wrapper.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _splashAnimController;
  late Animation<double> _splashFadeIn;
  late Animation<double> _splashFadeOut;

  static const _pages = [
    _OnboardingData(
      gif: 'assets/images/onboarding1.gif',
      title: 'Book Tickets',
      description:
          'Quick and easy ticket booking\nwith interactive seat selection.',
    ),
    _OnboardingData(
      gif: 'assets/images/onboarding2.gif',
      title: 'Manage Events',
      description:
          'Create, organize, and manage your events\nwith powerful built-in tools.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _splashAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _splashFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _splashAnimController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _splashFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _splashAnimController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );
    _splashAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
    _splashAnimController.forward();
  }

  @override
  void dispose() {
    _splashAnimController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _onGetStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: _currentPage > 0 && _currentPage <= _pages.length
                    ? TextButton(
                        onPressed: _onGetStarted,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.poppins(
                            color: AppColors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : const SizedBox(height: 48),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length + 1,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildSplashPage();
                    return _buildOnboardingPage(_pages[index - 1]);
                  },
                ),
              ),
              if (_currentPage > 0) ...[
                _buildIndicator(),
                const SizedBox(height: 24),
                _buildBottomButton(),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==================== Splash Page ====================

  Widget _buildSplashPage() {
    return AnimatedBuilder(
      animation: _splashAnimController,
      builder: (context, child) {
        final opacity = _splashFadeIn.value - _splashFadeOut.value;
        return Center(
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Text(
              'VELOCE',
              style: GoogleFonts.poppins(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
                letterSpacing: 6,
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== Onboarding Pages ====================

  Widget _buildOnboardingPage(_OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              data.gif,
              width: 260,
              height: 260,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.white.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Indicator ====================

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index + 1 ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index + 1
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  // ==================== Bottom Button ====================

  Widget _buildBottomButton() {
    final isLast = _currentPage == _pages.length;
    return GestureDetector(
      onTap: isLast ? _onGetStarted : _onNext,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isLast ? 200 : 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLast
              ? Text(
                  'Get Started',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String gif;
  final String title;
  final String description;

  const _OnboardingData({
    required this.gif,
    required this.title,
    required this.description,
  });
}
