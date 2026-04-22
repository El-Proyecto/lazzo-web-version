# 04 — Fake Repository Contracts (P4)

**Priority:** 4.

**Coverage target:** ≥ 80 % lines in `lib/features/*/data/fakes/`.

**Pre-requisites:** `test/guides/00_conventions.md`, P1 and P2 complete.

---

## 1. Objective

Fake repositories are the **default DI implementation** (`main.dart` uses fakes by default; a single override switches to Supabase). If a fake violates the repository interface contract, the entire app runs on broken data in development, and tests written against fakes are worthless.

These tests verify that each fake:

1. Correctly **implements** the `abstract` interface — static analysis confirms this but tests confirm runtime behaviour.
2. Returns **correctly typed** data (entities, not maps or nulls when the interface says non-null).
3. Respects **state mutations** — `create` increases a collection, `delete` removes it.
4. Handles **not-found** cases as expected by the interface contract (null vs exception).

No mocks are needed — you call the fake directly.

---

## 2. Scope — fakes to test

### `event` feature

| Fake | Interface | File | Test file |
|------|-----------|------|-----------|
| `FakeEventRepository` | `EventRepository` | `lib/features/event/data/fakes/fake_event_repository.dart` | `test/features/event/data/fakes/fake_event_repository_test.dart` |
| `FakeRsvpRepository` | `RsvpRepository` | `lib/features/event/data/fakes/fake_rsvp_repository.dart` | `test/features/event/data/fakes/fake_rsvp_repository_test.dart` |
| `FakePollRepository` | `PollRepository` | `lib/features/event/data/fakes/fake_poll_repository.dart` | `test/features/event/data/fakes/fake_poll_repository_test.dart` |
| `FakeSuggestionRepository` | `SuggestionRepository` | `lib/features/event/data/fakes/fake_suggestion_repository.dart` | `test/features/event/data/fakes/fake_suggestion_repository_test.dart` |
| `FakeChatRepository` | `ChatRepository` | `lib/features/event/data/fakes/fake_chat_repository.dart` | `test/features/event/data/fakes/fake_chat_repository_test.dart` |

### `create_event` feature

| Fake | Interface | File | Test file |
|------|-----------|------|-----------|
| `FakeEventRepository` (create_event) | `EventRepository` (create_event) | `lib/features/create_event/data/fakes/` | `test/features/create_event/data/fakes/fake_event_repository_test.dart` |

Check `lib/features/create_event/data/fakes/` — if a fake exists there, add it to this list.

### `memory` feature

Check `lib/features/memory/data/fakes/` and add any fakes found.

### `auth` feature

Check `lib/features/auth/data/` for a `FakeAuthRepository` and add it if present.

---

## 3. Canonical pattern for fake contract tests

```dart
// test/features/event/data/fakes/fake_rsvp_repository_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/data/fakes/fake_rsvp_repository.dart';
import 'package:lazzo/features/event/domain/entities/rsvp.dart';
import 'package:lazzo/features/event/domain/repositories/rsvp_repository.dart';

void main() {
  // Verify the fake satisfies the interface at compile time.
  // If this line fails to compile, the fake is broken.
  // ignore: unused_local_variable
  final RsvpRepository _ = FakeRsvpRepository();

  late FakeRsvpRepository repo;

  setUp(() {
    repo = FakeRsvpRepository();
  });

  group('FakeRsvpRepository', () {
    group('getEventRsvps', () {
      test('returns non-empty list for the seeded event', () async {
        final rsvps = await repo.getEventRsvps('event-1');
        expect(rsvps, isNotEmpty);
        expect(rsvps.every((r) => r.eventId == 'event-1'), isTrue);
      });

      test('returns empty list for unknown event', () async {
        final rsvps = await repo.getEventRsvps('no-such-event');
        expect(rsvps, isEmpty);
      });
    });

    group('submitRsvp', () {
      test('creates RSVP and returns entity with correct status', () async {
        final rsvp = await repo.submitRsvp('event-1', 'new-user', RsvpStatus.going);
        expect(rsvp.status, RsvpStatus.going);
        expect(rsvp.userId, 'new-user');
        expect(rsvp.eventId, 'event-1');
      });

      test('updates existing RSVP status', () async {
        // First submit
        await repo.submitRsvp('event-1', 'user-1', RsvpStatus.going);
        // Update
        final updated = await repo.submitRsvp('event-1', 'user-1', RsvpStatus.notGoing);
        expect(updated.status, RsvpStatus.notGoing);
      });
    });

    group('getUserRsvp', () {
      test('returns null for user with no RSVP', () async {
        final rsvp = await repo.getUserRsvp('event-1', 'no-user');
        expect(rsvp, isNull);
      });

      test('returns RSVP for existing user', () async {
        await repo.submitRsvp('event-1', 'user-a', RsvpStatus.maybe);
        final rsvp = await repo.getUserRsvp('event-1', 'user-a');
        expect(rsvp, isNotNull);
        expect(rsvp!.status, RsvpStatus.maybe);
      });
    });
  });
}
```

