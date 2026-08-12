import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_five_fe/features/auth/presentation/pages/signup_page.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const ProviderScope(child: MaterialApp(home: SignupPage()));
  }

  group('SignupPage Widget Tests', () {
    testWidgets(
      'Happy Path: Should render all essential UI components and role selector',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Join the Sound'), findsOneWidget);
        expect(find.text('Register As'), findsOneWidget);
        expect(find.text('Customer'), findsOneWidget);
        expect(find.text('Event Organizer'), findsOneWidget);
        expect(
          find.byType(TextField),
          findsNWidgets(4),
        ); // Username, Email, Password, ConfirmPassword
        expect(find.text('Create Account'), findsOneWidget);
      },
    );

    testWidgets(
      'Happy Path: Should toggle role between Customer and Event Organizer',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final eoTab = find.text('Event Organizer');
        await tester.tap(eoTab);
        await tester.pumpAndSettle();

        final customerTab = find.text('Customer');
        await tester.tap(customerTab);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Unhappy Path: Tap Create Account with empty fields triggers validation snackbar',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final createAccountButton = find.widgetWithText(
          ElevatedButton,
          'Create Account',
        );
        await tester.ensureVisible(createAccountButton);
        await tester.tap(createAccountButton);
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('All fields are required'), findsOneWidget);
      },
    );
  });
}
