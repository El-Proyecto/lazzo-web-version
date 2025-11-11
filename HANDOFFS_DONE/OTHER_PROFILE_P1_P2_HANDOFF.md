# Other Profile Feature — Role P1→P2 Handoff

**Feature:** Other User Profile with Shared Context  
**Date:** 2025-11-09  
**From:** Role P1 (UI + State + Contracts)  
**To:** Role P2 (Data + Supabase)  
**Status:** ✅ P1 Complete — Ready for P2 implementation

---

## 1) Feature Overview

Displays another user's profile with:
- User basic info (photo, name, location, birthday)
- Shared upcoming confirmed events (vertical list)
- Shared memories together
- Invite to group(s) functionality with multi-select

**User Flow:**
1. User navigates to `/other-profile?userId=<id>`
2. Sees other user's info + shared context
3. Taps invite icon → bottom sheet appears
4. Selects one or multiple groups (checkbox right-aligned)
5. Taps "Send Invitation" (green when groups selected)
6. Success banner confirms invitations sent

---

## 2) Domain Contracts (P2 Must Follow)

### Entities

**`OtherProfileEntity`** (`lib/features/profile/domain/entities/other_profile_entity.dart`)
```dart
class OtherProfileEntity {
  final String id;
  final String name;
  final String? profileImageUrl;
  final String? location;
  final DateTime? birthday;
  final List<GroupEventEntity> upcomingTogether;    // shared confirmed events
  final List<MemoryEntity> memoriesTogether;        // shared memories
}
```

**`InviteGroupEntity`** (`lib/features/profile/domain/entities/invite_group_entity.dart`)
```dart
class InviteGroupEntity {
  final String id;
  final String name;
  final int memberCount;
  final String? groupPhotoUrl;
}
```

### Repository Interface

**`OtherProfileRepository`** (`lib/features/profile/domain/repositories/other_profile_repository.dart`)

```dart
abstract class OtherProfileRepository {
  /// Get another user's profile by ID
  /// Returns profile with shared events and memories
  Future<OtherProfileEntity> getOtherUserProfile(String userId);

  /// Get list of groups where current user can invite this person
  /// Only returns groups where current user is member and other user is not
  Future<List<InviteGroupEntity>> getInvitableGroups(String userId);

  /// Send group invitation to user
  /// Returns true if invitation was sent successfully
  Future<bool> inviteToGroup({
    required String userId,
    required String groupId,
  });
}
```

### Use Cases

**`GetOtherUserProfile`** (`lib/features/profile/domain/usecases/get_other_user_profile.dart`)
- Single responsibility: fetch other user's profile with shared context
- Method: `Future<OtherProfileEntity> call(String userId)`

**`GetInvitableGroups`** (`lib/features/profile/domain/usecases/get_invitable_groups.dart`)
- Single responsibility: fetch groups where current user can invite target user
- Method: `Future<List<InviteGroupEntity>> call(String userId)`

**`InviteToGroup`** (`lib/features/profile/domain/usecases/invite_to_group.dart`)
- Single responsibility: send group invitation to user
- Method: `Future<bool> call({required String userId, required String groupId})`

---

## 3) UI Components (Complete)

### Pages
**`OtherProfilePage`** (`lib/features/profile/presentation/pages/other_profile_page.dart`)
- ✅ Uses `AsyncValue` for loading/error/success states
- ✅ Displays profile info, shared events, shared memories
- ✅ Handles invite flow with loading dialog + bottom sheet
- ✅ Multi-group invitation with batch success/error handling
- ✅ Pull-to-refresh implemented
- ✅ No Supabase imports (uses providers only)

### Widgets
**`OtherProfileAppBar`** (`lib/features/profile/presentation/widgets/other_profile_app_bar.dart`)
- Custom app bar with invite icon button
- Callback: `onInvitePressed()`

**`UserInfoCard`** (`lib/features/profile/presentation/widgets/user_info_card.dart`)
- ✅ Reused from profile feature (96x96 photo, titleMediumEmph name)
- Shows photo, name, optional location, optional birthday

