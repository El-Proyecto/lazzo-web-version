# 03 — Data DTOs / Models (P3)

**Priority:** 3.

**Coverage target:** ≥ 90 % lines in `lib/features/*/data/models/`.

**Pre-requisites:** `test/guides/00_conventions.md`, P1 complete.

---

## 1. Objective

Data models (DTOs) are the translation boundary between Supabase JSON rows and domain entities. Parse bugs here cause silent data corruption. Tests verify:

- `fromJson` parses all fields from a representative JSON map.
- `fromJson` handles **nullable/optional fields** being absent from the JSON (missing key or `null` value).
- `toJson` serialises all fields back to the Supabase format.
- `toEntity` produces the correct domain entity (field mapping + enum parsing).
- **Round-trip**: `fromJson(model.toJson()).toEntity()` equals the original entity (where equality is defined).
- Edge cases: empty strings, null joins, deprecated field fallbacks.

These tests have no external dependencies — they only use `Map<String, dynamic>` literals.

---

## 2. Scope — models to test

### `auth` feature

| Model | File | Test file |
|-------|------|-----------|
| `UserModel` | `lib/features/auth/data/models/user_model.dart` | `test/features/auth/data/models/user_model_test.dart` |

### `create_event` feature

| Model | File | Test file |
|-------|------|-----------|
| `EventOriginalModel` | `lib/features/create_event/data/models/event_original_model.dart` | `test/features/create_event/data/models/event_original_model_test.dart` |
| `EventHistoryModel` | `lib/features/create_event/data/models/event_history_model.dart` | `test/features/create_event/data/models/event_history_model_test.dart` |
| `LocationModel` | `lib/features/create_event/data/models/location_model.dart` | `test/features/create_event/data/models/location_model_test.dart` |

### `event` feature

| Model | File | Test file |
|-------|------|-----------|
| `EventDetailModel` | `lib/features/event/data/models/event_detail_model.dart` | `test/features/event/data/models/event_detail_model_test.dart` |
| `RsvpModel` | `lib/features/event/data/models/rsvp_model.dart` | `test/features/event/data/models/rsvp_model_test.dart` |
| `ChatMessageModel` | `lib/features/event/data/models/chat_message_model.dart` | `test/features/event/data/models/chat_message_model_test.dart` |
| `PollModel` | `lib/features/event/data/models/poll_model.dart` | `test/features/event/data/models/poll_model_test.dart` |
| `SuggestionModel` | `lib/features/event/data/models/suggestion_model.dart` | `test/features/event/data/models/suggestion_model_test.dart` |

---

## 3. Canonical pattern for DTO tests

```dart
// test/features/event/data/models/rsvp_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/data/models/rsvp_model.dart';
import 'package:lazzo/features/event/domain/entities/rsvp.dart';

void main() {
  group('RsvpModel', () {
    // Representative JSON row from Supabase (event_participants table + user join)
    final fullJson = <String, dynamic>{
      'user_id': 'user-1',
      'pevent_id': 'event-1',
      'rsvp': 'yes',
      'confirmed_at': '2025-06-15T20:00:00.000Z',
      'user': {
        'name': 'Alice',
        'avatar_url': 'https://example.com/alice.jpg',
        'email': 'alice@example.com',
      },
    };

    group('fromJson', () {
      test('parses all fields from full JSON', () {
        final model = RsvpModel.fromJson(fullJson);

        expect(model.userId, 'user-1');
        expect(model.eventId, 'event-1');
        expect(model.status, 'yes');
        expect(model.userName, 'Alice');
        expect(model.userAvatar, 'https://example.com/alice.jpg');
        expect(model.userEmail, 'alice@example.com');
        expect(model.confirmedAt, isNotNull);
      });

      test('handles missing user join gracefully', () {
        final json = Map<String, dynamic>.from(fullJson)..remove('user');
        final model = RsvpModel.fromJson(json);
        expect(model.userName, 'Unknown User');
        expect(model.userAvatar, isNull);
      });

      test('handles null confirmed_at', () {
        final json = Map<String, dynamic>.from(fullJson)
          ..['confirmed_at'] = null;
        final model = RsvpModel.fromJson(json);
        expect(model.confirmedAt, isNull);
      });

      test('defaults rsvp to pending when column is absent', () {
        final json = Map<String, dynamic>.from(fullJson)..remove('rsvp');
        final model = RsvpModel.fromJson(json);
        expect(model.status, 'pending');
      });
    });

    group('toEntity', () {
      test('maps "yes" to RsvpStatus.going', () {
        final entity = RsvpModel.fromJson(fullJson).toEntity();
        expect(entity.status, RsvpStatus.going);
      });

      test('maps "no" to RsvpStatus.notGoing', () {
        final json = Map<String, dynamic>.from(fullJson)..['rsvp'] = 'no';
        final entity = RsvpModel.fromJson(json).toEntity();
        expect(entity.status, RsvpStatus.notGoing);
      });

      test('maps "maybe" to RsvpStatus.maybe', () {
        final json = Map<String, dynamic>.from(fullJson)..['rsvp'] = 'maybe';
        final entity = RsvpModel.fromJson(json).toEntity();
        expect(entity.status, RsvpStatus.maybe);
      });

      test('maps unknown value to RsvpStatus.pending', () {
        final json = Map<String, dynamic>.from(fullJson)
          ..['rsvp'] = 'pending';
        final entity = RsvpModel.fromJson(json).toEntity();
        expect(entity.status, RsvpStatus.pending);
      });
    });

    group('toJson', () {
      test('includes user_id, pevent_id, rsvp', () {
        final model = RsvpModel.fromJson(fullJson);
        final json = model.toJson();
        expect(json['user_id'], 'user-1');
        expect(json['pevent_id'], 'event-1');
        expect(json['rsvp'], 'yes');
      });

      test('omits confirmed_at when null', () {
        final json = Map<String, dynamic>.from(fullJson)
          ..['confirmed_at'] = null;
        final output = RsvpModel.fromJson(json).toJson();
        expect(output.containsKey('confirmed_at'), isFalse);
      });
    });
  });
}
```

