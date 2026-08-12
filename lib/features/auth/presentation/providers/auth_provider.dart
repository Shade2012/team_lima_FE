import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/login_request.dart';
import '../../data/models/login_response.dart';
import '../../data/models/register_request.dart';
import '../../data/models/register_response.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthState {
  final String username;
  final String email;
  final String password;
  final String confirmPassword;
  final String role;
  final String? eventId;
  final bool isLoading;
  final String? error;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final LoginResponse? loginResponse;
  final RegisterResponse? registerResponse;
  final UserModel? currentUser;
  final bool isAuthenticated;

  AuthState({
    this.username = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.role = 'CUSTOMER',
    this.eventId,
    this.isLoading = false,
    this.error,
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
    this.loginResponse,
    this.registerResponse,
    this.currentUser,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    String? username,
    String? email,
    String? password,
    String? confirmPassword,
    String? role,
    String? eventId,
    bool? isLoading,
    String? error,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
    LoginResponse? loginResponse,
    RegisterResponse? registerResponse,
    UserModel? currentUser,
    bool? isAuthenticated,
  }) {
    return AuthState(
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      role: role ?? this.role,
      eventId: eventId ?? this.eventId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible:
          isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      loginResponse: loginResponse ?? this.loginResponse,
      registerResponse: registerResponse ?? this.registerResponse,
      currentUser: currentUser ?? this.currentUser,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Check initial stored token asynchronously
    Future.microtask(() => checkAuthStatus());
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

  void setRole(String role) {
    state = state.copyWith(role: role);
  }

  void setEventId(String? eventId) {
    state = state.copyWith(eventId: eventId);
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
    final currentToken = state.isAuthenticated;
    final currentUser = state.currentUser;
    state = AuthState(isAuthenticated: currentToken, currentUser: currentUser);
  }

  /// Auto-login check on app initialization
  Future<void> checkAuthStatus() async {
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final token = await authRepository.initToken();
      if (token != null && token.isNotEmpty) {
        final profile = await authRepository.getProfile();
        state = state.copyWith(isAuthenticated: true, currentUser: profile);
      }
    } catch (_) {
      // Token expired or invalid, reset
      state = state.copyWith(isAuthenticated: false, currentUser: null);
    }
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

      // Fetch user profile after successful login
      UserModel? profile;
      try {
        profile = await authRepository.getProfile();
      } catch (_) {}

      state = state.copyWith(
        isLoading: false,
        loginResponse: response,
        currentUser: profile,
        isAuthenticated: true,
      );
      return true;
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: cleanMessage);
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
        role: state.role,
        eventId: state.eventId,
      );
      final response = await authRepository.register(request);
      state = state.copyWith(isLoading: false, registerResponse: response);
      return true;
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: cleanMessage);
      return false;
    }
  }

  Future<bool> logout() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.logout();
      state = AuthState();
      return true;
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      state = AuthState(error: cleanMessage);
      return false;
    }
  }

  Future<bool> updateProfile({String? username, String? email}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final updatedUser = await authRepository.updateProfile(
        username: username,
        email: email,
      );
      state = state.copyWith(isLoading: false, currentUser: updatedUser);
      return true;
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: cleanMessage);
      return false;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
