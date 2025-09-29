# Create Group Feature - P1 to P2 Handoff Document

**Date:** December 2024  
**From:** Role P1 (UI + State + Contracts)  
**To:** Role P2 (Data + Supabase)  
**Feature:** Create Group Flow  

---

## ✅ **P1 DELIVERABLES COMPLETED**

All Role P1 responsibilities have been successfully implemented according to the Lazzo architecture guidelines. The create group feature is fully functional with fake data and ready for P2 to implement Supabase integration.

---

## 🏗️ **1. DOMAIN CONTRACTS DEFINED**

### **GroupEntity** - `lib/features/groups/domain/entities/group_entity.dart`

Minimal domain model representing group creation data:

```dart
class GroupEntity {
  final int? id;
  final String name;
  final String? description;
  final String? photoUrl;
  final GroupPermissions permissions;
  final DateTime? createdAt;

  const GroupEntity({
    this.id,
    required this.name,
    this.description,
    this.photoUrl,
    required this.permissions,
    this.createdAt,
  });

  GroupEntity copyWith({
    int? id,
    String? name,
    String? description,
    String? photoUrl,
    GroupPermissions? permissions,
    DateTime? createdAt,
  }) => GroupEntity(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    photoUrl: photoUrl ?? this.photoUrl,
    permissions: permissions ?? this.permissions,
    createdAt: createdAt ?? this.createdAt,
  );
}
```

### **GroupPermissions** - `lib/features/groups/domain/entities/group_permissions.dart`

Permission settings for group creation:

```dart
class GroupPermissions {
  final bool membersCanInvite;
  final bool membersCanAddPhotos;
  final bool membersCanCreateEvents;

  const GroupPermissions({
    this.membersCanInvite = false,
    this.membersCanAddPhotos = false,
    this.membersCanCreateEvents = false,
  });

  GroupPermissions copyWith({
    bool? membersCanInvite,
    bool? membersCanAddPhotos,
    bool? membersCanCreateEvents,
  }) => GroupPermissions(
    membersCanInvite: membersCanInvite ?? this.membersCanInvite,
    membersCanAddPhotos: membersCanAddPhotos ?? this.membersCanAddPhotos,
    membersCanCreateEvents: membersCanCreateEvents ?? this.membersCanCreateEvents,
  );
}
```

### **CreateGroup Use Case** - `lib/features/groups/domain/usecases/create_group.dart`

Single responsibility use case for group creation:

```dart
class CreateGroup {
  final GroupRepository _repository;

  const CreateGroup(this._repository);

  Future<GroupEntity> call(GroupEntity group) async {
    // Business rule validation
    if (group.name.trim().isEmpty) {
      throw ArgumentError('Group name cannot be empty');
    }

    if (group.name.trim().length < 2) {
      throw ArgumentError('Group name must be at least 2 characters');
    }

    return await _repository.createGroup(group);
  }
}
```

---

## 🎨 **2. UI COMPONENTS (TOKENIZED & REUSABLE)**

### **Shared Components Created:**

#### **`ToggleSwitch`** - `lib/shared/components/inputs/toggle_switch.dart`
- ✅ **Fully tokenized** (uses `BrandColors`, `Radii`)
- ✅ **Stateless** with callback props
- ✅ **Smooth animation** with AnimatedContainer
- ✅ **Proper touch feedback** with gesture detection
- ✅ **Reusable across features** for boolean settings

```dart
ToggleSwitch(
  value: permissions.membersCanInvite,
  onChanged: (value) => _updatePermission('membersCanInvite', value),
)
```

### **Feature-Specific Widgets:**

#### **`GroupPhotoSelector`** - `lib/features/groups/presentation/widgets/group_photo_selector.dart`
- ✅ **Image picker integration** with proper permissions
- ✅ **Placeholder state** with tokenized styling
- ✅ **Error handling** for image selection failures
- ✅ **Proper constraints** and aspect ratio handling

#### **`GroupPermissionsSection`** - `lib/features/groups/presentation/widgets/group_permissions_section.dart`
- ✅ **Uses shared ToggleSwitch component**
- ✅ **Clear permission descriptions**
- ✅ **Proper spacing** using design tokens
- ✅ **Callback-based state management**

---

## 🎯 **3. PRESENTATION LAYER (PAGES & STATE)**

### **Create Group Page** - `lib/features/groups/presentation/pages/create_group_page.dart`

Complete screen implementation:
- ✅ **Form validation** with real-time feedback
- ✅ **State management** using controllers and Riverpod
- ✅ **Navigation handling** with success/error flows
- ✅ **Responsive design** following design system
- ✅ **Accessibility support** with proper semantics

```dart
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({Key? key}) : super(key: key);

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}
```

### **State Management** - `lib/features/groups/presentation/providers/create_group_provider.dart`

Riverpod state management:
- ✅ **CreateGroupController** managing AsyncValue states
- ✅ **Loading/error/success state handling**
- ✅ **Automatic UI updates** via StateNotifier
- ✅ **Clean error propagation** with user-friendly messages

