# Memory Management Feature - P1 to P2 Handoff Documentation

**Date:** 16 de novembro de 2025  
**Feature:** Memory viewing, photo management, and cover selection system  
**P1 Status:** ✅ COMPLETE - Ready for P2  
**P2 Focus:** Data layer implementation with Supabase, Storage integration, and RLS policies  

---

## 📋 Executive Summary

The Memory Management feature UI layer (P1) is complete with three distinct pages: Memory Viewer (full-screen photo browsing), Photo Preview (photo management preview), and Manage Photos (photo editing/deletion/cover selection). All components follow Clean Architecture principles, use design tokens, and implement proper selection modes. P2 needs to implement the Supabase data layer with proper Storage integration, RLS policies, and photo upload/deletion operations.

---

## ✅ P1 Deliverables Completed

### 🎨 **Pages Implemented**

#### **1. Memory Page** (`memory_page.dart`)
- **Purpose:** Main memory display page with state-based UI
- **Features:**
  - 3-state system based on event status (living/recap/ended)
  - CTA banner for adding photos (living=purple camera, recap=orange add_photo)
  - Cover mosaic with 1-3 photos (adaptive layout)
  - Event title and subtitle (location • date)
  - Photo grid for non-cover photos
  - Edit button (conditional on event status and permissions)
  - Navigation to Memory Viewer, Manage Photos, and Photo Preview

**Three Event States:**
1. **Living (`FakeEventStatus.living`):**
   - CTA banner shown if `!userHasUploadedPhotos` (purple camera button)
   - Edit button visible if `isHost || userHasUploadedPhotos`
   - Banner text: "Add your photos" / "You can then select a photo cover"
   
2. **Recap (`FakeEventStatus.recap`):**
   - CTA banner shown if `!userHasUploadedPhotos` (orange add_photo button)
   - Edit button visible if `isHost || userHasUploadedPhotos`
   - Banner text: "Add your photos" / "You can then select a photo cover"
   
3. **Ended (`FakeEventStatus.ended`):**
   - No CTA banner (read-only)
   - No edit button
   - Memory becomes a permanent record

#### **2. Memory Viewer Page** (`memory_viewer_page.dart`)
- **Purpose:** Full-screen photo viewer for browsing event memories
- **Features:**
  - Horizontal scroll navigation between photos
  - Dynamic app bar with event title and subtitle (location • date)
  - Edit button (only visible for living/recap events, not ended)
  - Multi-day event detection with day labels
  - Opens directly to specific photo via initialPhotoId
  - Photo ordering: covers first (by votes), then grid (by timestamp)

