# Group Hub Feature - P1 to P2 Handoff Document

**Date:** October 21, 2025  
**From:** Role P1 (UI + State + Contracts)  
**To:** Role P2 (Data + Supabase)  
**Feature:** Group Hub (Events, Expenses, Memories)  

---

## ✅ **P1 DELIVERABLES COMPLETED**

All Role P1 responsibilities have been successfully implemented according to the Lazzo architecture guidelines. The group hub feature is fully functional with fake data including **Events**, **Expenses**, and **Memories** sections with proper sorting, shared components, and tokenized design. Ready for P2 to implement Supabase integration.

---

## 🏗️ **1. DOMAIN CONTRACTS DEFINED**

### **Group Event Entity** - `lib/features/group_hub/domain/entities/group_event_entity.dart`

Complete domain model representing group events with RSVP functionality:

```dart
class GroupEventEntity {
  final String id;
  final String name;
  final String emoji;
  final DateTime? date;
  final String? location;
  final GroupEventStatus status;
  final int goingCount;
  final List<String> attendeeAvatars;
  final List<String> attendeeNames;
  final bool? userVote; // true = going, false = not going, null = pending
  final List<RsvpVote> allVotes;
}

enum GroupEventStatus { 
  planning, confirmed, cancelled, completed 
}
```

### **Group Expense Entity** - `lib/features/group_hub/domain/entities/group_expense_entity.dart`

Domain model for group expense tracking:

```dart
class GroupExpenseEntity {
  final String id;
  final String description;
  final double amount;
  final String paidBy;
  final DateTime date;
  final bool isSettled;
}
```

### **Group Memory Entity** - `lib/features/group_hub/domain/entities/group_memory_entity.dart`

Domain model for group memories implementing MemoryData interface for shared components:

```dart
class GroupMemoryEntity implements MemoryData {
  final String id;
  final String title;
  final String? location;
  final DateTime date;
  final String coverImageUrl;
  final int photoCount;

  // MemoryData interface implementation
  String get memoryId => id;
  String get memoryTitle => title;
  String? get memoryCoverPhotoUrl => coverImageUrl;
  DateTime get memoryCreatedAt => date;
  int get memoryPhotoCount => photoCount;
}
```

### **Expense Participant Entity** - `lib/features/group_hub/domain/entities/expense_participant_entity.dart`

Supporting entity for expense details:

```dart
class ExpenseParticipant {
  final String id;
  final String name;
  final double amount;
  final bool hasPaid;
}
```

**Key Features:**
- Immutable data classes with `copyWith()` methods
- RSVP vote tracking for events
- Payment status tracking for expenses
- Photo count and cover images for memories
- Interface compatibility with shared components

---

## 🔄 **2. REPOSITORY INTERFACES DEFINED**

### **Group Event Repository** - `lib/features/group_hub/domain/repositories/group_event_repository.dart`

```dart
abstract class GroupEventRepository {
  /// Get all events for a specific group
  Future<List<GroupEventEntity>> getGroupEvents(String groupId);

  /// Get a single event by ID
  Future<GroupEventEntity?> getEventById(String eventId);
}
```

### **Group Expense Repository** - `lib/features/group_hub/domain/repositories/group_expense_repository.dart`

```dart
abstract class GroupExpenseRepository {
  /// Get all expenses for a specific group
  Future<List<GroupExpenseEntity>> getGroupExpenses(String groupId);

  /// Get a single expense by ID
  Future<GroupExpenseEntity?> getExpenseById(String expenseId);
}
```

### **Group Memory Repository** - `lib/features/group_hub/domain/repositories/group_memory_repository.dart`

```dart
abstract class GroupMemoryRepository {
  /// Get all memories for a specific group
  Future<List<GroupMemoryEntity>> getGroupMemories(String groupId);

  /// Get a single memory by ID
  Future<GroupMemoryEntity?> getMemoryById(String memoryId);
}
```

**Contract Requirements:**
- All methods are asynchronous with Future return types
- Repository methods follow consistent naming conventions
- Entities are returned instead of DTOs
- Group-scoped data access patterns

---

## 🎯 **3. USE CASES IMPLEMENTED**

### **Get Group Events** - `lib/features/group_hub/domain/usecases/get_group_events.dart`

