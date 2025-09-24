# Groups Feature - P1 to P2 Handoff Document

**Date:** September 24, 2025  
**From:** Role P1 (UI + State + Contracts)  
**To:** Role P2 (Data + Supabase)  
**Feature:** Groups Management System  

---

## ✅ **P1 DELIVERABLES COMPLETED**

All Role P1 responsibilities have been successfully implemented according to the Lazzo architecture guidelines. The groups feature is fully functional with fake data and ready for P2 to implement Supabase integration.

---

## 🏗️ **1. DOMAIN CONTRACTS DEFINED**

### **Group Entity** - `lib/features/groups/domain/entities/group.dart`

Complete domain model representing a group with all UI-required fields:

```dart
class Group {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? lastActivity;
  final DateTime? lastActivityTime;
  final int? unreadCount;
  final int? openActionsCount;
  final int? addPhotosCount;
  final String? addPhotosTimeLeft;
  final GroupStatus status;
  final bool isMuted;
  final bool isPinned;
  final int memberCount;
}
```

**Key Features:**
- Immutable data class with `copyWith()` method for state updates
- Smart contextual subline logic based on group status and activity priority
- Support for pinned, muted, and archived states
- Badge system integration with `GroupStatus` enum

### **Repository Interface** - `lib/features/groups/domain/repositories/group_repository.dart`

Complete contract defining all data operations:

```dart
abstract class GroupRepository {
  Future<List<Group>> getUserGroups();
  Future<List<Group>> searchGroups(String searchTerm);
  Future<Group?> getGroupById(String groupId);
  Future<Group> createGroup({required String name, String? avatarUrl, List<String>? memberIds});
  Future<void> inviteMembers(String groupId, List<String> memberIds);
  Future<void> leaveGroup(String groupId);
  Future<void> toggleMute(String groupId, bool isMuted);
  Future<void> togglePin(String groupId);
  Future<void> toggleArchive(String groupId);
  Future<List<String>> getGroupMembers(String groupId);
}
```

### **Use Cases Implemented**

All single-responsibility use cases following Clean Architecture:

1. **`GetUserGroups`** - Fetches all user groups
2. **`SearchGroups`** - Searches groups by term
3. **`LeaveGroup`** - Handles leaving a group
4. **`ToggleGroupMute`** - Manages mute status
5. **`ToggleGroupPin`** - Manages pinned status
6. **`ToggleGroupArchive`** - Manages archived status

Each use case is a simple orchestrator calling repository methods.

---

## 🎨 **2. UI COMPONENTS (TOKENIZED & REUSABLE)**

### **Shared Components Created:**

#### **`GroupCard`** - `lib/shared/components/cards/group_card.dart`
- ✅ **Fully tokenized** (uses `BrandColors`, `Radii`, `Gaps`, `Insets`)
- ✅ **Stateless** with callback props for actions
- ✅ **Complex UI logic**: side-by-side icon positioning for pinned+muted states
- ✅ **Avatar with status indicators**: pinned, muted, archived icons with proper positioning
- ✅ **Smart content display**: contextual sublines, badge integration, unread counts

#### **`GroupsAppBar`** - `lib/shared/components/nav/groups_app_bar.dart`
- ✅ **Tokenized** with proper Material 3 theming
- ✅ **Fixed surface tint issues** (prevents green color on scroll)
- ✅ **Create group action** integrated

#### **`GroupBadge`** - `lib/shared/components/badges/group_badge.dart`
- ✅ **Status indicator** for active/archived states
- ✅ **Tokenized colors** from `BrandColors` palette

#### **`GroupContextMenu`** - `lib/shared/components/dialogs/group_context_menu.dart`
- ✅ **Overlay-based** context menu with proper positioning
- ✅ **Conditional actions** based on group state
- ✅ **Clean dismissal** mechanism

---

## 🎯 **3. PRESENTATION LAYER (PAGES & STATE)**

### **Groups Page** - `lib/features/groups/presentation/pages/groups_page.dart`

Complete screen implementation:
- ✅ **Consumes shared components** (`GroupCard`, `GroupsAppBar`)
- ✅ **AsyncValue handling** for loading/error/success states
- ✅ **Context menu integration** with proper overlay management
- ✅ **Navigation logic** to Create Event with pre-selected group
- ✅ **Search functionality** with debounced input
- ✅ **State management** through providers

