# 02 — Domain Entities (P2)

**Priority:** 2.

**Coverage target:** ≥ 85 % lines in `lib/features/*/domain/entities/`.

**Pre-requisites:** `test/guides/00_conventions.md`.

---

## 1. Objective

Domain entities are pure Dart value objects. Tests here verify:

- `copyWith` behaviour — fields update correctly and nullable fields clear correctly.
- Value equality — entities with the same data are equal (if `==` is implemented; document if not).
- Computed properties and getters.
- Enum parsing helpers (`fromString`, etc.).
- `ValueWrapper` pattern (used by `Event.copyWith` to allow explicit null clearing).

These tests have zero external dependencies — no mocks, no fakes, no Flutter.

---

## 2. Scope — entities to test

### `auth` feature

| Entity | File | Test file |
|--------|------|-----------|
| `User` | `lib/features/auth/domain/entities/user.dart` | `test/features/auth/domain/entities/user_test.dart` |

### `create_event` feature

| Entity | File | Test file |
|--------|------|-----------|
| `Event` | `lib/features/create_event/domain/entities/event.dart` | `test/features/create_event/domain/entities/event_test.dart` |
| `EventLocation` | `lib/features/create_event/domain/entities/event.dart` | included in `event_test.dart` |
| `EventStatus` (enum) | `lib/features/create_event/domain/entities/event.dart` | included in `event_test.dart` |
| `ValueWrapper` | `lib/features/create_event/domain/entities/event.dart` | included in `event_test.dart` |
| `EventHistory` | `lib/features/create_event/domain/entities/event_history.dart` | `test/features/create_event/domain/entities/event_history_test.dart` |

### `event` feature

| Entity | File | Test file |
|--------|------|-----------|
| `EventDetail` | `lib/features/event/domain/entities/event_detail.dart` | `test/features/event/domain/entities/event_detail_test.dart` *(already exists — review and expand)* |
| `EventLocation` (shared) | `lib/features/event/domain/entities/event_detail.dart` | included in `event_detail_test.dart` |
| `Rsvp` | `lib/features/event/domain/entities/rsvp.dart` | `test/features/event/domain/entities/rsvp_test.dart` |
| `RsvpStatus` (enum) | `lib/features/event/domain/entities/rsvp.dart` | included in `rsvp_test.dart` |
| `Poll` | `lib/features/event/domain/entities/poll.dart` | `test/features/event/domain/entities/poll_test.dart` |
| `PollOption` | `lib/features/event/domain/entities/poll.dart` | included in `poll_test.dart` |
| `Suggestion` | `lib/features/event/domain/entities/suggestion.dart` | `test/features/event/domain/entities/suggestion_test.dart` |
| `ChatMessage` | `lib/features/event/domain/entities/chat_message.dart` | `test/features/event/domain/entities/chat_message_test.dart` |
| `EventParticipantEntity` | `lib/features/event/domain/entities/event_participant_entity.dart` | `test/features/event/domain/entities/event_participant_entity_test.dart` |
| `EventDisplayEntity` | `lib/features/event/domain/entities/event_display_entity.dart` | `test/features/event/domain/entities/event_display_entity_test.dart` |

### `memory` feature

| Entity | File | Test file |
|--------|------|-----------|
| `MemoryEntity` | `lib/features/memory/domain/entities/memory_entity.dart` | `test/features/memory/domain/entities/memory_entity_test.dart` |
| `MemoryPhoto` | `lib/features/memory/domain/entities/memory_entity.dart` | included in `memory_entity_test.dart` |
| `EventStatus` (enum) | `lib/features/memory/domain/entities/memory_entity.dart` | included in `memory_entity_test.dart` |

---

## 3. Canonical pattern for entity tests