```dart
class GetGroupEvents {
  final GroupEventRepository _repository;

  GetGroupEvents(this._repository);

  Future<List<GroupEventEntity>> call(String groupId) async {
    return await _repository.getGroupEvents(groupId);
  }
}
```

### **Get Group Expenses** - `lib/features/group_hub/domain/usecases/get_group_expenses.dart`

```dart
class GetGroupExpenses {
  final GroupExpenseRepository _repository;

  GetGroupExpenses(this._repository);

  Future<List<GroupExpenseEntity>> call(String groupId) async {
    return await _repository.getGroupExpenses(groupId);
  }
}
```

### **Get Group Memories** - `lib/features/group_hub/domain/usecases/get_group_memories.dart`

```dart
class GetGroupMemories {
  final GroupMemoryRepository _repository;

  GetGroupMemories(this._repository);

  Future<List<GroupMemoryEntity>> call(String groupId) async {
    return await _repository.getGroupMemories(groupId);
  }
}
```

**Use Case Features:**
- Single responsibility per class
- Repository dependency injection
- Consistent call() method pattern
- Group ID parameter validation

---

## 🎨 **4. SHARED COMPONENTS CREATED**

### **Generic Memories Section** - `lib/shared/components/sections/memories_section.dart`

Reusable component for displaying memories with generic MemoryData interface:

```dart
class MemoriesSection<T extends MemoryData> extends StatelessWidget {
  final List<T> memories;
  final String title;
  final Function(T)? onMemoryTap;
  final bool enableScroll;

  // Features:
  // - Generic interface supporting multiple memory types
  // - Scrollable grid layout with spacing
  // - Empty state handling
  // - Bottom padding for scroll areas
  // - Tokenized design system compliance
}

abstract class MemoryData {
  String get memoryId;
  String get memoryTitle;
  String? get memoryCoverPhotoUrl;
  DateTime get memoryCreatedAt;
  int get memoryPhotoCount;
}
```

### **Group Expense Card** - `lib/features/group_hub/presentation/widgets/group_expense_card.dart`

Feature-specific widget for expense display:

```dart
class GroupExpenseCard extends StatelessWidget {
  final GroupExpenseEntity expense;
  final String eventName;
  final double userAmount;
  final double totalAmount;
  final bool isOwedToUser;
  final String paymentStatus;
  final VoidCallback? onTap;

  // Features:
  // - Payment status indicators (Paid, Settled, Active)
  // - Amount formatting and currency display
  // - Debt/credit visual indicators
  // - Tokenized colors and spacing
}
```

**Component Features:**
- All components use design tokens (no hardcoded values)
- Shared components exported in `components.dart`
- Responsive design with proper touch targets
- Empty state handling
- Loading state compatibility

---

## 🔧 **5. PRESENTATION LAYER (PAGES & STATE)**

### **Group Hub Page** - `lib/features/group_hub/presentation/pages/group_hub_page.dart`

Main page with three-tab interface:

```dart
class GroupHubPage extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupPhotoUrl;
  final int memberCount;

  // Features:
  // - Three tabs: Events, Expenses, Memories
  // - Group info header with photo and member count
  // - Segmented control navigation
  // - AsyncValue state handling for all sections
  // - Smart expense sorting (Active → Paid → Settled)
  // - Scrollable memories with shared component
}
```

### **State Management** - `lib/features/group_hub/presentation/providers/group_hub_providers.dart`

Complete Riverpod provider setup:

```dart
// Repository providers (default to fake implementations)
final groupEventRepositoryProvider = Provider<GroupEventRepository>((ref) {
  return FakeGroupEventRepository();
});

final groupExpenseRepositoryProvider = Provider<GroupExpenseRepository>((ref) {
  return FakeGroupExpenseRepository();
});

final groupMemoryRepositoryProvider = Provider<GroupMemoryRepository>((ref) {
  return FakeGroupMemoryRepository();
});

// Use case providers
final getGroupEventsUseCaseProvider = Provider<GetGroupEvents>((ref) {
  return GetGroupEvents(ref.watch(groupEventRepositoryProvider));
});

// State providers with StateNotifierProvider.family
final groupEventsProvider = StateNotifierProvider.family<GroupEventsController,
    AsyncValue<List<GroupEventEntity>>, String>((ref, groupId) {
  return GroupEventsController(
    ref.watch(getGroupEventsUseCaseProvider),
    groupId,
  );
});
```

