// test/unit/supabase_auth_gateway_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../mocks/mock_supabase.dart'; // MockGoTrueClient já existe aqui
import '../../mocks/test_bootstrap.dart'; // opcional

/// Erro de domínio mínimo para o teste (ajusta ao teu projeto se quiseres)
class AuthFailure implements Exception {
  final String message;
  AuthFailure(this.message);
  @override
  String toString() => 'AuthFailure($message)';
}

/// "Service" mínimo apenas para acionar o mock do Supabase nas chamadas.
/// ISTO NÃO É O TEU CÓDIGO DE PRODUÇÃO — é só um thin wrapper para o teste.
class AuthService {
  final GoTrueClient auth;
  AuthService(this.auth);

  Future<void> signInWithOtp({required String email}) async {
    try {
      await auth.signInWithOtp(email: email);
    } on AuthException catch (e) {
      // mapeia para erro de domínio
      throw AuthFailure(e.message);
    }
  }
}

void main() {
  setupTestBinding(); // opcional, aqui não faz mal

  late MockGoTrueClient auth;
  late AuthService service;

  setUp(() {
    auth = MockGoTrueClient();
    service = AuthService(auth);
  });

  tearDown(() {
    reset(auth);
  });

  test('signInWithOtp chama o SDK e retorna sucesso', () async {
    // Arrange
    when(
      () => auth.signInWithOtp(email: any(named: 'email')),
    ).thenAnswer((_) async => AuthResponse());

    // Act
    await service.signInWithOtp(email: 'a@b.com');

    // Assert (2-passos para evitar "verification in progress")
    final v = verify(() => auth.signInWithOtp(email: 'a@b.com'));
    v.called(1);

    // Nota: não verificamos signInWithOAuth para não precisar de registerFallbackValue
  });

  test(
    'signInWithOtp mapeia AuthException para o teu erro de domínio',
    () async {
      // Arrange
      when(
        () => auth.signInWithOtp(email: any(named: 'email')),
      ).thenThrow(AuthException('Invalid OTP'));

      // Act + Assert
      await expectLater(
        () => service.signInWithOtp(email: 'a@b.com'),
        throwsA(isA<AuthFailure>()),
      );

      // Assert verificação fora do expect
      final v = verify(() => auth.signInWithOtp(email: 'a@b.com'));
      v.called(1);
    },
  );
}
