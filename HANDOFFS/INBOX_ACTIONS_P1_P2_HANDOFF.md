# Inbox Actions Feature — P1 to P2 Handoff

**Feature:** Action items system with time-based priority and completion tracking  
**Status:** P1 Complete ✅ | Ready for P2 Implementation  
**Date:** October 3, 2025

---

## Summary

The actions system has been fully implemented for Role P1, including:
- ✅ Domain entities and repository contracts aligned with `notifications_catalog.md`
- ✅ Complete UI components with tokenized design
- ✅ State management with Riverpod providers  
- ✅ Fake repository with comprehensive test scenarios
- ✅ Time-based action sorting and deadline tracking
- ✅ Action completion and status management
- ✅ Deeplink navigation for action resolution

The system is **ready for Role P2** to implement Supabase data sources and real repository implementations.

---

## Domain Contracts (Stable - Do Not Change)

### ActionEntity
Located: `lib/features/inbox/domain/entities/action.dart`

**Required fields for UI:**
```dart
class ActionEntity {
  final String id;                      // Unique action identifier
  final String title;                   // Display title  
  final String description;             // Detailed description
  final ActionType type;                // Specific action type
  final ActionStatus status;            // pending, completed, overdue, cancelled
  final ActionPriority priority;        // low, medium, high, urgent
  final DateTime createdAt;             // Action creation timestamp
  final DateTime? dueDate;              // Action deadline (required for display)
  final String? groupId;                // Associated group
  final String? eventId;                // Associated event (required for deeplinks)
  final String? assigneeId;             // User responsible for action
  final String? eventEmoji;             // Event emoji for display
  final String? weekday;                // For vote deadlines - "closes {weekday}"
  final String? days;                   // For attendance - "{days}d left"
  final String? hours;                  // For uploads - "{hours}h left"
  final Map<String, dynamic>? metadata; // Additional action-specific data
}
```

**Enums (Based on notifications_catalog.md):**
```dart
enum ActionType {
  // Legacy types for compatibility
  vote, rsvp, payment, taskAssignment, eventPreparation,
  
  // New specific action types from catalog
  voteDate,           // action.vote.date - Vote a date · closes {weekday}
  votePlace,          // action.vote.place - Vote a place · closes {weekday}
  confirmAttendance,  // action.confirm.attendance - Confirm attendance · {days}d left
  completeDetails,    // action.complete.details - Complete event details (date/location)
  addPhotos,          // action.add.photos - Add photos · {hours}h left
}

enum ActionStatus { pending, completed, overdue, cancelled }
enum ActionPriority { low, medium, high, urgent }
```

**Key Properties:**
- `timeLeft` - Calculated time remaining until deadline
- `isOverdue` - Boolean indicating if deadline has passed
- `formattedDescription` - Standardized action descriptions
- `deadlineText` - Human-readable deadline display ("2d left", "5h left")
- `deeplink` - Generated navigation link based on action type

### Repository Interface (Implement in Data Layer)
Located: `lib/features/inbox/domain/repositories/action_repository.dart`

```dart
abstract class ActionRepository {
  // Get paginated actions with optional filters
  Future<List<ActionEntity>> getActions({
    int limit = 20,
    int offset = 0,
    String? groupId,
    String? eventId,
  });

  // Get actions sorted by time left (priority order)
  Future<List<ActionEntity>> getActionsByTimeLeft({
    int limit = 20,
    bool overdueFirst = true,
  });

  // Get single action by ID
  Future<ActionEntity?> getActionById(String id);

  // Mark action as completed
  Future<void> markAsCompleted(String id);

  // Update action status
  Future<void> updateActionStatus(String id, ActionStatus status);

  // Get count of pending actions for badge
  Future<int> getPendingCount();

  // Real-time action updates
  Stream<List<ActionEntity>> watchActions();
}
```

---

## Data Requirements for P2

### Supabase Schema Requirements

**Core actions table:**
```sql
CREATE TABLE actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  type action_type NOT NULL,
  status action_status NOT NULL DEFAULT 'pending',
  priority action_priority NOT NULL DEFAULT 'medium',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  due_date TIMESTAMPTZ, -- Required for most actions
  group_id UUID REFERENCES groups(id),
  event_id UUID NOT NULL REFERENCES events(id), -- Most actions are event-related
  assignee_id UUID NOT NULL REFERENCES auth.users(id),
  event_emoji TEXT,
  weekday TEXT, -- For vote actions
  days TEXT,    -- For attendance confirmation
  hours TEXT,   -- For photo uploads
  metadata JSONB -- Additional action-specific data
);
```

**Required indexes:**
```sql
CREATE INDEX idx_actions_assignee ON actions(assignee_id, status, due_date ASC);
CREATE INDEX idx_actions_event ON actions(event_id, status, created_at DESC);
CREATE INDEX idx_actions_group ON actions(group_id, status, created_at DESC);
CREATE INDEX idx_actions_due_date ON actions(due_date ASC) WHERE status = 'pending';
CREATE INDEX idx_actions_overdue ON actions(due_date, status) WHERE due_date < NOW() AND status = 'pending';
```

**Row Level Security (RLS):**
- Users can only see actions where they are `assignee_id`
- Users can only see actions from events they have access to
- Users can only see actions from groups they belong to
- Users can only update status on their own assigned actions

### Action Categories (From notifications_catalog.md)

**Vote Actions:**
- `voteDate`: "Vote a date · closes {weekday}" → `lazzo://event/{eventId}`
- `votePlace`: "Vote a place · closes {weekday}" → `lazzo://event/{eventId}`

