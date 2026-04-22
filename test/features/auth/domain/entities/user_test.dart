import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/auth/domain/entities/user.dart';

void main() {
  group('User', () {
    test('constructs with optional fields null', () {
      const user = User(id: 'u-1', email: 'user@test.com');

      expect(user.id, 'u-1');
      expect(user.email, 'user@test.com');
      expect(user.name, isNull);
      expect(user.dateOfBirth, isNull);
    });

    test('constructs with all fields provided', () {
      final birthDate = DateTime(1995, 3, 18);
      final user = User(
        id: 'u-2',
        email: 'ana@test.com',
        name: 'Ana',
        dateOfBirth: birthDate,
      );

      expect(user.id, 'u-2');
      expect(user.email, 'ana@test.com');
      expect(user.name, 'Ana');
      expect(user.dateOfBirth, birthDate);
    });
  });
}