### **State Management** - `lib/features/groups/presentation/providers/groups_provider.dart`

Comprehensive Riverpod providers:
- ✅ **Repository provider** (defaults to `FakeGroupRepository`)
- ✅ **Use case providers** for all domain operations
- ✅ **AsyncValue providers** for reactive UI updates
- ✅ **Controller pattern** for coordinated actions
- ✅ **Auto-refresh** after state changes

```dart
final groupsProvider = FutureProvider<List<Group>>((ref) async {
  final getUserGroups = ref.watch(getUserGroupsProvider);
  return await getUserGroups.call();
});

final groupsControllerProvider = Provider<GroupsController>((ref) {
  return GroupsController(ref);
});
```

---

## 🎭 **4. FAKE DATA LAYER**

### **FakeGroupRepository** - `lib/features/groups/data/fakes/fake_group_repository.dart`

Complete mock implementation:
- ✅ **Implements all repository methods** with realistic delays
- ✅ **Rich test data** covering all group states (active, archived, pinned, muted)
- ✅ **State mutation logic** for toggle operations
- ✅ **Search functionality** with case-insensitive matching
- ✅ **Edge cases covered** (empty results, not found scenarios)

**Sample Groups Include:**
- Obama Care (pinned, active, with unread count)
- Beach Volleyball (add photos countdown)
- Study Group (active with actions)
- Family (archived with last activity)
- Weekend Warriors (pinned + muted for testing overlay icons)

---

## 📁 **FILE STRUCTURE REFERENCE**

```
lib/features/groups/
├── domain/
│   ├── entities/
│   │   └── group.dart ✅
│   ├── repositories/
│   │   └── group_repository.dart ✅
│   └── usecases/
│       ├── get_user_groups.dart ✅
│       ├── search_groups.dart ✅
│       ├── leave_group.dart ✅
│       ├── toggle_group_mute.dart ✅
│       ├── toggle_group_pin.dart ✅
│       └── toggle_group_archive.dart ✅
├── data/
│   ├── data_sources/
│   │   └── groups_data_source.dart ❌ (P2)
│   ├── models/
│   │   └── group_model.dart ❌ (P2)
│   ├── repositories/
│   │   └── group_repository_impl.dart ❌ (P2)
│   └── fakes/
│       └── fake_group_repository.dart ✅
└── presentation/
    ├── pages/
    │   └── groups_page.dart ✅
    └── providers/
        └── groups_provider.dart ✅

lib/shared/components/
├── cards/
│   └── group_card.dart ✅
├── nav/
│   └── groups_app_bar.dart ✅
├── badges/
│   └── group_badge.dart ✅
└── dialogs/
    └── group_context_menu.dart ✅

lib/shared/models/
└── group_enums.dart ✅
```

---

## 🔧 **P2 IMPLEMENTATION REQUIREMENTS**

### **1. Supabase Schema Requirements**

**Groups Table (`groups`):**
```sql
- id: UUID PRIMARY KEY
- name: TEXT NOT NULL
- avatar_url: TEXT
- created_at: TIMESTAMP WITH TIME ZONE
- updated_at: TIMESTAMP WITH TIME ZONE
- created_by: UUID (FK to users)
- member_count: INTEGER DEFAULT 0
- last_activity: TEXT
- last_activity_time: TIMESTAMP WITH TIME ZONE
```

**Group Members Table (`group_members`):**
```sql
- id: UUID PRIMARY KEY
- group_id: UUID (FK to groups)
- user_id: UUID (FK to users)
- joined_at: TIMESTAMP WITH TIME ZONE
- is_muted: BOOLEAN DEFAULT FALSE
- is_pinned: BOOLEAN DEFAULT FALSE
- is_archived: BOOLEAN DEFAULT FALSE
- role: TEXT DEFAULT 'member' (member/admin)
```

**Group Activities Table (`group_activities`):**
```sql
- id: UUID PRIMARY KEY
- group_id: UUID (FK to groups)
- activity_type: TEXT (event, photo_request, decision)
- title: TEXT
- description: TEXT
- closes_at: TIMESTAMP WITH TIME ZONE
- unread_count: INTEGER DEFAULT 0
- created_at: TIMESTAMP WITH TIME ZONE
```

