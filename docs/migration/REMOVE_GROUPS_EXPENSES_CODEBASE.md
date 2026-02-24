# MIGRATION: Remove Groups, Group Hub, Expenses from Codebase

## Context
The Lazzo app has pivoted from group-centric to event-centric. SQL migrations 001-003 have removed the database tables (`groups`, `group_members`, `event_expenses`, `expense_splits`, `chat_*`, etc.) and renamed `group_photos` → `event_photos`. The Flutter code still references these removed tables and features, causing runtime errors (e.g., `group_members does not exist` on the profile page).

## Scope

### Features to DELETE entirely (folders)
| Folder | Files | Reason |
|--------|-------|--------|
| `lib/features/groups/` | ~39 | Groups feature fully removed from DB |
| `lib/features/group_hub/` | ~43 | Group hub depends on groups |
| `lib/features/expense/` | ~11 | Expenses tables dropped from DB |

### Feature to KEEP
| Folder | Reason |
|--------|--------|
| `lib/features/group_invites/` | Invite link logic will be reused for event invites |

### `event_chat/` — Does NOT exist as a folder (already removed or never created)

---

## Phase 1: Delete Feature Folders

**Safe to delete entirely** — no external imports except those listed in Phase 2:

```bash
rm -rf lib/features/groups/
rm -rf lib/features/group_hub/
rm -rf lib/features/expense/
```

---

## Phase 2: Clean External References to Deleted Features

### 2.1 `lib/main.dart`
- **Remove** 3 expense imports (lines ~50-52)
- **Remove** expense DI override block (lines ~254-259)
- **Remove/update** leftover LAZZO 2.0 comments

### 2.2 Shared Components to DELETE
| File | Used by | Safe to delete? |
|------|---------|-----------------|
| `lib/shared/components/cards/group_card.dart` | Only groups feature | ✅ YES |
| `lib/shared/components/badges/group_badge.dart` | Only group_card | ✅ YES |
| `lib/shared/models/group_enums.dart` | Only group_card + group_badge | ✅ YES |
| `lib/shared/components/cards/payment_summary_card.dart` | home.dart, home_search_page.dart | ✅ YES (expenses removed) |
| `lib/shared/components/dialogs/add_expense_bottom_sheet.dart` | event_page, event_living_page, home_event_card | ✅ YES (expenses removed) |

### 2.3 `lib/shared/components/components.dart`
- Remove export for `add_expense_bottom_sheet.dart` (line ~52)
- Remove export for `payment_summary_card.dart` (line ~13)
- Clean leftover LAZZO 2.0 comments about group_card, group_badge

### 2.4 Event Feature — Expense Widgets to DELETE
| File | Reason |
|------|--------|
| `lib/features/event/presentation/widgets/event_expenses_widget.dart` | Imports from expense feature |
| `lib/features/event/presentation/widgets/event_expense_card.dart` | Imports from expense feature |
| `lib/features/event/presentation/widgets/expense_detail_bottom_sheet.dart` | Imports from expense feature |
| `lib/features/event/domain/entities/expense_participant_entity.dart` | Expense entity |

### 2.5 Event Feature — Pages to EDIT (remove expense logic)

**`lib/features/event/presentation/pages/event_page.dart`:**
- Remove imports: `event_expenses_widget.dart`, `add_expense_bottom_sheet.dart`, `event_expense_providers.dart`
- Remove method: `_showAddExpenseBottomSheet()`
- Remove: `showAddExpense` variable and expense button in AppBar
- Remove: `ref.invalidate(eventExpensesProvider(eventId))`

**`lib/features/event/presentation/pages/event_living_page.dart`:**
- Remove imports: `add_expense_bottom_sheet.dart`, `event_expense_providers.dart`, `event_expenses_widget.dart`
- Remove: expense-related callbacks (`onAddExpense`)
- Remove: `EventExpensesWidget` from body
- Remove: `ref.invalidate(eventExpensesProvider(widget.eventId))`

### 2.6 `lib/shared/components/cards/home_event_card.dart`
- Remove import: `event_expense_providers.dart`
- Remove import: `add_expense_bottom_sheet.dart`
- Remove: `onExpensePressed` callback
- Remove: expense action button section (~lines 534-630+)

### 2.7 Home Feature — Remove Payment References
**`lib/features/home/presentation/pages/home.dart`:**
- Remove import: `payment_summary_card.dart`
- Remove any payment summary widget usage

**`lib/features/home/presentation/pages/home_search_page.dart`:**
- Remove import: `payment_summary_card.dart`
- Remove any payment summary usage

---

## Phase 3: Fix `group_members` → `event_participants` References

These files in **kept features** query the removed `group_members` table:

### 3.1 `lib/features/profile/data/data_sources/profile_memory_data_source.dart`
**Bug:** Queries `group_members` table to get user's group IDs, then calls `get_user_memories_with_covers` RPC with group IDs.
**Fix:** Rewrite to query `event_participants` for user's event IDs, then query events directly with status 'recap'/'ended' and cover photos. The RPC `get_user_memories_with_covers` likely no longer exists either — use direct query.