```dart
final createGroupControllerProvider = StateNotifierProvider<CreateGroupController, AsyncValue<void>>((ref) {
  final useCase = ref.watch(createGroupUseCaseProvider);
  return CreateGroupController(useCase);
});

class CreateGroupController extends StateNotifier<AsyncValue<void>> {
  final CreateGroup _createGroup;

  CreateGroupController(this._createGroup) : super(const AsyncValue.data(null));

  Future<void> createGroup(GroupEntity group) async {
    state = const AsyncValue.loading();
    
    try {
      await _createGroup.call(group);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
```

---

## 🎭 **4. FAKE DATA LAYER**

### **FakeGroupRepository** - `lib/features/groups/data/fakes/fake_group_repository.dart`

Mock implementation for `createGroup` method:
- ✅ **Realistic network delays** (500ms simulation)
- ✅ **Auto-generated IDs** for created groups
- ✅ **Timestamp assignment** for createdAt field
- ✅ **In-memory storage** for development testing

```dart
@override
Future<GroupEntity> createGroup(GroupEntity group) async {
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 500));

  final createdGroup = group.copyWith(
    id: _nextId++,
    createdAt: DateTime.now(),
  );

  _createdGroups.add(createdGroup);
  return createdGroup;
}
```

---

## 📁 **FILE STRUCTURE REFERENCE**

```
lib/features/groups/
├── domain/
│   ├── entities/
│   │   ├── group_entity.dart ✅
│   │   └── group_permissions.dart ✅
│   ├── repositories/
│   │   └── group_repository.dart ✅ (createGroup method)
│   └── usecases/
│       └── create_group.dart ✅
├── data/
│   ├── data_sources/
│   │   └── groups_data_source.dart ❌ (P2)
│   ├── models/
│   │   └── group_entity_model.dart ❌ (P2)
│   ├── repositories/
│   │   └── group_repository_impl.dart ❌ (P2)
│   └── fakes/
│       └── fake_group_repository.dart ✅
└── presentation/
    ├── pages/
    │   └── create_group_page.dart ✅
    ├── providers/
    │   └── create_group_provider.dart ✅
    └── widgets/
        ├── group_photo_selector.dart ✅
        └── group_permissions_section.dart ✅

lib/shared/components/inputs/
└── toggle_switch.dart ✅
```

---

## 🔧 **P2 IMPLEMENTATION REQUIREMENTS**

### **1. Supabase Schema Requirements**

**Groups Table (`groups`):**
```sql
CREATE TABLE groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  photo_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id) NOT NULL,
  member_count INTEGER DEFAULT 1,
  
  -- Permission settings
  members_can_invite BOOLEAN DEFAULT FALSE,
  members_can_add_photos BOOLEAN DEFAULT FALSE,
  members_can_create_events BOOLEAN DEFAULT FALSE,
  
  -- Constraints
  CONSTRAINT groups_name_length CHECK (char_length(name) >= 2 AND char_length(name) <= 100),
  CONSTRAINT groups_description_length CHECK (char_length(description) <= 500)
);

-- Indexes for performance
CREATE INDEX idx_groups_created_by ON groups(created_by);
CREATE INDEX idx_groups_created_at ON groups(created_at DESC);
```

**Group Members Table (`group_members`):**
```sql
CREATE TABLE group_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  
  -- User preferences per group
  is_muted BOOLEAN DEFAULT FALSE,
  is_pinned BOOLEAN DEFAULT FALSE,
  
  UNIQUE(group_id, user_id)
);

-- Indexes for performance
CREATE INDEX idx_group_members_group_id ON group_members(group_id);
CREATE INDEX idx_group_members_user_id ON group_members(user_id);
```

### **2. Required Data Sources**

**`GroupsDataSource`** - `lib/features/groups/data/data_sources/groups_data_source.dart`
```dart
abstract class GroupsDataSource {
  Future<Map<String, dynamic>> createGroup(String userId, Map<String, dynamic> groupData);
  Future<String?> uploadGroupPhoto(String imagePath, String groupId);
}

class SupabaseGroupsDataSource implements GroupsDataSource {
  final SupabaseClient _client;
  
  SupabaseGroupsDataSource(this._client);
  
  @override
  Future<Map<String, dynamic>> createGroup(String userId, Map<String, dynamic> groupData) async {
    // Start transaction
    final response = await _client.from('groups').insert({
      ...groupData,
      'created_by': userId,
    }).select().single();
    
    // Add creator as admin member
    await _client.from('group_members').insert({
      'group_id': response['id'],
      'user_id': userId,
      'role': 'admin',
    });
    
    return response;
  }
}
```

### **3. Data Models (DTOs)**

