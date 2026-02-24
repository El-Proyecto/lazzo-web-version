# GROUP_DETAILS P1→P2 HANDOFF

**Date:** 2025-11-09  
**Role P1 Status:** ✅ COMPLETE (UI + State + Domain Contracts)  
**Next:** Role P2 to implement Supabase data layer

---

## Overview

This handoff covers the **Group Details** feature including:
1. Group details page with shortcuts (Photos, Invite, Mute)
2. Group photos gallery (4-column grid with selection mode)
3. Group photo viewer (full-screen swipe navigation)
4. Invite bottom sheet (reusable component)

All UI is functional with **fake data**. P2 needs to implement Supabase repositories.

---

## ✅ Completed by P1

### 1. Domain Layer (Contracts)

#### Entities
**File:** `lib/features/group_hub/domain/entities/group_photo_entity.dart`
```dart
class GroupPhotoEntity {
  final String id;
  final String url;
  final DateTime capturedAt;
  final String? uploaderId;
  final String? uploaderName;
  final bool isPortrait;
}
```

**Critical Business Rules:**
- Photos are **always** associated with events/memories (not groups directly)
- One event can have multiple photos
- Events belong to groups, but photos link to events
- Photos must have captured timestamp for ordering

#### Repository Interface
**File:** `lib/features/group_hub/domain/repositories/group_photos_repository.dart`
```dart
abstract class GroupPhotosRepository {
  /// Get all photos for a specific memory/event
  /// Returns list of photos ordered by capturedAt desc
  Future<List<GroupPhotoEntity>> getMemoryPhotos(String memoryId);
}
```

**Method Contract:**
- **Input:** `memoryId` (String) - UUID of the event/memory
- **Output:** `List<GroupPhotoEntity>` ordered by `capturedAt DESC`
- **Expected behavior:** Return empty list if no photos, throw on error

---

### 2. Fake Data Layer

**File:** `lib/features/group_hub/data/fakes/fake_group_photos_repository.dart`

Implements `GroupPhotosRepository` with 10 mock photos:
- Mixed portrait/landscape orientations
- Various timestamps (2 hours ago to now)
- Different uploaders (Marco, Ana, João, Maria)
- Uses picsum.photos for placeholder images
- 500ms simulated network delay

**Mock Data Characteristics:**
- IDs: `photo-1` through `photo-10`
- URLs: `https://picsum.photos/{width}/{height}`
- Timestamps: Descending from now to -2 hours
- Uploader IDs: `user-1` through `user-4`

---

### 3. Presentation Layer

#### Providers
**File:** `lib/features/group_hub/presentation/providers/group_hub_providers.dart`

**Repository Provider:**
```dart
final groupPhotosRepositoryProvider = Provider<GroupPhotosRepository>((ref) {
  return FakeGroupPhotosRepository();
});
```

**State Provider:**
```dart
final groupPhotosProvider = StateNotifierProvider.family<
  GroupPhotosController, 
  AsyncValue<List<GroupPhotoEntity>>, 
  String
>((ref, memoryId) {
  return GroupPhotosController(
    ref.watch(groupPhotosRepositoryProvider),
    memoryId,
  );
});
```

**Controller:**
- `GroupPhotosController` manages photo list state
- Methods: `loadPhotos()`, `refresh()`
- Exposes `AsyncValue<List<GroupPhotoEntity>>`

#### Pages

##### 1. Group Photos Page (Gallery)
**File:** `lib/features/group_hub/presentation/pages/group_photos_page.dart`

**Features:**
- 4-column grid with square photo tiles
- Selection mode toggle (tap checkmark icon)
- Multi-select with visual feedback (green border + checkmark)
- Bottom action bar when photos selected (Share + Download buttons)
- CommonAppBar with back button and select icon
- Loading/error/empty states

**Props:**
```dart
GroupPhotosPage({
  required String memoryId,      // Event/memory UUID
  required String eventName,     // Display in viewer app bar
  required String locationAndDate, // Subtitle for viewer
})
```