---

## 4. Model-specific cases

### `RsvpModel`

- [ ] `fromJson` — full row including nested `user` join.
- [ ] `fromJson` — missing `user` join → `userName = 'Unknown User'`.
- [ ] `fromJson` — null `confirmed_at`.
- [ ] `fromJson` — missing `rsvp` column defaults to `'pending'`.
- [ ] `toEntity` — `'yes'` → `RsvpStatus.going`, `'no'` → `RsvpStatus.notGoing`, `'maybe'` → `RsvpStatus.maybe`, `'pending'` → `RsvpStatus.pending`.
- [ ] `toJson` — includes required keys; omits `confirmed_at` when null.

### `ChatMessageModel`

- [ ] `fromJson` — full row with nested `user` join.
- [ ] `fromJson` — falls back to `user_name` / `user_avatar` flat columns (RPC format).
- [ ] `fromJson` — `is_read_by_someone` key used when present; falls back to `read`.
- [ ] `fromJson` — missing `is_pinned` defaults to `false`.
- [ ] `fromJson` — missing `is_deleted` defaults to `false`.
- [ ] `toEntity` — `replyTo` is `null` (populated by repository separately).
- [ ] `toJson` — omits `reply_to_id` when null.

### `EventDetailModel`

- [ ] `fromJson` — full row including counts and host info.
- [ ] `fromJson` — null `location_id` → location fields all null.
- [ ] `fromJson` — null `start_datetime` / `end_datetime` preserved as null.
- [ ] `toEntity` — produces `EventDetail` with correct `hostId`, `goingCount`, `notGoingCount`.
- [ ] Status string parsing — `'pending'`, `'living'`, `'recap'`, `'ended'`.

### `PollModel`

- [ ] `fromJson` — parses `options` list correctly.
- [ ] `fromJson` — empty `options` array → empty `List<PollOption>`.
- [ ] `toEntity` — `voteCount` and `votedUserIds` per option.

### `SuggestionModel`

- [ ] `fromJson` — full row.
- [ ] `fromJson` — null optional fields.
- [ ] `toEntity` — correct entity mapping.

### `EventHistoryModel`

- [ ] `fromJson` — maps event history row to model.
- [ ] `toEntity` — produces `EventHistory` with correct fields.

### `LocationModel`

- [ ] `fromJson` — parses `lat`, `lng`, `display_name`, `formatted_address`.
- [ ] `toEntity` — produces `EventLocation`.

---

## 5. Agent workflow

```
1. Read 00_conventions.md
2. Read the production model file to understand fromJson/toEntity/toJson signatures
3. Build a representative JSON fixture that matches the Supabase schema
   - Refer to supabase_structure.sql or supabase_schema.sql at repo root for column names
4. Create the test file at the path in §2
5. Implement cases from §4 for this model
6. flutter analyze
7. flutter test test/features/<feature>/data/models/<file>_test.dart
8. flutter test --coverage → check lcov for the model file
9. Check off model in §6
```

**Important:** Column names come from Supabase, not from entity field names. Always read the production `fromJson` to know the exact key strings used.

---

## 6. Progress tracker

### auth
- [ ] `UserModel`

### create_event
- [ ] `EventOriginalModel`
- [ ] `EventHistoryModel`
- [ ] `LocationModel`

### event
- [ ] `EventDetailModel`
- [ ] `RsvpModel`
- [ ] `ChatMessageModel`
- [ ] `PollModel`
- [ ] `SuggestionModel`