#### **3. Photo Preview Page** (`photo_preview_page.dart`)
- **Purpose:** Photo management preview with actions (accessed from Manage Photos)
- **Features:**
  - Horizontal scroll through photos
  - Fixed header with "Photos Preview" title and back button
  - Profile photo (32x32) next to uploader name
  - Delete button (red, only for user's photos or if host)
  - "Promote to Cover" button (recap orange, always visible)
  - Navigation back to Manage Photos with success banner
  - Photos respect layout sizing (4:5 portrait, 16:9 landscape)

#### **4. Manage Photos Page** (`manage_memory_page.dart`)
- **Purpose:** Photo management interface with selection mode and cover selection
- **Features:**
  - **State-based header:**
    - If `!userHasUploadedPhotos`: CTA banner (living=purple camera, recap=orange add_photo)
    - If `userHasUploadedPhotos`: Cover selection card (centered, tap to select)
  - Selection mode toggle (delete icon → close icon when active)
  - User photos sorted first, then others
  - Selection restrictions: only user's photos (or all if host)
  - Bottom delete button with count when photos selected
  - Add photo card at the end if space available (max 20 or 5 × participants)
  - Confirmation dialogs for destructive actions
  - Success banners for operations

### 🧩 **Widget Components**

#### **Shared Components** (`shared/components/cards/`)
- **AddPhotosCtaCard:** CTA banner prompting users to add photos
  - Factory constructors: `AddPhotosCtaCard.living()` (purple camera), `.recap()` (orange add_photo)
  - Layout: Title/subtitle left, icon button right (48x48)
  - P1 Implementation: Navigates to Manage Photos for testing
  - **P2 TODO:** Replace navigation with actual camera/gallery picker
    - Living: open camera directly
    - Recap: open photo gallery picker
  - Styling: bg2 card, md radius, md padding, tokenized colors

#### **Feature-Specific Widgets** (`features/memory/presentation/widgets/`)
- **MemoryViewerAppBar:** Custom app bar with optional trailing action
- **PhotoViewerItem:** Full-screen photo display with day labels for multi-day events
- **PhotoGridItem:** Grid item with selection mode support, checkboxes, and borders
- **CoverSelectionCard:** Card for selecting/displaying cover photo
- **AddPhotoCard:** Placeholder card for adding new photos (grid item)

### 🏗️ **Domain Layer Contracts**

#### **Entities** (`features/memory/domain/entities/`)

**MemoryEntity:**
```dart
class MemoryEntity {
  final String id;
  final String eventId;          // Link to event for status checking
  final String title;
  final String? location;
  final DateTime eventDate;
  final List<MemoryPhoto> photos;
  
  List<MemoryPhoto> get coverPhotos;    // Up to 3, sorted by votes
  List<MemoryPhoto> get gridPhotos;     // Non-covers, sorted by timestamp
}
```

**MemoryPhoto:**
```dart
class MemoryPhoto {
  final String id;
  final String url;              // Full resolution
  final String? thumbnailUrl;    // 512px for grid
  final String? coverUrl;        // 1024px for cover mosaic
  final int voteCount;
  final DateTime capturedAt;
  final double aspectRatio;      // width / height
  final String uploaderId;
  final String uploaderName;
  final bool isCover;
  
  bool get isPortrait => aspectRatio < 1.0;
  bool get isLandscape => aspectRatio >= 1.0;
}
```

#### **Repository Interface** (`features/memory/domain/repositories/`)

```dart
abstract class MemoryRepository {
  /// Get memory by ID
  Future<MemoryEntity?> getMemoryById(String memoryId);
  
  /// Get memory by event ID
  Future<MemoryEntity?> getMemoryByEventId(String eventId);
  
  /// Share memory (returns share URL or triggers native share)
  Future<String> shareMemory(String memoryId);
  
  /// Update cover photo for a memory
  /// Pass null photoId to remove cover
  Future<bool> updateCover(String memoryId, String? photoId);
  
  /// Remove a photo from a memory
  /// Only uploader or host can remove photos
  Future<bool> removePhoto(String memoryId, String photoId);
}
```

#### **Use Cases** (`features/memory/domain/usecases/`)

1. **GetMemory:** Fetch memory by ID
2. **GetMemoryPhotos:** Get ordered photos (covers first, then grid)
3. **ShareMemory:** Generate share URL or trigger native share
4. **UpdateMemoryCover:** Update cover photo selection
5. **RemoveMemoryPhoto:** Delete photo with permission check

### 🎭 **Fake Data Layer**

**FakeMemoryRepository** (`features/memory/data/fakes/`)
- **FakeMemoryConfig:** Test configuration for different layouts and states
  - Photo counts: `coverPortraitCount`, `coverLandscapeCount`, `gridPortraitCount`, `gridLandscapeCount`
  - Event state: `eventStatus` (living/recap/ended) - controls UI behavior
  - Permissions: `isHost` - toggle host permissions for testing
  - Upload state: `userHasUploadedPhotos` - controls CTA banner visibility
- Dynamic memory generation based on config
- Realistic delays for network simulation
- Vote distribution ensures correct cover ordering (portraits first)
- First 2 portrait + first 2 landscape photos belong to current user
- Mock implementations for all repository methods

**Testing Different States:**
```dart
// Living state with CTA banner
FakeMemoryConfig.eventStatus = FakeEventStatus.living;
FakeMemoryConfig.userHasUploadedPhotos = false;

// Recap state with photos uploaded
FakeMemoryConfig.eventStatus = FakeEventStatus.recap;
FakeMemoryConfig.userHasUploadedPhotos = true;

// Ended state (read-only)
FakeMemoryConfig.eventStatus = FakeEventStatus.ended;
```

### 📱 **State Management**

#### **Memory Providers** (`memory_providers.dart`)
```dart
// Repository provider (fake by default)
final memoryRepositoryProvider = Provider<MemoryRepository>

// Use case providers
final getMemoryUseCaseProvider = Provider<GetMemory>
final shareMemoryUseCaseProvider = Provider<ShareMemory>
final getMemoryPhotosUseCaseProvider = Provider<GetMemoryPhotos>
final updateMemoryCoverUseCaseProvider = Provider<UpdateMemoryCover>
final removeMemoryPhotoUseCaseProvider = Provider<RemoveMemoryPhoto>

// Data providers
final memoryDetailProvider = FutureProvider.family<MemoryEntity?, String>
final memoryPhotosProvider = FutureProvider.family<List<MemoryPhoto>, String>

// Action provider
final shareMemoryProvider = StateNotifierProvider<ShareMemoryNotifier, AsyncValue<String?>>
```

#### **Manage Memory Providers** (`manage_memory_providers.dart`)
```dart
// State model
class ManageMemoryState {
  final String memoryId;
  final List<ManagePhotoItem> allPhotos;      // User photos first, then others
  final ManagePhotoItem? selectedCover;       // Cover selection
  final int maxPhotos;                        // max(20, 5 × participants)
  final bool isHost;
  final String currentUserId;
}

// Photo item for management UI
class ManagePhotoItem {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final bool isPortrait;
  final String uploaderId;
  final String uploaderName;
  final bool isUploadedByCurrentUser;
}

// State notifier
final manageMemoryProvider = StateNotifierProvider.family<ManageMemoryNotifier, AsyncValue<ManageMemoryState>, String>
```

### ✨ **Key Features Implemented**

#### **Selection Mode System**
- ✅ Toggle between normal and selection mode (delete → close icon)
- ✅ Only user's photos selectable (or all if host)
- ✅ Green border (3px) on selected photos
- ✅ Checkboxes visible only in selection mode
- ✅ Non-selectable photos dimmed with ColorFilter
- ✅ Bottom delete button shows count when photos selected
- ✅ Confirmation dialog before deletion
- ✅ Selection mode exits after deletion or close

#### **Photo Layout Sizing**
- ✅ Portrait photos: 4:5 aspect ratio (0.8)
- ✅ Landscape photos: 16:9 aspect ratio (1.78)
- ✅ Photo Preview respects layout sizing (not full screen)
- ✅ Memory Viewer shows full screen photos
- ✅ Grid uses thumbnailUrl (512px) for performance
- ✅ Viewer uses coverUrl (1024px) for quality

#### **Cover Selection Flow**
- ✅ Cover selection card centered at top of Manage Photos
- ✅ Tap to open bottom sheet with photo selector
- ✅ Selected photo shown in card with "Change" text
- ✅ Remove cover option when cover exists
- ✅ No cover selected by default
- ✅ Save changes updates memory

#### **Permission System**
- ✅ Edit button only visible for living/recap events (EventStatus.ended)
- ✅ Delete button only for user's photos or if host
- ✅ Selection mode respects photo ownership
- ✅ Promote to Cover available for all photos

#### **User Experience**
- ✅ Top banners for success feedback ("Cover updated!", "Photo deleted!")
- ✅ Confirmation dialogs for destructive actions
- ✅ Profile photos (32x32) next to uploader names
- ✅ Proper empty states and error handling
- ✅ Smooth animations and transitions
- ✅ Keyboard-safe layouts

#### **3-State Event System**
- ✅ FakeEventStatus enum (living/recap/ended) in FakeMemoryConfig
- ✅ Memory Page shows CTA banner for living/recap when !userHasUploadedPhotos
- ✅ Manage Photos Page shows CTA banner when !userHasUploadedPhotos
- ✅ Edit button visibility based on event status and permissions
- ✅ Ended events are read-only (no CTA, no edit button)
- ✅ CTA banner navigates to Manage Photos (temporary P1 implementation)

---

## 🚀 P2 Implementation Requirements

### 📸 **Photo Upload & CTA Banner (Critical P2 Task)**

#### **Replace CTA Banner Navigation with Camera/Gallery Picker**

**Current P1 Implementation:**
- `AddPhotosCtaCard.living()` and `.recap()` navigate to Manage Photos for testing
- `onPressed` callback passed from Memory Page and Manage Photos Page

**P2 Required Changes:**

1. **Living State - Open Camera:**
```dart
// In memory_page.dart and manage_memory_page.dart
AddPhotosCtaCard.living(
  onPressed: () async {
    // P2: Replace with actual camera picker
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85, // Compression
    );
    
    if (photo != null) {
      await _uploadPhoto(File(photo.path));
    }
  },
)
```

2. **Recap State - Open Gallery:**
```dart
// In memory_page.dart and manage_memory_page.dart
AddPhotosCtaCard.recap(
  onPressed: () async {
    // P2: Replace with actual gallery picker
    final ImagePicker picker = ImagePicker();
    final List<XFile> photos = await picker.pickMultiImage(
      imageQuality: 85, // Compression
      limit: 10, // Max photos per selection
    );
    
    if (photos.isNotEmpty) {
      for (final photo in photos) {
        await _uploadPhoto(File(photo.path));
      }
    }
  },
)
```

3. **Upload Photo Method (P2):**
```dart
Future<void> _uploadPhoto(File photo) async {
  // Show loading indicator
  setState(() => _isUploading = true);
  
  try {
    // Get memory and event details
    final memory = await ref.read(memoryDetailProvider(memoryId).future);
    final event = await getEventDetail(memory.eventId);
    
    // Compress image
    final compressed = await ImageCompressionService.compress(photo);
    
    // Generate storage path
    final uuid = const Uuid().v4();
    final path = '${event.groupId}/${memory.eventId}/$currentUserId/$uuid.jpg';
    
    // Upload to Supabase Storage
    final storageService = ref.read(storageServiceProvider);
    await storageService.uploadMemoryPhoto(
      path: path,
      file: compressed,
      metadata: {
        'uploader': currentUserId,
        'type': 'memory_photo',
        'captured_at': DateTime.now().toIso8601String(),
      },
    );
    
    // Create photo record in database
    final photoRepository = ref.read(memoryRepositoryProvider);
    await photoRepository.addPhoto(
      memoryId: memoryId,
      storagePath: path,
      aspectRatio: await _calculateAspectRatio(photo),
    );
    
    // Refresh memory data
    ref.invalidate(memoryDetailProvider(memoryId));
    
    // Show success banner
    TopBanner.showSuccess(context, message: 'Photo uploaded!');
    
    // Update userHasUploadedPhotos flag (P2: from real data)
    FakeMemoryConfig.userHasUploadedPhotos = true;
    
  } catch (e) {
    TopBanner.showError(context, message: 'Failed to upload photo: $e');
  } finally {
    setState(() => _isUploading = false);
  }
}
```

4. **Dependencies:**
```yaml
dependencies:
  image_picker: ^1.1.2  # Camera and gallery access
  uuid: ^4.5.1          # Generate unique photo IDs
```

5. **Permissions (iOS/Android):**
```xml
<!-- iOS: Info.plist -->
<key>NSCameraUsageDescription</key>
<string>We need camera access to capture memories</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select photos</string>

<!-- Android: AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

**P2 Testing Checklist:**
- [ ] Camera opens in Living state
- [ ] Gallery opens in Recap state with multi-select
- [ ] Image compression works (target <1MB)
- [ ] Storage upload succeeds with correct path
- [ ] Database record created with correct metadata
- [ ] CTA banner disappears after first upload
- [ ] Edit button appears after first upload
- [ ] Cover selection card appears in Manage Photos after first upload
- [ ] Proper error handling for failed uploads
- [ ] Loading states during upload

### 🗄️ **Data Layer Implementation**

#### **1. Supabase Memory Repository** (`features/memory/data/repositories/memory_repository_impl.dart`)
```dart
class MemoryRepositoryImpl implements MemoryRepository {
  final SupabaseClient _client;
  final StorageService _storage;
  
  @override
  Future<MemoryEntity?> getMemoryById(String memoryId) async {
    // Select minimal columns:
    // - memory.id, event_id, title, location, event_date
    // - photos: id, url, thumbnail_url, cover_url, vote_count, captured_at,
    //          aspect_ratio, uploader_id, uploader_name, is_cover
    // ORDER BY photos: is_cover DESC, vote_count DESC, captured_at ASC
    // Include uploader name via join or RPC
  }
  
  @override
  Future<bool> updateCover(String memoryId, String? photoId) async {
    // Update photos.is_cover = true for selected photo
    // Set is_cover = false for all other photos in this memory
    // Use transaction or RPC for atomicity
    // Respect RLS: only host can update
  }
  
  @override
  Future<bool> removePhoto(String memoryId, String photoId) async {
    // Check permissions: uploader_id = current_user OR user is event host
    // Delete from Supabase Storage: /groupId/eventId/userId/uuid.jpg
    // Delete photo record from database
    // Use transaction to ensure consistency
  }
  
  @override
  Future<String> shareMemory(String memoryId) async {
    // Generate shareable link or trigger native share
    // Could use deep links: lazzo://memory/{memoryId}
  }
}
```

#### **2. Memory Data Source** (`features/memory/data/data_sources/memory_data_source.dart`)
```dart
class MemoryDataSource {
  final SupabaseClient _client;
  final StorageService _storage;
  
  // Raw Supabase operations
  Future<Map<String, dynamic>?> fetchMemory(String memoryId);
  Future<List<Map<String, dynamic>>> fetchMemoryPhotos(String memoryId);
  Future<void> updatePhotoIsCover(String photoId, bool isCover);
  Future<void> deletePhoto(String photoId);
  Future<String> deletePhotoFromStorage(String storagePath);
}
```

#### **3. Memory DTO/Models** (`features/memory/data/models/memory_model.dart`)
```dart
class MemoryModel {
  final String id;
  final String eventId;
  final String title;
  final String? location;
  final DateTime eventDate;
  final List<MemoryPhotoModel> photos;
  
  // From Supabase row
  factory MemoryModel.fromJson(Map<String, dynamic> json);
  
  // To domain entity
  MemoryEntity toEntity();
}

class MemoryPhotoModel {
  // All MemoryPhoto fields
  
  factory MemoryPhotoModel.fromJson(Map<String, dynamic> json);
  MemoryPhoto toEntity();
}
```

### 📸 **Storage Integration**

#### **Photo Upload Flow** (for Add Photo Card)
```dart
Future<String> uploadPhoto(File photo, String memoryId) async {
  // 1. Get event details for groupId
  final memory = await getMemoryById(memoryId);
  final event = await getEventDetail(memory.eventId);
  
  // 2. Generate path: /groupId/eventId/userId/uuid.jpg
  final uuid = Uuid().v4();
  final path = '${event.groupId}/${memory.eventId}/$currentUserId/$uuid.jpg';
  
  // 3. Compress image (see image_compression_service.dart)
  final compressed = await compressImage(photo);
  
  // 4. Upload to Supabase Storage
  await _storage.upload(path, compressed, metadata: {
    'uploader': currentUserId,
    'type': 'memory_photo',
    'captured_at': DateTime.now().toIso8601String(),
  });
  
  // 5. Generate thumbnails (512px and 1024px) - consider using Supabase transforms
  
  // 6. Insert photo record in database
  await _client.from('memory_photos').insert({
    'memory_id': memoryId,
    'url': publicUrl,
    'thumbnail_url': thumbnailUrl,
    'cover_url': coverUrl,
    'aspect_ratio': aspectRatio,
    'uploader_id': currentUserId,
    'captured_at': capturedAt,
    'is_cover': false,
  });
  
  return photoId;
}
```

#### **Photo Deletion Flow**
```dart
Future<bool> deletePhoto(String memoryId, String photoId) async {
  // 1. Get photo record
  final photo = await _client
    .from('memory_photos')
    .select('storage_path, uploader_id, memory_id')
    .eq('id', photoId)
    .single();
  
  // 2. Check permissions (RLS should also enforce this)
  final memory = await getMemoryById(memoryId);
  final event = await getEventDetail(memory.eventId);
  final isHost = event.hostId == currentUserId;
  final isUploader = photo['uploader_id'] == currentUserId;
  
  if (!isHost && !isUploader) {
    throw UnauthorizedException('Cannot delete this photo');
  }
  
  // 3. Delete from Storage
  await _storage.delete(photo['storage_path']);
  
  // 4. Delete thumbnails if separate files
  await _storage.delete('${photo['storage_path']}_thumb');
  await _storage.delete('${photo['storage_path']}_cover');
  
  // 5. Delete database record (cascade should handle related data)
  await _client.from('memory_photos').delete().eq('id', photoId);
  
  return true;
}
```

### 🔧 **Dependency Injection Setup**

#### **Update main.dart**
```dart
ProviderScope(
  overrides: [
    memoryRepositoryProvider.overrideWithValue(
      MemoryRepositoryImpl(
        supabaseClient,
        storageService,
      )
    ),
  ],
  child: App(),
)
```

---

## 📊 Database Schema Requirements

### **Memories Table**
```sql
CREATE TABLE memories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  location TEXT,
  event_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for event lookup
CREATE INDEX idx_memories_event_id ON memories(event_id);
```

### **Memory Photos Table**
```sql
CREATE TABLE memory_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  memory_id UUID NOT NULL REFERENCES memories(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  thumbnail_url TEXT,
  cover_url TEXT,
  storage_path TEXT NOT NULL,  -- For deletion
  vote_count INTEGER DEFAULT 0,
  captured_at TIMESTAMPTZ NOT NULL,
  aspect_ratio DECIMAL(5,2) NOT NULL,
  uploader_id UUID NOT NULL REFERENCES auth.users(id),
  is_cover BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_memory_photos_memory_id ON memory_photos(memory_id);
CREATE INDEX idx_memory_photos_uploader_id ON memory_photos(uploader_id);
CREATE INDEX idx_memory_photos_is_cover ON memory_photos(is_cover) WHERE is_cover = TRUE;

-- Constraint: max 3 covers per memory
CREATE UNIQUE INDEX idx_memory_max_covers 
ON memory_photos(memory_id, is_cover) 
WHERE is_cover = TRUE;
-- Note: This allows exactly 1 cover per memory. For multiple covers, use a check constraint instead.
```

### **RLS Policies**

#### **Memories Table**
```sql
-- Read: users can view memories for events in their groups
CREATE POLICY memories_read ON memories
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM events e
      JOIN group_members gm ON gm.group_id = e.group_id
      WHERE e.id = memories.event_id
      AND gm.user_id = auth.uid()
    )
  );