**State Features:**
- AsyncValue for loading/error/success states
- Family providers for group-specific data
- State controllers for each section
- Automatic refresh and invalidation
- Repository dependency injection

---

## 📊 **6. FAKE DATA IMPLEMENTATIONS**

### **Events Fake Data** - `lib/features/group_hub/data/fakes/fake_group_event_repository.dart`

7 mock events with varied statuses and RSVP data:

```dart
final List<GroupEventEntity> _events = [
  GroupEventEntity(
    id: '1',
    name: 'Beach Day',
    emoji: '🏖️',
    date: DateTime.now().add(const Duration(days: 3)),
    location: 'Cascais Beach',
    status: GroupEventStatus.confirmed,
    goingCount: 5,
    attendeeAvatars: [...],
    userVote: true,
    allVotes: [...],
  ),
  // ... 6 more events with different statuses
];
```

### **Expenses Fake Data** - `lib/features/group_hub/data/fakes/fake_group_expense_repository.dart`

6 mock expenses with different payment statuses:

```dart
final List<GroupExpenseEntity> _expenses = [
  GroupExpenseEntity(
    id: '1',
    description: 'Dinner at Restaurant',
    amount: 120.50,
    paidBy: 'Marco',
    date: DateTime.now().subtract(const Duration(days: 1)),
    isSettled: false,
  ),
  // ... 5 more expenses with varied settlement status
];
```

### **Memories Fake Data** - `lib/features/group_hub/data/fakes/fake_group_memory_repository.dart`

7 mock memories with realistic data:

```dart
final List<GroupMemoryEntity> _memories = [
  GroupMemoryEntity(
    id: 'memory_1',
    title: 'Beach Day Vibes',
    location: 'Cascais',
    date: DateTime(2025, 10, 15),
    coverImageUrl: 'https://picsum.photos/300/300?random=101',
    photoCount: 24,
  ),
  // ... 6 more memories with varied locations and dates
];
```

**Fake Data Features:**
- Realistic mock data with varied statuses
- Network delay simulation (500ms)
- Proper interface implementation
- Different user payment states for expenses
- Comprehensive RSVP scenarios for events

---

## 🎯 **7. BUSINESS LOGIC IMPLEMENTED**

### **Smart Expense Sorting**

Expenses are sorted with priority logic:
1. **Active expenses** (neither Paid nor Settled) - shown first
2. **Paid expenses** - shown in middle
3. **Settled expenses** - shown last
4. Within each group: **most recent first**

```dart
final sortedExpenses = List<GroupExpenseEntity>.from(expenses)
  ..sort((a, b) {
    final statusA = _getPaymentStatus(a);
    final statusB = _getPaymentStatus(b);
    
    int getPriority(String status) {
      switch (status) {
        case 'Settled': return 2;
        case 'Paid': return 1;
        default: return 0; // Active
      }
    }
    
    final priorityA = getPriority(statusA);
    final priorityB = getPriority(statusB);
    
    if (priorityA != priorityB) {
      return priorityA.compareTo(priorityB);
    }
    
    return b.date.compareTo(a.date); // Most recent first
  });
```

### **Payment Status Logic**

```dart
String _getPaymentStatus(GroupExpenseEntity expense) {
  if (expense.isSettled) return 'Settled';
  
  final currentUserParticipant = _expenseParticipants[expense.id]
    ?.firstWhere((p) => p.id == 'current_user');
  
  if (currentUserParticipant?.hasPaid == true) return 'Paid';
  
  return ''; // Active - show amount instead
}
```

### **UI State Handling**

Each section handles AsyncValue states:
- **Loading**: Circular progress indicator
- **Error**: Error message with retry button
- **Empty**: Custom empty state per section
- **Success**: Data display with proper sorting

---

## 📁 **FILE STRUCTURE REFERENCE**

