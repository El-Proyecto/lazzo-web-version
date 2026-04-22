# 01 — Domain Use Cases (P1)

**Priority:** 1 — implement this first.

**Coverage target:** ≥ 90 % lines in `lib/features/*/domain/usecases/`.

**Pre-requisites:** Read `test/guides/00_conventions.md`.

---

## 1. Objective

Use cases are pure Dart. They have no Flutter, Supabase, or IO imports. Tests are fast, require only `mocktail` mocks of repository interfaces, and give the highest coverage ROI per line of test written.

Every use case class must be tested against its production code in `lib/`. The existing tests in `test/unit_tests/` define mock classes locally — those tests do not count toward coverage of `lib/`.

---

## 2. Scope — use cases to test

### `auth` feature

| Use case | Production file | Test file to create |
|----------|-----------------|---------------------|
| `LoginUser` | `lib/features/auth/domain/usecases/login_user.dart` | `test/features/auth/domain/usecases/login_user_test.dart` |

### `create_event` feature

| Use case | Production file | Test file to create |
|----------|-----------------|---------------------|
| `CreateEventUseCase` | `lib/features/create_event/domain/usecases/create_event.dart` | `test/features/create_event/domain/usecases/create_event_use_case_test.dart` |
| `UpdateEventUseCase` | `lib/features/create_event/domain/usecases/update_event.dart` | `test/features/create_event/domain/usecases/update_event_use_case_test.dart` |
| `DeleteEventUseCase` | `lib/features/create_event/domain/usecases/delete_event.dart` | `test/features/create_event/domain/usecases/delete_event_use_case_test.dart` |
| `GetUserEventHistory` | `lib/features/create_event/domain/usecases/get_user_event_history.dart` | `test/features/create_event/domain/usecases/get_user_event_history_test.dart` |
| `GetActiveEvent` (if implemented) | `lib/features/create_event/domain/usecases/get_active_event.dart` | `test/features/create_event/domain/usecases/get_active_event_test.dart` |

### `event` feature

| Use case | Production file | Test file to create |
|----------|-----------------|---------------------|
| `GetEventDetail` | `lib/features/event/domain/usecases/get_event_detail.dart` | `test/features/event/domain/usecases/get_event_detail_test.dart` |
| `SubmitRsvp` | `lib/features/event/domain/usecases/submit_rsvp.dart` | `test/features/event/domain/usecases/submit_rsvp_test.dart` |
| `GetEventRsvps` | `lib/features/event/domain/usecases/get_event_rsvps.dart` | `test/features/event/domain/usecases/get_event_rsvps_test.dart` |
| `GetEventParticipants` | `lib/features/event/domain/usecases/get_event_participants.dart` | `test/features/event/domain/usecases/get_event_participants_test.dart` |
| `GetEventPolls` | `lib/features/event/domain/usecases/get_event_polls.dart` | `test/features/event/domain/usecases/get_event_polls_test.dart` |
| `GetEventSuggestions` | `lib/features/event/domain/usecases/get_event_suggestions.dart` | `test/features/event/domain/usecases/get_event_suggestions_test.dart` |
| `CreateSuggestion` | `lib/features/event/domain/usecases/create_suggestion.dart` | `test/features/event/domain/usecases/create_suggestion_test.dart` |
| `CreateLocationSuggestion` | `lib/features/event/domain/usecases/create_location_suggestion.dart` | `test/features/event/domain/usecases/create_location_suggestion_test.dart` |
| `ToggleSuggestionVote` | `lib/features/event/domain/usecases/toggle_suggestion_vote.dart` | `test/features/event/domain/usecases/toggle_suggestion_vote_test.dart` |
| `SendChatMessage` | `lib/features/event/domain/usecases/send_chat_message.dart` | `test/features/event/domain/usecases/send_chat_message_test.dart` |
| `GetChatMessages` | `lib/features/event/domain/usecases/get_chat_messages.dart` | `test/features/event/domain/usecases/get_chat_messages_test.dart` |
| `GetRecentMessages` | `lib/features/event/domain/usecases/get_recent_messages.dart` | `test/features/event/domain/usecases/get_recent_messages_test.dart` |
| `DeleteMessage` | `lib/features/event/domain/usecases/delete_message.dart` | `test/features/event/domain/usecases/delete_message_test.dart` |
| `PinMessage` | `lib/features/event/domain/usecases/pin_message.dart` | `test/features/event/domain/usecases/pin_message_test.dart` |
| `GetUnreadMessageCount` | `lib/features/event/domain/usecases/get_unread_message_count.dart` | `test/features/event/domain/usecases/get_unread_message_count_test.dart` |
| `UpdateLastReadMessage` | `lib/features/event/domain/usecases/update_last_read_message.dart` | `test/features/event/domain/usecases/update_last_read_message_test.dart` |
| `UploadEventPhoto` | `lib/features/event/domain/usecases/upload_event_photo.dart` | `test/features/event/domain/usecases/upload_event_photo_test.dart` |
| `EndEventNow` | `lib/features/event/domain/usecases/end_event_now.dart` | `test/features/event/domain/usecases/end_event_now_test.dart` |
| `ExtendEventTime` | `lib/features/event/domain/usecases/extend_event_time.dart` | `test/features/event/domain/usecases/extend_event_time_test.dart` |
| `UpdateEventStatus` | `lib/features/event/domain/usecases/update_event_status.dart` | `test/features/event/domain/usecases/update_event_status_test.dart` |
| `ConfirmEventStatus` | `lib/features/event/domain/usecases/confirm_event_status.dart` | `test/features/event/domain/usecases/confirm_event_status_test.dart` |
| `ToggleEventConfirmation` | `lib/features/event/domain/usecases/toggle_event_confirmation_use_case.dart` | `test/features/event/domain/usecases/toggle_event_confirmation_use_case_test.dart` |

