import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockStorageClient extends Mock implements SupabaseStorageClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockStorageFileApi extends Mock implements StorageFileApi {}

class MockPostgrestFilterBuilderList extends Mock
    implements PostgrestFilterBuilder<PostgrestList> {}

class MockPostgrestFilterBuilderMap extends Mock
    implements PostgrestFilterBuilder<PostgrestMap> {}

class MockPostgrestFilterBuilderMapNullable extends Mock
    implements PostgrestFilterBuilder<PostgrestMap?> {}

class MockPostgrestTransformBuilderList extends Mock
    implements PostgrestTransformBuilder<PostgrestList> {}

class MockPostgrestTransformBuilderMap extends Mock
    implements PostgrestTransformBuilder<PostgrestMap> {}

class MockPostgrestTransformBuilderMapNullable extends Mock
    implements PostgrestTransformBuilder<PostgrestMap?> {}

// …adiciona stubs úteis:
void stubOtpSuccess(MockGoTrueClient auth) {
  when(
    () => auth.signInWithOtp(email: any(named: 'email')),
  ).thenAnswer((_) async => AuthResponse());
}
