# 07 — Presentation Widgets & Pages (P7)

**Priority:** 7.

**Coverage target:** ≥ 60 % lines in `lib/features/*/presentation/pages/` and `lib/features/*/presentation/widgets/`.

**Pre-requisites:** `test/guides/00_conventions.md`, P6 complete. Read `test/helpers/test_app_wrapper.dart`.

---

## 1. Objective

Widget tests verify that pages:

- Render the correct UI for each `AsyncValue` state (`loading`, `data`, `error`).
- React to user interactions (taps, text input) by calling the correct provider methods.
- Show the correct content when providers are overridden with known data.
- Do NOT call Supabase directly (all providers must be overridden).

Use `TestAppWrapper` from `test/helpers/test_helpers.dart` — it provides a `ProviderScope` + dark `MaterialApp` matching the real app.

---

## 2. Scope — pages and widgets to test

### Priority pages (implement in order)

| Page | File | Test file |
|------|------|-----------|
| `AuthPage` | `lib/features/auth/presentation/pages/auth_page.dart` | `test/features/auth/presentation/pages/auth_page_test.dart` |
| `CreateEventPage` | `lib/features/create_event/presentation/pages/create_event_page.dart` | `test/widget_tests/create_event_page_test.dart` *(already exists — review and extend)* |
| `EventPage` | `lib/features/event/presentation/pages/event_page.dart` | `test/features/event/presentation/pages/event_page_test.dart` |
| `MemoryPage` | `lib/features/memory/presentation/pages/` | `test/features/memory/presentation/pages/memory_page_test.dart` |

### Secondary pages (add after priority pages pass)

| Page | File | Test file |
|------|------|-----------|
| `EditEventPage` | `lib/features/create_event/presentation/pages/edit_event_page.dart` | `test/features/create_event/presentation/pages/edit_event_page_test.dart` |
| `EventLivingPage` | `lib/features/event/presentation/pages/event_living_page.dart` | `test/features/event/presentation/pages/event_living_page_test.dart` |
| `EventRecapPage` | `lib/features/event/presentation/pages/event_recap_page.dart` | `test/features/event/presentation/pages/event_recap_page_test.dart` |
| `ManageGuestsPage` | `lib/features/event/presentation/pages/manage_guests_page.dart` | `test/features/event/presentation/pages/manage_guests_page_test.dart` |

### Shared components (already partially tested — extend)

| Component | File | Test file |
|-----------|------|-----------|
| `MissingFieldsConfirmationDialog` | see `shared/components/dialogs/` | `test/shared/components/dialogs/missing_fields_confirmation_dialog_test.dart` *(exists)* |
| `HelpPlanEventWidget` | see `shared/components/widgets/` | `test/shared/components/widgets/help_plan_event_widget_test.dart` *(exists)* |

---

## 3. Canonical pattern — page widget test

```dart
// test/features/event/presentation/pages/event_page_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lazzo/features/event/presentation/pages/event_page.dart';
import 'package:lazzo/features/event/presentation/providers/event_providers.dart';
import 'package:lazzo/features/event/domain/entities/event_detail.dart';
import 'package:lazzo/features/event/domain/repositories/event_repository.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepo;

  setUp(() {
    mockRepo = MockEventRepository();
  });

  Widget buildSubject({required String eventId}) {
    return ProviderScope(
      overrides: [
        eventRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: EventPage(eventId: eventId),
      ),
    );
  }

  group('EventPage', () {
    testWidgets('shows loading indicator while fetching event', (tester) async {
      // Arrange — repository never resolves (stays loading)
      when(() => mockRepo.getEventDetail('evt-1'))
          .thenAnswer((_) => Future.delayed(const Duration(minutes: 1), () => throw Exception()));

      await tester.pumpWidget(buildSubject(eventId: 'evt-1'));
      await tester.pump(); // one frame — shows loading state

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows event name when data loads successfully', (tester) async {
      // Arrange
      final event = EventDetail(
        id: 'evt-1', name: 'Churrascada', emoji: '🍖',
        status: EventStatus.pending,
        createdAt: DateTime(2025, 6, 1),
        hostId: 'host-1', goingCount: 5, notGoingCount: 2,
      );
      when(() => mockRepo.getEventDetail('evt-1'))
          .thenAnswer((_) async => event);

      await tester.pumpWidget(buildSubject(eventId: 'evt-1'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Churrascada'), findsOneWidget);
    });

    testWidgets('shows error state when repository throws', (tester) async {
      // Arrange
      when(() => mockRepo.getEventDetail(any()))
          .thenThrow(Exception('not found'));

      await tester.pumpWidget(buildSubject(eventId: 'bad-id'));
      await tester.pumpAndSettle();

      // Assert — verify the page renders something for the error state
      // (exact widget depends on the page's error UI implementation)
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
```

