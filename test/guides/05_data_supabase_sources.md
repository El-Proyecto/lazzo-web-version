# 05 — Supabase Data Sources (P5)

**Priority:** 5.

**Coverage target:** ≥ 70 % lines in `lib/features/*/data/data_sources/`.

**Pre-requisites:** `test/guides/00_conventions.md`, P3 and P4 complete.

---

## 1. Objective

Data sources contain the actual Supabase calls (`from().select()`, `rpc()`, `storage`). They are the noisiest part of the codebase from a testing perspective — you must mock the Supabase client.

**What to test:**
- The correct Supabase table/column names and query structure are used.
- Results are parsed via the model's `fromJson` and returned as entities.
- Exceptions from Supabase are propagated (not swallowed).
- Optional best-effort paths (fire-and-forget RPCs) do not crash on failure.

**What NOT to test here:**
- Business logic — that belongs to use cases (P1).
- JSON parsing — that belongs to DTO tests (P3).
- Full integration with a live Supabase project.

---

## 2. Available mocks

Use `test/mocks/mock_supabase.dart` (already in the repo):

```dart
import 'package:lazzo/test/mocks/mock_supabase.dart'; // adjust path

// Available:
// MockSupabaseClient    — mocktail mock of SupabaseClient
// MockGoTrueClient      — mocktail mock of GoTrueClient
// MockStorageClient     — mocktail mock of SupabaseStorageClient
// stubOtpSuccess(MockGoTrueClient) — pre-configured OTP stub
```

---

## 3. Scope — data sources to test

### `auth` feature

| Data source | File | Test file |
|-------------|------|-----------|
| `AuthRemoteDatasource` | `lib/features/auth/data/datasources/auth_remote_datasource.dart` | `test/features/auth/data/data_sources/auth_remote_datasource_test.dart` |

### `event` feature

| Data source | File | Test file |
|-------------|------|-----------|
| `EventRemoteDataSource` | `lib/features/event/data/data_sources/event_remote_data_source.dart` | `test/features/event/data/data_sources/event_remote_data_source_test.dart` |
| `RsvpRemoteDataSource` | `lib/features/event/data/data_sources/rsvp_remote_data_source.dart` | `test/features/event/data/data_sources/rsvp_remote_data_source_test.dart` |
| `ChatRemoteDataSource` | `lib/features/event/data/data_sources/chat_remote_data_source.dart` | `test/features/event/data/data_sources/chat_remote_data_source_test.dart` |
| `PollRemoteDataSource` | `lib/features/event/data/data_sources/poll_remote_data_source.dart` | `test/features/event/data/data_sources/poll_remote_data_source_test.dart` |
| `RsvpRemoteDataSource` | `lib/features/event/data/data_sources/rsvp_remote_data_source.dart` | already listed above |
| `SuggestionRemoteDataSource` | `lib/features/event/data/data_sources/suggestion_remote_data_source.dart` | `test/features/event/data/data_sources/suggestion_remote_data_source_test.dart` |
| `EventPhotoDataSource` | `lib/features/event/data/data_sources/event_photo_data_source.dart` | `test/features/event/data/data_sources/event_photo_data_source_test.dart` |

### `create_event` feature

Check `lib/features/create_event/data/data_sources/` for data source files and add test files accordingly.

### `memory` feature

Check `lib/features/memory/data/data_sources/` and add entries.

---

## 4. Canonical pattern — mocking SupabaseClient

Supabase Flutter's query builder chain (`from().select().eq().single()`) is deeply nested and difficult to mock directly with mocktail. Use the following strategy:

### Strategy A — Mock the query chain (preferred for simple queries)

```dart
// test/features/auth/data/data_sources/auth_remote_datasource_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lazzo/features/auth/data/datasources/auth_remote_datasource.dart';

// Mocks from test/mocks/mock_supabase.dart
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late AuthRemoteDatasource sut;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    sut = AuthRemoteDatasource(mockClient);
  });

  group('AuthRemoteDatasource', () {
    group('login', () {
      test('calls signInWithOtp with trimmed lowercase email', () async {
        // Arrange: stub the users table lookup to return an existing user
        final mockQueryBuilder = _MockPostgrestFilterBuilder();
        when(() => mockClient.from('users')).thenReturn(_mockFrom(mockQueryBuilder));
        when(() => mockQueryBuilder.maybeSingle())
            .thenAnswer((_) async => {'id': 'user-1'});
        when(() => mockAuth.signInWithOtp(
              email: any(named: 'email'),
              shouldCreateUser: any(named: 'shouldCreateUser'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => AuthResponse());

        // Act
        await sut.login('  User@Email.COM  ');

        // Assert
        verify(() => mockAuth.signInWithOtp(
              email: 'user@email.com',
              shouldCreateUser: false,
              data: any(named: 'data'),
            )).called(1);
      });

      test('throws when user does not exist in users table', () async {
        final mockQueryBuilder = _MockPostgrestFilterBuilder();
        when(() => mockClient.from('users')).thenReturn(_mockFrom(mockQueryBuilder));
        when(() => mockQueryBuilder.maybeSingle())
            .thenAnswer((_) async => null); // user not found

        expect(
          () => sut.login('notfound@example.com'),
          throwsA(isA<Exception>()),
        );
        verifyNever(() => mockAuth.signInWithOtp(
              email: any(named: 'email'),
              shouldCreateUser: any(named: 'shouldCreateUser'),
            ));
      });
    });
  });
}
```

