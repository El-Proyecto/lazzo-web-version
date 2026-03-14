# Home Feature - P1 to P2 Handoff Document

**Date:** 2025-11-12  
**Feature:** Home (Main Dashboard)  
**P1 Developer:** AI Agent  
**P2 Developer:** TBD  

---

## 📋 **P1 DELIVERABLES SUMMARY**

### ✅ **Domain Layer (Contracts) - COMPLETE**
**Location**: `lib/features/home/domain/`

#### **Entities:**
1. **HomeEventEntity** (`entities/home_event.dart`)
   - Unified event model for next event, confirmed events, and pending events
   - Fields: id, name, emoji, date, location, status, goingCount, attendeeAvatars, attendeeNames, userVote, allVotes
   - Enum: `HomeEventStatus` (pending, confirmed, living, recap)

2. **TodoEntity** (`entities/todo_entity.dart`)
   - Action items for user
   - Fields: id, actionName, eventEmoji, eventName, groupName, deadline
   - Computed: timeLeft, isOverdue, deadlineText

3. **PaymentSummaryEntity** (`entities/payment_summary_entity.dart`)
   - Person and total amount owed/to receive
   - Fields: userId, userName, userPhotoUrl, amount, expenseCount, currency
   - Computed: isOwedToYou, youOwe, absoluteAmount, formattedAmount

4. **RecentMemoryEntity** (`entities/recent_memory_entity.dart`)
   - Memory from last 30 days
   - Fields: id, eventName, location, date, coverPhotoUrl
   - Computed: formattedDate, locationDateText

5. **MemorySummary** (`entities/memory_summary.dart`)
   - Last ready memory for recap card
   - Fields: eventId, title, emoji, createdAt

6. **RsvpVote** (`entities/rsvp_vote.dart`)
   - Individual vote for event RSVP
   - Fields: id, userId, userName, userAvatar, status, votedAt
   - Used by HomeEventEntity for allVotes

6. **ParticipantPhoto** (`entities/participant_photo.dart`)
   - Photo contribution tracking per user (Living/Recap states)
   - Fields: userId, userName, userAvatar, photoCount
   - Used by HomeEventEntity for participantPhotos list

7. **PendingEvent** (`entities/pending_event.dart`)
   - **Legacy entity** (kept for backwards compatibility)
   - Used by stacked pending events card
   - Fields: id, name, deadline, groupId, groupName

#### **Repository Interfaces:**
1. **HomeEventRepository** (`repositories/home_event_repository.dart`)
   ```dart
   Future<HomeEventEntity?> getNextEvent();
   Future<List<HomeEventEntity>> getConfirmedEvents();
   Future<List<HomeEventEntity>> getPendingEvents();
   ```

2. **TodoRepository** (`repositories/todo_repository.dart`)
   ```dart
   Future<List<TodoEntity>> getTodos();
   ```

3. **PaymentSummaryRepository** (`repositories/payment_summary_repository.dart`)
   ```dart
   Future<List<PaymentSummaryEntity>> getPaymentSummaries();
   Future<double> getTotalBalance();
   ```

4. **RecentMemoryRepository** (`repositories/recent_memory_repository.dart`)
   ```dart
   Future<List<RecentMemoryEntity>> getRecentMemories();
   ```

5. **MemoryRepository** (`repositories/memory_repository.dart`)
   ```dart
   Future<MemorySummary?> getLastReadyMemory(String userId);
   ```

6. **PendingEventRepository** (`repositories/pending_event_repository.dart`)
   - **Legacy interface** (kept for backwards compatibility)
   ```dart
   Future<List<PendingEvent>> getPendingEvents(String userId);
   Future<bool> voteOnEvent(String eventId, String userId, bool isYes);
   ```

