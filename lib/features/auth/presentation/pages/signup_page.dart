import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_five_fe/core/theme/app_colors.dart';
import 'package:team_five_fe/core/theme/app_text_styles.dart';
import 'package:team_five_fe/core/widgets/custom_text_field.dart';
import 'package:team_five_fe/features/auth/presentation/providers/auth_provider.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 50,
            left: 16,
            child: IconButton(
              onPressed: () {
                authNotifier.reset();
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.arrow_back,
                color: isDarkMode ? AppColors.white : AppColors.black,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLogo(isDarkMode),
                    const SizedBox(height: 24),
                    _buildTitle(isDarkMode),
                    const SizedBox(height: 8),
                    _buildSubtitle(isDarkMode),
                    const SizedBox(height: 32),
                    _buildFullNameField(authState, authNotifier),
                    const SizedBox(height: 16),
                    _buildEmailField(authState, authNotifier),
                    const SizedBox(height: 16),
                    _buildPasswordField(authState, authNotifier),
                    const SizedBox(height: 16),
                    _buildConfirmPasswordField(authState, authNotifier),
                    const SizedBox(height: 24),
                    _buildCreateAccountButton(authState, authNotifier),
                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 24),
                    _buildGoogleButton(isDarkMode),
                    const SizedBox(height: 24),
                    _buildLoginLink(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(bool isDarkMode) {
    return Row(
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 3),
            Container(
              width: 6,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 3),
            Container(
              width: 6,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 3),
            Container(
              width: 6,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Text(
          'DEEP SOUND',
          style: AppTextStyles.logo.copyWith(
            color: isDarkMode ? AppColors.white : AppColors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(bool isDarkMode) {
    return Text(
      'Join the Sound',
      style: AppTextStyles.title.copyWith(
        color: isDarkMode ? AppColors.white : AppColors.black,
      ),
    );
  }

  Widget _buildSubtitle(bool isDarkMode) {
    return Text(
      'Create an account to start discovering events.',
      style: AppTextStyles.subtitle.copyWith(color: AppColors.grey),
    );
  }

  Widget _buildFullNameField(AuthState state, AuthNotifier notifier) {
    return CustomTextField(
      controller: _fullNameController,
      hintText: 'Full Name',
      prefixIcon: Icons.person_outline,
      onChanged: (value) => notifier.setFullName(value),
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

  Widget _buildConfirmPasswordField(AuthState state, AuthNotifier notifier) {
    return CustomTextField(
      controller: _confirmPasswordController,
      hintText: 'Confirm Password',
      prefixIcon: Icons.lock_outline,
      obscureText: !state.isConfirmPasswordVisible,
      suffixIcon: IconButton(
        icon: Icon(
          state.isConfirmPasswordVisible
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: AppColors.grey,
        ),
        onPressed: () => notifier.toggleConfirmPasswordVisibility(),
      ),
      onChanged: (value) => notifier.setConfirmPassword(value),
    );
  }

  Widget _buildCreateAccountButton(AuthState state, AuthNotifier notifier) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: state.isLoading ? null : () => _handleRegister(notifier),
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
            : Text('Create Account', style: AppTextStyles.button),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.greyLight)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.greyLight)),
      ],
    );
  }

  Widget _buildGoogleButton(bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.greyLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.g_mobiledata, size: 28, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Sign Up with Google',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? AppColors.white : AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: AppTextStyles.link.copyWith(color: AppColors.grey),
        ),
        GestureDetector(
          onTap: () {
            ref.read(authProvider.notifier).reset();
            Navigator.pop(context);
          },
          child: Text(
            'Log in',
            style: AppTextStyles.link.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegister(AuthNotifier notifier) async {
    if (_formKey.currentState!.validate()) {
      final success = await notifier.register();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Registration successful!',
              style: AppTextStyles.snackbar,
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
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
}
