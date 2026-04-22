import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:lazzo/features/auth/data/models/user_model.dart';
import 'package:lazzo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRemoteDatasource extends Mock implements AuthRemoteDatasource {}

void main() {
  late MockAuthRemoteDatasource mockRemoteDatasource;
  late AuthRepositoryImpl sut;

  setUp(() {
    mockRemoteDatasource = MockAuthRemoteDatasource();
    sut = AuthRepositoryImpl(mockRemoteDatasource);
  });

  group('AuthRepositoryImpl', () {
    test('calls login on remote datasource with email', () async {
      // Arrange
      const email = 'user@example.com';
      when(() => mockRemoteDatasource.login(email)).thenAnswer((_) async {});

      // Act
      await sut.login(email: email);

      // Assert
      verify(() => mockRemoteDatasource.login(email)).called(1);
      verifyNoMoreInteractions(mockRemoteDatasource);
    });

    test('maps UserModel from remote datasource into domain User', () async {
      // Arrange
      final userModel = UserModel(
        id: 'user-1',
        email: 'user@example.com',
        name: 'Alice',
        birthDate: DateTime(1992, 4, 10),
      );
      when(
        () => mockRemoteDatasource.getCurrentUser(),
      ).thenAnswer((_) async => userModel);

      // Act
      final result = await sut.getCurrentUser();

      // Assert
      expect(result, isNotNull);
      expect(result!.id, userModel.id);
      expect(result.email, userModel.email);
      expect(result.name, userModel.name);
      expect(result.dateOfBirth, userModel.birthDate);
      verify(() => mockRemoteDatasource.getCurrentUser()).called(1);
      verifyNoMoreInteractions(mockRemoteDatasource);
    });

    test('delegates verifyOtp and returns mapped domain user', () async {
      // Arrange
      final userModel = const UserModel(
        id: 'user-2',
        email: 'verify@example.com',
        name: 'Bob',
      );
      when(
        () => mockRemoteDatasource.verifyOtp(
          email: 'verify@example.com',
          token: '123456',
          name: 'Bob',
          isSignup: true,
        ),
      ).thenAnswer((_) async => userModel);

      // Act
      final result = await sut.verifyOtp(
        email: 'verify@example.com',
        otp: '123456',
        name: 'Bob',
        isSignup: true,
      );

      // Assert
      expect(result, isNotNull);
      expect(result!.id, userModel.id);
      expect(result.email, userModel.email);
      expect(result.name, userModel.name);
      verify(
        () => mockRemoteDatasource.verifyOtp(
          email: 'verify@example.com',
          token: '123456',
          name: 'Bob',
          isSignup: true,
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRemoteDatasource);
    });
  });
}