**UI Specifications:**
- Grid: 4 columns, 8px spacing, 16px padding
- Photo tiles: Square (1:1 aspect ratio), BoxFit.cover
- Selection border: 3px green (BrandColors.planning)
- Checkmark indicator: 24px circle, top-right (4px offset)
- Action bar height: 48px buttons + padding + safe area
- Action buttons: Share (bg3), Download (planning green)

##### 2. Group Photo Viewer Page
**File:** `lib/features/group_hub/presentation/pages/group_photo_viewer_page.dart`

**Features:**
- Full-screen photo viewer with horizontal swipe (PageView)
- Pinch-to-zoom (0.5x to 4x via InteractiveViewer)
- Custom app bar matching MemoryViewerAppBar format
- Download button in app bar (top-right)

**Props:**
```dart
GroupPhotoViewerPage({
  required List<GroupPhotoEntity> photos,
  required int initialIndex,
  required String eventName,        // NOT group name!
  required String locationAndDate,
})
```

**UI Specifications:**
- Photo display: BoxFit.contain, centered
- Zoom: min 0.5x, max 4.0x
- App bar: Back button + centered title + download icon
- Title: Event name (18px, titleMediumEmph)
- Subtitle: Location • Date (12px, bodyMedium, text2)

##### 3. Group Details Page Updates
**File:** `lib/features/group_hub/presentation/pages/group_details_page.dart`

**New Shortcut: Photos**
- Icon: `Icons.photo_library_outlined`
- Navigation: Opens `GroupPhotosPage`
- Props passed: `groupId` (as memoryId), `groupName`, placeholder location/date

**Existing Shortcuts:**
- **Invite:** Opens `InviteBottomSheet` with group link and QR code
- **Mute/Unmute:** Toggles group notifications with optimistic UI update

#### Widgets

**File:** `lib/features/group_hub/presentation/widgets/group_photo_viewer_app_bar.dart`

Custom app bar matching `MemoryViewerAppBar` design:
```dart
GroupPhotoViewerAppBar({
  required String title,          // Event name
  String? subtitle,               // Location • Date (optional)
  required VoidCallback onBackPressed,
})
```

**Design Specs:**
- Height: 44px base (32px row + 12px top padding)
- Height with subtitle: 72px (44px + 8px gap + 20px text)
- Back button: 32x32px, iOS back arrow, left-aligned
- Title: Centered, 18px, titleMediumEmph
- Subtitle: Centered, 12px, bodyMedium, text2
- Download icon: 24px, top-right (placeholder for now)
- Background: BrandColors.bg1 (solid, not gradient)

---

### 4. Shared Components

#### Invite Bottom Sheet
**File:** `lib/shared/components/common/invite_bottom_sheet.dart`

**Reusable component** for inviting people to any entity (groups, events, etc.)

**Usage:**
```dart
InviteBottomSheet.show(
  context: context,
  entityName: 'My Group',
  entityType: 'group',
  shareLink: 'https://lazzo.app/join/xyz',
);
```

**Features:**
- Grabber bar (proper spacing, no extra padding)
- Title: Left-aligned, no subtitle
- Share link section: Copy button (bg2) + Share button (planning green)
- QR code section: Full-width, 180px QR code, white background
- TopBanner feedback for copy action
- share_plus integration for native sharing

**Dependencies:**
- `qr_flutter` for QR code generation
- `share_plus` for native share sheet

**Export:** Added to `lib/shared/components/components.dart`

---

## 🔄 P2 Implementation Tasks

### 1. Database Schema Requirements

#### Photos Table
```sql
CREATE TABLE group_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  memory_id UUID NOT NULL REFERENCES group_memories(id) ON DELETE CASCADE,
  url TEXT NOT NULL,  -- Storage path or URL
  captured_at TIMESTAMPTZ NOT NULL,
  uploader_id UUID REFERENCES profiles(id),
  is_portrait BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for efficient queries
CREATE INDEX idx_group_photos_memory_captured 
  ON group_photos(memory_id, captured_at DESC);
```

