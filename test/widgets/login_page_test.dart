import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_five_fe/features/auth/presentation/pages/login_page.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const ProviderScope(child: MaterialApp(home: LoginPage()));
  }

  group('LoginPage Widget Tests', () {
    testWidgets(
      'Happy Path: Should render all essential UI components on LoginPage',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('VELOCE'), findsOneWidget);
        expect(find.text('Sign in to feel the pulse.'), findsOneWidget);
        expect(
          find.byType(TextField),
          findsNWidgets(2),
        ); // Email & Password fields
        expect(find.text('Sign In'), findsOneWidget);
        expect(find.text("Don't have an account? "), findsOneWidget);
        expect(find.text('Sign Up'), findsOneWidget);
      },
    );

    testWidgets(
      'Happy Path: Should allow typing email and password into text fields',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final emailField = find.byType(TextField).at(0);
        final passwordField = find.byType(TextField).at(1);

        await tester.enterText(emailField, 'john@example.com');
        await tester.enterText(passwordField, 'Password123!');
        await tester.pump();

        expect(find.text('john@example.com'), findsOneWidget);
        expect(find.text('Password123!'), findsOneWidget);
      },
    );

    testWidgets(
      'Unhappy Path: Tap Sign In with empty fields displays validation errors',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
        await tester.tap(signInButton);
        await tester.pumpAndSettle();

        // Form validators show error text below each field
        expect(find.text('Email is required'), findsOneWidget);
        expect(find.text('Password is required'), findsOneWidget);
        // No SnackBar should appear since validation blocks login
        expect(find.byType(SnackBar), findsNothing);
      },
    );
  });
}