#### **Use Cases:**
1. **GetNextEvent** - Fetch highest priority upcoming event
2. **GetConfirmedEvents** - Fetch all confirmed events
3. **GetHomePendingEvents** - Fetch pending events (home-specific)
4. **GetTodos** - Fetch user's pending to-dos
5. **GetPaymentSummaries** - Fetch payment summaries with all users
6. **GetTotalBalance** - Calculate total balance (sum of all amounts)
7. **GetRecentMemories** - Fetch memories from last 30 days
8. **GetLastMemory** - Get last ready memory for recap card
9. **GetPendingEvents** - **Legacy** (fetch pending events for stacked card)
10. **VoteOnEvent** - **Legacy** (vote on pending event)

---

### ✅ **Presentation Layer - COMPLETE**
**Location**: `lib/features/home/presentation/`

#### **Pages:**
- **HomePage** (`pages/home.dart`)
  - Main dashboard screen
  - Handles 3 empty states: no groups, no events, normal
  - Mock control: `FakeGroupRepository.mockNoGroups`, `FakeHomeEventRepository.mockEmptyState`
  - Sections: Search, Next Event, Confirmed Events, Pending Events, To Dos, Payments, Memories
  - Uses AsyncValue for all data fetching

#### **Providers** (`providers/`):
1. **home_event_providers.dart**
   - Repository providers: homeEventRepositoryProvider, todoRepositoryProvider, paymentSummaryRepositoryProvider, recentMemoryRepositoryProvider
   - Use case providers: getNextEventProvider, getConfirmedEventsProvider, getHomePendingEventsProvider, getTodosProvider, etc.
   - Controller providers (FutureProvider): nextEventControllerProvider, confirmedEventsControllerProvider, todosControllerProvider, etc.

2. **memory_providers.dart**
   - memoryRepositoryProvider (FakeMemoryRepository)
   - getLastMemoryProvider (use case)
   - lastMemoryControllerProvider (FutureProvider)

3. **pending_event_providers.dart** - **Legacy**
   - For stacked pending events card compatibility

4. **banner_provider.dart**
   - eventCreatedBannerProvider (StateProvider)
   - Controls success banner display

5. **home_data_provider.dart**
   - Combines multiple data sources for complex views

#### **Feature-Specific Widgets** (`widgets/`):
1. **NoGroupsYetCard** - Empty state when user has no groups
2. **NoUpcomingEventsCard** - Empty state when user has groups but no events
   - Group chip selector with scroll fade indicators
   - Close button to dismiss card
3. **Stacked pending events** - Legacy components (compact_vote_widget, stacked_pending_events_card, etc.)
4. **Vote buttons** - vote_button, voting_button, voted_button, voted_no_button, simple_vote_button
5. **MemorySummaryCard** - Last ready memory card
6. **Pending events section** - pending_event_widget, pending_events_section

---

### ✅ **Data Layer - FAKES IMPLEMENTED**
**Location**: `lib/features/home/data/fakes/`

#### **Fake Repositories:**
1. **FakeHomeEventRepository**
   - Mock control: `static String mockEmptyState = 'no-events'` (or 'normal')
   - Returns mock HomeEventEntity data
   - Implements: getNextEvent(), getConfirmedEvents(), getPendingEvents()
   - **IMPORTANT**: Hot Restart required after changing mockEmptyState

2. **FakeTodoRepository**
   - Returns 4 mock todos with deadlines
   - Depends on FakeHomeEventRepository.mockEmptyState
   - Returns empty list when mockEmptyState == 'no-events'

3. **FakePaymentSummaryRepository**
   - Returns 3 mock payment summaries
   - Implements: getPaymentSummaries(), getTotalBalance()

4. **FakeRecentMemoryRepository**
   - Returns 2 mock recent memories from last 30 days

5. **FakeMemoryRepository**
   - Returns 1 mock memory summary for recap card

6. **FakePendingEventRepository** - **Legacy**
   - For stacked pending events compatibility

**Photo System Mock Data:**
- Living state: 18 total photos, 30 max (6 participants × 5)
- Recap state: 12 total photos, 35 max (7 participants × 5)
- Photo counts distributed across participants (sorted by count)
- Formula: maxPhotos = max(20, participantCount × 5)

---

### ✅ **Shared Components Used** (Already Tokenized)
**Location**: `lib/shared/components/`