**`GroupEntityModel`** - `lib/features/groups/data/models/group_entity_model.dart`
```dart
class GroupEntityModel {
  static GroupEntity fromJson(Map<String, dynamic> json) {
    return GroupEntity(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      name: json['name'] ?? '',
      description: json['description'],
      photoUrl: json['photo_url'],
      permissions: GroupPermissions(
        membersCanInvite: json['members_can_invite'] ?? false,
        membersCanAddPhotos: json['members_can_add_photos'] ?? false,
        membersCanCreateEvents: json['members_can_create_events'] ?? false,
      ),
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : null,
    );
  }

  static Map<String, dynamic> toJson(GroupEntity entity) {
    return {
      'name': entity.name,
      'description': entity.description,
      'photo_url': entity.photoUrl,
      'members_can_invite': entity.permissions.membersCanInvite,
      'members_can_add_photos': entity.permissions.membersCanAddPhotos,
      'members_can_create_events': entity.permissions.membersCanCreateEvents,
    };
  }
}
```

### **4. Repository Implementation**

**`GroupRepositoryImpl`** - `lib/features/groups/data/repositories/group_repository_impl.dart`
```dart
class GroupRepositoryImpl implements GroupRepository {
  final GroupsDataSource _dataSource;
  final String _currentUserId;

  GroupRepositoryImpl(this._dataSource, this._currentUserId);

  @override
  Future<GroupEntity> createGroup(GroupEntity group) async {
    try {
      final groupData = GroupEntityModel.toJson(group);
      final response = await _dataSource.createGroup(_currentUserId, groupData);
      return GroupEntityModel.fromJson(response);
    } catch (e) {
      throw RepositoryException('Failed to create group: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadGroupPhoto(String imagePath, String groupId) async {
    try {
      return await _dataSource.uploadGroupPhoto(imagePath, groupId);
    } catch (e) {
      throw RepositoryException('Failed to upload photo: ${e.toString()}');
    }
  }
}
```

### **5. RLS Policies Required**

```sql
-- Groups table policies
CREATE POLICY "Users can create groups" ON groups FOR INSERT 
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can read groups they belong to" ON groups FOR SELECT 
  USING (id IN (
    SELECT group_id FROM group_members WHERE user_id = auth.uid()
  ));

-- Group members table policies  
CREATE POLICY "Group admins can add members" ON group_members FOR INSERT
  WITH CHECK (
    group_id IN (
      SELECT group_id FROM group_members 
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Users can read group members for their groups" ON group_members FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM group_members WHERE user_id = auth.uid()
    )
  );
```

---

## 🔄 **DEPENDENCY INJECTION OVERRIDE**

In `main.dart`, override the repository provider:

```dart
ProviderScope(
  overrides: [
    groupRepositoryProvider.overrideWithValue(
      GroupRepositoryImpl(
        SupabaseGroupsDataSource(supabaseClient),
        supabaseClient.auth.currentUser!.id,
      ),
    ),
  ],
  child: const MyApp(),
)
```

---

## ✨ **QUALITY VERIFICATION CHECKLIST**

### **✅ Architecture Compliance**
- [x] Domain layer has no Flutter/Supabase imports
- [x] GroupEntity is immutable with pure Dart
- [x] Repository interface defines clean contracts
- [x] CreateGroup use case has single responsibility
- [x] Business rules validation in use case

### **✅ UI/UX Excellence**
- [x] All components use design tokens (no hardcoded values)
- [x] ToggleSwitch is stateless and reusable
- [x] Form validation provides real-time feedback
- [x] AsyncValue handles loading/error/success states
- [x] Navigation flows work correctly

### **✅ State Management**
- [x] CreateGroupController manages AsyncValue states
- [x] State updates trigger UI re-renders
- [x] Error handling with user-friendly messages
- [x] Default DI uses fake repository

### **✅ Fake Data Quality**
- [x] Realistic network delays simulation
- [x] Proper ID and timestamp assignment
- [x] Edge cases covered (validation failures)
- [x] Maintains state across app lifecycle

---

## 🚀 **NEXT STEPS FOR P2**

1. **Create Supabase schema** following the requirements above
2. **Implement `SupabaseGroupsDataSource`** with RLS-compliant queries
3. **Create `GroupEntityModel`** for JSON serialization/deserialization  
4. **Implement `GroupRepositoryImpl`** bridging data source to domain
5. **Add photo upload functionality** to Supabase Storage
6. **Test with real data** and verify all functionality works
7. **Override DI** to switch from fake to real implementation

**Success Criteria:** Create group flow continues to work exactly the same but with real Supabase data instead of mock data.

---

## 📞 **HANDOFF CONTACT**

**P1 Completed By:** AI Assistant  
**Domain Contracts Frozen:** ✅ Ready for P2  
**UI Components Available:** ✅ All tokenized and tested  
**State Management:** ✅ Controllers configured with fake defaults  

**Questions?** All repository method signatures and entity fields are stable. Do not modify domain contracts without coordination.

---

**Status: READY FOR P2 IMPLEMENTATION** 🎯