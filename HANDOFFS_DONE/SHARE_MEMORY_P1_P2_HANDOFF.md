# Share Memory Feature — P1 → P2 Handoff

**Date**: 24 November 2025  
**Feature**: Share Memory Page with PNG Export  
**Status**: ✅ P1 Complete — Ready for P2

---

## Overview

Feature allowing users to share memory photos as Instagram Stories (1080x1920 PNG). Users can:
- Preview share card with memory photos
- Edit selected photos (choose 4 from all memory photos)
- Export as high-quality PNG (1080x1920)
- Share to Instagram Stories, WhatsApp, or save to gallery

**Architecture Pattern**: Clean Architecture with fake-first approach.

---

## 1. Domain Layer (Contracts) ✅

### 1.1 Entities
**Location**: `lib/features/memory/domain/entities/memory_entity.dart`

```dart
class MemoryEntity {
  final String id;
  final String eventId;
  final String title;
  final String? location;
  final DateTime eventDate;
  final List<MemoryPhoto> photos;
  
  List<MemoryPhoto> get coverPhotos; // Photos marked as cover
  List<MemoryPhoto> get gridPhotos;  // Non-cover photos sorted by date
}

class MemoryPhoto {
  final String id;
  final String url;           // Full resolution
  final String? thumbnailUrl; // 512px for grid
  final String? coverUrl;     // 1024px for cover
  final int voteCount;
  final DateTime capturedAt;
  final double aspectRatio;
  final String uploaderId;
  final String uploaderName;
  final bool isCover;
}
```

**P2 Notes:**
- All fields map directly to Supabase schema
- URLs come from Supabase Storage
- `thumbnailUrl` and `coverUrl` are generated versions
- `aspectRatio` = width / height (used for layout)

---

### 1.2 Repository Interface
**Location**: `lib/features/memory/domain/repositories/memory_repository.dart`

```dart
abstract class MemoryRepository {
  /// Get memory by ID with all photos
  Future<MemoryEntity?> getMemoryById(String memoryId);
  
  /// Get memory by event ID (when coming from event)
  Future<MemoryEntity?> getMemoryByEventId(String eventId);
  
  /// Share memory (returns share URL or triggers native share)
  Future<String> shareMemory(String memoryId);
  
  /// Update cover photo selection
  Future<bool> updateCover(String memoryId, String? photoId);
  
  /// Remove photo from memory (uploader or host only)
  Future<bool> removePhoto(String memoryId, String photoId);
}
```

**P2 Implementation Checklist:**
- [ ] `getMemoryById()`: Query memory + join photos, respect RLS
- [ ] Include cover/thumbnail URLs from Storage
- [ ] Order photos by `capturedAt`
- [ ] `shareMemory()`: Optional — generate shareable link
- [ ] `updateCover()` & `removePhoto()`: Optional for MVP

---

## 2. Presentation Layer (UI + State) ✅

### 2.1 Pages

#### ShareMemoryPage
**Location**: `lib/features/memory/presentation/pages/share_memory_page.dart`

**Responsibilities:**
- Load memory data via `memoryDetailProvider(memoryId)`
- Generate PNG from ShareCard widget using RepaintBoundary
- Manage photo selection state (`_selectedPhotoIds`)
- Handle share actions (Instagram, WhatsApp, Save, More)

**Key State:**
```dart
Uint8List? _cachedImageBytes;      // PNG ready for sharing (1080x1920)
bool _isGeneratingImage;            // Prevents concurrent generation
List<String>? _selectedPhotoIds;   // 4 photo IDs in order (null = use defaults)
```

**PNG Generation:**
- Off-screen ShareCard rendered at 360x640 logical pixels
- Captured at pixelRatio 3.0 → 1080x1920 physical pixels
- Images preloaded before capture to avoid blank renders
- Cached to avoid regeneration on every rebuild

**Share Handlers (TODOs for P2):**
```dart
void _handleInstagramShare(BuildContext context)  // TODO: Use _cachedImageBytes
void _handleWhatsAppShare(BuildContext context)   // TODO: Use _cachedImageBytes
void _handleSave(BuildContext context)            // TODO: Save to gallery
void _handleMore(BuildContext context)            // TODO: Native share sheet
```

**P2 Integration Points:**
1. `memoryDetailProvider` → wire to real repository
2. Implement share handlers using platform channels or packages
3. No UI changes needed!

---

#### ShareMemoryPreviewPage
**Location**: `lib/features/memory/presentation/pages/share_memory_preview_page.dart`

