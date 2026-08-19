import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_five_fe/features/customer/presentation/pages/customer_profile_page.dart';
import 'package:team_five_fe/features/auth/presentation/providers/auth_provider.dart';
import 'package:team_five_fe/features/auth/data/models/user_model.dart';
import 'package:team_five_fe/features/customer/presentation/providers/customer_provider.dart';

class MockAuthNotifier extends AuthNotifier {
  final UserModel? mockUser;
  MockAuthNotifier(this.mockUser);

  @override
  AuthState build() {
    return AuthState(currentUser: mockUser, isAuthenticated: mockUser != null);
  }

  @override
  Future<bool> updateProfile({String? username, String? email}) async {
    if (username == null ||
        email == null ||
        username.isEmpty ||
        email.isEmpty) {
      return false;
    }
    state = state.copyWith(
      currentUser: UserModel(
        id: mockUser?.id ?? 'usr-1',
        username: username,
        email: email,
        role: mockUser?.role ?? 'CUSTOMER',
      ),
    );
    return true;
  }

  @override
  Future<bool> logout() async {
    state = AuthState();
    return true;
  }
}

class MockCustomerTicketsNotifier extends CustomerTicketsNotifier {
  @override
  CustomerTicketsState build() {
    return CustomerTicketsState(tickets: [], isLoading: false);
  }

  @override
  Future<void> loadTickets({bool forceRefresh = false}) async {}
}

void main() {
  group('CustomerProfilePage Actions Widget Tests', () {
    testWidgets(
      'Happy Path: CustomerProfilePage renders profile header with initials avatar and options',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final user = UserModel(
          id: 'usr-customer-1',
          username: 'Alex Chen',
          email: 'alex.chen@example.com',
          role: 'CUSTOMER',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(() => MockAuthNotifier(user)),
              customerTicketsProvider.overrideWith(
                () => MockCustomerTicketsNotifier(),
              ),
            ],
            child: const MaterialApp(home: CustomerProfilePage()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('My Profile'), findsOneWidget);
        expect(find.text('AC'), findsOneWidget);
        expect(find.text('Alex Chen'), findsOneWidget);
        expect(find.text('CUSTOMER'), findsOneWidget);
        expect(find.text('Edit Profile'), findsOneWidget);
        expect(find.text('Logout'), findsOneWidget);
        expect(find.text('Delete Account'), findsOneWidget);
      },
    );

    testWidgets(
      'Happy Path: Tapping Edit Profile opens edit sheet and updates user info',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final user = UserModel(
          id: 'usr-customer-1',
          username: 'Alex Chen',
          email: 'alex.chen@example.com',
          role: 'CUSTOMER',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(() => MockAuthNotifier(user)),
              customerTicketsProvider.overrideWith(
                () => MockCustomerTicketsNotifier(),
              ),
            ],
            child: const MaterialApp(home: CustomerProfilePage()),
          ),
        );

        await tester.pumpAndSettle();

        // Tap Edit Profile item
        await tester.tap(find.text('Edit Profile'));
        await tester.pumpAndSettle();

        expect(find.text('Save Changes'), findsOneWidget);

        // Enter new username
        await tester.enterText(
          find.widgetWithText(TextField, 'Username'),
          'Alex Rivera',
        );
        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();

        expect(find.text('Alex Rivera'), findsOneWidget);
        expect(find.text('AR'), findsOneWidget);
      },
    );

    testWidgets('Unhappy Path: Tapping Logout shows confirmation dialog', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final user = UserModel(
        id: 'usr-customer-1',
        username: 'Alex Chen',
        email: 'alex.chen@example.com',
        role: 'CUSTOMER',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => MockAuthNotifier(user)),
            customerTicketsProvider.overrideWith(
              () => MockCustomerTicketsNotifier(),
            ),
          ],
          child: const MaterialApp(home: CustomerProfilePage()),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Logout option
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(
        find.text('Are you sure you want to logout from VELOCE?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
