# Event Page Optimization Plan

## Context
`event_page.dart` is one of the most critical and complex pages in the app. Currently at 1473 lines with highly nested AsyncValue logic. About to add edge case handling and expanded logic for RSVP and suggestions widgets. **Need to optimize NOW before adding more complexity.**

## Current Problems

### 1. **Date/Time Suggestions Section** (Lines 373-538)
**Issues:**
- 4 levels of nested `.when()` (suggestionsAsync → suggestionVotesAsync → userSuggestionVotesAsync → rsvpsAsync.maybeWhen)
- Complex filtering logic inline (alternateSuggestions)
- Vote count calculation duplicated
- Manual mapping of entities to widget models
- ~165 lines of nested complexity

**Impact:** Hard to debug, test, and extend with edge cases

### 2. **Location Suggestions Section** (Lines 540-681)
**Issues:**
- 3 levels of nested `.when()` (locationSuggestionsAsync → locationVotesAsync → userLocationVotesAsync)
- Duplicate filtering logic (alternateLocationSuggestions)
- Same vote count calculation pattern as DateTime
- Empty `if (kDebugMode) {}` blocks (cleanup needed)
- ~141 lines of nested complexity

**Impact:** Almost identical structure to DateTime but can't reuse logic

### 3. **Chat Preview Section** (Lines 683-893)
**Issues:**
- Complex message mapping with nested conditionals
- Manual ChatMessagePreview creation (verbose)
- Duplicate error handling patterns
- Finding messages by content/timestamp (fragile)
- ~210 lines with tight coupling

**Impact:** Brittle message matching, hard to add features like reactions

### 4. **RSVP Section** (Already partially refactored)
**Issues:**
- Logic split between `_buildRsvpSection()` and inline checks
- `rsvpsAsync` still watched at top level and passed around
- Vote status calculation scattered across methods
- ~300 lines across multiple methods

**Impact:** Will get worse when adding edge cases (pending users, conflicts, etc.)

---

## Optimization Strategy

### Phase 1: Extract Data Processing Logic ✅ PRIORITY
**Goal:** Separate data transformation from UI building

#### 1.1 Create Data Processing Methods (in EventPage class)
```dart
// Process date/time suggestions with votes and filters
DateTimeSuggestionsData _processDateTimeSuggestions(
  List<Suggestion> suggestions,
  List<SuggestionVote> allVotes,
  Set<String> userVoteIds,
  EventDetail event,
  int goingCount,
  String? currentUserId,
) {
  // Returns: filtered suggestions, current event option, processed votes
}

// Process location suggestions with votes and filters  
LocationSuggestionsData _processLocationSuggestions(
  List<LocationSuggestion> suggestions,
  List<LocationSuggestionVote> allVotes,
  Set<String> userVoteIds,
  EventDetail event,
  int goingCount,
  String? currentUserId,
) {
  // Returns: filtered suggestions, has alternatives, processed votes
}

// Process chat messages into preview models
ChatPreviewData _processChatMessages(
  List<ChatMessage> messages,
  int unreadCount,
  String? currentUserId,
) {
  // Returns: preview list, message lookup map
}
```

#### 1.2 Create Data Classes (new file: `event_page_models.dart`)
```dart
class DateTimeSuggestionsData {
  final List<DateTimeSuggestion> suggestions;
  final bool hasAlternatives;
  final DateTimeSuggestion? currentEventOption;
}

class LocationSuggestionsData {
  final List<LocationSuggestion> suggestions;
  final bool hasAlternatives;
  final int currentEventGoingCount;
}

class ChatPreviewData {
  final List<ChatMessagePreview> previews;
  final Map<String, ChatMessage> messageMap; // For faster lookups
}
```

### Phase 2: Flatten AsyncValue Nesting ✅ PRIORITY
**Goal:** Reduce cognitive load and improve testability

#### 2.1 Use `AsyncValue.guard()` for combined states
```dart
// Instead of nested .when() chains:
final suggestionsDataAsync = ref.watch(
  dateTimeSuggestionsDataProvider(eventId)
); // Combines all async dependencies

// Provider handles the complexity:
final dateTimeSuggestionsDataProvider = FutureProvider.autoDispose.family<DateTimeSuggestionsData, String>(
  (ref, eventId) async {
    final suggestions = await ref.watch(eventSuggestionsProvider(eventId).future);
    final votes = await ref.watch(suggestionVotesProvider(eventId).future);
    final userVotes = await ref.watch(userSuggestionVotesProvider(eventId).future);
    final rsvps = await ref.watch(eventRsvpsProvider(eventId).future);
    
    return _processDateTimeSuggestions(...);
  },
);
```