**Simple full-screen PNG preview:**
```dart
class ShareMemoryPreviewPage extends StatelessWidget {
  final Uint8List imageBytes;
  // Shows Image.memory() in 9:16 aspect ratio
}
```

**P2 Notes**: No changes needed.

---

### 2.2 Feature Widgets

#### EditSharePhotosSheet
**Location**: `lib/features/memory/presentation/widgets/edit_share_photos_sheet.dart`

**Bottom sheet for selecting 4 photos:**
- Interactive preview card showing selected photos
- Grid of all memory photos (3 columns)
- Multi-select with order badges (1-4)
- Orange (recap) borders for selected photos
- TopBanner warnings for invalid selections

**State Management:**
```dart
List<String> _selectedPhotoIds;  // Maintains order of selection
static const int _requiredPhotos = 4;

void _togglePhoto(String photoId) {
  // Add/remove with validation
  // Show TopBanner if trying to exceed 4
}

void _handleSave() {
  if (_selectedPhotoIds.length == 4) {
    widget.onSave(_selectedPhotoIds); // Pass IDs in order
  } else {
    TopBanner.showWarning('Please select 4 photos');
  }
}
```

**P2 Notes**: 
- Works with any photo data structure
- No changes needed when switching to real data

---

#### InteractiveShareCardPreview
**Location**: `lib/features/memory/presentation/widgets/interactive_share_card_preview.dart`

**Compact preview inside bottom sheet:**
- Shows glass-effect card (no wallpaper background)
- 4 photo slots (1 hero + 3 thumbnails)
- Empty slots show "Pick a photo" placeholder
- Filled slots have remove button (X)

**P2 Notes**: Pure presentation widget, no changes needed.

---

#### ShareOptionsSection
**Location**: `lib/features/memory/presentation/widgets/share_options_section.dart`

**Bottom section with share buttons:**
- Instagram Story
- WhatsApp
- Save to gallery
- More (native share)

**P2 Notes**: Callbacks passed from parent, no changes needed.

---

### 2.3 Shared Components

#### ShareCard
**Location**: `lib/shared/components/cards/share_card.dart`

**Reusable card for PNG generation:**
- 9:16 aspect ratio (Instagram Story)
- Wallpaper background with glass effect
- 1 square hero photo + 3 square thumbnails
- Memory title, location, date
- "made with LAZZO" branding

**Design Specifications:**
- Container: 360x640 logical pixels
- Padding: 32px horizontal, 48px vertical
- Card border radius: 32px
- Hero photo: square (1:1)
- Thumbnails: 3 equal squares with 4px gap
- Glass effect: blur(30px) + white overlay (6% opacity)

**P2 Notes**: 
- Stateless, fully tokenized
- No changes needed for real data
- Works with any photo URLs

---

### 2.4 Providers
**Location**: `lib/features/memory/presentation/providers/memory_providers.dart`

```dart
// Provider exposing memory detail by ID
final memoryDetailProvider = FutureProvider.family<MemoryEntity?, String>(
  (ref, memoryId) async {
    final repo = ref.watch(memoryRepositoryProvider);
    return repo.getMemoryById(memoryId);
  },
);

// Repository provider (currently points to fake)
final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return ref.watch(fakeMemoryRepositoryProvider);
});

// Fake repository provider
final fakeMemoryRepositoryProvider = Provider<FakeMemoryRepository>((ref) {
  return FakeMemoryRepository();
});
```

**P2 Action Items:**
1. Create `realMemoryRepositoryProvider` injecting Supabase client
2. Override in `main.dart`:
```dart
ProviderScope(
  overrides: [
    memoryRepositoryProvider.overrideWithValue(
      MemoryRepositoryImpl(supabaseClient: supabase)
    ),
  ],
  child: MyApp(),
)
```

---

## 3. Data Layer (Fake Implementation) ✅

### 3.1 Fake Repository
**Location**: `lib/features/memory/data/fakes/fake_memory_repository.dart`