### **2. Required Data Sources**

**`GroupsDataSource`** - `lib/features/groups/data/data_sources/groups_data_source.dart`
```dart
abstract class GroupsDataSource {
  Future<List<Map<String, dynamic>>> getUserGroups(String userId);
  Future<List<Map<String, dynamic>>> searchGroups(String userId, String searchTerm);
  Future<Map<String, dynamic>?> getGroupById(String groupId);
  Future<Map<String, dynamic>> createGroup(String userId, Map<String, dynamic> groupData);
  Future<void> updateGroupMember(String groupId, String userId, Map<String, dynamic> updates);
  Future<void> leaveGroup(String groupId, String userId);
  Future<List<String>> getGroupMembers(String groupId);
}
```

### **3. Data Models (DTOs)**

**`GroupModel`** - `lib/features/groups/data/models/group_model.dart`
```dart
class GroupModel {
  // Map Supabase rows to Group entity
  static Group fromJson(Map<String, dynamic> json, Map<String, dynamic>? memberData);
  Map<String, dynamic> toJson();
}
```

### **4. Repository Implementation**

**`GroupRepositoryImpl`** - `lib/features/groups/data/repositories/group_repository_impl.dart`
- Implement all `GroupRepository` methods
- Use `GroupsDataSource` for Supabase operations
- Convert between `GroupModel` and `Group` entity
- Handle RLS policies for user-specific data
- Implement efficient queries with proper indexing

### **5. RLS Policies Required**

```sql
-- Users can only see groups they're members of
CREATE POLICY groups_member_access ON groups
  FOR ALL USING (
    id IN (
      SELECT group_id FROM group_members 
      WHERE user_id = auth.uid()
    )
  );

-- Users can manage their own group membership settings
CREATE POLICY group_members_self_access ON group_members
  FOR ALL USING (user_id = auth.uid());
```

---

## 🔄 **DEPENDENCY INJECTION OVERRIDE**

Once P2 implementation is complete, switch from fake to real data in `main.dart`:

```dart
ProviderScope(
  overrides: [
    groupRepositoryProvider.overrideWithValue(
      GroupRepositoryImpl(
        SupabaseGroupsDataSource(supabaseClient)
      )
    ),
  ],
  child: MyApp(),
)
```

---

## ✨ **QUALITY VERIFICATION CHECKLIST**

### **✅ Architecture Compliance**
- [x] Domain layer has no Flutter/Supabase imports
- [x] Entities are immutable with pure Dart
- [x] Repository interfaces define clean contracts
- [x] Use cases have single responsibility

### **✅ UI/UX Excellence**
- [x] All components use design tokens (no hardcoded values)
- [x] Shared components are stateless and reusable
- [x] AsyncValue handles loading/error/success states
- [x] Complex UI logic (side-by-side icons) implemented correctly

### **✅ State Management**
- [x] Providers expose AsyncValue for reactive UI
- [x] Controllers coordinate related actions
- [x] Auto-refresh after state mutations
- [x] Default DI uses fake repositories

### **✅ Testing & Development**
- [x] Fake repository with comprehensive test data  
- [x] All group states represented (pinned, muted, archived)
- [x] Edge cases covered (empty results, not found)
- [x] Realistic network delays simulated

---

## 🚀 **NEXT STEPS FOR P2**

1. **Create Supabase schema** following the requirements above
2. **Implement `GroupsDataSource`** with RLS-compliant queries
3. **Create `GroupModel`** for JSON serialization/deserialization  
4. **Implement `GroupRepositoryImpl`** bridging data source to domain
5. **Test with real data** and verify all functionality works
6. **Override DI** to switch from fake to real implementation

**Success Criteria:** UI continues to work exactly the same but with real Supabase data instead of mock data.

---

## 📞 **HANDOFF CONTACT**

**P1 Completed By:** AI Assistant  
**Domain Contracts Frozen:** ✅ Ready for P2  
**UI Components Available:** ✅ All tokenized and tested  
**State Management:** ✅ Providers configured with fake defaults  

**Questions?** All repository method signatures and entity fields are stable. Do not modify domain contracts without coordination.

---

**Status: READY FOR P2 IMPLEMENTATION** 🎯