### `memory` feature

| Use case | Production file | Test file to create |
|----------|-----------------|---------------------|
| `GetMemory` | `lib/features/memory/domain/usecases/get_memory.dart` | `test/features/memory/domain/usecases/get_memory_test.dart` |
| `GetMemoryPhotos` | `lib/features/memory/domain/usecases/get_memory_photos.dart` | `test/features/memory/domain/usecases/get_memory_photos_test.dart` |
| `CloseRecap` | `lib/features/memory/domain/usecases/close_recap.dart` | `test/features/memory/domain/usecases/close_recap_test.dart` |
| `RemoveMemoryPhoto` | `lib/features/memory/domain/usecases/remove_memory_photo.dart` | `test/features/memory/domain/usecases/remove_memory_photo_test.dart` |
| `ShareMemory` | `lib/features/memory/domain/usecases/share_memory.dart` | `test/features/memory/domain/usecases/share_memory_test.dart` |
| `UpdateMemoryCover` | `lib/features/memory/domain/usecases/update_memory_cover.dart` | `test/features/memory/domain/usecases/update_memory_cover_test.dart` |

---

## 3. Canonical pattern for use case tests

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
    registerFallbackValue(RsvpStatus.pending);
  });

  setUp(() {
    mockRepo = MockRsvpRepository();
    sut = SubmitRsvp(mockRepo);
  });

  group('SubmitRsvp', () {
    test('calls repository and returns Rsvp on success', () async {
      // Arrange
      final expected = Rsvp(
        id: 'user-1', eventId: 'event-1', userId: 'user-1',
        userName: 'Alice', status: RsvpStatus.going,
      );
      when(() => mockRepo.submitRsvp('event-1', 'user-1', RsvpStatus.going))
          .thenAnswer((_) async => expected);

      // Act
      final result = await sut.call('event-1', 'user-1', RsvpStatus.going);

      // Assert
      expect(result, expected);
      verify(() => mockRepo.submitRsvp('event-1', 'user-1', RsvpStatus.going))
          .called(1);
      verifyNoMoreInteractions(mockRepo);
    });

    test('propagates repository exceptions', () {
      when(() => mockRepo.submitRsvp(any(), any(), any()))
          .thenThrow(Exception('network'));
      expect(
        () => sut.call('event-1', 'user-1', RsvpStatus.going),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```

---

## 4. Checklist per use case

For every use case, write at minimum:

- [ ] **Happy path** — correct inputs, repository stub returns expected value, result matches.
- [ ] **Repository delegation** — `verify()` that the repository method was called with the correct arguments.
- [ ] **No extra calls** — `verifyNoMoreInteractions(mockRepo)`.
- [ ] **Error propagation** — repository throws, use case propagates (or maps) the exception.
- [ ] **Business rule branches** — if the use case has `if`/validation logic, cover each branch.

### Business-rule-heavy use cases (extra cases required)

#### `CreateEventUseCase` (`create_event.dart`)

- [ ] Empty name throws `ArgumentError`.
- [ ] Name with only whitespace throws `ArgumentError`.
- [ ] `endDateTime` before `startDateTime` throws `ArgumentError`.
- [ ] `endDateTime` equal to `startDateTime` throws `ArgumentError`.
- [ ] Valid inputs with all optional fields null succeeds.
- [ ] Valid inputs with all fields provided succeeds.

#### `UpdateEventUseCase` (`update_event.dart`)

- [ ] Empty name throws `ArgumentError`.
- [ ] `endDateTime` before `startDateTime` throws `ArgumentError`.
- [ ] Repository returns null for `getEventById` → throws `ArgumentError('Event not found')`.
- [ ] Successfully updates with nullable fields set to null (ValueWrapper).

#### `DeleteEventUseCase` (`delete_event.dart`)

- [ ] Empty eventId throws `ArgumentError`.
- [ ] Repository returns null for `getEventById` → throws `ArgumentError('Event not found')`.
- [ ] Happy path calls `deleteEvent` with correct id.

#### `UploadEventPhoto` (`upload_event_photo.dart`)

- [ ] Empty eventId throws `ArgumentError`.
- [ ] Image file that does not exist throws `ArgumentError`.
- [ ] Valid inputs call `repository.uploadPhoto` with eventId and file.

Note: `UploadEventPhoto` uses `dart:io.File.exists()` — use a real temp file or a fake file class. Do not use Supabase in this test.

#### `ToggleSuggestionVote` (`toggle_suggestion_vote.dart`)

- [ ] User has **not** voted → calls `voteOnSuggestion`, returns `true`.
- [ ] User **has** voted → calls `removeVoteFromSuggestion`, returns `false`.

#### `LoginUser` (`login_user.dart`)

- [ ] Calls `repository.login(email: email)` with correct argument.
- [ ] Propagates exception from repository.

---

## 5. Agent workflow

```
1. Read this guide + 00_conventions.md
2. Pick the first unchecked use case from §2
3. Create the test file at the path shown in the table
4. Implement the cases from §4
5. flutter analyze       ← zero violations
6. flutter test test/features/<feature>/domain/usecases/<file>_test.dart
7. flutter test --coverage
8. Check coverage for the production file in coverage/lcov.info
9. Check off the use case in the table in §2
10. Repeat from step 2
```

---

## 6. Review checklist

- [ ] Test file path mirrors `lib/` (see conventions §1).
- [ ] SUT is imported from `lib/` — not redefined.
- [ ] `flutter analyze` passes with zero violations.
- [ ] No `print()`.
- [ ] AAA in every `test()`.
- [ ] `verifyNoMoreInteractions` called.
- [ ] Coverage ≥ 90 % for the tested file (check `lcov.info`).

---

## 7. Progress tracker

Mark items as done with `[x]` when the test file passes and coverage is confirmed.

### auth
- [ ] `LoginUser`

### create_event
- [ ] `CreateEventUseCase`
- [ ] `UpdateEventUseCase`
- [ ] `DeleteEventUseCase`
- [ ] `GetUserEventHistory`
- [ ] `GetActiveEvent`

### event
- [ ] `GetEventDetail`
- [ ] `SubmitRsvp`
- [ ] `GetEventRsvps`
- [ ] `GetEventParticipants`
- [ ] `GetEventPolls`
- [ ] `GetEventSuggestions`
- [ ] `CreateSuggestion`
- [ ] `CreateLocationSuggestion`
- [ ] `ToggleSuggestionVote`
- [ ] `SendChatMessage`
- [ ] `GetChatMessages`
- [ ] `GetRecentMessages`
- [ ] `DeleteMessage`
- [ ] `PinMessage`
- [ ] `GetUnreadMessageCount`
- [ ] `UpdateLastReadMessage`
- [ ] `UploadEventPhoto`
- [ ] `EndEventNow`
- [ ] `ExtendEventTime`
- [ ] `UpdateEventStatus`
- [ ] `ConfirmEventStatus`
- [ ] `ToggleEventConfirmation`

### memory
- [ ] `GetMemory`
- [ ] `GetMemoryPhotos`
- [ ] `CloseRecap`
- [ ] `RemoveMemoryPhoto`
- [ ] `ShareMemory`
- [ ] `UpdateMemoryCover`