---

## 4. `TestAppWrapper` usage (simpler pages)

For pages that don't use router-specific features:

```dart
import 'package:lazzo/test/helpers/test_helpers.dart'; // adjust import

testWidgets('renders correctly', (tester) async {
  await pumpTestWidget(
    tester,
    const AuthPage(),
    overrides: [
      // add provider overrides here
    ],
  );
  await tester.pumpAndSettle();
  expect(find.byType(TextField), findsOneWidget);
});
```

---

## 5. Existing test to review — `CreateEventPage`

`test/widget_tests/create_event_page_test.dart` already contains two tests:

1. Empty name → shows validation error, no dialog.
2. Valid name → opens `ConfirmEventBottomSheet`.

**Review tasks:**

- [ ] Move file to `test/features/create_event/presentation/pages/create_event_page_test.dart` (mirrors `lib/` layout).
- [ ] Replace `wrap()` helper with `TestAppWrapper` or the pattern in §3.
- [ ] Add missing cases listed in §6.

---

## 6. Page-specific cases

### `AuthPage`

- [ ] Shows email input field.
- [ ] Shows disabled submit button when email is empty.
- [ ] Shows enabled submit button when email is non-empty.
- [ ] Tapping submit calls the auth provider method.

### `CreateEventPage`

*(extend existing test)*

- [ ] Continue without name shows validation error.
- [ ] Valid name opens `ConfirmEventBottomSheet`.
- [ ] Loading state shows a progress indicator.
- [ ] Error state from provider shows error message.

### `EventPage`

- [ ] Shows `CircularProgressIndicator` while loading.
- [ ] Shows event name when data is available.
- [ ] Shows error UI when provider emits error.
- [ ] Shows RSVP section for events in `pending` status.

### `MemoryPage`

- [ ] Shows event title and emoji.
- [ ] Shows cover photos.
- [ ] Shows grid photos.
- [ ] Shows empty state when no photos.

---

## 7. What NOT to test in widget tests

- Internal implementation details (private state variables).
- Pixel-perfect layout (that's for golden tests in P8).
- Network calls (always override repositories).
- Navigation results that require a real router (use `TestAppWrapperWithRouter` if needed).

---

## 8. Agent workflow

```
1. Read 00_conventions.md + test/helpers/test_app_wrapper.dart
2. Open the page file in lib/
3. Identify all providers the page watches/reads
4. Build a buildSubject() helper (see §3) with overrides for all providers
5. Implement cases: loading, data, error, and key interactions
6. flutter analyze
7. flutter test test/features/<feature>/presentation/pages/<file>_test.dart
8. flutter test --coverage → check lcov
9. Check off in §9
```

---

## 9. Progress tracker

### Priority pages
- [ ] `AuthPage`
- [ ] `CreateEventPage` *(review + extend existing test)*
- [ ] `EventPage`
- [ ] `MemoryPage`

### Secondary pages
- [ ] `EditEventPage`
- [ ] `EventLivingPage`
- [ ] `EventRecapPage`
- [ ] `ManageGuestsPage`

### Shared components
- [ ] `MissingFieldsConfirmationDialog` *(review existing)*
- [ ] `HelpPlanEventWidget` *(review existing)*