**Mock data structure:**
```dart
class FakeMemoryRepository implements MemoryRepository {
  final List<MemoryEntity> _memories = [
    MemoryEntity(
      id: 'mem1',
      eventId: 'evt1',
      title: 'Barcelona Trip',
      location: 'Barcelona, Spain',
      eventDate: DateTime(2025, 11, 15),
      photos: [
        MemoryPhoto(
          id: 'photo1',
          url: 'https://picsum.photos/800/800?random=1',
          thumbnailUrl: 'https://picsum.photos/512/512?random=1',
          coverUrl: 'https://picsum.photos/1024/1024?random=1',
          voteCount: 15,
          capturedAt: DateTime(2025, 11, 15, 14, 30),
          aspectRatio: 1.0,
          uploaderId: 'user1',
          uploaderName: 'Alice',
          isCover: true,
        ),
        // ... more photos
      ],
    ),
  ];

  @override
  Future<MemoryEntity?> getMemoryById(String memoryId) async {
    await Future.delayed(Duration(milliseconds: 500)); // Simulate network
    return _memories.firstWhere((m) => m.id == memoryId);
  }
  
  // ... other methods with mock implementations
}
```

**P2 Notes**: 
- Fake data uses real image URLs (picsum.photos)
- Simulates network delay
- Replace entirely with real implementation

---

## 4. P2 Implementation Guide

### 4.1 Database Schema (Supabase)

**Expected Tables:**
```sql
-- memories table
CREATE TABLE memories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  location TEXT,
  event_date TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- memory_photos table
CREATE TABLE memory_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  memory_id UUID REFERENCES memories(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,        -- Path in Supabase Storage
  thumbnail_path TEXT,                -- 512px version
  cover_path TEXT,                    -- 1024px version
  vote_count INT DEFAULT 0,
  captured_at TIMESTAMP NOT NULL,
  aspect_ratio DECIMAL(5,2) NOT NULL,
  uploader_id UUID REFERENCES profiles(id),
  is_cover BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_memory_photos_memory_id ON memory_photos(memory_id);
CREATE INDEX idx_memory_photos_captured_at ON memory_photos(captured_at DESC);
```

**RLS Policies:**
```sql
-- Users can read memories from events they're part of
CREATE POLICY "Users can view memories from their events"
  ON memories FOR SELECT
  USING (
    event_id IN (
      SELECT event_id FROM event_participants 
      WHERE user_id = auth.uid()
    )
  );

-- Similar policy for memory_photos
CREATE POLICY "Users can view photos from their memories"
  ON memory_photos FOR SELECT
  USING (
    memory_id IN (
      SELECT m.id FROM memories m
      JOIN event_participants ep ON ep.event_id = m.event_id
      WHERE ep.user_id = auth.uid()
    )
  );
```

---

### 4.2 Data Source Implementation

**Location**: `lib/features/memory/data/data_sources/memory_remote_data_source.dart`

```dart
class MemoryRemoteDataSource {
  final SupabaseClient supabase;

  Future<Map<String, dynamic>?> getMemoryById(String memoryId) async {
    final response = await supabase
      .from('memories')
      .select('''
        id,
        event_id,
        title,
        location,
        event_date,
        memory_photos (
          id,
          storage_path,
          thumbnail_path,
          cover_path,
          vote_count,
          captured_at,
          aspect_ratio,
          uploader_id,
          is_cover,
          profiles!uploader_id (
            full_name
          )
        )
      ''')
      .eq('id', memoryId)
      .order('captured_at', referencedTable: 'memory_photos')
      .single();
      
    return response;
  }
  
  // Convert storage paths to signed URLs
  Future<String> getPhotoUrl(String storagePath) async {
    return supabase.storage
      .from('memory-photos')
      .createSignedUrl(storagePath, 3600); // 1 hour expiry
  }
}
```

**Key Points:**
- Use `.select()` with join syntax for nested data
- Order photos by `captured_at`
- Convert Storage paths to signed URLs
- Respect RLS (queries auto-filtered by policies)

---

### 4.3 Model/DTO Implementation

**Location**: `lib/features/memory/data/models/memory_model.dart`

