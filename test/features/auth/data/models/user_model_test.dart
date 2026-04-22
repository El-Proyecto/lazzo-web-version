import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    final fullRow = <String, dynamic>{
      'id': 'user-1',
      'name': 'Alice',
      'email': 'alice@example.com',
      'birth_date': '1995-01-10T00:00:00.000Z',
      'created_at': '2025-06-15T20:00:00.000Z',
      'city': 'Porto',
      'Notify_birthday': true,
      'updated_at': '2025-06-20T18:00:00.000Z',
    };

    group('fromUsersRow', () {
      test('parses all fields from a full row', () {
        final model = UserModel.fromUsersRow(fullRow);

        expect(model.id, 'user-1');
        expect(model.name, 'Alice');
        expect(model.email, 'alice@example.com');
        expect(model.birthDate, DateTime.parse('1995-01-10T00:00:00.000Z'));
        expect(model.createdAt, DateTime.parse('2025-06-15T20:00:00.000Z'));
        expect(model.city, 'Porto');
        expect(model.notifyBirthday, isTrue);
        expect(model.updatedAt, DateTime.parse('2025-06-20T18:00:00.000Z'));
      });

      test('handles nullable and optional fields when absent', () {
        final row = <String, dynamic>{
          'id': 'user-1',
          'email': 'alice@example.com',
        };
        final model = UserModel.fromUsersRow(row);

        expect(model.name, isNull);
        expect(model.birthDate, isNull);
        expect(model.createdAt, isNull);
        expect(model.city, isNull);
        expect(model.updatedAt, isNull);
        expect(model.notifyBirthday, isFalse);
      });

      test('handles null values explicitly', () {
        final row = Map<String, dynamic>.from(fullRow)
          ..['name'] = null
          ..['birth_date'] = null
          ..['city'] = null
          ..['Notify_birthday'] = null;
        final model = UserModel.fromUsersRow(row);

        expect(model.name, isNull);
        expect(model.birthDate, isNull);
        expect(model.city, isNull);
        expect(model.notifyBirthday, isFalse);
      });
    });

    group('toUsersInsert/toUsersPatch', () {
      test('serializes all non-null fields with supabase column names', () {
        final model = UserModel.fromUsersRow(fullRow);

        final insertJson = model.toUsersInsert();
        final patchJson = model.toUsersPatch();

        expect(insertJson['id'], 'user-1');
        expect(insertJson['email'], 'alice@example.com');
        expect(insertJson['name'], 'Alice');
        expect(insertJson['birth_date'], '1995-01-10T00:00:00.000Z');
        expect(insertJson['city'], 'Porto');
        expect(insertJson['Notify_birthday'], isTrue);

        expect(patchJson.containsKey('id'), isFalse);
        expect(patchJson['email'], 'alice@example.com');
        expect(patchJson['name'], 'Alice');
        expect(patchJson['birth_date'], '1995-01-10T00:00:00.000Z');
        expect(patchJson['city'], 'Porto');
        expect(patchJson['Notify_birthday'], isTrue);
      });

      test('omits nullable keys when values are null', () {
        const model = UserModel(
          id: 'user-1',
          email: 'alice@example.com',
          notifyBirthday: false,
        );

        final insertJson = model.toUsersInsert();
        final patchJson = model.toUsersPatch();

        expect(insertJson.containsKey('name'), isFalse);
        expect(insertJson.containsKey('birth_date'), isFalse);
        expect(insertJson.containsKey('city'), isFalse);
        expect(patchJson.containsKey('name'), isFalse);
        expect(patchJson.containsKey('birth_date'), isFalse);
        expect(patchJson.containsKey('city'), isFalse);
      });
    });
  });
}