```
lib/features/group_hub/
├── domain/
│   ├── entities/
│   │   ├── group_event_entity.dart ✅
│   │   ├── group_expense_entity.dart ✅
│   │   ├── group_memory_entity.dart ✅
│   │   └── expense_participant_entity.dart ✅
│   ├── repositories/
│   │   ├── group_event_repository.dart ✅
│   │   ├── group_expense_repository.dart ✅
│   │   └── group_memory_repository.dart ✅
│   └── usecases/
│       ├── get_group_events.dart ✅
│       ├── get_group_expenses.dart ✅
│       └── get_group_memories.dart ✅
├── data/
│   ├── data_sources/
│   │   ├── group_event_data_source.dart ❌ (P2)
│   │   ├── group_expense_data_source.dart ❌ (P2)
│   │   └── group_memory_data_source.dart ❌ (P2)
│   ├── models/
│   │   ├── group_event_model.dart ❌ (P2)
│   │   ├── group_expense_model.dart ❌ (P2)
│   │   └── group_memory_model.dart ❌ (P2)
│   ├── repositories/
│   │   ├── group_event_repository_impl.dart ❌ (P2)
│   │   ├── group_expense_repository_impl.dart ❌ (P2)
│   │   └── group_memory_repository_impl.dart ❌ (P2)
│   └── fakes/
│       ├── fake_group_event_repository.dart ✅
│       ├── fake_group_expense_repository.dart ✅
│       └── fake_group_memory_repository.dart ✅
└── presentation/
    ├── pages/
    │   └── group_hub_page.dart ✅
    ├── providers/
    │   └── group_hub_providers.dart ✅
    └── widgets/
        ├── group_expense_card.dart ✅
        ├── expense_detail_bottom_sheet.dart ✅
        └── group_expenses_section.dart ✅

lib/shared/components/
├── sections/
│   └── memories_section.dart ✅ (Generic MemoryData interface)
└── components.dart ✅ (Updated exports)
```

**Delivery Status:**
- ✅ **P1 Complete**: All domain contracts, fake implementations, UI, and state management
- ❌ **P2 Pending**: Supabase data sources, DTOs, and repository implementations

---

## 🔧 **P2 IMPLEMENTATION REQUIREMENTS**

### **1. Supabase Schema Requirements**

#### **Events Table** - `group_events`
```sql
CREATE TABLE group_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  emoji TEXT DEFAULT '📅',
  date TIMESTAMPTZ,
  location TEXT,
  status TEXT DEFAULT 'planning' CHECK (status IN ('planning', 'confirmed', 'cancelled', 'completed')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES profiles(id),
  
  -- RLS policies needed for group members only
);

-- Index for performance
CREATE INDEX idx_group_events_group_id_date ON group_events(group_id, date DESC);
```

#### **Event RSVP Table** - `event_rsvps`
```sql
CREATE TABLE event_rsvps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES group_events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  vote BOOLEAN, -- true = going, false = not going, null = pending
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(event_id, user_id)
);
```

#### **Expenses Table** - `group_expenses`
```sql
CREATE TABLE group_expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  paid_by UUID REFERENCES profiles(id),
  date TIMESTAMPTZ DEFAULT NOW(),
  is_settled BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- RLS policies needed for group members only
);

-- Index for performance
CREATE INDEX idx_group_expenses_group_id_date ON group_expenses(group_id, date DESC);
```

#### **Expense Participants Table** - `expense_participants`
```sql
CREATE TABLE expense_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  expense_id UUID REFERENCES group_expenses(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  has_paid BOOLEAN DEFAULT FALSE,
  
  UNIQUE(expense_id, user_id)
);
```

#### **Memories Table** - `group_memories`
```sql
CREATE TABLE group_memories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  location TEXT,
  date TIMESTAMPTZ NOT NULL,
  cover_image_url TEXT,
  photo_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES profiles(id),
  
  -- RLS policies needed for group members only
);

-- Index for performance
CREATE INDEX idx_group_memories_group_id_date ON group_memories(group_id, date DESC);
```

### **2. Data Sources**

#### **Group Event Data Source** - `lib/features/group_hub/data/data_sources/group_event_data_source.dart`

```dart
abstract class GroupEventDataSource {
  Future<List<Map<String, dynamic>>> getGroupEvents(String groupId);
  Future<Map<String, dynamic>?> getEventById(String eventId);
  Future<List<Map<String, dynamic>>> getEventRsvps(String eventId);
}

class SupabaseGroupEventDataSource implements GroupEventDataSource {
  final SupabaseClient _client;
  
  SupabaseGroupEventDataSource(this._client);
  
  @override
  Future<List<Map<String, dynamic>>> getGroupEvents(String groupId) async {
    final response = await _client
        .from('group_events')
        .select('''
          id, name, emoji, date, location, status, created_at,
          event_rsvps(user_id, vote)
        ''')
        .eq('group_id', groupId)
        .order('date', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }
}
```