#### 2.2 Benefits
- Single `.when()` in UI (3 states: loading/data/error)
- Data processing logic in pure functions (testable)
- No manual state coordination
- Clear dependency graph

### Phase 3: Extract UI Builder Methods ✅ MEDIUM PRIORITY
**Goal:** Keep build() clean and focused

```dart
Widget _buildDateTimeSuggestionsSection(
  DateTimeSuggestionsData data,
  EventDetail event,
  String? currentUserId,
);

Widget _buildLocationSuggestionsSection(
  LocationSuggestionsData data,
  EventDetail event,
  String? currentUserId,
);

Widget _buildChatPreviewSection(
  ChatPreviewData data,
  EventDetail event,
  String? currentUserId,
);
```

### Phase 4: Cleanup & Edge Case Foundation 🔄 AFTER OPTIMIZATION
**Goal:** Prepare for edge case additions

- Remove all empty `if (kDebugMode) {}` blocks
- Consolidate error states
- Add proper loading states for each section
- Document edge cases to handle next

---

## Implementation Order

### Step 1: Create Data Models File ⏱️ 5 min
- Create `event_page_models.dart`
- Define `DateTimeSuggestionsData`, `LocationSuggestionsData`, `ChatPreviewData`
- Export from appropriate location

### Step 2: Extract Data Processing Methods ⏱️ 20 min
- Add 3 private methods to EventPage
- Move all filtering/mapping/calculation logic
- Keep pure (no refs, no mutations)

### Step 3: Create Combined Providers ⏱️ 15 min
- `dateTimeSuggestionsDataProvider`
- `locationSuggestionsDataProvider` 
- `chatPreviewDataProvider`
- Add to `event_providers.dart`

### Step 4: Refactor UI to Use New Providers ⏱️ 30 min
- Replace nested `.when()` with single provider watch
- Update widget builders to use processed data
- Test functionality preserved

### Step 5: Extract UI Builder Methods ⏱️ 15 min
- Create `_build*Section()` methods
- Move widget composition logic
- Update `build()` to use methods

### Step 6: Cleanup ⏱️ 10 min
- Remove debug blocks
- Run `flutter analyze`
- Verify no regressions

**Total Time: ~95 minutes**

---

## Expected Results

### Before Optimization
```
build() method: ~600 lines
- 4-level nested .when() for DateTime (165 lines)
- 3-level nested .when() for Location (141 lines)  
- 2-level nested .when() for Chat (210 lines)
- Mixed data/UI logic everywhere
```

### After Optimization
```
build() method: ~150 lines
- Single .when() per section (3 states each)
- Data processing in pure functions (testable)
- UI builders focused on composition
- Clear separation of concerns

New structure:
- event_page_models.dart: 3 data classes (~60 lines)
- event_providers.dart: 3 combined providers (~90 lines)
- event_page.dart: 3 data processors + 3 UI builders (~400 lines)
- build() method: orchestration only (~150 lines)
```

### Maintainability Gains
- ✅ Easy to add edge cases (in data processors)
- ✅ Testable business logic (pure functions)
- ✅ Clear error boundaries (per provider)
- ✅ Reusable data processing
- ✅ Faster hot reload (less nested widgets)

---

## Risk Assessment

### Low Risk
- Data models are internal contracts
- Providers tested via existing UI
- No breaking changes to widgets

### Medium Risk
- Provider dependency coordination (use `.future` carefully)
- Cache invalidation (properly scoped providers)

### Mitigation
- Implement one section at a time
- Test after each step
- Keep old code commented until verified
- Use `autoDispose` for all new providers

---

## Success Criteria

- [ ] `build()` method under 200 lines
- [ ] No nesting deeper than 2 levels
- [ ] All data processing in pure functions
- [ ] Zero `if (kDebugMode) {}` empty blocks
- [ ] `flutter analyze` passes with 0 errors
- [ ] App functionality unchanged (manual test)
- [ ] Ready for edge case additions (documented)

---

## Next Steps After Optimization

1. **Add RSVP Edge Cases**
   - Pending users not counted
   - Conflict resolution UI
   - Optimistic updates with rollback

2. **Add Suggestions Edge Cases**
   - Duplicate detection
   - Date conflicts
   - Vote weight/priority

3. **Add Chat Edge Cases**
   - Message reactions
   - Thread support
   - Better error recovery

**This optimization makes those additions 3-5x easier.**
