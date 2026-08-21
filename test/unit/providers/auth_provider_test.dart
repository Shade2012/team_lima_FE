import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/features/auth/presentation/providers/auth_provider.dart';

void main() {
  group('AuthNotifier Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'Happy Path: AuthNotifier should initialize with default AuthState',
      () {
        final state = container.read(authProvider);

        expect(state.username, isEmpty);
        expect(state.email, isEmpty);
        expect(state.password, isEmpty);
        expect(state.confirmPassword, isEmpty);
        expect(state.role, equals('CUSTOMER'));
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
        expect(state.isPasswordVisible, isFalse);
        expect(state.isAuthenticated, isFalse);
      },
    );

    test(
      'Happy Path: AuthNotifier state update methods (setEmail, setPassword, setRole)',
      () {
        final notifier = container.read(authProvider.notifier);

        notifier.setEmail('john@example.com');
        notifier.setPassword('Password123!');
        notifier.setRole('ORGANIZER');

        final state = container.read(authProvider);

        expect(state.email, equals('john@example.com'));
        expect(state.password, equals('Password123!'));
        expect(state.role, equals('ORGANIZER'));
      },
    );

    test('Happy Path: togglePasswordVisibility toggles state boolean', () {
      final notifier = container.read(authProvider.notifier);

      expect(container.read(authProvider).isPasswordVisible, isFalse);

      notifier.togglePasswordVisibility();
      expect(container.read(authProvider).isPasswordVisible, isTrue);

      notifier.togglePasswordVisibility();
      expect(container.read(authProvider).isPasswordVisible, isFalse);
    });

    test(
      'Unhappy Path: login fails validation when email or password is empty',
      () async {
        final notifier = container.read(authProvider.notifier);

        final success = await notifier.login();

        expect(success, isFalse);
        final state = container.read(authProvider);
        expect(state.error, equals('Email and password are required'));
      },
    );

    test(
      'Unhappy Path: register fails validation when passwords do not match',
      () async {
        final notifier = container.read(authProvider.notifier);

        notifier.setUsername('john_doe');
        notifier.setEmail('john@example.com');
        notifier.setPassword('Password123!');
        notifier.setConfirmPassword('WrongPassword!');

        final success = await notifier.register();

        expect(success, isFalse);
        final state = container.read(authProvider);
        expect(state.error, equals('Passwords do not match'));
      },
    );
  });
}