#### **Group Expense Data Source** - `lib/features/group_hub/data/data_sources/group_expense_data_source.dart`

```dart
abstract class GroupExpenseDataSource {
  Future<List<Map<String, dynamic>>> getGroupExpenses(String groupId);
  Future<Map<String, dynamic>?> getExpenseById(String expenseId);
  Future<List<Map<String, dynamic>>> getExpenseParticipants(String expenseId);
}

class SupabaseGroupExpenseDataSource implements GroupExpenseDataSource {
  final SupabaseClient _client;
  
  @override
  Future<List<Map<String, dynamic>>> getGroupExpenses(String groupId) async {
    final response = await _client
        .from('group_expenses')
        .select('''
          id, description, amount, paid_by, date, is_settled,
          expense_participants(user_id, amount, has_paid),
          paid_by_profile:profiles!paid_by(name)
        ''')
        .eq('group_id', groupId)
        .order('date', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }
}
```

#### **Group Memory Data Source** - `lib/features/group_hub/data/data_sources/group_memory_data_source.dart`

```dart
abstract class GroupMemoryDataSource {
  Future<List<Map<String, dynamic>>> getGroupMemories(String groupId);
  Future<Map<String, dynamic>?> getMemoryById(String memoryId);
}

class SupabaseGroupMemoryDataSource implements GroupMemoryDataSource {
  final SupabaseClient _client;
  
  @override
  Future<List<Map<String, dynamic>>> getGroupMemories(String groupId) async {
    final response = await _client
        .from('group_memories')
        .select('id, title, location, date, cover_image_url, photo_count')
        .eq('group_id', groupId)
        .order('date', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }
}
```

### **3. Data Models (DTOs)**

#### **Group Event Model** - `lib/features/group_hub/data/models/group_event_model.dart`

```dart
class GroupEventModel {
  static GroupEventEntity fromJson(Map<String, dynamic> json) {
    // Parse event_rsvps to calculate going count and user vote
    final rsvps = (json['event_rsvps'] as List<dynamic>?)
        ?.map((rsvp) => RsvpVote.fromJson(rsvp))
        .toList() ?? [];
    
    final goingCount = rsvps.where((rsvp) => rsvp.vote == true).length;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final userVote = rsvps
        .firstWhere((rsvp) => rsvp.userId == currentUserId, orElse: () => null)
        ?.vote;
    
    return GroupEventEntity(
      id: json['id'],
      name: json['name'] ?? '',
      emoji: json['emoji'] ?? '📅',
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      location: json['location'],
      status: _parseStatus(json['status']),
      goingCount: goingCount,
      attendeeAvatars: [], // Fetch separately if needed
      attendeeNames: [], // Fetch separately if needed
      userVote: userVote,
      allVotes: rsvps,
    );
  }
  
  static GroupEventStatus _parseStatus(String? status) {
    switch (status) {
      case 'planning': return GroupEventStatus.planning;
      case 'confirmed': return GroupEventStatus.confirmed;
      case 'cancelled': return GroupEventStatus.cancelled;
      case 'completed': return GroupEventStatus.completed;
      default: return GroupEventStatus.planning;
    }
  }
}
```

#### **Group Expense Model** - `lib/features/group_hub/data/models/group_expense_model.dart`

```dart
class GroupExpenseModel {
  static GroupExpenseEntity fromJson(Map<String, dynamic> json) {
    return GroupExpenseEntity(
      id: json['id'],
      description: json['description'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paidBy: json['paid_by_profile']?['name'] ?? 'Unknown',
      date: json['date'] != null 
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      isSettled: json['is_settled'] ?? false,
    );
  }
}
```

#### **Group Memory Model** - `lib/features/group_hub/data/models/group_memory_model.dart`

```dart
class GroupMemoryModel {
  static GroupMemoryEntity fromJson(Map<String, dynamic> json) {
    return GroupMemoryEntity(
      id: json['id'],
      title: json['title'] ?? '',
      location: json['location'],
      date: json['date'] != null 
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      coverImageUrl: json['cover_image_url'] ?? '',
      photoCount: json['photo_count'] ?? 0,
    );
  }
}
```