-- No direct insert/update/delete (handled through events lifecycle)
```

#### **Memory Photos Table**
```sql
-- Read: same as memories
CREATE POLICY memory_photos_read ON memory_photos
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM memories m
      JOIN events e ON e.id = m.event_id
      JOIN group_members gm ON gm.group_id = e.group_id
      WHERE m.id = memory_photos.memory_id
      AND gm.user_id = auth.uid()
    )
  );

-- Insert: group members can add photos
CREATE POLICY memory_photos_insert ON memory_photos
  FOR INSERT
  WITH CHECK (
    uploader_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM memories m
      JOIN events e ON e.id = m.event_id
      JOIN group_members gm ON gm.group_id = e.group_id
      WHERE m.id = memory_photos.memory_id
      AND gm.user_id = auth.uid()
    )
  );

-- Update: only host can update is_cover
CREATE POLICY memory_photos_update_cover ON memory_photos
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM memories m
      JOIN events e ON e.id = m.event_id
      WHERE m.id = memory_photos.memory_id
      AND e.host_id = auth.uid()
    )
  )
  WITH CHECK (
    -- Only allow updating is_cover field
    (old.url = new.url 
    AND old.uploader_id = new.uploader_id
    AND old.captured_at = new.captured_at)
  );

-- Delete: uploader or host can delete
CREATE POLICY memory_photos_delete ON memory_photos
  FOR DELETE
  USING (
    uploader_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM memories m
      JOIN events e ON e.id = m.event_id
      WHERE m.id = memory_photos.memory_id
      AND e.host_id = auth.uid()
    )
  );
