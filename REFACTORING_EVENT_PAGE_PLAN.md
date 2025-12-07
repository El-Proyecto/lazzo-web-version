# Event Page Refactoring Plan

## Current State
- **File**: `lib/features/event/presentation/pages/event_page.dart`
- **Lines**: 1736 lines (too complex)
- **Issues**:
  - Build method has ~1400 lines of nested widgets
  - Difficult to navigate and maintain
  - Hard to test individual sections
  - Multiple levels of Consumer/AsyncValue nesting

## Proposed Structure

### Keep Existing
- State variables (`_addedToCalendar`, `_scrollController`, `_showTitleInAppBar`, `_cachedIsHost`)
- Lifecycle methods (`initState`, `dispose`, `_onScroll`)
- Helper methods (`_getUserDisplayName`, `_getUserVoteStatus`, `_showStatusChangeDialog`, etc.)
- Business logic methods (`_addToCalendar`, `_setEventDate`, `_setEventLocation`)

### New Private Widget Builder Methods

#### 1. `Widget _buildEventStatusSection(EventDetail event)`
**Purpose**: Event status chip with host management options  
**Lines**: ~365-430 (65 lines)  
**Contains**: Consumer with canManageEventProvider, EventStatusChip, caching logic

#### 2. `Widget _buildRsvpSection(EventDetail event, String? currentUserId)`
**Purpose**: RSVP widget with voting logic  
**Lines**: ~432-950 (518 lines!)  
**Contains**: Nested AsyncValues (rsvps, userRsvp, suggestions, locationSuggestions), vote counts, callbacks

#### 3. `Widget _buildDateTimeSuggestionsSection(EventDetail event, String? currentUserId, AsyncValue rsvpsAsync)`
**Purpose**: Date/time suggestions voting widget  
**Lines**: ~987-1140 (153 lines)  
**Contains**: Suggestions filtering, vote tracking, DateTimeSuggestionsWidget integration

#### 4. `Widget _buildLocationSuggestionsSection(EventDetail event, String? currentUserId, AsyncValue rsvpsAsync)`
**Purpose**: Location suggestions voting widget  
**Lines**: ~1142-1270 (128 lines)  
**Contains**: Location suggestions filtering, LocationSuggestionsWidget integration

#### 5. `Widget _buildChatPreviewSection(EventDetail event, String? currentUserId, List<ChatMessage> messages)`
**Purpose**: Chat preview with recent messages  
**Lines**: ~1272-1450 (178 lines)  
**Contains**: Message mapping, ChatPreviewWidget, navigation callbacks

#### 6. `Widget _buildExpensesSection(EventDetail event, String? currentUserId)`
**Purpose**: Event expenses widget  
**Lines**: ~1452-1500 (48 lines)  
**Contains**: Participants async, EventExpensesWidget integration

#### 7. `Widget _buildEventDetailsSection(EventDetail event)`
**Purpose**: Location + DateTime widgets  
**Lines**: ~1502-1538 (36 lines)  
**Contains**: LocationWidget, DateTimeWidget, conditional rendering

#### 8. `Widget _buildPollsSection(EventDetail event, String? currentUserId)`
**Purpose**: Polls display and voting  
**Lines**: ~1540-1574 (34 lines)  
**Contains**: PollWidget list, vote tracking

### Simplified build() Method (After Refactoring)

```dart
@override
Widget build(BuildContext context) {
  // Provider watches (keep as is)
  final currentUserId = ref.watch(currentUserIdProvider);
  final eventAsync = ref.watch(eventDetailProvider(eventId));
  final rsvpsAsync = ref.watch(eventRsvpsProvider(eventId));
  // ... other watches

  // Helper to refresh (keep as is)
  Future<void> refreshEventData() async { ... }

  final eventName = eventAsync.value?.name ?? '';

  return Scaffold(
    backgroundColor: BrandColors.bg1,
    appBar: CommonAppBar( ... ), // Keep as is
    body: eventAsync.when(
      data: (event) => RefreshIndicator(
        onRefresh: refreshEventData,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              // Event header
              EventHeader( ... ),
              const SizedBox(height: Gaps.md),

              // Extracted sections
              _buildEventStatusSection(event),
              _buildRsvpSection(event, currentUserId),
              _buildDateTimeSuggestionsSection(event, currentUserId, rsvpsAsync),
              _buildLocationSuggestionsSection(event, currentUserId, rsvpsAsync),
              
              // Chat Preview
              messagesAsync.when(
                data: (messages) => _buildChatPreviewSection(event, currentUserId, messages),
                loading: () => ...,
                error: (_, __) => ...,
              ),

              _buildExpensesSection(event, currentUserId),
              _buildEventDetailsSection(event),
              _buildPollsSection(event, currentUserId),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    ),
  );
}
```

## Benefits
1. **Readability**: build() method becomes ~150 lines instead of ~1400
2. **Maintainability**: Each section is self-contained and easy to locate
3. **Testability**: Can test individual sections in isolation
4. **Navigation**: Jump directly to `_buildRsvpSection` instead of line 432
5. **Debugging**: Easier to identify which section has issues
6. **Architecture**: Follows Flutter best practices for large pages

## Implementation Steps
1. Add 8 private methods at end of class (before closing brace)
2. Extract widget code from build() to respective methods
3. Update build() to call new methods
4. Test functionality (no behavior changes)
5. Run `flutter analyze` to ensure no errors

## Risks/Considerations
- **Context access**: All methods have `BuildContext` available via `context`
- **Ref access**: All methods have `WidgetRef` available via `ref`
- **State access**: All methods have access to instance variables
- **No breaking changes**: Pure refactoring, no functionality changes
- **Single commit**: All changes in one commit to avoid broken intermediate states

## Estimated Impact
- **Lines reduced in build()**: ~1250 lines → ~150 lines (89% reduction)
- **New methods added**: 8 methods (~1300 lines total, well-organized)
- **Total file size**: Similar (~1750 lines) but much more organized
- **Cognitive load**: Significantly reduced

## Alternative Considered
Creating separate widget files (EventStatusSection, EventRsvpSection, etc.) was considered but rejected because:
- These sections need access to page-level state and providers
- Would require passing many parameters
- Not truly reusable outside this page
- Private methods are simpler and sufficient

## Next Steps
Do you approve this refactoring plan? If yes, I'll proceed with implementation.
