import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/custom_text_field.dart';
import 'package:veloce/features/auth/presentation/providers/auth_provider.dart';
import 'package:veloce/features/auth/presentation/pages/signup_page.dart';
import 'package:veloce/features/admin/presentation/pages/admin_main_screen.dart';
import 'package:veloce/features/customer/presentation/pages/customer_main_screen.dart';
import 'package:veloce/features/event/presentation/pages/organizer/organizer_main_screen.dart';
import 'package:veloce/features/gate/presentation/pages/gate_operator/gate_operator_dashboard_page.dart';

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
                      if (authState.error != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.danger,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authState.error!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildForgotPassword(),
                      const SizedBox(height: 24),
                      _buildSignInButton(authState, authNotifier),
                      const SizedBox(height: 24),
                      _buildSignUpLink(),
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
      onChanged: (value) {
        notifier.setEmail(value);
        if (state.error != null) notifier.clearError();
      },
      validator: (value) {
        if (value == null || value.isEmpty) return 'Email is required';
        if (!value.contains('@') || !value.contains('.')) {
          return 'Invalid email format';
        }
        return null;
      },
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
      onChanged: (value) {
        notifier.setPassword(value);
        if (state.error != null) notifier.clearError();
      },
      validator: (value) {
        if (value == null || value.isEmpty) return 'Password is required';
        if (value.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
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
    switch (role) {
      case 'ORGANIZER':
      case 'EVENT_ORGANIZER':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrganizerMainScreen()),
        );
        break;
      case 'ADMIN':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminMainScreen()),
        );
        break;
      case 'GATE_OPERATOR':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GateOperatorDashboardPage()),
        );
        break;
      default:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
        );
        break;
    }
  }
}
