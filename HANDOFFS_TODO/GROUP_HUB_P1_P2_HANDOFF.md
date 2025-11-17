# Group Hub Feature - P1 to P2 Handoff Document

**Date:** October 21, 2025 (Updated: November 17, 2025)  
**From:** Role P1 (UI + State + Contracts)  
**To:** Role P2 (Data + Supabase)  
**Feature:** Group Hub (Events, Memories)  

> **⚠️ UPDATE (Nov 13, 2025):** Expenses section has been **migrated to Event feature** where it's actually used. This handoff now covers only Events and Memories sections. For expenses functionality, refer to `EVENT_DETAIL_P1_P2_HANDOFF.md`.

> **🆕 UPDATE (Nov 17, 2025):** GroupEventEntity expanded with new fields for Live/Recap functionality: `participantCount`, `photoCount`, `maxPhotos`, `endsAt`. GroupEventStatus enum now includes `live` and `recap`. All data layer files scaffolded with detailed TODOs in `lib/features/group_hub/data/`.

---

## ✅ **P1 DELIVERABLES COMPLETED**

All Role P1 responsibilities have been successfully implemented according to the Lazzo architecture guidelines. The group hub feature is fully functional with fake data including **Events** and **Memories** sections with proper sorting, shared components, and tokenized design. Ready for P2 to implement Supabase integration.

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
  final DateTime? endsAt;            // 🆕 For Live/Recap - when event ends
  final String? location;
  final GroupEventStatus status;
  final int goingCount;
  final int participantCount;        // 🆕 Total participants (for "X participants")
  final int photoCount;              // 🆕 Current photos uploaded
  final int? maxPhotos;              // 🆕 Maximum photos allowed (for "X/Y photos")
  final List<String> attendeeAvatars;
  final List<String> attendeeNames;
  final bool? userVote; // true = going, false = not going, null = pending
  final List<RsvpVote> allVotes;
}