```dart
class MemoryModel {
  final String id;
  final String eventId;
  final String title;
  final String? location;
  final DateTime eventDate;
  final List<MemoryPhotoModel> photos;

  factory MemoryModel.fromJson(Map<String, dynamic> json) {
    return MemoryModel(
      id: json['id'],
      eventId: json['event_id'],
      title: json['title'],
      location: json['location'],
      eventDate: DateTime.parse(json['event_date']),
      photos: (json['memory_photos'] as List)
        .map((p) => MemoryPhotoModel.fromJson(p))
        .toList(),
    );
  }

  MemoryEntity toEntity() {
    return MemoryEntity(
      id: id,
      eventId: eventId,
      title: title,
      location: location,
      eventDate: eventDate,
      photos: photos.map((p) => p.toEntity()).toList(),
    );
  }
}

class MemoryPhotoModel {
  final String id;
  final String storagePath;
  final String? thumbnailPath;
  final String? coverPath;
  // ... other fields

  factory MemoryPhotoModel.fromJson(Map<String, dynamic> json) {
    return MemoryPhotoModel(
      id: json['id'],
      storagePath: json['storage_path'],
      thumbnailPath: json['thumbnail_path'],
      coverPath: json['cover_path'],
      voteCount: json['vote_count'] ?? 0,
      capturedAt: DateTime.parse(json['captured_at']),
      aspectRatio: (json['aspect_ratio'] as num).toDouble(),
      uploaderId: json['uploader_id'],
      uploaderName: json['profiles']['full_name'],
      isCover: json['is_cover'] ?? false,
    );
  }

  MemoryPhoto toEntity({
    required String url,
    required String? thumbnailUrl,
    required String? coverUrl,
  }) {
    return MemoryPhoto(
      id: id,
      url: url,
      thumbnailUrl: thumbnailUrl,
      coverUrl: coverUrl,
      voteCount: voteCount,
      capturedAt: capturedAt,
      aspectRatio: aspectRatio,
      uploaderId: uploaderId,
      uploaderName: uploaderName,
      isCover: isCover,
    );
  }
}
```

---

### 4.4 Repository Implementation

**Location**: `lib/features/memory/data/repositories/memory_repository_impl.dart`

```dart
class MemoryRepositoryImpl implements MemoryRepository {
  final MemoryRemoteDataSource dataSource;

  @override
  Future<MemoryEntity?> getMemoryById(String memoryId) async {
    try {
      final json = await dataSource.getMemoryById(memoryId);
      if (json == null) return null;
      
      final model = MemoryModel.fromJson(json);
      
      // Convert storage paths to URLs
      final photosWithUrls = await Future.wait(
        model.photos.map((photo) async {
          final url = await dataSource.getPhotoUrl(photo.storagePath);
          final thumbUrl = photo.thumbnailPath != null
            ? await dataSource.getPhotoUrl(photo.thumbnailPath!)
            : null;
          final coverUrl = photo.coverPath != null
            ? await dataSource.getPhotoUrl(photo.coverPath!)
            : null;
            
          return photo.toEntity(
            url: url,
            thumbnailUrl: thumbUrl,
            coverUrl: coverUrl,
          );
        }),
      );
      
      return MemoryEntity(
        id: model.id,
        eventId: model.eventId,
        title: model.title,
        location: model.location,
        eventDate: model.eventDate,
        photos: photosWithUrls,
      );
    } catch (e) {
      // Log error, return null or throw
      return null;
    }
  }

  @override
  Future<MemoryEntity?> getMemoryByEventId(String eventId) async {
    // Similar implementation querying by event_id
  }

  @override
  Future<String> shareMemory(String memoryId) async {
    // Optional: Generate shareable link or trigger native share
    throw UnimplementedError('Share not implemented yet');
  }

  @override
  Future<bool> updateCover(String memoryId, String? photoId) async {
    // Optional for MVP
    throw UnimplementedError();
  }

  @override
  Future<bool> removePhoto(String memoryId, String photoId) async {
    // Optional for MVP
    throw UnimplementedError();
  }
}
```

---

### 4.5 Dependency Injection Setup

**Location**: `lib/main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  
  final supabase = Supabase.instance.client;

  runApp(
    ProviderScope(
      overrides: [
        // Override memory repository with real implementation
        memoryRepositoryProvider.overrideWithValue(
          MemoryRepositoryImpl(
            dataSource: MemoryRemoteDataSource(supabase),
          ),
        ),
        // ... other overrides
      ],
      child: const MyApp(),
    ),
  );
}
```

---

## 5. Testing Checklist

### P1 Validation ✅
- [x] UI uses only tokens (no hardcoded colors/dimensions)
- [x] No Supabase imports in presentation layer
- [x] ShareCard is stateless and reusable
- [x] Feature widgets properly scoped to memory feature
- [x] Providers use AsyncValue for loading/error states
- [x] Photo selection maintains order correctly
- [x] PNG generation produces 1080x1920 output
- [x] All share handlers have TODO placeholders for P2

