import 'package:flutter_test/flutter_test.dart';
import 'package:team_five_fe/features/auth/data/models/login_request.dart';
import 'package:team_five_fe/features/auth/data/models/register_request.dart';

void main() {
  group('Auth Requests Unit Tests', () {
    test(
      'Happy Path: LoginRequest.toJson produces correct backend payload',
      () {
        final request = LoginRequest(
          email: 'john@example.com',
          password: 'Password123!',
        );

        final json = request.toJson();

        expect(
          json,
          equals({'email': 'john@example.com', 'password': 'Password123!'}),
        );
      },
    );

    test('Happy Path: RegisterRequest.toJson for CUSTOMER role', () {
      final request = RegisterRequest(
        username: 'john_doe',
        email: 'john@example.com',
        password: 'Password123!',
        role: 'CUSTOMER',
      );

      final json = request.toJson();

      expect(json['username'], equals('john_doe'));
      expect(json['email'], equals('john@example.com'));
      expect(json['password'], equals('Password123!'));
      expect(json['role'], equals('CUSTOMER'));
      expect(json.containsKey('eventId'), isFalse);
    });

    test(
      'Happy Path: RegisterRequest.toJson for GATE_OPERATOR role with eventId',
      () {
        final request = RegisterRequest(
          username: 'gate_operator_north',
          email: 'gateop@example.com',
          password: 'Password123!',
          role: 'GATE_OPERATOR',
          eventId: '019146a0-7d1e-7abc-9a12-abcdef123456',
        );

        final json = request.toJson();

        expect(json['role'], equals('GATE_OPERATOR'));
        expect(json['eventId'], equals('019146a0-7d1e-7abc-9a12-abcdef123456'));
      },
    );

    test(
      'Unhappy Path: RegisterRequest.toJson omits empty or null eventId',
      () {
        final request = RegisterRequest(
          username: 'john_doe',
          email: 'john@example.com',
          password: 'Password123!',
          eventId: '',
        );

        final json = request.toJson();

        expect(json.containsKey('eventId'), isFalse);
      },
    );
  });
}