#### **Cards:**
- `home_event_card.dart` - Next event card with:
  - Status-based display (Pending/Confirmed/Living/Recap)
  - Time-left countdown for Living/Recap states
  - Photo count display: "X participants • Y/Z photos"
  - Tap to open PhotosBottomSheet (Living/Recap) or VotesBottomSheet (Pending/Confirmed)
- `event_small_card.dart` - Confirmed/pending event cards
- `todo_card.dart` - To-do action item card
- `payment_summary_card.dart` - Payment summary with user avatar
- `recent_memory_card.dart` - Memory card with cover photo

#### **Navigation:**
- `common_app_bar.dart` - Standard app bar

#### **Inputs:**
- `search_bar.dart` - Search input

#### **Sections:**
- `section_block.dart` - Section wrapper with title and "See all" link

#### **Widgets:**
- `rsvp_widget.dart` - RSVP vote status display
- `photos_bottom_sheet.dart` - Photo contributions bottom sheet:
  - Displays participant photo counts sorted descending
  - Shows "No photos yet" for zero photos
  - Custom header with title and total count
  - Used by Living/Recap states
- `votes_bottom_sheet.dart` - RSVP votes bottom sheet for Pending/Confirmed states

---

## 🎯 **DOMAIN CONTRACTS (STABLE - DO NOT CHANGE)**

### **Critical Entities:**

#### **HomeEventEntity**
```dart
class HomeEventEntity {
  final String id;
  final String name;
  final String emoji;
  final DateTime? date;
  final DateTime? endDate; // For Living/Recap time-left calculation
  final String? location;
  final HomeEventStatus status;
  final int goingCount;
  final List<String> attendeeAvatars;
  final List<String> attendeeNames;
  final bool? userVote; // true = going, false = not going, null = pending
  final List<RsvpVote> allVotes;
  final int photoCount; // Total photos uploaded (Living/Recap)
  final int maxPhotos; // Max photos allowed: max(20, 5 × participantCount)
  final List<ParticipantPhoto> participantPhotos; // Photo contributions per user
}

enum HomeEventStatus { pending, confirmed, living, recap }
```

#### **TodoEntity**
```dart
class TodoEntity {
  final String id;
  final String actionName;
  final String eventEmoji;
  final String eventName;
  final String groupName;
  final DateTime? deadline;
}
```

#### **PaymentSummaryEntity**
```dart
class PaymentSummaryEntity {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double amount; // Positive if they owe you, negative if you owe them
  final int expenseCount;
  final String currency;
}
```

#### **RecentMemoryEntity**
```dart
class RecentMemoryEntity {
  final String id;
  final String eventName;
  final String? location;
  final DateTime date;
  final String? coverPhotoUrl;
}
```

### **Repository Method Signatures (DO NOT CHANGE)**

```dart
// HomeEventRepository
Future<HomeEventEntity?> getNextEvent();
Future<List<HomeEventEntity>> getConfirmedEvents();
Future<List<HomeEventEntity>> getPendingEvents();

// TodoRepository
Future<List<TodoEntity>> getTodos();

// PaymentSummaryRepository
Future<List<PaymentSummaryEntity>> getPaymentSummaries();
Future<double> getTotalBalance();

// RecentMemoryRepository
Future<List<RecentMemoryEntity>> getRecentMemories();

// MemoryRepository
Future<MemorySummary?> getLastReadyMemory(String userId);
```

---

## 🚀 **P2 IMPLEMENTATION REQUIREMENTS**

### **Database Schema Mapping**

#### **Home Events (from events table + rsvps table + event_photos table)**
```sql
-- events table
SELECT 
  id,
  name,
  emoji,
  date,
  end_date, -- NEW: For Living/Recap time-left calculation
  location,
  status, -- 'pending' | 'confirmed' | 'living' | 'recap'
  group_id
FROM events
WHERE user_id = $userId OR id IN (
  SELECT event_id FROM event_members WHERE user_id = $userId
)

-- rsvps table
SELECT
  id,
  event_id,
  user_id,
  status, -- 'going' | 'not-going' | 'pending'
  voted_at
FROM rsvps
WHERE event_id IN (...)

-- event_photos table (NEW: For Living/Recap photo counts)
SELECT
  user_id,
  COUNT(*) as photo_count
FROM event_photos
WHERE event_id = $eventId
GROUP BY user_id
```