**`UpcomingTogetherSection`** (`lib/features/profile/presentation/widgets/upcoming_together_section.dart`)
- ✅ Displays shared confirmed events in vertical Column (no carousel)
- ✅ Uses `ConfirmedEventCard` from shared components
- ✅ Fully tokenized styling
- Shows section header "Upcoming Together"
- Empty state: hides section when no events

**`MemoriesSection`** (`lib/features/profile/presentation/widgets/memories_section.dart`)
- ✅ Reused from profile feature
- Grid layout of shared memories

**`InviteToGroupBottomSheet`** (`lib/features/profile/presentation/widgets/invite_to_group_bottom_sheet.dart`)
- ✅ Multi-select with checkboxes (right-aligned)
- ✅ No separators between groups
- ✅ Green "Send Invitation" button (enabled when groups selected)
- ✅ Empty state handling ("No groups available")
- Callback: `onGroupsSelected(List<String> groupIds)`

### Shared Components Created
**`ConfirmedEventCard`** (`lib/shared/components/cards/confirmed_event_card.dart`)
- ✅ New reusable card for confirmed events without voting UI
- Shows emoji, title, date/location, "Confirmed" badge
- Fully tokenized (BrandColors, AppText, Gaps, Pads, Radii)
- Single line layout: emoji + title on left, badge on right

---

## 4) State Management (Complete)

**Providers** (`lib/features/profile/presentation/providers/other_profile_providers.dart`)

```dart
// Repository provider (defaults to FakeOtherProfileRepository)
final otherProfileRepositoryProvider = Provider<OtherProfileRepository>

// Profile data provider (FutureProvider.family)
final otherUserProfileProvider = FutureProvider.family<OtherProfileEntity, String>

// Invitable groups provider (FutureProvider.family)
final invitableGroupsProvider = FutureProvider.family<List<InviteGroupEntity>, String>

// Invite use case provider
final inviteToGroupProvider = Provider<InviteToGroup>
```

**State Flow:**
1. Page fetches `otherUserProfileProvider(userId)` → displays UI
2. Invite button fetches `invitableGroupsProvider(userId)` → shows bottom sheet
3. User selects groups → calls `inviteToGroupProvider` for each group → shows success banner

---

## 5) Fake Data (For Development)

**`FakeOtherProfileRepository`** (`lib/features/profile/data/fakes/fake_other_profile_repository.dart`)