### 3.2 `lib/features/profile/data/data_sources/other_profile_data_source.dart`
**Bug:** Multiple queries to `group_members` to find shared groups, then filters events by `group_id`.
**Fix:** Rewrite `getSharedMemories()` and `getSharedUpcomingEvents()` to find shared events via `event_participants` (both users are participants of the same event).

### 3.3 `lib/features/create_event/data/repositories/event_repository_impl.dart`
**Bug:** Gets group members for notification broadcast (line ~171).
**Fix:** Get event participants from `event_participants` table instead. Notifications should go to participants of the event, not group members.

### 3.4 `lib/features/home/data/data_sources/recent_memory_data_source.dart`
**Bug:** Queries `group_members` for user's group IDs, then calls `get_recent_memories_with_covers` RPC.
**Fix:** Rewrite to query `event_participants` → events with status 'recap'/'ended' + 30-day filter. RPC likely no longer exists.

### 3.5 `lib/features/memory/data/data_sources/memory_photo_data_source.dart`
**Bug:** Checks `group_members` membership before uploading photo (line ~60).
**Fix:** Check `event_participants` membership instead. Replace `.eq('group_id', groupId)` with `.eq('pevent_id', eventId)`.

---

## Phase 4: Fix `group_photos` → `event_photos` References

The DB table was renamed from `group_photos` to `event_photos` but code still uses old name.

### Files to update (in KEPT features only):

| File | Lines | Change |
|------|-------|--------|
| `lib/features/event/data/data_sources/event_photo_data_source.dart` | 60, 81, 144 | `.from('group_photos')` → `.from('event_photos')` |
| `lib/features/memory/data/data_sources/memory_data_source.dart` | 58 | `.from('group_photos')` → `.from('event_photos')` |
| `lib/features/memory/data/data_sources/memory_photo_data_source.dart` | 84, 118, 133, 143 | `.from('group_photos')` → `.from('event_photos')` |
| `lib/features/home/data/models/home_event_model.dart` | 161 | `.from('group_photos')` → `.from('event_photos')` |
| `lib/features/profile/data/data_sources/other_profile_data_source.dart` | 93, 110, 130 | `.from('group_photos')` → `.from('event_photos')` |

---

## Phase 5: Fix `group_id` References in Events

The `events` table no longer has a `group_id` column. Code that selects/filters by `group_id` will fail.

### Files to update:

| File | Issue |
|------|-------|
| `lib/features/event/data/data_sources/event_remote_data_source.dart` | Selects `group_id` (line 35), checks `group_id` (line 52), maps `group_id` (line 107) |
| `lib/features/event/data/models/event_detail_model.dart` | Parses `group_id` from JSON (line 51), serializes it (line 77) |
| `lib/features/memory/data/data_sources/memory_data_source.dart` | Selects `group_id` (line 31) |
| `lib/features/memory/data/data_sources/memory_photo_data_source.dart` | Selects `group_id` (line 44), checks group membership (lines 61-63) |
| `lib/features/memory/presentation/providers/manage_memory_providers.dart` | Selects `group_id` (line 174), uses it (line 178) |
| `lib/features/inbox/data/data_sources/notification_remote_data_source.dart` | Passes `p_group_id` (line 165) |
| `lib/features/inbox/data/models/notification_model.dart` | Parses `group_id` (lines 69, 99) |
| `lib/features/inbox/data/models/payment_debt_model.dart` | Parses `group_id` (line 65) |
| `lib/services/notification_service_old.dart` | Passes `p_group_id` (lines 35, 335) — check if file is used |

---

## Phase 6: Clean Leftover Files

### Check and remove if unused:
- `lib/services/notification_service_old.dart` — likely a dead file
- Any test files under `test/` referencing groups/expense/group_hub
- `lib/features/inbox/data/models/payment_debt_model.dart` — payments/expenses removed

---

## Execution Order (Safe Sequence)

1. **Phase 1**: Delete feature folders (`groups/`, `group_hub/`, `expense/`)
2. **Phase 2**: Clean all imports and references to deleted features
3. **Phase 4**: Fix `group_photos` → `event_photos` (quick find-replace, no logic change)
4. **Phase 5**: Fix `group_id` references (remove from selects/models)
5. **Phase 3**: Rewrite `group_members` → `event_participants` queries (logic changes)
6. **Phase 6**: Clean leftover files
7. **Verify**: `flutter analyze` to catch any remaining broken imports
8. **Test**: `flutter run` to verify no runtime errors

---

## Verification Checklist
- [ ] `grep -r "features/groups/" lib/` returns 0 results
- [ ] `grep -r "features/group_hub/" lib/` returns 0 results
- [ ] `grep -r "features/expense/" lib/` returns 0 results
- [ ] `grep -r "group_members" lib/` returns 0 results
- [ ] `grep -r "group_photos" lib/` returns 0 results (except comments)
- [ ] `grep -r "'group_id'" lib/` returns 0 results (except group_invites)
- [ ] `flutter analyze` passes with no errors
- [ ] Profile page loads without errors
- [ ] Home page loads without errors
- [ ] Event page loads without errors
- [ ] Memory viewer works