#### **To-Dos (from actions table)**
```sql
-- actions table
SELECT
  id,
  action_type, -- 'vote-date' | 'confirm-attendance' | 'add-photos' | 'vote-place'
  event_id,
  deadline,
  completed_at
FROM actions
WHERE user_id = $userId
  AND completed_at IS NULL
ORDER BY deadline ASC NULLS LAST
```

#### **Payment Summaries (from expenses table + expense_participants table)**
```sql
-- Aggregate expenses per user
SELECT
  user_id,
  SUM(amount_owed_to_current_user) as total_amount,
  COUNT(DISTINCT expense_id) as expense_count
FROM expense_participants
WHERE current_user_id = $userId
GROUP BY user_id
HAVING total_amount != 0
```

#### **Recent Memories (from memories table)**
```sql
-- memories table
SELECT
  id,
  event_id,
  event_name,
  location,
  date,
  cover_photo_url
FROM memories
WHERE user_id = $userId
  AND date >= NOW() - INTERVAL '30 days'
ORDER BY date DESC
```

### **Data Sources to Implement**
**Location**: `lib/features/home/data/data_sources/`

1. **HomeEventRemoteDataSource**
   - `fetchNextEvent(String userId)` - Query events with ORDER BY priority
   - `fetchConfirmedEvents(String userId)` - Filter status = 'confirmed'
   - `fetchPendingEvents(String userId)` - Filter status = 'pending'

2. **TodoRemoteDataSource**
   - `fetchTodos(String userId)` - Query actions where completed_at IS NULL

3. **PaymentSummaryRemoteDataSource**
   - `fetchPaymentSummaries(String userId)` - Aggregate expense_participants
   - `calculateTotalBalance(String userId)` - SUM of all amounts

4. **RecentMemoryRemoteDataSource**
   - `fetchRecentMemories(String userId)` - Query memories from last 30 days

5. **MemoryRemoteDataSource** (already exists in `lib/features/home/data/data_sources/memory_remote_data_source.dart`)
   - `fetchLastReady(String userId)` - Get last ready memory

### **DTO/Models to Create**
**Location**: `lib/features/home/data/models/`

1. **HomeEventModel** - Map Supabase row → HomeEventEntity
   - Handle rsvps aggregation (goingCount, attendeeAvatars, attendeeNames, userVote)
   - Parse allVotes from rsvps table
   - **NEW:** Calculate photoCount from event_photos aggregation
   - **NEW:** Calculate maxPhotos: max(20, goingCount × 5)
   - **NEW:** Build participantPhotos list from event_photos join with users table

2. **TodoModel** - Map actions row → TodoEntity
   - Extract event info from event_id foreign key
   - Map action_type to actionName

3. **PaymentSummaryModel** - Map aggregated query → PaymentSummaryEntity
   - Join with users table for userName, userPhotoUrl

4. **RecentMemoryModel** - Map memories row → RecentMemoryEntity

5. **MemorySummaryModel** (already exists in `lib/features/home/data/models/memory_summary_model.dart`)

### **Repository Implementations**
**Location**: `lib/features/home/data/repositories/`

1. **HomeEventRepositoryImpl**
   - Constructor: `HomeEventRepositoryImpl(this._dataSource)`
   - Implement all 3 methods from HomeEventRepository interface
   - Map models → entities

2. **TodoRepositoryImpl**
   - Constructor: `TodoRepositoryImpl(this._dataSource)`
   - Implement getTodos()

3. **PaymentSummaryRepositoryImpl**
   - Constructor: `PaymentSummaryRepositoryImpl(this._dataSource)`
   - Implement both methods

4. **RecentMemoryRepositoryImpl**
   - Constructor: `RecentMemoryRepositoryImpl(this._dataSource)`
   - Implement getRecentMemories()

