# Groups Feature - P1 to P2 Handoff Document

**Date:** September 30, 2025  
**From:** Role P1 (UI + State + Contracts)  
**To:** Role P2 (Data + Supabase)  
**Feature:** Groups Management System  

---

## ✅ **P1 DELIVERABLES COMPLETED**

All Role P1 responsibilities have been successfully implemented according to the Lazzo architecture guidelines. The groups feature is fully functional with fake data including **Create Group flow** and **Group Created confirmation**. Ready for P2 to implement Supabase integration.

---

## 🏗️ **1. DOMAIN CONTRACTS DEFINED**

### **Group Entity** - `lib/features/groups/domain/entities/group_entity.dart`

Complete domain model representing a group with all UI-required fields:

```dart
class GroupEntity {
  final String id;
  final String name;
  final String? description;
  final String? photoUrl;
  final GroupPermissions permissions;
  final DateTime createdAt;
  final String createdBy;
  final List<String> memberIds;
}
```

### **Group Permissions Entity** - `lib/features/groups/domain/entities/group_permissions.dart`

```dart
class GroupPermissions {
  final bool membersCanInvite;
  final bool membersCanAddPhotos;
  final bool membersCanCreateEvents;
}
```

**Key Features:**
- Immutable data classes with `copyWith()` methods for state updates
- Support for group permissions and settings
- Photo URL support for group avatars

### **Repository Interface** - `lib/features/groups/domain/repositories/group_repository.dart`

Complete contract defining all data operations:

```dart
abstract class GroupRepository {
  Future<List<GroupEntity>> getUserGroups();
  Future<List<GroupEntity>> searchGroups(String searchTerm);
  Future<GroupEntity?> getGroupById(String groupId);
  Future<GroupEntity> createGroupEntity(GroupEntity group);
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
3. **`CreateGroup`** - Creates new group with validation
4. **`LeaveGroup`** - Handles leaving a group
5. **`ToggleGroupMute`** - Manages mute status
6. **`ToggleGroupPin`** - Manages pinned status
7. **`ToggleGroupArchive`** - Manages archived status

Each use case is a simple orchestrator calling repository methods with business rule validation.

---

## 🎨 **2. UI COMPONENTS (TOKENIZED & REUSABLE)**

### **Shared Components Created:**

#### **`PhotoSelector`** - `lib/shared/components/inputs/photo_selector.dart`
- ✅ **Fully tokenized** shared component for photo selection
- ✅ **Stateless** with callback props for photo selection/removal
- ✅ **Dynamic text switching**: "Add Photo" → "Change Photo"
- ✅ **Clickable text labels** for photo actions
- ✅ **Bottom sheet integration** for camera/gallery selection

#### **`CommonAppBar`** - `lib/shared/components/nav/common_app_bar.dart`
- ✅ **Unified app bar** component with flexible configuration
- ✅ **Factory constructors** for different page types
- ✅ **Tokenized** with proper Material 3 theming
- ✅ **Back button and close button** support

#### **`GroupCard`** - `lib/shared/components/cards/group_card.dart`
- ✅ **Fully tokenized** (uses `BrandColors`, `Radii`, `Gaps`, `Insets`)
- ✅ **Stateless** with callback props for actions
- ✅ **Complex UI logic**: side-by-side icon positioning for pinned+muted states
- ✅ **Avatar with status indicators**: pinned, muted, archived icons with proper positioning
- ✅ **Smart content display**: contextual sublines, badge integration, unread counts

#### **`GroupBadge`** - `lib/shared/components/badges/group_badge.dart`
- ✅ **Status indicator** for active/archived states
- ✅ **Tokenized colors** from `BrandColors` palette

#### **`GroupContextMenu`** - `lib/shared/components/dialogs/group_context_menu.dart`
- ✅ **Overlay-based** context menu with proper positioning
- ✅ **Conditional actions** based on group state
- ✅ **Clean dismissal** mechanism
- ✅ **Overlay-based** context menu with proper positioning
- ✅ **Conditional actions** based on group state
- ✅ **Clean dismissal** mechanism

---

## 🎯 **3. PRESENTATION LAYER (PAGES & STATE)**

### **Groups Page** - `lib/features/groups/presentation/pages/groups_page.dart`

Complete screen implementation:
- ✅ **Consumes shared components** (`GroupCard`, `CommonAppBar`)
- ✅ **AsyncValue handling** for loading/error/success states
- ✅ **Context menu integration** with proper overlay management
- ✅ **Navigation logic** to Create Event with pre-selected group
- ✅ **Search functionality** with debounced input
- ✅ **State management** through providers

### **Create Group Page** - `lib/features/groups/presentation/pages/create_group_page.dart`

Complete create group flow:
- ✅ **Form validation** with real-time error handling
- ✅ **Photo selection** using shared PhotoSelector component
- ✅ **Group permissions** configuration section
- ✅ **Scrollable layout** prevents overflow issues
- ✅ **Button validation logic** matching design patterns
- ✅ **Navigation to Group Created** page on success

### **Group Created Page** - `lib/features/groups/presentation/pages/group_created_page.dart`

Success confirmation page:
- ✅ **Group photo display** with rounded corners
- ✅ **Share link widget** with copy/share actions and expiry info
- ✅ **QR code section** with square aspect ratio
- ✅ **Scrollable layout** for responsive design
- ✅ **Proper navigation** back to main layout with navigation bar

### **State Management** - `lib/features/groups/presentation/providers/`

Comprehensive Riverpod providers:
- ✅ **Repository provider** (defaults to `FakeGroupRepository`)
- ✅ **Use case providers** for all domain operations
- ✅ **CreateGroupProvider** with AsyncValue for form handling
- ✅ **AsyncValue providers** for reactive UI updates
- ✅ **Controller pattern** for coordinated actions
- ✅ **Auto-refresh** after state changes

```dart
final groupsProvider = FutureProvider<List<GroupEntity>>((ref) async {
  final getUserGroups = ref.watch(getUserGroupsProvider);
  return await getUserGroups.call();
});

