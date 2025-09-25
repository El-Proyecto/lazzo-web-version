// test/unit/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ===== Interface fina para isolar Supabase =====
abstract class AuthGateway {
  Future<String> signInWithOtp({required String email}); // devolve userId
  Future<String> signInWithGoogle(); // devolve userId
}

class AuthFailure implements Exception {
  final String code; // ex.: 'invalid-otp', 'network', 'unknown'
  final String message;
  AuthFailure(this.code, this.message);
}

// ===== SUT =====
class AuthService {
  final AuthGateway gateway;
  AuthService(this.gateway);

  Future<String> loginWithOtp(String rawEmail) async {
    final email = rawEmail.trim().toLowerCase();
    if (email.isEmpty) throw AuthFailure('invalid-email', 'Email vazio');
    try {
      return await gateway.signInWithOtp(email: email);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure('unknown', 'Erro inesperado: $e');
    }
  }

  Future<String> signInWithGoogle() async {
    try {
      return await gateway.signInWithGoogle();
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure('unknown', 'Erro inesperado: $e');
    }
  }
}

// ===== Mocks =====
class MockAuthGateway extends Mock implements AuthGateway {}

void main() {
  late MockAuthGateway gateway;
  late AuthService service;

  setUpAll(() {
    registerFallbackValue(''); // para evitar erros de argumentos em mocktail
  });

  setUp(() {
    gateway = MockAuthGateway();
    service = AuthService(gateway);
  });

  group('loginWithOtp', () {
    test(
      'normaliza email (trim + lower) e chama gateway com o normalizado',
      () async {
        when(
          () => gateway.signInWithOtp(email: any(named: 'email')),
        ).thenAnswer((_) async => 'uid_123');

        final uid = await service.loginWithOtp('  User@Email.COM  ');

        expect(uid, 'uid_123');
        verify(() => gateway.signInWithOtp(email: 'user@email.com')).called(1);
        verifyNoMoreInteractions(gateway);
      },
    );

    test('lança AuthFailure("invalid-email") se email vazio', () async {
      expect(
        () => service.loginWithOtp('   '),
        throwsA(
          isA<AuthFailure>().having((e) => e.code, 'code', 'invalid-email'),
        ),
      );
      verifyZeroInteractions(gateway);
    });

    test('propaga AuthFailure("invalid-otp") do gateway', () async {
      when(
        () => gateway.signInWithOtp(email: any(named: 'email')),
      ).thenThrow(AuthFailure('invalid-otp', 'Código inválido'));

      expect(
        () => service.loginWithOtp('a@b.com'),
        throwsA(
          isA<AuthFailure>().having((e) => e.code, 'code', 'invalid-otp'),
        ),
      );
    });

    test('mapeia exceções inesperadas para AuthFailure("unknown")', () async {
      when(
        () => gateway.signInWithOtp(email: any(named: 'email')),
      ).thenThrow(Exception('boom'));

      expect(
        () => service.loginWithOtp('a@b.com'),
        throwsA(isA<AuthFailure>().having((e) => e.code, 'code', 'unknown')),
      );
    });
  });

  group('signInWithGoogle', () {
    test('retorna userId em sucesso', () async {
      when(
        () => gateway.signInWithGoogle(),
      ).thenAnswer((_) async => 'uid_google');
      final uid = await service.signInWithGoogle();
      expect(uid, 'uid_google');
      verify(() => gateway.signInWithGoogle()).called(1);
    });

    test('propaga falhas do gateway (ex.: network)', () async {
      when(
        () => gateway.signInWithGoogle(),
      ).thenThrow(AuthFailure('network', 'Sem ligação'));
      expect(
        () => service.signInWithGoogle(),
        throwsA(isA<AuthFailure>().having((e) => e.code, 'code', 'network')),
      );
    });
  });
}