5. **MemoryRepositoryImpl** (already exists in `lib/features/home/data/repositories/memory_repository_impl.dart`)

### **DI Override in main.dart**
**Location**: `lib/main.dart`

Add to `ProviderScope(overrides: [...])`

```dart
// HOME - Events
homeEventRepositoryProvider.overrideWith((ref) {
  final client = Supabase.instance.client;
  final dataSource = HomeEventRemoteDataSource(client);
  return HomeEventRepositoryImpl(dataSource);
}),

// HOME - To-Dos
todoRepositoryProvider.overrideWith((ref) {
  final client = Supabase.instance.client;
  final dataSource = TodoRemoteDataSource(client);
  return TodoRepositoryImpl(dataSource);
}),

// HOME - Payments
paymentSummaryRepositoryProvider.overrideWith((ref) {
  final client = Supabase.instance.client;
  final dataSource = PaymentSummaryRemoteDataSource(client);
  return PaymentSummaryRepositoryImpl(dataSource);
}),

// HOME - Recent Memories
recentMemoryRepositoryProvider.overrideWith((ref) {
  final client = Supabase.instance.client;
  final dataSource = RecentMemoryRemoteDataSource(client);
  return RecentMemoryRepositoryImpl(dataSource);
}),

// HOME - Last Memory (recap card)
memoryRepositoryProvider.overrideWith((ref) {
  final client = Supabase.instance.client;
  final dataSource = MemoryRemoteDataSource(client);
  return MemoryRepositoryImpl(dataSource);
}),
```

---

## 🔒 **RLS (Row-Level Security) Requirements**

### **Events Table**
```sql
-- Read: User is member or creator
CREATE POLICY "Users can view their events"
ON events FOR SELECT
USING (
  auth.uid() = user_id OR
  EXISTS (
    SELECT 1 FROM event_members
    WHERE event_id = events.id AND user_id = auth.uid()
  )
);
```

### **RSVPs Table**
```sql
-- Read: User can view RSVPs for events they're part of
CREATE POLICY "Users can view RSVPs for their events"
ON rsvps FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM events
    WHERE id = rsvps.event_id
      AND (user_id = auth.uid() OR id IN (
        SELECT event_id FROM event_members WHERE user_id = auth.uid()
      ))
  )
);
```

### **Actions Table**
```sql
-- Read: User can view their own actions
CREATE POLICY "Users can view their actions"
ON actions FOR SELECT
USING (auth.uid() = user_id);
```

### **Expenses Table**
```sql
-- Read: User can view expenses they're part of
CREATE POLICY "Users can view their expenses"
ON expenses FOR SELECT
USING (
  auth.uid() IN (
    SELECT user_id FROM expense_participants WHERE expense_id = expenses.id
  )
);
```

### **Memories Table**
```sql
-- Read: User can view memories from their events
CREATE POLICY "Users can view their memories"
ON memories FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM events
    WHERE id = memories.event_id
      AND (user_id = auth.uid() OR id IN (
        SELECT event_id FROM event_members WHERE user_id = auth.uid()
      ))
  )
);
```

---

## 📊 **Query Optimization Guidelines**

### **Indexes Required**
```sql
-- Events
CREATE INDEX idx_events_user_id ON events(user_id);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_date ON events(date);

-- Event Members
CREATE INDEX idx_event_members_user_id ON event_members(user_id);
CREATE INDEX idx_event_members_event_id ON event_members(event_id);

-- RSVPs
CREATE INDEX idx_rsvps_event_id ON rsvps(event_id);
CREATE INDEX idx_rsvps_user_id ON rsvps(user_id);

-- Actions
CREATE INDEX idx_actions_user_id_completed ON actions(user_id, completed_at);
CREATE INDEX idx_actions_deadline ON actions(deadline);

-- Memories
CREATE INDEX idx_memories_user_id_date ON memories(user_id, date DESC);
```

