# 06 — Presentation Providers (P6)

**Priority:** 6.

**Coverage target:** ≥ 75 % lines in `lib/features/*/presentation/providers/`.

**Pre-requisites:** `test/guides/00_conventions.md`, P1 and P4 complete.

---

## 1. Objective

Providers are the state layer — they bridge use cases and the UI. Tests here verify:

- `FutureProvider` / `FutureProvider.family` — transitions through `loading → data → error`.
- `StateNotifierProvider` — state mutations (`loading`, `error`, `success`) triggered by controller methods.
- **Repository overrides** — the correct DI override pattern using `ProviderContainer`.
- **No Supabase in tests** — all repositories are replaced with mocks via overrides.

These tests run without Flutter — use `ProviderContainer` directly (no `WidgetTester`).

---

## 2. Scope — providers to test

### `event` feature

| Provider(s) | File | Test file |
|-------------|------|-----------|
| `eventDetailProvider` | `lib/features/event/presentation/providers/event_providers.dart` | `test/features/event/presentation/providers/event_providers_test.dart` |
| `rsvpListProvider` | same | same |
| `canManageEventProvider` | same | same |
| `eventPhotoProviders` | `lib/features/event/presentation/providers/event_photo_providers.dart` | `test/features/event/presentation/providers/event_photo_providers_test.dart` |
| `eventParticipantsProvider` | `lib/features/event/presentation/providers/event_participants_provider.dart` | `test/features/event/presentation/providers/event_participants_provider_test.dart` |

### `create_event` feature

| Provider(s) | File | Test file |
|-------------|------|-----------|
| `createEventControllerProvider` (`CreateEventController`) | `lib/features/create_event/presentation/providers/event_providers.dart` | `test/features/create_event/presentation/providers/create_event_providers_test.dart` |
| `editEventControllerProvider` (`EditEventController`) | same | same |
| `eventHistoryProvider` | `lib/features/create_event/presentation/providers/event_history_provider.dart` | `test/features/create_event/presentation/providers/event_history_provider_test.dart` |

### `auth` feature

| Provider(s) | File | Test file |
|-------------|------|-----------|
| Auth providers | `lib/features/auth/presentation/providers/` | `test/features/auth/presentation/providers/auth_providers_test.dart` |

---

## 3. Canonical pattern — `ProviderContainer` + override

```dart
// test/features/event/presentation/providers/event_providers_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lazzo/features/event/domain/entities/event_detail.dart';
import 'package:lazzo/features/event/domain/repositories/event_repository.dart';
import 'package:lazzo/features/event/presentation/providers/event_providers.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(EventStatus.pending);
  });

  setUp(() {
    mockRepo = MockEventRepository();
  });

  // Helper: create a ProviderContainer with the mock override
  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        eventRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  }

  group('eventDetailProvider', () {
    test('emits data when repository succeeds', () async {
      // Arrange
      final event = EventDetail(
        id: 'evt-1', name: 'BBQ', emoji: '🍖',
        status: EventStatus.pending,
        createdAt: DateTime(2025, 6, 1),
        hostId: 'host-1',
        goingCount: 5, notGoingCount: 2,
      );
      when(() => mockRepo.getEventDetail('evt-1'))
          .thenAnswer((_) async => event);

      final container = makeContainer();
      addTearDown(container.dispose);

      // Act
      final result = await container.read(eventDetailProvider('evt-1').future);

      // Assert
      expect(result, event);
    });

    test('emits error when repository throws', () async {
      // Arrange
      when(() => mockRepo.getEventDetail(any()))
          .thenThrow(Exception('network error'));

      final container = makeContainer();
      addTearDown(container.dispose);

      // Act & Assert
      expect(
        () => container.read(eventDetailProvider('evt-1').future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```

Key points:
- `ProviderContainer(overrides: [...])` — no Flutter/WidgetTester required.
- `addTearDown(container.dispose)` — prevents memory leaks between tests.
- Read `.future` on `FutureProvider` to get the resolved value directly.
- For `StateNotifier`, read the notifier and call methods, then read the state.

