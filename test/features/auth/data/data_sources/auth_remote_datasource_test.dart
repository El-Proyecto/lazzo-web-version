import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../mocks/mock_supabase.dart';

class MockAuthDatasourceSupabaseOps extends Mock
    implements AuthDatasourceSupabaseOps {}

void main() {
  late MockSupabaseClient mockClient;
  late MockAuthDatasourceSupabaseOps mockOps;
  late AuthRemoteDatasource sut;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockOps = MockAuthDatasourceSupabaseOps();
    sut = AuthRemoteDatasource(mockClient, ops: mockOps);
  });

  group('AuthRemoteDatasource', () {
    test('login calls signInWithOtp with trimmed lowercase email', () async {
      when(() => mockOps.findUserIdByEmail('user@email.com'))
          .thenAnswer((_) async => {'id': 'user-1'});
      when(
        () => mockOps.signInWithOtp(
          email: any(named: 'email'),
          shouldCreateUser: any(named: 'shouldCreateUser'),
          data: any(named: 'data'),
          emailRedirectTo: any(named: 'emailRedirectTo'),
        ),
      ).thenAnswer((_) async {});

      await sut.login('  User@Email.COM  ');

      verify(() => mockOps.findUserIdByEmail('user@email.com')).called(1);
      verify(
        () => mockOps.signInWithOtp(
          email: 'user@email.com',
          shouldCreateUser: false,
          data: any(named: 'data'),
          emailRedirectTo: any(named: 'emailRedirectTo'),
        ),
      ).called(1);
      verifyNoMoreInteractions(mockOps);
    });

    test('login throws if user not found in users table', () async {
      when(() => mockOps.findUserIdByEmail('notfound@example.com'))
          .thenAnswer((_) async => null);

      await expectLater(
        () => sut.login('notfound@example.com'),
        throwsA(isA<Exception>()),
      );
      verifyNever(
        () => mockOps.signInWithOtp(
          email: any(named: 'email'),
          shouldCreateUser: any(named: 'shouldCreateUser'),
          data: any(named: 'data'),
          emailRedirectTo: any(named: 'emailRedirectTo'),
        ),
      );
    });

    test('register calls signInWithOtp with shouldCreateUser true', () async {
      when(
        () => mockOps.signInWithOtp(
          email: any(named: 'email'),
          shouldCreateUser: any(named: 'shouldCreateUser'),
          emailRedirectTo: any(named: 'emailRedirectTo'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async {});

      await sut.register('  New@Email.COM ');

      verify(
        () => mockOps.signInWithOtp(
          email: 'new@email.com',
          shouldCreateUser: true,
          emailRedirectTo: null,
          data: any(named: 'data'),
        ),
      ).called(1);
      verifyNoMoreInteractions(mockOps);
    });

    test('register wraps supabase exception in Exception', () async {
      when(
        () => mockOps.signInWithOtp(
          email: any(named: 'email'),
          shouldCreateUser: any(named: 'shouldCreateUser'),
          emailRedirectTo: any(named: 'emailRedirectTo'),
          data: any(named: 'data'),
        ),
      ).thenThrow(const AuthException('boom'));

      await expectLater(
        () => sut.register('test@example.com'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Falha ao enviar código de verificação'),
          ),
        ),
      );
    });
  });
}
