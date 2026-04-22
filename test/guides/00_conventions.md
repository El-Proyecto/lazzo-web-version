# 00 — Conventions

**Read this before any other guide.** It defines the folder layout, naming, helpers, canonical patterns, and anti-patterns to fix.

---

## 1. Folder layout

Tests must mirror the `lib/` tree. Use the following mapping:

```
lib/features/<feature>/domain/usecases/   → test/features/<feature>/domain/usecases/
lib/features/<feature>/domain/entities/   → test/features/<feature>/domain/entities/
lib/features/<feature>/data/models/       → test/features/<feature>/data/models/
lib/features/<feature>/data/fakes/        → test/features/<feature>/data/fakes/
lib/features/<feature>/data/data_sources/ → test/features/<feature>/data/data_sources/
lib/features/<feature>/presentation/      → test/features/<feature>/presentation/
lib/shared/components/                    → test/shared/components/
```

**Do not use** `test/unit_tests/` or `test/widget_tests/` for new tests. Those folders contain legacy tests that will be migrated.

Example for `SubmitRsvp`:

```
lib/features/event/domain/usecases/submit_rsvp.dart
test/features/event/domain/usecases/submit_rsvp_test.dart
```

---

## 2. Naming rules

| Item | Convention | Example |
|------|-----------|---------|
| Test file | `<sut_snake_case>_test.dart` | `submit_rsvp_test.dart` |
| `group()` label | Describes what is being tested | `'SubmitRsvp'` |
| `test()` / `testWidgets()` label | Completes "it should…" | `'calls repository with correct args'` |
| Mock class | `Mock<InterfaceName>` | `MockRsvpRepository` |
| Fake value class | `Fake<EntityName>` | `FakeRsvp` |

---

## 3. Available helpers (always prefer these over re-implementing)

### `test/helpers/test_helpers.dart` (barrel — import this in tests)

Exports:
- `mock_repositories.dart` — `MockAuthRepository`, `MockMemoryRepository`, `MockEventRepository`, `MockProfileRepository`
- `test_app_wrapper.dart` — `TestAppWrapper`, `pumpTestWidget`, `pumpTestWidgetWithRouter`
- `golden_test_helper.dart` — `pumpGoldenWidget`, `testWidgetStatesGolden`, `TestScreenSizes`

### `test/mocks/mock_supabase.dart`

Exports:
- `MockSupabaseClient` — mocktail mock of `SupabaseClient`
- `MockGoTrueClient` — mocktail mock of `GoTrueClient`
- `MockStorageClient` — mocktail mock of `SupabaseStorageClient`
- `stubOtpSuccess(MockGoTrueClient)` — pre-configured stub

### `test/mocks/test_bootstrap.dart`

Contains any global `setUpAll` or shared fixture bootstrap. Read it before writing your own `setUpAll`.

### Missing mocks to add to `test/helpers/mock_repositories.dart`

The following repository interfaces exist in `lib/` but are **not yet mocked** in the helpers. Add them as you need them:

```dart
class MockRsvpRepository extends Mock implements RsvpRepository {}
class MockSuggestionRepository extends Mock implements SuggestionRepository {}
class MockChatRepository extends Mock implements ChatRepository {}
class MockPollRepository extends Mock implements PollRepository {}
class MockEventPhotoRepository extends Mock implements EventPhotoRepository {}
```

Add the corresponding imports at the top of `mock_repositories.dart`.

---

## 4. Canonical unit test pattern (AAA)

```dart
// test/features/event/domain/usecases/submit_rsvp_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lazzo/features/event/domain/usecases/submit_rsvp.dart';
import 'package:lazzo/features/event/domain/repositories/rsvp_repository.dart';
import 'package:lazzo/features/event/domain/entities/rsvp.dart';

class MockRsvpRepository extends Mock implements RsvpRepository {}

void main() {
  late MockRsvpRepository mockRepo;
  late SubmitRsvp sut;

  setUpAll(() {
    // Register fallback values for any complex type passed to mocks.
    // Required by mocktail when using any() matchers with named args.
    registerFallbackValue(RsvpStatus.pending);
  });

  setUp(() {
    mockRepo = MockRsvpRepository();
    sut = SubmitRsvp(mockRepo);
  });

  group('SubmitRsvp', () {
    test('calls repository with correct eventId, userId, and status', () async {
      // Arrange
      const eventId = 'event-1';
      const userId = 'user-1';
      const status = RsvpStatus.going;
      final expected = Rsvp(
        id: userId,
        eventId: eventId,
        userId: userId,
        userName: 'Alice',
        status: status,
      );
      when(() => mockRepo.submitRsvp(eventId, userId, status))
          .thenAnswer((_) async => expected);

      // Act
      final result = await sut.call(eventId, userId, status);

      // Assert
      expect(result, expected);
      verify(() => mockRepo.submitRsvp(eventId, userId, status)).called(1);
      verifyNoMoreInteractions(mockRepo);
    });

    test('propagates repository exceptions', () async {
      // Arrange
      when(() => mockRepo.submitRsvp(any(), any(), any()))
          .thenThrow(Exception('network error'));

      // Act & Assert
      expect(
        () => sut.call('event-1', 'user-1', RsvpStatus.going),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```

Key points:
- `setUpAll` for `registerFallbackValue` (run once per file).
- `setUp` for fresh mock + SUT instances (run before each test).
- AAA structure inside every `test()`.
- `verifyNoMoreInteractions` to catch unexpected calls.

---

## 5. Anti-patterns to fix (legacy debt)

### Anti-pattern 1 — SUT defined inside the test file

`test/unit_tests/auth/auth_service_test.dart` and `test/unit_tests/events/event_validator_test.dart` define their own `AuthService`, `AuthGateway`, `EventValidator`, etc. **These tests do not exercise production code.**

**Fix:** Replace with tests that import from `lib/`. If the production class does not exist or is structurally different, align the test with the real SUT — do not patch the test to shadow the real code.

### Anti-pattern 2 — Inconsistent folder placement

Old tests live in `test/unit_tests/<feature>/` or `test/features/<feature>/domain/entities/`. New tests must always follow the `test/features/<feature>/...` mirror layout (see §1).

### Anti-pattern 3 — Missing `registerFallbackValue`

If mocktail complains *"A value was requested from a mock but was not configured"*, add `registerFallbackValue(FakeX())` (or the enum value) in `setUpAll`. See mocktail docs.

### Anti-pattern 4 — Supabase in domain tests

Domain tests must be pure Dart (`import 'package:lazzo/features/.../domain/...`). If a test imports `supabase_flutter` it belongs in P5 (data source tests), not P1/P2.

---

## 6. Review checklist (run before every commit)

- [ ] File is named `*_test.dart`.
- [ ] File is placed mirroring `lib/` (see §1).
- [ ] File imports from `lib/` — SUT is not redefined in the test.
- [ ] `flutter analyze` passes with zero violations.
- [ ] No `print()` calls.
- [ ] All `test()` descriptions are meaningful.
- [ ] AAA structure is present in every test.
- [ ] `verifyNoMoreInteractions` used after `verify`.
- [ ] No hardcoded hex / magic numbers (use entity constants or `faker`).
- [ ] `const` constructors used where possible.
- [ ] Coverage for the touched file(s) reviewed in `coverage/lcov.info`.

---

## 7. Expected output of following this guide

No test files are created by guide 00. It is a reference document. When a downstream guide asks you to "follow conventions from 00", return here.