**Important Relationships:**
- Photos belong to `group_memories` (events), not directly to groups
- Events belong to groups via `group_memories.group_id`
- Use `memory_id` to fetch photos, not `group_id`

#### RLS Policies
```sql
-- Users can view photos from groups they belong to
CREATE POLICY "Users can view group photos"
  ON group_photos FOR SELECT
  USING (
    memory_id IN (
      SELECT id FROM group_memories
      WHERE group_id IN (
        SELECT group_id FROM group_members
        WHERE user_id = auth.uid()
      )
    )
  );

-- Users can upload photos to events in their groups
CREATE POLICY "Users can upload group photos"
  ON group_photos FOR INSERT
  WITH CHECK (
    memory_id IN (
      SELECT id FROM group_memories
      WHERE group_id IN (
        SELECT group_id FROM group_members
        WHERE user_id = auth.uid()
      )
    )
  );
```

---

### 2. Storage Structure

**Path Convention:**
```
/{groupId}/{eventId}/{userId}/{uuid}.jpg
```

**Metadata to Store:**
```json
{
  "uploader_id": "user-uuid",
  "uploaded_at": "2024-03-08T10:30:00Z",
  "content_type": "image/jpeg",
  "is_portrait": true,
  "captured_at": "2024-03-08T10:25:00Z"
}
```

**Bucket Configuration:**
- Name: `group-photos`
- Public: No (require auth)
- File size limit: 10MB per image
- Allowed types: `image/jpeg`, `image/png`, `image/heic`

---

### 3. Data Source Implementation

**File to Create:** `lib/features/group_hub/data/data_sources/group_photos_data_source.dart`

**Required Methods:**

```dart
class GroupPhotosDataSource {
  final SupabaseClient _supabase;

  GroupPhotosDataSource(this._supabase);

  /// Fetch photos for a memory/event
  /// Returns raw DB rows
  Future<List<Map<String, dynamic>>> getMemoryPhotos(String memoryId) async {
    final response = await _supabase
        .from('group_photos')
        .select('''
          id,
          url,
          captured_at,
          uploader_id,
          is_portrait,
          profiles:uploader_id (
            id,
            name
          )
        ''')
        .eq('memory_id', memoryId)
        .order('captured_at', ascending: false);

    return response as List<Map<String, dynamic>>;
  }

  /// Upload photo to storage and create DB record
  Future<String> uploadPhoto({
    required String memoryId,
    required String groupId,
    required File photoFile,
    required DateTime capturedAt,
    required bool isPortrait,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final fileExt = photoFile.path.split('.').last;
    final fileName = '${const Uuid().v4()}.$fileExt';
    final storagePath = '$groupId/$memoryId/$userId/$fileName';

    // 1. Upload to storage
    await _supabase.storage
        .from('group-photos')
        .upload(storagePath, photoFile, fileOptions: FileOptions(
          upsert: false,
          contentType: 'image/$fileExt',
        ));

    // 2. Get public URL
    final url = _supabase.storage
        .from('group-photos')
        .getPublicUrl(storagePath);

    // 3. Create DB record
    await _supabase.from('group_photos').insert({
      'memory_id': memoryId,
      'url': url,
      'captured_at': capturedAt.toIso8601String(),
      'uploader_id': userId,
      'is_portrait': isPortrait,
    });

    return url;
  }

  /// Delete photo (storage + DB)
  Future<void> deletePhoto(String photoId, String storagePath) async {
    // 1. Delete from storage
    await _supabase.storage.from('group-photos').remove([storagePath]);

    // 2. Delete DB record
    await _supabase.from('group_photos').delete().eq('id', photoId);
  }
}
```

**Key Implementation Notes:**
- Select only needed columns (id, url, captured_at, uploader_id, is_portrait)
- Join with `profiles` table for uploader name
- Use `order('captured_at', ascending: false)` with indexed column
- Respect storage path convention
- Handle storage errors separately from DB errors

---

### 4. Model/DTO Implementation