Key differences from use case tests:
- No mocks — you instantiate the fake directly.
- The compile-time assignment `RsvpRepository _ = FakeRsvpRepository()` confirms interface conformance.
- `setUp` creates a fresh fake before each test.

> **Note on static state:** Some fakes use `static` maps to persist data (e.g. `FakeEventRepository._events`). If the fake uses static state, you may need to call a reset method or re-instantiate. Check the production fake code and document the approach in your test's `setUp`.

---

## 4. Fake-specific cases

### `FakeEventRepository` (event feature)

Read `lib/features/event/domain/repositories/event_repository.dart` for the full interface.

- [ ] Implements `EventRepository` at compile time.
- [ ] `getEventDetail('event-1')` returns seeded `EventDetail`.
- [ ] `getEventDetail('unknown')` throws or returns a sensible value (match what the interface contract says — document which).
- [ ] `updateEventStatus` changes the returned status on subsequent `getEventDetail`.
- [ ] `endEventNow` updates end time and status.
- [ ] `extendEventTime` adds minutes to end time.

### `FakeRsvpRepository`

- [ ] Implements `RsvpRepository` at compile time.
- [ ] `getEventRsvps('event-1')` returns seeded list.
- [ ] `submitRsvp` creates new RSVP.
- [ ] `submitRsvp` idempotent update on same userId.
- [ ] `getUserRsvp` returns null for unknown user.
- [ ] `getRsvpsByStatus` filters by status.

### `FakePollRepository`

Read `lib/features/event/domain/repositories/poll_repository.dart`.

- [ ] Implements `PollRepository` at compile time.
- [ ] `getEventPolls('event-1')` returns seeded polls.
- [ ] Vote method increases `voteCount` for a poll option.
- [ ] Double-voting handling (if the fake prevents it).

### `FakeSuggestionRepository`

Read `lib/features/event/domain/repositories/suggestion_repository.dart`.

- [ ] Implements `SuggestionRepository` at compile time.
- [ ] `getEventSuggestions` returns seeded list.
- [ ] `createSuggestion` returns entity with non-empty id.
- [ ] `voteOnSuggestion` and `removeVoteFromSuggestion` toggle votes.
- [ ] `getUserSuggestionVotes` returns votes for correct userId.

### `FakeChatRepository`

Read `lib/features/event/domain/repositories/chat_repository.dart`.

- [ ] Implements `ChatRepository` at compile time.
- [ ] `sendMessage` returns `ChatMessage` with correct content.
- [ ] `watchMessages` emits a `Stream<List<ChatMessage>>` (use `emitsInOrder` or `first`).
- [ ] `pinMessage` toggles `isPinned`.
- [ ] `deleteMessage` marks message as `isDeleted = true`.

---

## 5. Agent workflow

```
1. Read 00_conventions.md
2. Open the fake repository file in lib/
3. Read the corresponding abstract interface in lib/features/*/domain/repositories/
4. Create the test file at the path in §2
5. Write the compile-time conformance assertion (see §3)
6. Implement cases from §4
7. flutter analyze
8. flutter test test/features/<feature>/data/fakes/<file>_test.dart
9. flutter test --coverage → check lcov
10. Check off fake in §6
```

---

## 6. Progress tracker

### event
- [ ] `FakeEventRepository`
- [ ] `FakeRsvpRepository`
- [ ] `FakePollRepository`
- [ ] `FakeSuggestionRepository`
- [ ] `FakeChatRepository`

### create_event
- [ ] `FakeEventRepository` (if exists)

### memory
- [ ] *(inspect `lib/features/memory/data/fakes/` and add entries)*

### auth
- [ ] *(inspect `lib/features/auth/data/` and add entries)*