**Mock Data:**
- **User:** Ana Silva (SF, birthday Dec 10)
- **3 Upcoming Events:**
  - 🍕 Pizza Night (Nov 15, 2025, 7:00 PM - Domino's Pizza SF)
  - 🎉 Weekend BBQ (Nov 22, 2025, 5:00 PM - Golden Gate Park)
  - 🎬 Movie Marathon (Nov 30, 2025, 6:00 PM - Ana's Place)
- **4 Shared Memories:** Mock photos with metadata
- **3 Invitable Groups:**
  - College Friends (12 members)
  - Book Club (8 members)
  - Running Crew (15 members)

**Behavior:**
- 500ms delay to simulate network
- `inviteToGroup()` always returns `true`

---

## 6) Routing (Complete)

**Route:** `/other-profile`  
**Arguments:** `userId` (String)  
**Location:** `lib/routes/app_router.dart`

```dart
static const otherProfile = '/other-profile';

case AppRouter.otherProfile:
  final userId = settings.arguments as String;
  return MaterialPageRoute(
    builder: (_) => OtherProfilePage(userId: userId),
  );
```

---

## 7) P2 Implementation Checklist

### Data Source (`lib/features/profile/data/data_sources/other_profile_data_source.dart`)

**Query Requirements:**

#### `getOtherUserProfile(String userId)`
- **Tables:** `profiles`, `event_participants`, `events`, `memories_participants`, `memories`
- **RLS:** Must respect row-level security (no admin keys)
- **Shared Events Logic:**
  - Find events where BOTH current user AND target user are participants
  - Filter by event status = 'confirmed'
  - Order by event date ascending
  - Select only: event_id, emoji, title, date, location, status
- **Shared Memories Logic:**
  - Find memories where BOTH users are participants
  - Order by created_at descending
  - Limit to recent 50 memories
  - Select only: memory_id, photo_url, created_at
- **User Profile:** Select id, name, profile_image_url, location, birthday

#### `getInvitableGroups(String userId)`
- **Logic:**
  - Get all groups where current user IS a member
  - Filter OUT groups where target user IS already a member
  - Filter OUT groups where pending invitation already exists for target user
- **Select:** group_id, name, member_count, group_photo_url
- **Order by:** name ascending

#### `inviteToGroup(String userId, String groupId)`
- **Action:** Insert into `group_invitations` table
- **Fields:**
  - group_id
  - invitee_user_id (target userId)
  - inviter_user_id (current user ID from auth)
  - status: 'pending'
  - created_at: now()
- **Return:** true if insert succeeds, false on error

### DTO Models (`lib/features/profile/data/models/`)

**`OtherProfileModel`** (`other_profile_model.dart`)
- Parse Supabase JSON → `OtherProfileEntity`
- Handle null profile image, location, birthday
- Parse nested events and memories arrays
- Default empty lists if no shared content

**`InviteGroupModel`** (`invite_group_model.dart`)
- Parse Supabase JSON → `InviteGroupEntity`
- Handle null group photo

### Repository Implementation (`lib/features/profile/data/repositories/other_profile_repository_impl.dart`)

```dart
class OtherProfileRepositoryImpl implements OtherProfileRepository {
  final OtherProfileDataSource dataSource;
  
  @override
  Future<OtherProfileEntity> getOtherUserProfile(String userId) async {
    try {
      final data = await dataSource.getOtherUserProfile(userId);
      return OtherProfileModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }
  
  @override
  Future<List<InviteGroupEntity>> getInvitableGroups(String userId) async {
    try {
      final data = await dataSource.getInvitableGroups(userId);
      return data.map((json) => InviteGroupModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to fetch invitable groups: $e');
    }
  }
  
  @override
  Future<bool> inviteToGroup({required String userId, required String groupId}) async {
    try {
      return await dataSource.inviteToGroup(userId, groupId);
    } catch (e) {
      return false;
    }
  }
}
```

### DI Override (`lib/main.dart`)

**Replace fake with real implementation:**

```dart
ProviderScope(
  overrides: [
    // ... other overrides ...
    
    otherProfileRepositoryProvider.overrideWithValue(
      OtherProfileRepositoryImpl(
        dataSource: OtherProfileDataSource(
          client: supabase.client,
        ),
      ),
    ),
  ],
  child: const App(),
)
```

---

## 8) Database Schema Requirements

### Required Tables
- `profiles` (id, name, profile_image_url, location, birthday)
- `events` (id, emoji, title, date, location, status)
- `event_participants` (event_id, user_id)
- `memories` (id, photo_url, created_at)
- `memories_participants` (memory_id, user_id)
- `groups` (id, name, group_photo_url)
- `group_members` (group_id, user_id)
- `group_invitations` (id, group_id, invitee_user_id, inviter_user_id, status, created_at)

### Required Indexes
- `event_participants(user_id, event_id)` — for shared events query
- `memories_participants(user_id, memory_id)` — for shared memories query
- `group_members(user_id, group_id)` — for invitable groups filter
- `group_invitations(invitee_user_id, group_id, status)` — for duplicate check
- `events(date)` — for ordering upcoming events
- `memories(created_at)` — for ordering memories

### RLS Policies Required
- **profiles:** Users can read any profile (public)
- **events/event_participants:** Users can read events they participate in
- **memories/memories_participants:** Users can read memories they're part of
- **groups/group_members:** Users can read groups they're members of
- **group_invitations:** Users can insert invitations for groups they're in; users can read their own invitations

---

## 9) Quality Checklist (P1 ✅ Complete)

### Architecture Boundaries
- ✅ No Supabase imports in `presentation/` or `domain/`
- ✅ Domain has no Flutter imports
- ✅ All styling uses tokens (zero hardcoded colors/dimensions)
- ✅ Shared components are stateless and reusable
- ✅ Feature has both fake repository (default in DI)
- ✅ Repository interface defines clear contracts

### Code Quality
- ✅ `const` constructors where possible
- ✅ Proper error handling with `AsyncValue`
- ✅ No TODO/FIXME comments without issues
- ✅ Multi-select checkbox behavior implemented
- ✅ Batch invitation handling with proper feedback

### Widget Management
- ✅ `flutter analyze` shows no errors
- ✅ Shared components exported in `shared/components/components.dart`
- ✅ Feature-specific widgets in correct folders
- ✅ All import paths correct and up-to-date

### UX/UI
- ✅ Loading states (dialog + AsyncValue)
- ✅ Error states with retry button
- ✅ Empty states handled (no groups, no events, no memories)
- ✅ Pull-to-refresh implemented
- ✅ Success/error banners with contextual messages
- ✅ Multi-group selection with visual feedback
- ✅ Checkbox right-aligned as requested
- ✅ No separators between groups
- ✅ Button disabled/enabled states with color change

---

## 10) Testing Guide for P2

### Manual Testing Scenarios

**Profile Loading:**
1. Navigate to other user profile
2. Verify loading indicator appears
3. Confirm profile data displays correctly
4. Test pull-to-refresh functionality

**Shared Events:**
1. Verify only confirmed events appear
2. Check date formatting and ordering
3. Confirm "Confirmed" badge displays
4. Test tap on event card (placeholder navigation)

**Shared Memories:**
1. Verify memory grid displays
2. Check proper photo loading
3. Test tap on memory (placeholder navigation)

**Invite Flow (Single Group):**
1. Tap invite icon
2. Select one group (checkbox becomes green)
3. Verify button turns green
4. Tap "Send Invitation"
5. Confirm success banner shows

**Invite Flow (Multiple Groups):**
1. Select 2+ groups (all checkboxes green)
2. Verify button stays green
3. Tap "Send Invitation"
4. Confirm success banner shows count (e.g., "2 invitations sent to Ana Silva")

**Edge Cases:**
1. User already in all groups → empty state message
2. Network error during load → error state with retry
3. Invitation fails → error banner displays
4. Partial failure (2 of 3 succeed) → info banner with count

### Supabase Queries to Test

**Shared events query:**
```sql
-- Must return events where BOTH users are participants
SELECT DISTINCT e.*
FROM events e
JOIN event_participants ep1 ON e.id = ep1.event_id
JOIN event_participants ep2 ON e.id = ep2.event_id
WHERE ep1.user_id = '<current_user_id>'
  AND ep2.user_id = '<target_user_id>'
  AND e.status = 'confirmed'
  AND e.date >= NOW()
ORDER BY e.date ASC;
```

**Invitable groups query:**
```sql
-- Groups where current user is member but target is not
SELECT g.id, g.name, g.group_photo_url, COUNT(gm.user_id) as member_count
FROM groups g
JOIN group_members gm1 ON g.id = gm1.group_id
LEFT JOIN group_members gm2 ON g.id = gm2.group_id AND gm2.user_id = '<target_user_id>'
LEFT JOIN group_invitations gi ON g.id = gi.group_id AND gi.invitee_user_id = '<target_user_id>' AND gi.status = 'pending'
JOIN group_members gm ON g.id = gm.group_id
WHERE gm1.user_id = '<current_user_id>'
  AND gm2.user_id IS NULL
  AND gi.id IS NULL
GROUP BY g.id, g.name, g.group_photo_url
ORDER BY g.name ASC;
```

---

## 11) Known Limitations & Future Work

**Current Scope (P1 Complete):**
- ✅ View other user profile
- ✅ See shared confirmed events
- ✅ See shared memories
- ✅ Multi-select group invitations
- ✅ Visual feedback for all states

**Out of Scope (Future Features):**
- Event detail page navigation (placeholder exists)
- Memory detail page navigation (placeholder exists)
- Real-time invitation status updates
- Invitation acceptance/rejection flow
- Block user functionality
- Report user functionality
- Edit shared event/memory from profile

**P2 Responsibilities:**
- Implement all data sources with proper RLS
- Create DTOs for JSON parsing
- Implement repository with error handling
- Override DI in main.dart
- Test all query performance with indexes
- Verify RLS policies prevent unauthorized access

---

## 12) Files Changed/Created (P1)

### Domain Layer
- ✅ `lib/features/profile/domain/entities/other_profile_entity.dart` (NEW)
- ✅ `lib/features/profile/domain/entities/invite_group_entity.dart` (NEW)
- ✅ `lib/features/profile/domain/repositories/other_profile_repository.dart` (NEW)
- ✅ `lib/features/profile/domain/usecases/get_other_user_profile.dart` (NEW)
- ✅ `lib/features/profile/domain/usecases/get_invitable_groups.dart` (NEW)
- ✅ `lib/features/profile/domain/usecases/invite_to_group.dart` (NEW)

### Data Layer
- ✅ `lib/features/profile/data/fakes/fake_other_profile_repository.dart` (NEW)

### Presentation Layer
- ✅ `lib/features/profile/presentation/pages/other_profile_page.dart` (NEW)
- ✅ `lib/features/profile/presentation/providers/other_profile_providers.dart` (NEW)
- ✅ `lib/features/profile/presentation/widgets/other_profile_app_bar.dart` (NEW)
- ✅ `lib/features/profile/presentation/widgets/upcoming_together_section.dart` (NEW)
- ✅ `lib/features/profile/presentation/widgets/invite_to_group_bottom_sheet.dart` (NEW)

### Shared Components
- ✅ `lib/shared/components/cards/confirmed_event_card.dart` (NEW)

### Routing
- ✅ `lib/routes/app_router.dart` (MODIFIED — added /other-profile route)

### Modified Shared Components
- ✅ `lib/shared/components/common/common_bottom_sheet.dart` (MODIFIED — fixed grabber bar spacing)

---

## 13) Dependencies

**Entities Used from Other Features:**
- `GroupEventEntity` — from `group_hub` feature
- `MemoryEntity` — from `profile` feature
- `ProfileEntity` — from `profile` feature (for UserInfoCard)

**Shared Components Used:**
- `UserInfoCard` — from profile feature widgets
- `MemoriesSection` — from profile feature widgets
- `TopBanner` — from shared/components/common
- `CommonBottomSheet` — from shared/components/common
- `ConfirmedEventCard` — from shared/components/cards (NEW)

**No Breaking Changes:** All entity dependencies are stable and already in use by other features.

---

## 14) Next Steps for P2

1. **Setup data layer structure:**
   - Create `data_sources/other_profile_data_source.dart`
   - Create `models/other_profile_model.dart`
   - Create `models/invite_group_model.dart`
   - Create `repositories/other_profile_repository_impl.dart`

2. **Implement Supabase queries:**
   - Test shared events query (check indexes)
   - Test invitable groups query (verify RLS)
   - Test invite insertion (handle duplicates)

3. **Create DTOs:**
   - Parse nested JSON for events/memories
   - Handle null values properly
   - Add toEntity() methods

4. **Override DI in main.dart:**
   - Replace fake repository provider
   - Wire SupabaseClient to data source

5. **Test end-to-end:**
   - Verify all queries respect RLS
   - Check performance with realistic data volumes
   - Test error handling (network failures, auth errors)
   - Validate batch invitation behavior

---

**Questions or blockers?** Open an issue tagged `other-profile` + `P2`.

**Ready for handoff!** 🚀