> **Note on Supabase query builder mocking:** The `SupabaseQueryBuilder` / `PostgrestFilterBuilder` chain is notoriously hard to mock with mocktail because it returns typed builder objects. You may need to create mock classes for each builder step in the chain. If a data source method has a very long query chain, prefer **Strategy B** below.

### Strategy B — Wrap Supabase calls in an injectable interface (recommended for complex queries)

If the query builder chain is too deep, introduce a thin interface:

```dart
// lib/features/event/data/data_sources/event_data_source_interface.dart
abstract class IEventDataSource {
  Future<Map<String, dynamic>> fetchEventDetail(String eventId);
}
```

Then mock `IEventDataSource` instead of `SupabaseClient`. This is the cleanest approach and avoids fighting the builder chain.

**When creating new data sources or refactoring existing ones, prefer Strategy B.** Document this decision in the test file with a comment.

---

## 5. Data source-specific cases

### `AuthRemoteDatasource`

- [ ] `login` — calls `signInWithOtp` with trimmed lowercase email.
- [ ] `login` — throws if user not found in `users` table.
- [ ] `register` — calls `signInWithOtp` with `shouldCreateUser: true`.
- [ ] `register` — propagates Supabase exception as wrapped `Exception`.

### `EventRemoteDataSource`

- [ ] `getEventDetail` — queries `events` table with correct `eventId`.
- [ ] `getEventDetail` — calls `_resetExpiredEventVotes` as fire-and-forget (no await; failure is silent).
- [ ] `updateEventStatus` — calls correct table and column.
- [ ] `endEventNow` — sends correct payload.
- [ ] `extendEventTime` — sends updated end time.

### `RsvpRemoteDataSource`

- [ ] `getEventRsvps` — queries `event_participants` with `pevent_id` filter.
- [ ] `getEventRsvps` — converts storage avatar paths to signed URLs.
- [ ] `submitRsvp` — upserts into `event_participants` with correct keys.
- [ ] Propagates Supabase exception.

### `ChatRemoteDataSource`

- [ ] `sendMessage` — inserts into correct table with `event_id`, `user_id`, `content`.
- [ ] `pinMessage` — updates `is_pinned` field.
- [ ] `deleteMessage` — updates `is_deleted = true`.
- [ ] `updateLastReadMessage` — upserts into read-tracking table.
- [ ] `getUnreadMessageCount` — calls correct RPC or query.

### `EventPhotoDataSource`

- [ ] `uploadPhoto` — calls `storage.from(...).upload(...)`.
- [ ] `uploadPhoto` — returns signed/public URL after upload.
- [ ] Propagates storage errors.

---

## 6. Mocking builder chains — helper classes

Add these to `test/mocks/mock_supabase.dart` as needed (do not redefine in individual test files):

```dart
// Add to test/mocks/mock_supabase.dart

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<dynamic> {}

class MockPostgrestTransformBuilder extends Mock
    implements PostgrestTransformBuilder<dynamic> {}

class MockSupabaseQueryBuilder extends Mock
    implements SupabaseQueryBuilder {}
```

---

## 7. Agent workflow

```
1. Read 00_conventions.md + this guide
2. Open the data source file in lib/
3. List all public methods — decide Strategy A or B per method
4. For complex query chains, consider refactoring to Strategy B
5. Create the test file
6. Start with the simplest method (fewest query builder steps)
7. flutter analyze
8. flutter test test/features/<feature>/data/data_sources/<file>_test.dart
9. flutter test --coverage → check lcov
10. Check off data source in §8
```

---

## 8. Progress tracker

### auth
- [ ] `AuthRemoteDatasource`

### event
- [ ] `EventRemoteDataSource`
- [ ] `RsvpRemoteDataSource`
- [ ] `ChatRemoteDataSource`
- [ ] `PollRemoteDataSource`
- [ ] `SuggestionRemoteDataSource`
- [ ] `EventPhotoDataSource`

### create_event
- [ ] *(check `lib/features/create_event/data/data_sources/`)*

### memory
- [ ] *(check `lib/features/memory/data/data_sources/`)*