### **Query Performance**
- **Next Event**: Always use `ORDER BY priority DESC, date ASC LIMIT 1`
- **Confirmed Events**: Filter by status first, then date
- **To-Dos**: Always filter `completed_at IS NULL` first
- **Payment Summaries**: Use materialized view if aggregation is slow
- **Recent Memories**: Always use `date >= NOW() - INTERVAL '30 days'` with indexed column

---

## 🧪 **Testing Checklist for P2**

### **Data Layer Tests**
- [ ] HomeEventRemoteDataSource fetches correct events
- [ ] TodoRemoteDataSource respects completed_at filter
- [ ] PaymentSummaryRemoteDataSource aggregates correctly
- [ ] All models parse Supabase rows correctly
- [ ] All models convert to entities correctly

### **Repository Tests**
- [ ] HomeEventRepositoryImpl returns HomeEventEntity (not model)
- [ ] Error handling for network failures
- [ ] Empty list handling (no events, no todos, etc.)

### **Integration Tests**
- [ ] RLS policies enforce correct access
- [ ] Queries use indexes (check EXPLAIN ANALYZE)
- [ ] Performance: Next event query < 100ms
- [ ] Performance: Confirmed events query < 200ms

### **UI Tests**
- [ ] Empty states display correctly
- [ ] Loading states work
- [ ] Error states show appropriate messages
- [ ] Voting updates optimistically

---

## 📁 **File Structure**

```
lib/features/home/
├── domain/
│   ├── entities/
│   │   ├── home_event.dart ✅ (Updated with photo fields)
│   │   ├── participant_photo.dart ✅ (NEW)
│   │   ├── todo_entity.dart ✅
│   │   ├── payment_summary_entity.dart ✅
│   │   ├── recent_memory_entity.dart ✅
│   │   ├── memory_summary.dart ✅
│   │   ├── rsvp_vote.dart ✅
│   │   └── pending_event.dart ✅ (legacy)
│   ├── repositories/
│   │   ├── home_event_repository.dart ✅
│   │   ├── todo_repository.dart ✅
│   │   ├── payment_summary_repository.dart ✅
│   │   ├── recent_memory_repository.dart ✅
│   │   ├── memory_repository.dart ✅
│   │   └── pending_event_repository.dart ✅ (legacy)
│   └── usecases/
│       ├── get_next_event.dart ✅
│       ├── get_confirmed_events.dart ✅
│       ├── get_home_pending_events.dart ✅
│       ├── get_todos.dart ✅
│       ├── get_payment_summaries.dart ✅
│       ├── get_total_balance.dart ✅
│       ├── get_recent_memories.dart ✅
│       ├── get_last_memory.dart ✅
│       ├── get_pending_events.dart ✅ (legacy)
│       └── vote_on_event.dart ✅ (legacy)
├── data/
│   ├── data_sources/
│   │   ├── memory_remote_data_source.dart ✅ (existing)
│   │   ├── home_event_remote_data_source.dart ⏳ P2
│   │   ├── todo_remote_data_source.dart ⏳ P2
│   │   ├── payment_summary_remote_data_source.dart ⏳ P2
│   │   └── recent_memory_remote_data_source.dart ⏳ P2
│   ├── models/
│   │   ├── memory_summary_model.dart ✅ (existing)
│   │   ├── home_event_model.dart ⏳ P2
│   │   ├── todo_model.dart ⏳ P2
│   │   ├── payment_summary_model.dart ⏳ P2
│   │   └── recent_memory_model.dart ⏳ P2
│   ├── repositories/
│   │   ├── memory_repository_impl.dart ✅ (existing)
│   │   ├── home_event_repository_impl.dart ⏳ P2
│   │   ├── todo_repository_impl.dart ⏳ P2
│   │   ├── payment_summary_repository_impl.dart ⏳ P2
│   │   └── recent_memory_repository_impl.dart ⏳ P2
│   └── fakes/
│       ├── fake_home_event_repository.dart ✅
│       ├── fake_todo_repository.dart ✅
│       ├── fake_payment_summary_repository.dart ✅
│       ├── fake_recent_memory_repository.dart ✅
│       ├── fake_memory_repository.dart ✅
│       └── fake_pending_event_repository.dart ✅ (legacy)
└── presentation/
    ├── pages/
    │   └── home.dart ✅
    ├── providers/
    │   ├── home_event_providers.dart ✅
    │   ├── memory_providers.dart ✅
    │   ├── pending_event_providers.dart ✅ (legacy)
    │   ├── banner_provider.dart ✅
    │   └── home_data_provider.dart ✅
    └── widgets/
        ├── no_groups_yet_card.dart ✅
        ├── no_upcoming_events_card.dart ✅
        ├── memory_summary_card.dart ✅
        └── [legacy widgets] ✅
```