---

## 4. `StateNotifier` pattern — `CreateEventController`

```dart
group('CreateEventController', () {
  test('state is loading then success after createEvent call', () async {
    // Arrange
    final mockUseCase = MockCreateEventUseCase();
    final expectedEvent = Event(
      id: 'e-1', name: 'BBQ', emoji: '🍖',
      status: EventStatus.pending,
      createdAt: DateTime.now(),
    );
    when(() => mockUseCase.execute(
          name: any(named: 'name'),
          emoji: any(named: 'emoji'),
        )).thenAnswer((_) async => expectedEvent);

    final container = ProviderContainer(
      overrides: [
        createEventUseCaseProvider.overrideWithValue(mockUseCase),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(createEventControllerProvider.notifier);

    // Act
    await notifier.createEvent(name: 'BBQ', emoji: '🍖');
    final state = container.read(createEventControllerProvider);

    // Assert
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.createdEvent, expectedEvent);
  });

  test('sets error on use case failure', () async {
    final mockUseCase = MockCreateEventUseCase();
    when(() => mockUseCase.execute(
          name: any(named: 'name'),
          emoji: any(named: 'emoji'),
        )).thenThrow(ArgumentError('Event name cannot be empty'));

    final container = ProviderContainer(
      overrides: [createEventUseCaseProvider.overrideWithValue(mockUseCase)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(createEventControllerProvider.notifier);
    await notifier.createEvent(name: '', emoji: '🍖');
    final state = container.read(createEventControllerProvider);

    expect(state.isLoading, isFalse);
    expect(state.error, isNotNull);
    expect(state.createdEvent, isNull);
  });
});
```

---

## 5. Provider-specific cases

### `eventDetailProvider(eventId)` — `FutureProvider.family`

- [ ] Returns `EventDetail` on success.
- [ ] Returns error state when repository throws.
- [ ] Uses `eventRepositoryProvider` (verify with override).

### `canManageEventProvider(eventId)`

- [ ] Returns `true` when `event.hostId == currentUserId`.
- [ ] Returns `false` when `currentUserId` is null.
- [ ] Returns `false` when `event.hostId != currentUserId`.
- [ ] Returns `false` when `getEventDetail` throws (caught internally).

### `CreateEventController`

- [ ] Initial state: `isLoading = false`, `error = null`, `createdEvent = null`.
- [ ] During call: state has `isLoading = true`.
- [ ] Success: `createdEvent` is set, `isLoading = false`, `error = null`.
- [ ] Failure: `error` is non-null, `isLoading = false`, `createdEvent = null`.
- [ ] Guards against duplicate calls when `isLoading = true`.

### `EditEventController`

- [ ] `updateEvent` — success sets `updatedEvent`, clears error.
- [ ] `updateEvent` — failure sets `error`.
- [ ] `deleteEvent` — success sets `isDeleted = true`.
- [ ] `deleteEvent` — failure sets `error`.

### `eventHistoryProvider(userId)`

- [ ] Returns `List<EventHistory>` on success.
- [ ] Empty list when repository returns empty.

---

## 6. Agent workflow

```
1. Read 00_conventions.md
2. Open the provider file in lib/
3. List all providers and notifiers
4. Create the test file using ProviderContainer pattern (§3)
5. For StateNotifiers, use the pattern in §4
6. flutter analyze
7. flutter test test/features/<feature>/presentation/providers/<file>_test.dart
8. flutter test --coverage → check lcov
9. Check off in §7
```

---

## 7. Progress tracker

### event
- [ ] `eventDetailProvider`, `canManageEventProvider`, RSVP providers
- [ ] `eventPhotoProviders`
- [ ] `eventParticipantsProvider`

### create_event
- [ ] `CreateEventController` + `EditEventController`
- [ ] `eventHistoryProvider`

### auth
- [ ] Auth providers