### **4. Repository Implementations**

#### **Group Event Repository Implementation**

```dart
class GroupEventRepositoryImpl implements GroupEventRepository {
  final GroupEventDataSource _dataSource;
  
  GroupEventRepositoryImpl(this._dataSource);
  
  @override
  Future<List<GroupEventEntity>> getGroupEvents(String groupId) async {
    try {
      final data = await _dataSource.getGroupEvents(groupId);
      return data.map((json) => GroupEventModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch group events: $e');
    }
  }
  
  @override
  Future<GroupEventEntity?> getEventById(String eventId) async {
    try {
      final data = await _dataSource.getEventById(eventId);
      return data != null ? GroupEventModel.fromJson(data) : null;
    } catch (e) {
      throw Exception('Failed to fetch event: $e');
    }
  }
}
```

### **5. Provider Overrides for main.dart**

Add these overrides to `main.dart` ProviderScope:

```dart
// GROUP HUB repositories -> real (Supabase) 
groupEventRepositoryProvider.overrideWith((ref) {
  final client = Supabase.instance.client;
  final dataSource = SupabaseGroupEventDataSource(client);
  return GroupEventRepositoryImpl(dataSource);
}),

groupExpenseRepositoryProvider.overrideWith((ref) {
  final client = Supabase.instance.client;
  final dataSource = SupabaseGroupExpenseDataSource(client);
  return GroupExpenseRepositoryImpl(dataSource);
}),

groupMemoryRepositoryProvider.overrideWith((ref) {
  final client = Supabase.instance.client;
  final dataSource = SupabaseGroupMemoryDataSource(client);
  return GroupMemoryRepositoryImpl(dataSource);
}),
```

---

## ⚠️ **CRITICAL P2 REQUIREMENTS**

### **1. RLS (Row Level Security)**
- All tables MUST have RLS policies restricting access to group members only
- Use group membership validation in policies
- Test with different user contexts

### **2. Performance Considerations**
- Use provided indexes for date-based queries
- Implement pagination for large datasets (LIMIT/OFFSET)
- Consider caching for frequently accessed data

### **3. Error Handling**
- Implement proper exception handling in data sources
- Use consistent error types across repository implementations
- Handle network failures and timeouts gracefully

### **4. Data Consistency**
- Ensure expense participants sum matches expense amount
- Validate RSVP uniqueness per user per event
- Handle concurrent modifications appropriately

### **5. Testing Requirements**
- Unit tests for all DTOs and repository implementations
- Integration tests for Supabase data sources
- Test RLS policies with different user contexts

---

## 🚀 **POST-IMPLEMENTATION VALIDATION**

After P2 implementation, verify:

1. **Data Flow**: UI → Provider → Use Case → Repository → Data Source → Supabase
2. **RLS Security**: Only group members can access group data
3. **Performance**: Queries use indexes and return quickly
4. **Error States**: Network errors are handled gracefully in UI
5. **Sorting Logic**: Expenses maintain proper status-based ordering
6. **Memory Interface**: Memories display correctly with shared component

---

## 📝 **SUMMARY**

### **P1 Deliverables Complete:**
- ✅ 4 Domain entities with proper relationships
- ✅ 3 Repository interfaces with clear contracts  
- ✅ 3 Use cases with single responsibilities
- ✅ Complete UI with tokenized design system
- ✅ Generic shared components (MemoriesSection)
- ✅ Comprehensive fake data (21 total mock items)
- ✅ Smart sorting algorithms (expense priority)
- ✅ Full state management with AsyncValue
- ✅ Feature-specific widgets and bottom sheets
- ✅ Error, loading, and empty state handling

### **P2 Implementation Required:**
- ❌ Supabase schema creation (5 tables with RLS)
- ❌ Data sources for all three domains
- ❌ DTO models with proper JSON parsing
- ❌ Repository implementations
- ❌ Provider overrides in main.dart

**Estimated P2 Effort:** 3-4 days for complete Supabase integration

---

**Ready for handoff! 🚀** 

The Group Hub feature has a complete P1 implementation with all domain contracts, shared components, and UI functionality. P2 can proceed with Supabase integration using the detailed specifications above.