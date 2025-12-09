# Remove Actions from MVP Migration

## Context
Actions feature was developed at P1 level (UI/presentation only) but won't be included in MVP. We need to **remove from UI** while **preserving components** for future use when P2 backend implementation is ready.

**Critical Rule:** Do NOT delete any widgets/components. Only remove their usage from MVP pages.

---

## Affected Features

### 1. Home Page - "To Dos" Section
**Current State:**
- Section displaying list of pending actions/todos
- Uses `TodoCard` component
- Provider: `todosControllerProvider`
- Located in: `lib/features/home/presentation/pages/home.dart`

**Changes Required:**
- Remove "To Dos" section from Home page UI
- Keep provider invalidations (no-op if not used)
- Preserve `TodoCard` in `shared/components/cards/`
- Preserve `todosControllerProvider` in providers (inactive)

**Files to Modify:**
- `/lib/features/home/presentation/pages/home.dart` - Remove section rendering

**Files to Preserve:**
- `/lib/shared/components/cards/todo_card.dart` - Keep component
- `/lib/features/home/presentation/providers/*` - Keep providers (future use)

---

### 2. Groups Page - Actions Logic
**Current State:**
- Groups display chip showing action count
- Separate tab/filter for groups with actions
- Visual indicator when group has pending actions
- Located in: `lib/features/groups/presentation/pages/groups_page.dart`

**Changes Required:**
- Remove actions chip from group cards
- Remove actions filter/separator logic
- Keep group card component structure
- Remove action count from UI

**Files to Modify:**
- `/lib/features/groups/presentation/pages/groups_page.dart` - Remove actions UI
- Group card widgets (if they show action counts)

**Files to Preserve:**
- All group-related components (just remove action-specific props)
- Group providers remain intact

---

### 3. Inbox Page - Actions Tab
**Current State:**
- Segmented control with 3 tabs: Notifications, Actions, Payments
- Actions tab shows pending group/event actions
- Located in: `lib/features/inbox/presentation/pages/inbox_page.dart`

**Changes Required:**
- Remove "Actions" tab from segmented control (2 tabs only)
- Update tab indexes: Notifications (0), Payments (1)
- Remove actions page content/widgets
- Update `inboxTabIndexProvider` logic

**Files to Modify:**
- `/lib/features/inbox/presentation/pages/inbox_page.dart` - Remove tab
- Segmented control tab list

**Files to Preserve:**
- Action-related widgets in inbox feature (future use)
- Action providers (inactive)

---

## Migration Steps

### Phase 1: Audit & Documentation
- [x] Identify all actions-related UI elements
- [x] Document component locations to preserve
- [x] List exact file modifications needed
- [x] Verify no backend dependencies exist (P1 only)

### Phase 2: Home Page Changes
- [x] Remove "To Dos" section from `home.dart`
- [x] Remove section rendering code
- [x] Keep provider watches (safe, returns empty)
- [x] Verify Home page still renders correctly
- [x] Test: Home loads without errors

### Phase 3: Groups Page Changes
- [x] Remove actions chip from group cards
- [x] Remove actions filter/separator logic
- [x] Remove action count displays
- [x] Verify groups list renders correctly
- [x] Test: Groups page loads, cards display properly

### Phase 4: Inbox Page Changes
- [x] Update segmented control from 3 to 2 tabs
- [x] Remove Actions tab (index 1)
- [x] Update tab indexes: Notifications (0), Payments (1)
- [x] Remove actions tab content
- [x] Update `inboxTabIndexProvider` initial value handling
- [x] Verify tab switching works correctly
- [x] Test: Inbox navigation between Notifications/Payments works

### Phase 5: Validation
- [x] Run `flutter analyze` - no errors
- [x] Test all modified pages manually
- [x] Verify no broken imports
- [x] Verify preserved components compile
- [x] Check no actions UI visible in MVP
- [x] Test navigation flows still work

### Phase 6: Cleanup Checks
- [x] No `print()` statements added
- [x] All tokens still used correctly
- [x] No breaking architecture changes
- [x] Components preserved in `shared/` and `features/*/presentation/widgets/`
- [x] Update this document with completion status

---

## Rollback Plan

If issues arise during migration:

1. **Git Reset:** All changes are in presentation layer only
   ```bash
   git checkout -- lib/features/home/presentation/pages/home.dart
   git checkout -- lib/features/groups/presentation/pages/groups_page.dart
   git checkout -- lib/features/inbox/presentation/pages/inbox_page.dart
   ```

2. **Verify Rollback:**
   - Run `flutter analyze`
   - Test all pages render
   - Verify actions visible again

3. **Debug Issues:**
   - Check for import errors
   - Verify provider names unchanged
   - Check tab index logic in Inbox

---

## Post-Migration State

**What Users See:**
- ✅ Home: Next event, confirmed events, pending events, payments, memories
- ✅ Groups: List of groups (no action indicators)
- ✅ Inbox: Notifications and Payments tabs only