final createGroupProvider = StateNotifierProvider<CreateGroupController, AsyncValue<GroupEntity?>>((ref) {
  final useCase = ref.watch(createGroupUseCaseProvider);
  return CreateGroupController(useCase);
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
│   │   ├── group_entity.dart ✅
│   │   └── group_permissions.dart ✅
│   ├── repositories/
│   │   └── group_repository.dart ✅
│   └── usecases/
│       ├── get_user_groups.dart ✅
│       ├── search_groups.dart ✅
│       ├── create_group.dart ✅
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
    │   ├── groups_page.dart ✅
    │   ├── create_group_page.dart ✅
    │   └── group_created_page.dart ✅
    ├── providers/
    │   ├── groups_provider.dart ✅
    │   └── create_group_provider.dart ✅
    └── widgets/
        ├── group_context_menu.dart ✅
        └── group_permissions_section.dart ✅

lib/shared/components/
├── cards/
│   └── group_card.dart ✅
├── nav/
│   └── common_app_bar.dart ✅
├── badges/
│   └── group_badge.dart ✅
├── inputs/
│   └── photo_selector.dart ✅
└── dialogs/
    └── group_context_menu.dart ✅

lib/shared/models/
└── group_enums.dart ✅

lib/routes/
└── app_router.dart ✅ (includes create-group and group-created routes)
```

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
- description: TEXT
- photo_url: TEXT
- created_at: TIMESTAMP WITH TIME ZONE DEFAULT NOW()
- updated_at: TIMESTAMP WITH TIME ZONE DEFAULT NOW()
- created_by: UUID (FK to users) NOT NULL
- member_count: INTEGER DEFAULT 1
```

**Group Members Table (`group_members`):**
```sql
- id: UUID PRIMARY KEY
- group_id: UUID (FK to groups) NOT NULL
- user_id: UUID (FK to users) NOT NULL
- joined_at: TIMESTAMP WITH TIME ZONE DEFAULT NOW()
- is_muted: BOOLEAN DEFAULT FALSE
- is_pinned: BOOLEAN DEFAULT FALSE
- is_archived: BOOLEAN DEFAULT FALSE
- role: TEXT DEFAULT 'member' (member/admin)
- UNIQUE(group_id, user_id)
```

**Group Permissions Table (`group_permissions`):**
```sql
- id: UUID PRIMARY KEY
- group_id: UUID (FK to groups) NOT NULL UNIQUE
- members_can_invite: BOOLEAN DEFAULT TRUE
- members_can_add_photos: BOOLEAN DEFAULT TRUE
- members_can_create_events: BOOLEAN DEFAULT TRUE
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
  // Map Supabase rows to GroupEntity
  static GroupEntity fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

**`GroupPermissionsModel`** - `lib/features/groups/data/models/group_permissions_model.dart`
```dart
class GroupPermissionsModel {
  static GroupPermissions fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### **4. Repository Implementation**

**`GroupRepositoryImpl`** - `lib/features/groups/data/repositories/group_repository_impl.dart`
- Implement all `GroupRepository` methods
- Use `GroupsDataSource` for Supabase operations
- Convert between `GroupModel` and `GroupEntity`
- Handle RLS policies for user-specific data
- Implement efficient queries with proper indexing
- Support create group flow with permissions

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

-- Users can create groups
CREATE POLICY groups_create ON groups
  FOR INSERT WITH CHECK (created_by = auth.uid());

-- Group permissions are readable by group members
CREATE POLICY group_permissions_member_read ON group_permissions
  FOR SELECT USING (
    group_id IN (
      SELECT group_id FROM group_members 
      WHERE user_id = auth.uid()
    )
  );
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
- [x] Create group flow with validation and confirmation
- [x] Proper navigation preserving navigation bar

### **✅ State Management**
- [x] Providers expose AsyncValue for reactive UI
- [x] Controllers coordinate related actions
- [x] Auto-refresh after state mutations
- [x] Default DI uses fake repositories
- [x] Create group provider returns created entity

### **✅ Testing & Development**
- [x] Fake repository with comprehensive test data  
- [x] All group states represented (pinned, muted, archived)
- [x] Edge cases covered (empty results, not found)
- [x] Realistic network delays simulated
- [x] Create group flow fully tested

---

## 🚀 **NEXT STEPS FOR P2**

1. **Create Supabase schema** following the requirements above
2. **Implement `GroupsDataSource`** with RLS-compliant queries
3. **Create data models** for JSON serialization/deserialization  
4. **Implement `GroupRepositoryImpl`** bridging data source to domain
5. **Test create group flow** with real Supabase storage for photos
6. **Test with real data** and verify all functionality works
7. **Override DI** to switch from fake to real implementation

**Success Criteria:** UI continues to work exactly the same but with real Supabase data instead of mock data. Create group flow should work end-to-end with photo upload to Supabase Storage.

---

## 📞 **HANDOFF CONTACT**

**P1 Completed By:** Guilherme Monteiro (CEO)
**Domain Contracts Frozen:** ✅ Ready for P2  
**UI Components Available:** ✅ All tokenized and tested  
**State Management:** ✅ Providers configured with fake defaults  
**Create Group Flow:** ✅ Complete with confirmation page

**Questions?** All repository method signatures and entity fields are stable. Do not modify domain contracts without coordination.

---

**Status: READY FOR P2 IMPLEMENTATION** 🎯