enum GroupEventStatus { 
  pending,    // Event is being planned
  confirmed,  // Event is confirmed (shows date + RSVP details)
  live,       // 🆕 Event is happening now (shows "X hours left" + participant count)
  recap       // 🆕 Event ended, recap available (shows "X hours left" + photos)
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

**Key Features:**
- Immutable data classes with `copyWith()` methods
- RSVP vote tracking for events
- Photo count and cover images for memories
- Interface compatibility with shared components

**🆕 New Fields (Nov 17, 2025):**
- `participantCount` - Total number of participants (used for "6 participants" display)
- `photoCount` - Current number of photos uploaded (used for "18/30 photos" display)
- `maxPhotos` - Maximum photo limit (nullable, used for "X/Y photos" format)
- `endsAt` - End time for Live/Recap events (used to calculate "X hours left")

**Status Logic:**
- **Live**: Event in progress, show purple badge with "X hours left" + participant/photo counts
- **Recap**: Event ended, show orange badge with "X hours left" to view recap + photos
- **Confirmed**: Future event, show green badge with date + RSVP details ("5 going • You, Sarah and 3 others")
- **Pending**: Event being planned, show date only

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

**Component Features:
- All components use design tokens (no hardcoded values)
- Shared components exported in `components.dart`
- Responsive design with proper touch targets
- Empty state handling
- Loading state compatibility

---

## 🔧 **5. PRESENTATION LAYER (PAGES & STATE)**

### **Group Hub Page** - `lib/features/group_hub/presentation/pages/group_hub_page.dart`

Main page with two-tab interface:

```dart
class GroupHubPage extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupPhotoUrl;
  final int memberCount;

  // Features:
  // - Two tabs: Events, Memories
  // - Group info header with photo and member count
  // - Segmented control navigation
  // - AsyncValue state handling for all sections
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
- Comprehensive RSVP scenarios for events

---

## 🎯 **7. UI STATE HANDLING**

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
│   │   ├── group_memory_entity.dart ✅
│   │   ├── group_details_entity.dart ✅
│   │   ├── group_member_entity.dart ✅
│   │   └── group_photo_entity.dart ✅
│   ├── repositories/
│   │   ├── group_event_repository.dart ✅
│   │   ├── group_memory_repository.dart ✅
│   │   ├── group_details_repository.dart ✅
│   │   └── group_photos_repository.dart ✅
│   └── usecases/
│       ├── get_group_events.dart ✅
│       ├── get_group_memories.dart ✅
│       ├── get_group_details.dart ✅
│       ├── get_group_members.dart ✅
│       └── toggle_group_mute.dart ✅
├── data/
│   ├── data_sources/
│   │   ├── group_event_data_source.dart ❌ (P2)
│   │   └── group_memory_data_source.dart ❌ (P2)
│   ├── models/
│   │   ├── group_event_model.dart ❌ (P2)
│   │   └── group_memory_model.dart ❌ (P2)
│   ├── repositories/
│   │   ├── group_event_repository_impl.dart ❌ (P2)
│   │   └── group_memory_repository_impl.dart ❌ (P2)
│   └── fakes/
│       ├── fake_group_event_repository.dart ✅
│       ├── fake_group_memory_repository.dart ✅
│       ├── fake_group_details_repository.dart ✅
│       └── fake_group_photos_repository.dart ✅
└── presentation/
    ├── pages/
    │   └── group_hub_page.dart ✅
    ├── providers/
    │   └── group_hub_providers.dart ✅
    └── widgets/
        └── (no expense widgets - migrated to event feature)

lib/shared/components/
├── sections/
│   └── memories_section.dart ✅ (Generic MemoryData interface)
└── components.dart ✅ (Updated exports)
```

> **Note:** Expense-related files have been migrated to `lib/features/event/` feature where they're actually used.

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
  ends_at TIMESTAMPTZ,              -- 🆕 For Live/Recap status (when event ends)
  location TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'live', 'recap')),
  photo_count INT DEFAULT 0,        -- 🆕 Current number of photos uploaded
  max_photos INT,                   -- 🆕 Maximum photo limit (nullable)
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES profiles(id),
  deleted_at TIMESTAMPTZ,           -- For soft deletes
  
  -- RLS policies needed for group members only
);

-- Index for performance (sort by date DESC for recent events first)
CREATE INDEX idx_group_events_group_id_date ON group_events(group_id, date DESC);

-- Index for filtering by status
CREATE INDEX idx_group_events_status ON group_events(status) WHERE deleted_at IS NULL;
```

#### **Event RSVP Table** - `event_rsvps`
```sql
CREATE TABLE event_rsvps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES group_events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('going', 'notGoing', 'pending')),
  voted_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(event_id, user_id)
);

CREATE INDEX idx_event_rsvps_event_id ON event_rsvps(event_id);
CREATE INDEX idx_event_rsvps_user_id ON event_rsvps(user_id);
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
- ✅ 2 Core domain entities (Events, Memories)
- ✅ 5 Supporting entities (Details, Members, Photos)
- ✅ 2 Repository interfaces with clear contracts  
- ✅ 5 Use cases with single responsibilities
- ✅ Complete UI with tokenized design system (2-tab interface)
- ✅ Generic shared components (MemoriesSection)
- ✅ Comprehensive fake data (Events and Memories)
- ✅ Full state management with AsyncValue
- ✅ Error, loading, and empty state handling

### **P2 Implementation Required:**
- ❌ Supabase schema creation (2 main tables + supporting tables)
- ❌ Data sources for Events and Memories
- ❌ DTO models with proper JSON parsing
- ❌ Repository implementations
- ❌ Provider overrides in main.dart

**Estimated P2 Effort:** 2-3 days for complete Supabase integration

---

**Ready for handoff! 🚀** 

The Group Hub feature (Events and Memories) has a complete P1 implementation with all domain contracts, shared components, and simplified 2-tab UI. P2 can proceed with Supabase integration using the detailed specifications above.

> **Note:** Expense functionality has been migrated to the Event feature. See `EVENT_DETAIL_P1_P2_HANDOFF.md` for expenses implementation details.