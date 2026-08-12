import 'package:flutter_test/flutter_test.dart';
import 'package:team_five_fe/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel Unit Tests', () {
    test('Happy Path: Should correctly parse full JSON response from backend DTO', () {
      final jsonMap = {
        "id": "019146a0-7d1e-7abc-9a12-abcdef123456",
        "email": "john@example.com",
        "username": "john_doe",
        "role": "CUSTOMER",
        "eventId": "019146a0-7d1e-7abc-9a12-event0000001",
        "createdAt": "2026-08-12T10:00:00.000Z",
        "updatedAt": "2026-08-12T10:00:00.000Z",
      };

      final user = UserModel.fromJson(jsonMap);

      expect(user.id, equals("019146a0-7d1e-7abc-9a12-abcdef123456"));
      expect(user.email, equals("john@example.com"));
      expect(user.username, equals("john_doe"));
      expect(user.role, equals("CUSTOMER"));
      expect(user.eventId, equals("019146a0-7d1e-7abc-9a12-event0000001"));
      expect(user.createdAt, equals(DateTime.parse("2026-08-12T10:00:00.000Z")));
      expect(user.updatedAt, equals(DateTime.parse("2026-08-12T10:00:00.000Z")));
    });

    test('Unhappy Path: Should handle empty or missing JSON fields gracefully without crashing', () {
      final jsonMap = <String, dynamic>{};

      final user = UserModel.fromJson(jsonMap);

      expect(user.id, equals(''));
      expect(user.email, equals(''));
      expect(user.username, equals(''));
      expect(user.role, isNull);
      expect(user.eventId, isNull);
      expect(user.createdAt, isNull);
      expect(user.updatedAt, isNull);
    });

    test('Happy Path: Should serialize UserModel to valid JSON Map', () {
      final user = UserModel(
        id: "019146a0-7d1e-7abc-9a12-abcdef123456",
        email: "john@example.com",
        username: "john_doe",
        role: "ORGANIZER",
      );

      final json = user.toJson();

      expect(json['id'], equals("019146a0-7d1e-7abc-9a12-abcdef123456"));
      expect(json['email'], equals("john@example.com"));
      expect(json['username'], equals("john_doe"));
      expect(json['role'], equals("ORGANIZER"));
      expect(json.containsKey('eventId'), isFalse);
    });
  });
}