```dart
// test/features/create_event/domain/entities/event_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/create_event/domain/entities/event.dart';

void main() {
  final baseEvent = Event(
    id: 'evt-1',
    name: 'BBQ',
    emoji: '🍖',
    status: EventStatus.pending,
    createdAt: DateTime(2025, 6, 1),
  );

  group('Event.copyWith', () {
    test('returns new instance with updated name', () {
      final updated = baseEvent.copyWith(name: 'Beach BBQ');
      expect(updated.name, 'Beach BBQ');
      expect(updated.id, baseEvent.id);       // unchanged
      expect(updated.emoji, baseEvent.emoji); // unchanged
    });

    test('clears startDateTime when ValueWrapper(null) is provided', () {
      final withDate = baseEvent.copyWith(
        startDateTime: ValueWrapper(DateTime(2025, 7, 1)),
      );
      final cleared = withDate.copyWith(
        startDateTime: ValueWrapper(null),
      );
      expect(cleared.startDateTime, isNull);
    });

    test('preserves startDateTime when copyWith is called without it', () {
      final withDate = baseEvent.copyWith(
        startDateTime: ValueWrapper(DateTime(2025, 7, 1)),
      );
      final touched = withDate.copyWith(name: 'Updated');
      expect(touched.startDateTime, DateTime(2025, 7, 1));
    });

    test('clears description via ValueWrapper(null)', () {
      final withDesc = baseEvent.copyWith(description: ValueWrapper('desc'));
      final cleared = withDesc.copyWith(description: ValueWrapper(null));
      expect(cleared.description, isNull);
    });
  });

  group('EventStatus', () {
    test('has expected values', () {
      expect(
        EventStatus.values,
        containsAll([
          EventStatus.pending,
          EventStatus.confirmed,
          EventStatus.living,
          EventStatus.recap,
          EventStatus.expired,
        ]),
      );
    });
  });
}
```

---

## 4. Entity-specific cases

### `Event` (`create_event/domain/entities/event.dart`)

- [ ] `copyWith` updates individual string fields.
- [ ] `copyWith` with `ValueWrapper(null)` clears `startDateTime`, `endDateTime`, `location`, `description`.
- [ ] Without wrapping, existing nullable field is preserved.
- [ ] `EventStatus` enum contains all expected values.
- [ ] `EventLocation` can be constructed with `const`.

### `EventDetail` (`event/domain/entities/event_detail.dart`)

*A test file already exists at `test/features/event/domain/entities/event_detail_test.dart` — review it and add any missing cases.*

- [ ] `copyWith` updates each required and optional field.
- [ ] `copyWith` with `clearDescription: true` sets description to null.
- [ ] `goingCount` and `notGoingCount` are preserved when unspecified.
- [ ] `EventStatus` is preserved when status not passed to `copyWith`.

### `Rsvp` (`event/domain/entities/rsvp.dart`)

- [ ] `copyWith` updates `status`.
- [ ] `copyWith` preserves null optionals.
- [ ] `RsvpStatus` enum has `going`, `notGoing`, `maybe`, `pending`.

### `Poll` and `PollOption`

- [ ] `Poll.copyWith` replaces `options` list.
- [ ] `PollOption.copyWith` updates `voteCount`.
- [ ] `PollOption` with empty `votedUserIds` is valid.

### `ChatMessage`

- [ ] `copyWith` updates `isPinned`.
- [ ] `copyWith` updates `isDeleted`.
- [ ] `copyWith` sets nested `replyTo` message.
- [ ] `isPending` defaults to `false`.

### `MemoryEntity`

- [ ] `coverPhotos` returns only photos where `isCover == true`.
- [ ] `gridPhotos` excludes cover photos and is sorted by `capturedAt`.
- [ ] `recapTimeRemaining` returns `null` when status is not `recap`.
- [ ] `recapTimeRemaining` returns `Duration.zero` when the window has passed.
- [ ] `EventStatus.fromString('living')` returns `EventStatus.living`.
- [ ] `EventStatus.fromString('unknown')` falls back to `EventStatus.ended`.

### `User` (`auth/domain/entities/user.dart`)

- [ ] Construction with all optional fields null.
- [ ] Construction with all fields provided.

---

## 5. Agent workflow

```
1. Read 00_conventions.md
2. Pick the first unchecked entity from §2
3. Check if a test file already exists at the target path
   - If yes: read it and extend with missing cases from §4
   - If no: create it following the pattern in §3
4. flutter analyze
5. flutter test test/features/<feature>/domain/entities/<file>_test.dart
6. flutter test --coverage → check lcov for the entity file
7. Check off the entity in §6
```

---

## 6. Progress tracker

### auth
- [x] `User`

### create_event
- [x] `Event` + `EventLocation` + `EventStatus` + `ValueWrapper`
- [x] `EventHistory`

### event
- [x] `EventDetail` *(review existing test)*
- [x] `Rsvp` + `RsvpStatus`
- [x] `Poll` + `PollOption`
- [x] `Suggestion`
- [x] `ChatMessage`
- [x] `EventParticipantEntity`
- [x] `EventDisplayEntity`

### memory
- [x] `MemoryEntity` + `MemoryPhoto` + `EventStatus.fromString`