**File to Create:** `lib/features/group_hub/data/models/group_photo_model.dart`

```dart
import '../../domain/entities/group_photo_entity.dart';

class GroupPhotoModel {
  final String id;
  final String url;
  final DateTime capturedAt;
  final String? uploaderId;
  final String? uploaderName;
  final bool isPortrait;

  const GroupPhotoModel({
    required this.id,
    required this.url,
    required this.capturedAt,
    this.uploaderId,
    this.uploaderName,
    required this.isPortrait,
  });

  /// Parse from Supabase row
  factory GroupPhotoModel.fromJson(Map<String, dynamic> json) {
    return GroupPhotoModel(
      id: json['id'] as String,
      url: json['url'] as String,
      capturedAt: DateTime.parse(json['captured_at'] as String),
      uploaderId: json['uploader_id'] as String?,
      uploaderName: json['profiles']?['name'] as String?,
      isPortrait: json['is_portrait'] as bool? ?? false,
    );
  }

  /// Convert to domain entity
  GroupPhotoEntity toEntity() {
    return GroupPhotoEntity(
      id: id,
      url: url,
      capturedAt: capturedAt,
      uploaderId: uploaderId,
      uploaderName: uploaderName,
      isPortrait: isPortrait,
    );
  }
}
```

**Parsing Rules:**
- Handle nested `profiles` join for uploader name
- Default `isPortrait` to false if null
- Parse ISO8601 timestamp strings to DateTime
- Validate required fields (id, url, captured_at)

---

### 5. Repository Implementation

**File to Create:** `lib/features/group_hub/data/repositories/group_photos_repository_impl.dart`

```dart
import '../../domain/entities/group_photo_entity.dart';
import '../../domain/repositories/group_photos_repository.dart';
import '../data_sources/group_photos_data_source.dart';
import '../models/group_photo_model.dart';

class GroupPhotosRepositoryImpl implements GroupPhotosRepository {
  final GroupPhotosDataSource _dataSource;

  GroupPhotosRepositoryImpl(this._dataSource);

  @override
  Future<List<GroupPhotoEntity>> getMemoryPhotos(String memoryId) async {
    try {
      final rows = await _dataSource.getMemoryPhotos(memoryId);
      return rows
          .map((row) => GroupPhotoModel.fromJson(row).toEntity())
          .toList();
    } catch (e) {
      // Log error and rethrow
      throw Exception('Failed to fetch memory photos: $e');
    }
  }
}
```

