import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockStorageClient extends Mock implements SupabaseStorageClient {}

// …adiciona stubs úteis:
void stubOtpSuccess(MockGoTrueClient auth) {
  when(
    () => auth.signInWithOtp(email: any(named: 'email')),
  ).thenAnswer((_) async => AuthResponse());
}