```

### **Storage Bucket**

```sql
-- Create bucket for memory photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('memory-photos', 'memory-photos', true);

-- RLS policies for storage
CREATE POLICY "Group members can upload photos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'memory-photos'
  AND auth.role() = 'authenticated'
  AND (storage.foldername(name))[1] IN (
    SELECT g.id::text 
    FROM group_members gm 
    JOIN groups g ON g.id = gm.group_id
    WHERE gm.user_id = auth.uid()
  )
);

CREATE POLICY "Anyone can view photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'memory-photos');

CREATE POLICY "Uploader or host can delete photos"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'memory-photos'
  AND (
    -- Uploader can delete own photos
    (storage.foldername(name))[3] = auth.uid()::text
    -- OR user is host of the event
    OR EXISTS (
      SELECT 1 FROM events e
      WHERE e.id::text = (storage.foldername(name))[2]
      AND e.host_id = auth.uid()
    )
  )
);
```

---

## 🧪 Testing Strategy for P2

### **Unit Tests**
- MemoryRepositoryImpl with mock Supabase client
- Photo upload/deletion logic
- Permission checks (host, uploader, group member)
- Model serialization/deserialization
- Use case business logic

### **Integration Tests**
- End-to-end memory fetching flow
- Photo upload with storage and database
- Cover selection update (transaction)
- Photo deletion (storage + database)
- RLS policy validation

### **UI Tests**
- Selection mode toggle and selection
- Cover selection bottom sheet flow
- Photo deletion confirmation
- Permission-based UI visibility
- Success banners and error handling

---

## 📁 File Structure Reference

```
lib/features/memory/
├── domain/
│   ├── entities/
│   │   └── memory_entity.dart ✅
│   ├── repositories/
│   │   └── memory_repository.dart ✅
│   └── usecases/
│       ├── get_memory.dart ✅
│       ├── get_memory_photos.dart ✅
│       ├── share_memory.dart ✅
│       ├── update_memory_cover.dart ✅
│       └── remove_memory_photo.dart ✅
├── data/
│   ├── data_sources/
│   │   └── memory_data_source.dart ❌ (P2)
│   ├── models/
│   │   ├── memory_model.dart ❌ (P2)
│   │   └── memory_photo_model.dart ❌ (P2)
│   ├── repositories/
│   │   └── memory_repository_impl.dart ❌ (P2)
│   └── fakes/
│       └── fake_memory_repository.dart ✅
└── presentation/
    ├── pages/
    │   ├── memory_page.dart ✅
    │   ├── memory_viewer_page.dart ✅
    │   ├── photo_preview_page.dart ✅
    │   └── manage_memory_page.dart ✅
    ├── providers/
    │   ├── memory_providers.dart ✅
    │   └── manage_memory_providers.dart ✅
    └── widgets/
        ├── memory_viewer_app_bar.dart ✅
        ├── photo_viewer_item.dart ✅
        ├── photo_grid_item.dart ✅
        ├── cover_selection_card.dart ✅
        └── add_photo_card.dart ✅