### P2 Validation Checklist
- [ ] `getMemoryById()` returns correct data structure
- [ ] RLS policies tested (users only see their memories)
- [ ] Photo URLs are valid signed URLs from Storage
- [ ] Photos ordered by `captured_at`
- [ ] Cover photos correctly identified (`isCover` flag)
- [ ] No UI changes needed after switching to real data
- [ ] Share handlers implemented (Instagram/WhatsApp/Save)
- [ ] Error handling for network/auth failures
- [ ] Loading states work correctly with real latency
- [ ] Photo selection persists across edits

---

## 6. Platform Integration (P2)

### 6.1 Instagram Story Share
**Package**: `share_plus` or custom platform channel

```dart
void _handleInstagramShare(BuildContext context) async {
  if (_cachedImageBytes == null) return;
  
  // Save to temp file
  final tempDir = await getTemporaryDirectory();
  final file = await File('${tempDir.path}/share.png').create();
  await file.writeAsBytes(_cachedImageBytes!);
  
  // Share to Instagram Stories
  await Share.shareXFiles(
    [XFile(file.path)],
    text: 'Check out this memory!',
  );
}
```

---

### 6.2 Save to Gallery
**Package**: `image_gallery_saver`

```dart
void _handleSave(BuildContext context) async {
  if (_cachedImageBytes == null) return;
  
  final result = await ImageGallerySaver.saveImage(
    _cachedImageBytes!,
    name: 'lazzo_memory_${DateTime.now().millisecondsSinceEpoch}',
  );
  
  if (result['isSuccess']) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved to gallery!')),
    );
  }
}
```

---

## 7. Known Limitations & Future Improvements

**Current Limitations:**
- Fixed 4-photo requirement (could be flexible 1-4)
- No custom text/stickers on share card
- No photo ordering by drag-and-drop (order = selection order)
- Share handlers are stubs (need platform implementation)

**Future Enhancements:**
- Custom share card templates
- Add text overlays/filters
- Direct Instagram API integration (requires app review)
- Share multiple cards as carousel
- Save draft selections

---

## 8. File Checklist

### Domain Layer ✅
- [x] `lib/features/memory/domain/entities/memory_entity.dart`
- [x] `lib/features/memory/domain/repositories/memory_repository.dart`

### Presentation Layer ✅
- [x] `lib/features/memory/presentation/pages/share_memory_page.dart`
- [x] `lib/features/memory/presentation/pages/share_memory_preview_page.dart`
- [x] `lib/features/memory/presentation/widgets/edit_share_photos_sheet.dart`
- [x] `lib/features/memory/presentation/widgets/interactive_share_card_preview.dart`
- [x] `lib/features/memory/presentation/widgets/share_options_section.dart`
- [x] `lib/features/memory/presentation/providers/memory_providers.dart`

### Shared Components ✅
- [x] `lib/shared/components/cards/share_card.dart`
- [x] `lib/shared/components/common/top_banner.dart` (already exists)

### Data Layer (Fake) ✅
- [x] `lib/features/memory/data/fakes/fake_memory_repository.dart`

### Data Layer (To Create in P2) 📋
- [ ] `lib/features/memory/data/data_sources/memory_remote_data_source.dart`
- [ ] `lib/features/memory/data/models/memory_model.dart`
- [ ] `lib/features/memory/data/models/memory_photo_model.dart`
- [ ] `lib/features/memory/data/repositories/memory_repository_impl.dart`

### Documentation ✅
- [x] `SHARE_MEMORY_PHOTO_FLOW.md` (technical flow diagram)
- [x] This handoff document

---

## 9. Questions for P2 Developer

1. **Storage organization**: Should memory photos use same bucket as event photos or separate?
2. **Thumbnail generation**: Server-side (Storage triggers) or client-side?
3. **Share analytics**: Track share counts/platforms?
4. **Share URL format**: Deep link to memory or event?
5. **Permissions**: Who can share memories? (all participants vs only host)

---

## 10. Acceptance Criteria

### P1 (Complete) ✅
- User can preview memory share card
- User can edit selected photos (4 required)
- Card generates as 1080x1920 PNG
- All UI uses design tokens
- Loading/error states handled
- Works with fake data

### P2 (To Implement) 📋
- Data loads from Supabase
- Photos show from Storage with signed URLs
- PNG generation works with real photos
- Instagram share opens Instagram app
- WhatsApp share opens WhatsApp
- Save stores PNG in device gallery
- RLS policies protect user data
- Network errors handled gracefully

---

**Handoff Complete** — P2 ready to start! 🚀

For questions or clarifications, refer to:
- `agents.md` for architecture guidelines
- `README.md` for project structure
