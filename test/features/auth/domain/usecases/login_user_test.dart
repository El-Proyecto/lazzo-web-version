import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/auth/domain/repositories/auth_repository.dart';
import 'package:lazzo/features/auth/domain/usecases/login_user.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late LoginUser sut;

  setUp(() {
    mockRepository = MockAuthRepository();
    sut = LoginUser(mockRepository);
  });

  group('LoginUser', () {
    test('calls repository.login with correct email', () async {
      // Arrange
      const email = 'user@test.com';
      const password = 'secret';
      when(() => mockRepository.login(email: email)).thenAnswer((_) async {});

      // Act
      await sut.call(email, password);

      // Assert
      verify(() => mockRepository.login(email: email)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates exception from repository', () {
      // Arrange
      when(() => mockRepository.login(email: any(named: 'email')))
          .thenThrow(Exception('network'));

      // Act & Assert
      expect(
        () => sut.call('user@test.com', 'secret'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