**Error Handling:**
- Catch and normalize Supabase errors
- Return empty list if no photos (don't throw)
- Throw on network/auth errors
- Log errors for debugging

---

### 6. DI Override

**File to Update:** `lib/main.dart`

Add to `ProviderScope(overrides: [...])`:

```dart
// Group Photos Repository Override
groupPhotosRepositoryProvider.overrideWithValue(
  GroupPhotosRepositoryImpl(
    GroupPhotosDataSource(supabaseClient),
  ),
),
```

**Verification:**
- Provider uses `GroupPhotosRepository` interface (not fake)
- Data source receives authenticated Supabase client
- No UI changes needed after override

---

## 📋 Testing Checklist for P2

### Database & RLS
- [ ] Create `group_photos` table with correct schema
- [ ] Add indexes for `memory_id` and `captured_at`
- [ ] Verify RLS policies allow group members to view photos
- [ ] Verify RLS policies allow group members to upload photos
- [ ] Test photo deletion policies

### Storage
- [ ] Create `group-photos` bucket
- [ ] Configure bucket as private (require auth)
- [ ] Set file size limit to 10MB
- [ ] Test upload with path convention
- [ ] Test storage URL generation

### Data Source
- [ ] Implement `getMemoryPhotos()` with correct SQL query
- [ ] Join with `profiles` table for uploader name
- [ ] Order by `captured_at DESC`
- [ ] Handle empty results gracefully
- [ ] Test error scenarios (network, auth, invalid memoryId)

### Model/DTO
- [ ] Parse nested `profiles` join correctly
- [ ] Handle null `uploader_id` and `uploader_name`
- [ ] Default `isPortrait` to false
- [ ] Parse ISO8601 timestamps correctly
- [ ] Validate required fields

### Repository
- [ ] Implement interface correctly
- [ ] Convert models to entities
- [ ] Return empty list for no photos (don't throw)
- [ ] Normalize error messages
- [ ] Log errors appropriately

### Integration
- [ ] Update DI override in `main.dart`
- [ ] Test photo loading in gallery page
- [ ] Verify photo viewer navigation
- [ ] Test selection mode functionality
- [ ] Verify share/download placeholders work

### UI Verification
- [ ] Gallery shows photos in 4-column grid
- [ ] Photos are square (cropped correctly)
- [ ] Selection mode toggles properly
- [ ] Bottom action bar appears when photos selected
- [ ] Viewer swipes horizontally between photos
- [ ] Zoom works (0.5x to 4x)
- [ ] App bar shows event name (not group name)
- [ ] Back navigation works from gallery and viewer

---

## 🚨 Critical Notes

### Photos → Events → Groups Relationship
**IMPORTANT:** Photos are linked to **events (memories)**, not groups directly.

```
Group → has many → Events (Memories) → has many → Photos
```

- Use `memory_id` to fetch photos, not `group_id`
- Event name displayed in viewer app bar (not group name)
- Photos cannot exist without an associated event
- Deleting an event should cascade delete its photos

### Navigation Flow
```
GroupDetailsPage → (tap Photos shortcut)
  ↓
GroupPhotosPage (gallery with grid)
  ↓ (tap photo)
GroupPhotoViewerPage (full-screen viewer)
```

**Data passed through navigation:**
- `memoryId` (String) - Required for fetching photos
- `eventName` (String) - Display in viewer app bar
- `locationAndDate` (String) - Subtitle in viewer
- Current implementation uses placeholder: "Porto • Mar 8, 2024"

### Photo Upload (Future Work)
Not included in this handoff, but P2 should prepare for:
- Camera/gallery picker integration
- Image compression before upload
- Upload progress indicator
- Batch upload support
- EXIF data extraction (captured_at, is_portrait)

---

## 📦 Files Checklist

### Created by P1 ✅
- [x] `domain/entities/group_photo_entity.dart`
- [x] `domain/repositories/group_photos_repository.dart`
- [x] `data/fakes/fake_group_photos_repository.dart`
- [x] `presentation/providers/group_hub_providers.dart` (updated)
- [x] `presentation/pages/group_photos_page.dart`
- [x] `presentation/pages/group_photo_viewer_page.dart`
- [x] `presentation/widgets/group_photo_viewer_app_bar.dart`
- [x] `shared/components/common/invite_bottom_sheet.dart`

### To Create by P2 ⏳
- [ ] `data/data_sources/group_photos_data_source.dart`
- [ ] `data/models/group_photo_model.dart`
- [ ] `data/repositories/group_photos_repository_impl.dart`
- [ ] Database migration for `group_photos` table
- [ ] RLS policies for `group_photos`
- [ ] Storage bucket `group-photos` configuration
- [ ] DI override in `main.dart`

---

## 🎯 Success Criteria

P2 implementation is complete when:
1. ✅ Photos load from Supabase in gallery page
2. ✅ Photos display in correct order (captured_at DESC)
3. ✅ RLS allows group members to view photos
4. ✅ Error states handled gracefully (network, auth, empty)
5. ✅ No UI changes needed (fake → real swap transparent)
6. ✅ All tests pass (unit + integration)
7. ✅ Storage bucket configured with correct permissions
8. ✅ Photo viewer shows correct event name and metadata

---

## 📞 Questions for P2?

Contact P1 if you need clarification on:
- Entity field meanings or validation rules
- Expected error handling behavior
- UI state transitions
- Navigation parameter requirements
- Photo upload requirements (future work)

---

**P1 Sign-off:** ✅ Ready for P2 implementation  
**Next Review:** After P2 completes data layer + DI override
