import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/login_request.dart';
import '../../data/models/login_response.dart';
import '../../data/models/register_request.dart';
import '../../data/models/register_response.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthState {
  final String username;
  final String email;
  final String password;
  final String confirmPassword;
  final bool isLoading;
  final String? error;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final LoginResponse? loginResponse;
  final RegisterResponse? registerResponse;

  AuthState({
    this.username = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.isLoading = false,
    this.error,
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
    this.loginResponse,
    this.registerResponse,
  });

  AuthState copyWith({
    String? username,
    String? email,
    String? password,
    String? confirmPassword,
    bool? isLoading,
    String? error,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
    LoginResponse? loginResponse,
    RegisterResponse? registerResponse,
  }) {
    return AuthState(
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible:
          isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      loginResponse: loginResponse ?? this.loginResponse,
      registerResponse: registerResponse ?? this.registerResponse,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState();
  }

  void setUsername(String username) {
    state = state.copyWith(username: username);
  }

  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password);
  }

  void setConfirmPassword(String confirmPassword) {
    state = state.copyWith(confirmPassword: confirmPassword);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(
      isConfirmPasswordVisible: !state.isConfirmPasswordVisible,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = AuthState();
  }

  Future<bool> login() async {
    if (state.email.isEmpty || state.password.isEmpty) {
      state = state.copyWith(error: 'Email and password are required');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final request = LoginRequest(
        email: state.email,
        password: state.password,
      );
      final response = await authRepository.login(request);
      state = state.copyWith(isLoading: false, loginResponse: response);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register() async {
    if (state.username.isEmpty ||
        state.email.isEmpty ||
        state.password.isEmpty ||
        state.confirmPassword.isEmpty) {
      state = state.copyWith(error: 'All fields are required');
      return false;
    }

    if (state.password != state.confirmPassword) {
      state = state.copyWith(error: 'Passwords do not match');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final request = RegisterRequest(
        username: state.username,
        email: state.email,
        password: state.password,
        confirmPassword: state.confirmPassword,
      );
      final response = await authRepository.register(request);
      state = state.copyWith(isLoading: false, registerResponse: response);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