**Event Actions:**
- `confirmAttendance`: "Confirm attendance · {days}d left" → `lazzo://event/{eventId}`
- `completeDetails`: "Complete event details (date/location)" → `lazzo://event/{eventId}`

**Upload Actions:**
- `addPhotos`: "Add photos · {hours}h left" → `lazzo://event/{eventId}/uploads`

### Data Source Implementation Path

1. **Create data source:** `lib/features/inbox/data/data_sources/action_remote_data_source.dart`
2. **Create models:** `lib/features/inbox/data/models/action_model.dart`
3. **Implement repository:** `lib/features/inbox/data/repositories/action_repository_impl.dart`
4. **Add DI override** in `main.dart`

---

## UI Components (Complete - No Changes Needed)

### Shared Components
- ✅ `InboxActionCard` - Main action display with priority and deadline
- ✅ `ActionsSection` - Section with time-sorted actions

### Key UI Features
- ✅ **Time-based sorting** - Overdue first, then by deadline proximity
- ✅ **Dynamic deadlines** - Real-time countdown display ("2d left", "5h left")
- ✅ **Priority indicators** - Visual priority levels and urgency
- ✅ **Event context** - Event emoji and name for action context
- ✅ **Completion actions** - Mark as completed functionality
- ✅ **Deeplink navigation** - Tap actions route to appropriate event/upload screens

### State Management (Complete)
- ✅ `ActionsController` - Manages action list with time-based sorting
- ✅ Filters out payment actions (handled in payments section)
- ✅ Only shows actions with deadlines
- ✅ All providers properly wired with fake repositories
- ✅ AsyncValue error/loading state handling

---

## Current DI Setup

**Provider location:** `lib/features/inbox/presentation/providers/actions_provider.dart`

```dart
// Repository provider - currently points to fake
final actionRepositoryProvider = Provider<ActionRepository>((ref) {
  return FakeActionRepository();
});
```

**Required P2 override in `main.dart`:**
```dart
// Action repo -> real (Supabase)
actionRepositoryProvider.overrideWith(
  (ref) => ActionRepositoryImpl(
    ActionRemoteDataSource(Supabase.instance.client),
  ),
),
```

---

## Fake Data Reference

The `FakeActionRepository` provides comprehensive test scenarios:
- ✅ All action types from catalog (vote, attendance, details, photos)
- ✅ Various priority levels and deadlines
- ✅ Overdue and upcoming actions
- ✅ Event associations with emojis
- ✅ Realistic time-based scenarios
- ✅ Complete metadata for each action type

**Test scenarios:** Date voting, place voting, attendance confirmation, event details completion, photo uploads with deadlines.

---

## Action Behavior Rules

### Time-based Display
- **Overdue actions** appear first (red indicators)
- **Actions by deadline** sorted ascending (most urgent first)
- **No deadline actions** filtered out (not shown in actions section)
- **Completed actions** removed from active list

### Deadline Formatting
- **Days remaining**: "3d left", "1d left"
- **Hours remaining**: "5h left", "1h left"  
- **Overdue**: "Overdue" (red text)
- **Due soon**: "Due soon" (< 1 hour remaining)

### Priority Levels
- **Urgent**: Red indicators, top priority
- **High**: Orange indicators, second priority
- **Medium**: Default blue indicators
- **Low**: Gray indicators, lowest priority

---

## Critical Notes for P2

### ⚠️ **DO NOT MODIFY:**
1. **ActionEntity fields** - UI depends on exact field structure
2. **Action type mapping** - Must match `notifications_catalog.md` exactly
3. **Repository method signatures** - Providers are already wired
4. **Enum values** - Used throughout UI for type-specific behavior
5. **Deeplink patterns** - Follow existing format: `lazzo://event/id` or `lazzo://event/id/uploads`

### ✅ **IMPLEMENT:**
1. **Supabase data source** with proper error handling
2. **DTO model** with JSON serialization  
3. **Repository implementation** calling data source
4. **RLS policies** for secure action access
5. **Real-time subscriptions** for live action updates
6. **Deadline calculations** server-side for accuracy
7. **Auto-cleanup** of expired actions (TTL logic)

### 🔧 **VALIDATION:**
1. Verify time-based sorting works correctly
2. Test deadline calculations and overdue detection
3. Ensure proper RLS with different user contexts
4. Validate action completion workflow
5. Test real-time updates for action status changes

---

## Testing Scenarios

1. **Vote actions** - Date and place voting with weekday deadlines
2. **Attendance actions** - RSVP confirmation with day countdown
3. **Event setup** - Complete missing event details
4. **Photo uploads** - Add photos with hour-based deadlines
5. **Overdue handling** - Actions past deadline with proper indicators
6. **Real-time updates** - Action completion and status changes
7. **Priority sorting** - Mixed priority actions with proper ordering

---

## Auto-cleanup Rules (For Implementation)

- **Upload actions**: Auto-remove when upload window closes
- **Vote actions**: Auto-remove when voting deadline passes
- **Event actions**: Auto-remove when event ends
- **Completed actions**: Archive but keep for analytics

---

## Definition of Done for P2

- [ ] Supabase schema created with proper RLS and indexes
- [ ] Data source implements all repository methods
- [ ] DTO model handles all ActionEntity fields including metadata
- [ ] Repository implementation passes integration tests
- [ ] DI override added to main.dart
- [ ] Real-time action updates working
- [ ] Time-based sorting and deadline calculations accurate
- [ ] Action completion workflow functional
- [ ] Deeplink navigation working for all action types
- [ ] Overdue detection and auto-cleanup implemented
- [ ] RLS policies tested with multiple users
- [ ] TTL logic for expired actions working

---

**Contact:** P1 implementation complete. Ready for P2 Supabase integration.