**What's Preserved (for P2 implementation):**
- ✅ `TodoCard` component
- ✅ Actions-related providers (inactive)
- ✅ Actions widgets in inbox feature
- ✅ All domain/data layers for actions (if exist)

**Architecture Compliance:**
- ✅ No components deleted
- ✅ Only presentation layer modified
- ✅ Clean Architecture preserved
- ✅ DI/providers remain intact
- ✅ Future P2 work unblocked

---

## Future P2 Work

When backend is ready:
1. Uncomment/restore removed sections
2. Implement data layer (data sources, repositories)
3. Add DI overrides in `main.dart`
4. Connect providers to real data
5. Test actions end-to-end

**Components ready for P2:**
- TodoCard (shared component)
- Action providers (need data implementation)
- Inbox actions widgets (need wiring)

---

## Notes

- This is a **UI-only migration** (presentation layer)
- No backend/Supabase changes needed
- No domain layer changes needed
- Components preserved follow "move-don't-delete" principle
- Future re-enabling is straightforward

---

**Migration Status:** ✅ **COMPLETE** - All phases executed successfully

**Actual Time:** ~30 minutes

**Risk Level:** Low (presentation only, easily reversible)

---

## Implementation Summary

### Changes Made

**1. Home Page (`lib/features/home/presentation/pages/home.dart`)**
- ✅ Removed "To Dos" section rendering
- ✅ Commented out `TodoCard` import (preserved for P2)
- ✅ Commented out `todosAsync` watch (preserved for P2)
- ✅ Kept provider invalidations (no-op, safe for future)
- ✅ Added comments indicating MVP removal and P2 preservation

**2. Groups Page (`lib/features/groups/presentation/pages/groups_page.dart`)**
- ✅ Removed "Actions" filter chip
- ✅ Removed "Open Actions" menu item from context menu
- ✅ Commented out `_handleOpenActions()` method (preserved for P2)
- ✅ Kept `openActionsCount` property in Group entity (future use)
- ✅ Simplified filter logic (All/Archived only)

**3. Inbox Page (`lib/features/inbox/presentation/pages/inbox_page.dart`)**
- ✅ Updated `TabController` length from 3 to 2 tabs
- ✅ Removed "Actions" label from segmented control
- ✅ Removed Actions tab from `TabBarView`
- ✅ Commented out actions imports (preserved for P2)
- ✅ Commented out `_buildActionsTab()` method (preserved for P2)
- ✅ Tab indexes now: Notifications (0), Payments (1)

### Components Preserved (for P2 Implementation)

**Preserved Components:**
- ✅ `TodoCard` component (`shared/components/cards/todo_card.dart`)
- ✅ `ActionsSection` widget (`features/inbox/presentation/widgets/actions_section.dart`)
- ✅ Actions providers (`features/inbox/presentation/providers/actions_provider.dart`)
- ✅ Group entity with `openActionsCount` property

**Preserved Providers:**
- ✅ `todosControllerProvider` (Home feature - inactive)
- ✅ `actionsProvider` (Inbox feature - inactive)
- ✅ `completeActionUseCaseProvider` (Inbox feature - inactive)

### Architecture Compliance

- ✅ **Clean Architecture:** Only presentation layer modified
- ✅ **Component Preservation:** All widgets/components kept for P2
- ✅ **No Deletions:** Followed "move-don't-delete" principle
- ✅ **Tokens:** All existing tokens remain unchanged
- ✅ **No Breaking Changes:** Domain/Data layers untouched
- ✅ **Future-Ready:** Easy to re-enable when P2 backend is ready

### Testing Results

- ✅ `flutter analyze`: 0 errors, 0 warnings
- ✅ Home page renders without To Dos section
- ✅ Groups page shows All/Archived filters only
- ✅ Inbox page shows Notifications/Payments tabs only
- ✅ No broken imports
- ✅ No runtime errors
- ✅ Navigation flows work correctly

---

## Re-enabling Actions for P2

When backend is ready:

1. **Uncomment imports:**
   - `todo_card.dart` in home.dart
   - `actions_provider.dart` in inbox_page.dart
   - `actions_section.dart` in inbox_page.dart

2. **Uncomment watches:**
   - `todosAsync` in home.dart
   - Tab controller length back to 3 in inbox_page.dart

3. **Uncomment methods:**
   - `_buildActionsTab()` in inbox_page.dart
   - `_handleOpenActions()` in groups_page.dart

4. **Restore UI elements:**
   - To Dos section in home.dart
   - Actions filter chip in groups_page.dart
   - Actions tab in inbox_page.dart tab labels

5. **Implement P2:**
   - Add data sources for actions/todos
   - Implement repositories
   - Add DI overrides in main.dart
   - Connect providers to real data
   - Test end-to-end

**Estimated Re-enable Time:** 15-20 minutes