lib/routes/
└── app_router.dart ✅ (routes: memoryViewer, photoPreview, manageMemory)
```

**Legend:**
- ✅ Complete (P1)
- ❌ To implement (P2)

---

## 🔍 Quality Checklist for P2

### **Code Quality**
- [ ] All repository methods implement proper error handling
- [ ] RLS policies are respected in all queries and tested
- [ ] Minimal column selection following agent guide
- [ ] Proper use of indexes for photo queries
- [ ] No Flutter/UI imports in domain layer
- [ ] Storage paths follow convention: /groupId/eventId/userId/uuid.jpg
- [ ] Image compression before upload (see image_compression_service.dart)
- [ ] Thumbnail generation (512px and 1024px)

### **Performance**
- [ ] Database queries use proper indexes (memory_id, uploader_id, is_cover)
- [ ] Photos use thumbnailUrl for grid display (not full URL)
- [ ] Large photo lists are paginated or lazy-loaded
- [ ] Storage operations have timeout handling
- [ ] Image compression reduces upload size

### **Security**
- [ ] RLS policies prevent unauthorized access to memories
- [ ] Only uploader or host can delete photos
- [ ] Only host can update cover selection
- [ ] Storage bucket policies match database RLS
- [ ] No admin keys or bypasses in client code

### **User Experience**
- [ ] Loading states shown for network operations
- [ ] Offline state handled gracefully
- [ ] Upload progress indicator
- [ ] Error messages are user-friendly
- [ ] Success banners provide clear feedback

---

## 🚨 Known Issues & Considerations

### **Current State (Fake Implementation)**
- All data operations use in-memory fake repository
- Photo URLs point to picsum.photos (placeholders)
- No actual storage operations
- No network error handling
- Permission checks simulated via FakeMemoryConfig.isHost

### **Photo Sizing Considerations**
- Portrait: 4:5 aspect ratio (0.8) - 800x1000px source
- Landscape: 16:9 aspect ratio (1.78) - 1600x900px source
- Thumbnail: 512px (for grid display)
- Cover: 1024px (for cover mosaic and viewer)
- Full: Original resolution (for full-screen viewing)

### **Cover Selection Rules**
- Maximum 3 covers per memory
- Covers sorted by votes (portraits tend to have higher votes)
- User can remove cover (sets is_cover = false)
- No cover selected by default in manage mode

### **Permission Matrix**
| Action | Own Photo | Other's Photo (Not Host) | Other's Photo (Host) |
|--------|-----------|-------------------------|---------------------|
| View | ✅ | ✅ | ✅ |
| Delete | ✅ | ❌ | ✅ |
| Select for deletion | ✅ | ❌ | ✅ |
| Promote to Cover | ✅ | ✅ | ✅ |
| See in grid | ✅ | ✅ | ✅ |

### **Storage Path Convention**
```
/groupId/eventId/userId/uuid.jpg
Example: /550e8400-e29b-41d4-a716-446655440000/event123/user456/photo-uuid.jpg
```

### **Performance Notes**
- Grid should use thumbnailUrl (512px) for performance
- Memory Viewer should use coverUrl (1024px) for quality
- Full resolution only loaded on demand
- Consider lazy loading for large photo counts
- Image compression should target <1MB per photo

---

## 📞 Support & Questions

For questions about the P1 implementation or clarification on P2 requirements:

1. **Architecture Questions**: Refer to `agents.md` and `README.md`
2. **Component Usage**: Check component documentation in source files
3. **State Management**: Review providers and state notifier patterns
4. **Domain Contracts**: All interfaces are defined and documented
5. **Photo Sizing**: See `photos_layout_sizes.md` in RELEVANT_FILES
6. **Storage**: See existing `storage_service.dart` for patterns

---

## 🔗 Related Documentation

- **Photo Layout Sizes:** `/RELEVANT_FILES/photos_layout_sizes.md`
- **Architecture Guide:** `/agents.md` and `/README.md`
- **Storage Service:** `/lib/services/storage_service.dart`
- **Image Compression:** `/lib/shared/utils/image_compression_service.dart`

---

**P1 Sign-off:** ✅ Complete - Ready for P2 implementation  
**Next Steps:** P2 can proceed with Supabase data layer, Storage integration, and RLS policies

---

## 📋 P1 Implementation Summary

### **Domain Contracts** ✅
- MemoryEntity with coverPhotos/gridPhotos getters
- MemoryPhoto with isPortrait/isLandscape getters
- MemoryRepository interface with 5 methods
- 5 use cases: GetMemory, GetMemoryPhotos, ShareMemory, UpdateMemoryCover, RemoveMemoryPhoto

### **Presentation Layer** ✅
- 3 pages: MemoryViewerPage, PhotoPreviewPage, ManageMemoryPage
- 5 widgets: MemoryViewerAppBar, PhotoViewerItem, PhotoGridItem, CoverSelectionCard, AddPhotoCard
- 2 provider files: memory_providers, manage_memory_providers
- Complete state management with AsyncValue
- Selection mode with proper toggle and permissions
- Cover selection with bottom sheet

### **Fake Data** ✅
- FakeMemoryRepository with configurable layouts
- FakeMemoryConfig for testing different scenarios
- Dynamic memory generation with proper ordering
- Realistic delays and mock implementations

### **Routes** ✅
- memoryViewer: /memory-viewer
- photoPreview: /photo-preview
- manageMemory: /manage-memory

### **User Experience** ✅
- Top banners for success feedback
- Confirmation dialogs for destructive actions
- Profile photos next to uploader names
- Selection mode with visual feedback
- Permission-based UI visibility
- Proper error and empty states

### **Code Quality** ✅
- All components follow Clean Architecture
- Design tokens used consistently
- No hardcoded colors or dimensions
- Proper separation of concerns
- Feature-specific widgets in correct locations
- Stateless shared components
