import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_five_fe/core/theme/app_colors.dart';
import 'package:team_five_fe/core/theme/app_text_styles.dart';
import 'package:team_five_fe/core/widgets/custom_text_field.dart';
import 'package:team_five_fe/features/auth/presentation/providers/auth_provider.dart';
import 'package:team_five_fe/features/auth/presentation/pages/signup_page.dart';
import 'package:team_five_fe/features/event/presentation/pages/organizer/my_events_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hasNavigated = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated && !_hasNavigated && mounted) {
        _hasNavigated = true;
        _navigateByRole(next.currentUser?.role);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: Opacity(
              opacity: 0.3,
              child: Container(
                width: 280,
                height: 280,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.circleGradient1,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Opacity(
              opacity: 0.3,
              child: Container(
                width: 320,
                height: 320,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.circleGradient2,
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'VELOCE',
                        style: AppTextStyles.logo.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to feel the pulse.',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildEmailField(authState, authNotifier),
                      const SizedBox(height: 16),
                      _buildPasswordField(authState, authNotifier),
                      const SizedBox(height: 8),
                      _buildForgotPassword(),
                      const SizedBox(height: 24),
                      _buildSignInButton(authState, authNotifier),
                      const SizedBox(height: 24),
                      _buildSignUpLink(),
                      const SizedBox(height: 32),
                      _buildDebugResetButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(AuthState state, AuthNotifier notifier) {
    return CustomTextField(
      controller: _emailController,
      hintText: 'Email Address',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      onChanged: (value) => notifier.setEmail(value),
    );
  }

  Widget _buildPasswordField(AuthState state, AuthNotifier notifier) {
    return CustomTextField(
      controller: _passwordController,
      hintText: 'Password',
      prefixIcon: Icons.lock_outline,
      obscureText: !state.isPasswordVisible,
      suffixIcon: IconButton(
        icon: Icon(
          state.isPasswordVisible
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: AppColors.grey,
        ),
        onPressed: () => notifier.togglePasswordVisibility(),
      ),
      onChanged: (value) => notifier.setPassword(value),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        child: Text(
          'Forgot Password?',
          style: AppTextStyles.linkSmall.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildSignInButton(AuthState state, AuthNotifier notifier) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: state.isLoading ? null : () => _handleLogin(notifier),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: state.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : Text('Sign In', style: AppTextStyles.button),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: AppTextStyles.link.copyWith(color: AppColors.grey),
        ),
        GestureDetector(
          onTap: () {
            ref.read(authProvider.notifier).reset();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignupPage()),
            );
          },
          child: Text(
            'Sign Up',
            style: AppTextStyles.link.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin(AuthNotifier notifier) async {
    if (_formKey.currentState!.validate()) {
      _hasNavigated = false;
      final success = await notifier.login();
      if (!success && mounted) {
        final currentState = ref.read(authProvider);
        if (currentState.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(currentState.error!, style: AppTextStyles.snackbar),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateByRole(String? role) {
    if (!mounted) return;
    if (role == 'ORGANIZER' || role == 'EVENT_ORGANIZER') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyEventsPage()),
      );
    }
  }

  Widget _buildDebugResetButton() {
    return GestureDetector(
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('hasSeenOnboarding');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Text(
          'Debug: Reset Onboarding',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.warning,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
