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
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
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
                    const SizedBox(height: 60),
                    _buildLogo(isDarkMode),
                    const SizedBox(height: 24),
                    _buildTitle(isDarkMode),
                    const SizedBox(height: 8),
                    _buildSubtitle(isDarkMode),
                    const SizedBox(height: 24),
                    _buildRoleSelector(authState, authNotifier, isDarkMode),
                    const SizedBox(height: 20),
                    _buildUsernameField(authState, authNotifier),
                    const SizedBox(height: 16),
                    _buildEmailField(authState, authNotifier),
                    const SizedBox(height: 16),
                    _buildPasswordField(authState, authNotifier),
                    const SizedBox(height: 16),
                    _buildConfirmPasswordField(authState, authNotifier),
                    const SizedBox(height: 24),
                    _buildCreateAccountButton(authState, authNotifier),
                    const SizedBox(height: 24),
                    _buildLoginLink(),
                    const SizedBox(height: 40),
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

  Widget _buildRoleSelector(AuthState state, AuthNotifier notifier, bool isDarkMode) {
    final isCustomer = state.role == 'CUSTOMER';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Register As',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppColors.white : AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setRole('CUSTOMER'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCustomer ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Customer',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCustomer ? AppColors.white : AppColors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setRole('ORGANIZER'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: !isCustomer ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Event Organizer',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: !isCustomer ? AppColors.white : AppColors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField(AuthState state, AuthNotifier notifier) {
    return CustomTextField(
      controller: _usernameController,
      hintText: 'Username',
      prefixIcon: Icons.person_outline,
      onChanged: (value) => notifier.setUsername(value),
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
              'Registration successful! Please sign in.',
              style: AppTextStyles.snackbar,
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