---

## 🔄 **Migration Notes**

### **Empty State Logic**
Home page has 3 states controlled by mock variables:

1. **No Groups** (`FakeGroupRepository.mockNoGroups = true`)
   - Shows `NoGroupsYetCard`
   - Hides all event sections

2. **No Events** (`FakeHomeEventRepository.mockEmptyState = 'no-events'`)
   - Shows `NoUpcomingEventsCard` with group selector
   - User can select group and create event

3. **Normal** (`mockEmptyState = 'normal'`)
   - Shows all event sections
   - Shows to-dos, payments, memories

**IMPORTANT**: After changing mock variables, you MUST do **Hot Restart** (not Hot Reload) for static variables to reset.

### **Legacy Components**
The following components are kept for backwards compatibility but should be phased out:

- `pending_event.dart` entity (replaced by HomeEventEntity)
- `pending_event_repository.dart` (replaced by HomeEventRepository)
- `get_pending_events.dart` use case (replaced by GetHomePendingEvents)
- `vote_on_event.dart` use case (voting should be in Event feature)
- Stacked pending events card and vote widgets (replaced by EventSmallCard)

**P2 can ignore these during Supabase implementation.**

---

## ⚠️ **CRITICAL NOTES FOR P2**

1. **DO NOT change domain contracts** (entities, repository interfaces) without syncing with P1
2. **RSVPs aggregation**: HomeEventEntity requires joining events + rsvps tables
3. **Photo system aggregation**: Requires joining event_photos table grouped by user_id
4. **Photo count formula**: maxPhotos = max(20, participantCount × 5)
5. **Time-left display**: Requires end_date field for Living/Recap states
6. **Payment summaries**: Complex aggregation - consider materialized view
7. **Mock control**: Remove mock control variables from fakes when implementing real repos
8. **Groups dependency**: Home depends on Groups feature for empty state logic
9. **User ID**: All queries must use authenticated user ID from Supabase auth
10. **Date filtering**: Use indexed columns for date range queries
11. **Error handling**: Return empty lists (not null) for no results scenarios

---

## ✅ **P1 Sign-Off Checklist**

- [x] All domain entities defined with correct fields
- [x] All repository interfaces defined with method signatures
- [x] All use cases implemented (thin wrappers)
- [x] All fake repositories implemented with realistic mock data
- [x] HomePage implemented with AsyncValue loading/error/success
- [x] All providers set up with correct DI
- [x] Empty states (no groups, no events) implemented
- [x] Mock control variables documented
- [x] Feature-specific widgets tokenized
- [x] Shared components properly imported
- [x] No Supabase imports in presentation/domain layers
- [x] `flutter analyze` passes (only 2 pre-existing warnings)
- [x] README.md guidelines followed
- [x] .agents/agents.md compliance verified

---

## 📞 **P1 Contact for Questions**

**Questions about:**
- Domain contracts → Clarify entity fields or repository methods
- UI behavior → Explain empty state logic or section rendering
- Mock data → Adjust fake repository responses

**Next Steps:**
1. P2 reviews this handoff document
2. P2 asks clarifying questions if needed
3. P2 implements data sources, models, and repository implementations
4. P2 adds DI overrides in main.dart
5. P2 tests with real Supabase data
6. P2 verifies RLS policies
7. Feature complete! 🎉

---

**P1 Role Complete ✅**  
**Ready for P2 Implementation 🚀**
