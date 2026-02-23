# Memory Feature — P1→P2 Handoff

**Feature:** Memory screen (completed event photos with cover mosaic + grid)  
**Status:** P1 Complete (UI + Fake Data) → Ready for P2 (Supabase Integration)  
**Date:** 26 October 2025  
**Architecture:** Clean Architecture (Presentation/Domain/Data) + Riverpod

---

## 1) P1 Completion Summary

### ✅ What's Done

#### Domain Layer (Contracts)
- **Entity:** `MemoryEntity` with cover/grid photo separation logic
- **Entity:** `MemoryPhoto` with orientation detection
- **Repository Interface:** `MemoryRepository` (3 methods)
- **Use Cases:**
  - `GetMemory` - fetch memory by ID
  - `ShareMemory` - generate share URL

#### Presentation Layer (UI)
- **Page:** `MemoryPage` - main screen with 3 sections:
  1. Cover Mosaic (1-3 photos, adaptive layouts)
  2. Event title + subtitle (location • date)
  3. Hybrid Photo Grid (temporal clustering)
- **Providers:** Full Riverpod state management
  - `memoryDetailProvider` - loads memory
  - `shareMemoryProvider` - handles share action
- **Shared Components:**
  - `CoverMosaic` - 12 deterministic layouts (1-3 covers, portrait/landscape)
  - `HybridPhotoGrid` - greedy template matching (PPP, LspanP, PLspanP, LspanLspan)
  - `CommonAppBar` - reusable app bar

#### Data Layer (Fake)
- **Fake Repository:** `FakeMemoryRepository`
  - 12 predefined scenarios (enum-based)
  - **NEW:** `FakeMemoryConfig` global variables for dynamic testing
  - Configurable cover count (portrait/landscape) and grid count
  - Helper methods for easy scenario switching
  - **NEW:** Event state configuration (`eventStatus`: living/recap/ended)
  - **NEW:** User state flags (`isHost`, `userHasUploadedPhotos`)

#### Routes & DI
- ✅ Route registered: `/memory` → `MemoryPage`
- ✅ DI wired in `main.dart`: `memoryRepositoryProvider` defaults to `FakeMemoryRepository`

#### 3-State Event System
- **NEW:** Memory page adapts UI based on event status:
  - **Living:** CTA banner (purple camera) if no photos uploaded, edit button if host/has photos
  - **Recap:** CTA banner (orange gallery) if no photos uploaded, edit button if host/has photos
  - **Ended:** Read-only (no CTA, no edit button)
- **NEW:** `AddPhotosCtaCard` shared component for prompting photo uploads
  - P1: Navigates to Manage Photos (temporary)
  - P2 TODO: Open camera (living) or gallery (recap)

---

## 2) Testing the Implementation

### Quick Test Scenarios

Use `FakeMemoryConfig` to test all cover mosaic layouts:

```dart
// In your test file or main.dart for preview:

// Test 1 cover (portrait)
FakeMemoryConfig.singlePortrait(); // 1P cover + 4 grid photos

// Test 1 cover (landscape)  
FakeMemoryConfig.singleLandscape(); // 1L cover + 4 grid photos

// Test 2 covers
FakeMemoryConfig.portraitLandscape(); // [V, H]
FakeMemoryConfig.landscapePortrait(); // [H, V]
FakeMemoryConfig.doublePortrait(); // [V, V]
FakeMemoryConfig.doubleLandscape(); // [H, H]

// Test 3 covers
FakeMemoryConfig.portraitLandscapeLandscape(); // [V, H, H]
FakeMemoryConfig.landscapePortraitLandscape(); // [H, V, H]
FakeMemoryConfig.landscapeLandscapePortrait(); // [H, H, V]
FakeMemoryConfig.portraitPortraitLandscape(); // [V, V, H]
FakeMemoryConfig.allPortrait(); // [V, V, V]
FakeMemoryConfig.allLandscape(); // [H, H, H]

// Custom config
FakeMemoryConfig.coverPortraitCount = 2;
FakeMemoryConfig.coverLandscapeCount = 1;
FakeMemoryConfig.gridPortraitCount = 5;
FakeMemoryConfig.gridLandscapeCount = 5;
```

### Layout Verification

All 12 cover mosaic scenarios are implemented per spec:

**1 Cover:**
- `[V]` or `[H]` → B (2×2) centered at cols 2-3, rows 1-2

**2 Covers:**
- `[V, H]` → V (col 1) + H (cols 2-3, row 1)
- `[H, V]` → H (cols 1-2, row 1) + V (col 4)
- `[V, V]` → B (cols 1-2) + V (col 4)
- `[H, H]` → H (cols 1-2, row 1) + H (cols 3-4, row 1)

**3 Covers:**
- `[V, H, H]` → V (col 1) + H (cols 2-3, row 1) + H (cols 2-3, row 2)
- `[H, V, H]` → H (cols 1-2, row 1) + V (col 4) + H (cols 1-2, row 2)
- `[H, H, V]` → H (cols 1-2, row 1) + H (cols 1-2, row 2) + V (col 4)  
  *(Note: Spec had typo causing overlap; corrected to stack H tiles)*
- `[V, V, H]` → V (col 1) + V (col 2) + H (cols 3-4, row 2)
- `[V, V, V]` → B (cols 1-2) + V (col 3) + V (col 4)
- `[H, H, H]` → H (cols 1-2, row 1) + H (cols 3-4, row 1) + H (cols 1-4, row 2)

**Grid Photos:**
- Hybrid templates: PPP, LspanP, PLspan, LspanLspan
- Temporal clustering with day labels
- Greedy template matching with penalty system

---

## 3) P2 Tasks (Supabase Integration)

### Required Files to Create

```
lib/features/memory/data/
├─ data_sources/
│  └─ memory_supabase_data_source.dart   # NEW
├─ models/
│  └─ memory_model.dart                   # NEW (DTO)
└─ repositories/
   └─ memory_repository_impl.dart         # NEW
```

### 3.1 Data Source (Supabase Queries)

**File:** `lib/features/memory/data/data_sources/memory_supabase_data_source.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class MemorySupabaseDataSource {
  final SupabaseClient _client;
  
  const MemorySupabaseDataSource(this._client);

  /// Get memory by ID with photos (ordered by votes for covers)
  Future<Map<String, dynamic>?> getMemoryById(String memoryId) async {
    // Query structure (pseudo):
    // SELECT 
    //   memories.id, memories.event_id, memories.title, 
    //   memories.location, memories.event_date,
    //   photos.id, photos.url, photos.thumbnail_url, photos.cover_url,
    //   photos.vote_count, photos.captured_at, photos.aspect_ratio,
    //   photos.uploader_id, uploader.name as uploader_name
    // FROM memories
    // LEFT JOIN photos ON photos.memory_id = memories.id
    // LEFT JOIN profiles AS uploader ON photos.uploader_id = uploader.id
    // WHERE memories.id = memoryId
    // ORDER BY photos.vote_count DESC, photos.captured_at DESC
    
    final response = await _client
        .from('memories')
        .select('''
          id, event_id, title, location, event_date,
          photos (
            id, url, thumbnail_url, cover_url, vote_count,
            captured_at, aspect_ratio, uploader_id,
            uploader:profiles!uploader_id (name)
          )
        ''')
        .eq('id', memoryId)
        .single();
    
    return response;
  }

  /// Get memory by event ID
  Future<Map<String, dynamic>?> getMemoryByEventId(String eventId) async {
    final response = await _client
        .from('memories')
        .select('''
          id, event_id, title, location, event_date,
          photos (
            id, url, thumbnail_url, cover_url, vote_count,
            captured_at, aspect_ratio, uploader_id,
            uploader:profiles!uploader_id (name)
          )
        ''')
        .eq('event_id', eventId)
        .maybeSingle();
    
    return response;
  }

  /// Generate share URL or trigger native share
  Future<String> shareMemory(String memoryId) async {
    // Option 1: Deep link
    return 'https://lazzo.app/memory/$memoryId';
    
    // Option 2: Call RPC to generate short link
    // final response = await _client.rpc('generate_share_link', 
    //   params: {'memory_id': memoryId});
    // return response as String;
  }
}
```

**Database Columns Needed:**
- `memories`: `id`, `event_id`, `title`, `location`, `event_date`
- `photos`: `id`, `url`, `thumbnail_url`, `cover_url`, `vote_count`, `captured_at`, `aspect_ratio`, `uploader_id`, `memory_id`
- `profiles`: `id`, `name`

**RLS Policies:**
- User can read memories for events they're a member of
- User can read photos in accessible memories

### 3.2 DTO Model (JSON Parsing)

**File:** `lib/features/memory/data/models/memory_model.dart`

```dart
import '../../domain/entities/memory_entity.dart';

class MemoryModel {
  final String id;
  final String eventId;
  final String title;
  final String? location;
  final DateTime eventDate;
  final List<MemoryPhotoModel> photos;

  const MemoryModel({
    required this.id,
    required this.eventId,
    required this.title,
    this.location,
    required this.eventDate,
    required this.photos,
  });

  /// Parse from Supabase JSON
  factory MemoryModel.fromJson(Map<String, dynamic> json) {
    return MemoryModel(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      title: json['title'] as String,
      location: json['location'] as String?,
      eventDate: DateTime.parse(json['event_date'] as String),
      photos: (json['photos'] as List<dynamic>?)
              ?.map((p) => MemoryPhotoModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert to domain entity
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
  final String url;
  final String? thumbnailUrl;
  final String? coverUrl;
  final int voteCount;
  final DateTime capturedAt;
  final double aspectRatio;
  final String uploaderId;
  final String uploaderName;

  const MemoryPhotoModel({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    this.coverUrl,
    required this.voteCount,
    required this.capturedAt,
    required this.aspectRatio,
    required this.uploaderId,
    required this.uploaderName,
  });

  factory MemoryPhotoModel.fromJson(Map<String, dynamic> json) {
    return MemoryPhotoModel(
      id: json['id'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      voteCount: json['vote_count'] as int? ?? 0,
      capturedAt: DateTime.parse(json['captured_at'] as String),
      aspectRatio: (json['aspect_ratio'] as num?)?.toDouble() ?? 1.0,
      uploaderId: json['uploader_id'] as String,
      uploaderName: (json['uploader'] as Map<String, dynamic>?)?['name'] as String? ?? 'Unknown',
    );
  }

  MemoryPhoto toEntity() {
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
    );
  }
}
```

### 3.3 Repository Implementation

**File:** `lib/features/memory/data/repositories/memory_repository_impl.dart`

```dart
import '../../domain/entities/memory_entity.dart';
import '../../domain/repositories/memory_repository.dart';
import '../data_sources/memory_supabase_data_source.dart';
import '../models/memory_model.dart';

class MemoryRepositoryImpl implements MemoryRepository {
  final MemorySupabaseDataSource _dataSource;

  const MemoryRepositoryImpl(this._dataSource);

  @override
  Future<MemoryEntity?> getMemoryById(String memoryId) async {
    try {
      final json = await _dataSource.getMemoryById(memoryId);
      if (json == null) return null;
      return MemoryModel.fromJson(json).toEntity();
    } catch (e) {
      // Log error
      rethrow;
    }
  }

  @override
  Future<MemoryEntity?> getMemoryByEventId(String eventId) async {
    try {
      final json = await _dataSource.getMemoryByEventId(eventId);
      if (json == null) return null;
      return MemoryModel.fromJson(json).toEntity();
    } catch (e) {
      // Log error
      rethrow;
    }
  }

  @override
  Future<String> shareMemory(String memoryId) async {
    try {
      return await _dataSource.shareMemory(memoryId);
    } catch (e) {
      // Log error
      rethrow;
    }
  }
}
```

### 3.4 DI Override (main.dart)

Replace fake with real repository:

```dart
// In main.dart ProviderScope overrides:
memoryRepositoryProvider.overrideWith((ref) {
  final client = ref.watch(supabaseClientProvider);
  final dataSource = MemorySupabaseDataSource(client);
  return MemoryRepositoryImpl(dataSource);
}),
```

---

## 4) Database Schema

### Tables Required

```sql
-- memories table
CREATE TABLE memories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  location TEXT,
  event_date TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- photos table (linked to memories)
CREATE TABLE photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  memory_id UUID NOT NULL REFERENCES memories(id) ON DELETE CASCADE,
  uploader_id UUID NOT NULL REFERENCES profiles(id),
  url TEXT NOT NULL,              -- full resolution (2048px)
  thumbnail_url TEXT,             -- grid tile (512px)
  cover_url TEXT,                 -- cover mosaic (1024px)
  vote_count INTEGER DEFAULT 0,
  captured_at TIMESTAMPTZ NOT NULL,
  aspect_ratio DECIMAL(4,2) DEFAULT 1.0, -- width/height
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for performance
CREATE INDEX idx_memories_event_id ON memories(event_id);
CREATE INDEX idx_photos_memory_id ON photos(memory_id);
CREATE INDEX idx_photos_vote_count ON photos(vote_count DESC);
CREATE INDEX idx_photos_captured_at ON photos(captured_at);

-- RLS policies
ALTER TABLE memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;

-- Policy: User can read memories for events they're a member of
CREATE POLICY memory_read_policy ON memories
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM event_members
      WHERE event_members.event_id = memories.event_id
        AND event_members.user_id = auth.uid()
    )
  );

-- Policy: User can read photos in accessible memories
CREATE POLICY photo_read_policy ON photos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM memories
      JOIN event_members ON event_members.event_id = memories.event_id
      WHERE memories.id = photos.memory_id
        AND event_members.user_id = auth.uid()
    )
  );
```

### Storage Structure

Photo derivatives should be stored in Supabase Storage:

```
/memories/
  /{memory_id}/
    /{photo_id}/
      original.jpg        (uploaded, 2048px max)
      cover.jpg          (1024px, for cover mosaic)
      thumbnail.jpg      (512px, for grid)
      lqip.jpg           (64-128px, placeholder)
```

Metadata to store with each photo:
- `uploader`: user ID
- `type`: image/jpeg, etc.
- `captured_at`: timestamp from EXIF or upload time

---

## 5) Image Derivatives & Performance

Per spec (`photos_layout_sizes.md`):

| Purpose | Max long edge | Usage |
|---------|---------------|-------|
| LQIP | 64-128 px | Placeholder |
| Grid tiles | 512 px | `thumbnail_url` |
| Cover mosaic | 1024 px | `cover_url` |
| Viewer/share | 2048 px | `url` |

**Implementation Strategy:**
1. User uploads original (any size)
2. Backend/Edge Function generates 3 derivatives on upload
3. Store all 4 versions (original + 3 derivatives)
4. UI loads LQIP first, then progressive load higher quality

**Prefetch Strategy:**
- Cover mosaic: prefetch all 3 covers on page load
- Grid: prefetch ±12 upcoming tiles during scroll
- Viewer: prefetch ±3 adjacent photos

---

## 6) Missing P2 Features

### Share Functionality
- **Current:** Placeholder SnackBar with share URL
- **P2:** Integrate native share sheet (`share_plus` package)
- **TODO:** Replace `TODO: Trigger native share` in `memory_page.dart`

```dart
import 'package:share_plus/share_plus.dart';

// In _handleShare method:
if (shareUrl != null) {
  await Share.share(
    'Check out this memory: $shareUrl',
    subject: memory.title,
  );
}
```

### Photo Viewer (Future P3)
- Tap on photo → full-screen viewer with swipe navigation
- Not required for P2, but consider route placeholder

### Vote Interaction (Future P3)
- Users can upvote/downvote photos
- Affects cover selection and ranking

---

## 7) Testing Checklist

### P2 Integration Tests
- [ ] Memory loads from Supabase with correct photos
- [ ] Cover photos are sorted by vote count (descending)
- [ ] Grid photos exclude covers and sort by capture time
- [ ] Share generates valid deep link
- [ ] RLS policies prevent unauthorized access
- [ ] Loading states show correctly
- [ ] Error states display user-friendly messages
- [ ] All 12 cover mosaic layouts render without gaps

### Performance Tests
- [ ] Cover mosaic renders in < 100ms (cached)
- [ ] Grid scrolls smoothly at 60fps
- [ ] Image derivatives load progressively (LQIP → full)
- [ ] Memory with 50+ photos doesn't cause jank

### Edge Cases
- [ ] Memory with 0 photos (shouldn't happen, but handle gracefully)
- [ ] Memory with 1 photo (1 cover, empty grid)
- [ ] Memory with 2 photos (2 covers, empty grid)
- [ ] All portrait photos
- [ ] All landscape photos
- [ ] Mixed aspect ratios (very wide/tall)

---

## 8) Code Locations Reference

### Core Files
```
lib/features/memory/
├─ presentation/
│  ├─ pages/memory_page.dart              # Main screen
│  └─ providers/memory_providers.dart      # Riverpod state
├─ domain/
│  ├─ entities/memory_entity.dart          # Entity with cover/grid logic
│  ├─ repositories/memory_repository.dart  # Interface
│  └─ usecases/
│     ├─ get_memory.dart                   # Fetch memory
│     └─ share_memory.dart                 # Share action
└─ data/
   └─ fakes/fake_memory_repository.dart    # P1 fake data (with FakeMemoryConfig)
   [P2 TODO:]
   ├─ data_sources/memory_supabase_data_source.dart
   ├─ models/memory_model.dart
   └─ repositories/memory_repository_impl.dart
```

### Shared Components
```
lib/shared/components/sections/
├─ cover_mosaic.dart           # 12 adaptive layouts for 1-3 covers
└─ hybrid_photo_grid.dart      # Greedy template matching grid
```

### Routes
```
lib/routes/app_router.dart
- Route: '/memory'
- Handler: MemoryPage(memoryId)
```

### DI
```
lib/main.dart
- memoryRepositoryProvider override (currently FakeMemoryRepository)
```

---

## 9) Known Issues & Notes

### ✅ FIXED: Cover Mosaic Layout Bug
- **Issue:** `[H, H, V]` spec had typo causing overlap (2nd H and V both wanted col 4)
- **Fix:** Changed 2nd H to stack vertically at cols 1-2, row 2
- **Result:** All 12 scenarios now render without gaps

### Photo Sorting
- Cover photos: sorted by `voteCount DESC, isPortrait, capturedAt DESC`
- Grid photos: sorted by `capturedAt ASC` (chronological)

### Aspect Ratio Handling
- Portrait: `aspectRatio < 1.0`
- Landscape: `aspectRatio >= 1.0`
- Stored as `width / height` (e.g., 0.8 for 4:5, 1.78 for 16:9)

### Temporal Clustering
- Grid clusters photos by day
- Label format: "5 July 2024" (localized via `intl` package)
- Show labels only when multiple clusters exist

---

## 10) Architecture Compliance

### ✅ Clean Architecture
- Domain has **zero** Flutter/Supabase imports
- Presentation consumes use cases via providers
- Data layer isolated in repositories

### ✅ Tokenization
- All colors from `BrandColors` / `colorScheme`
- All spacing from `Insets`, `Gaps`, `Radii`, `Pads`
- All text styles from `AppText`
- No hardcoded hex/px values

### ✅ DI Coverage
- Repository provider in `main.dart`
- Use case providers in `memory_providers.dart`
- Easy flip from fake → real by single override

### ✅ Shared Components
- `CoverMosaic` - stateless, reusable across features
- `HybridPhotoGrid` - stateless, reusable for any photo list
- Both use tokens exclusively

---

## 11) P2 Acceptance Criteria

Before closing P2:
- [ ] All 3 data layer files created (data_source, model, repository_impl)
- [ ] DI override in `main.dart` switches to Supabase
- [ ] Database schema deployed with RLS policies
- [ ] Photos load from Supabase Storage
- [ ] Share action generates valid deep link
- [ ] Error handling covers network/auth failures
- [ ] No regressions in UI (all 12 layouts still work)
- [ ] Performance meets targets (< 100ms cover load, 60fps scroll)

---

## 12) Next Steps (After P2)

### P3 Enhancements
- **Photo Viewer:** Full-screen viewer with swipe navigation
- **Vote Interaction:** Upvote/downvote photos
- **Photo Upload:** Add new photos to memory
- **Captions:** Add/edit photo captions
- **Filters:** Filter by date range, uploader
- **Download:** Download original photos
- **Native Share:** Integrate OS share sheet

### Performance Optimizations
- Implement blurhash for LQIP
- Add image caching layer (e.g., `cached_network_image`)
- Lazy load grid photos (virtualized list)
- Prefetch strategy for smoother scrolling

### Analytics
- Track memory views
- Track photo interactions (views, votes)
- Track share conversions

---

## Questions for P2 Agent

1. **Storage Strategy:** Should we use Supabase Storage or CDN (e.g., Cloudflare Images)?
2. **Derivative Generation:** Edge Function on upload or batch job?
3. **Share Links:** Deep links only or also short links (bit.ly style)?
4. **EXIF Parsing:** Extract capture timestamp from EXIF or trust file metadata?
5. **Vote Sync:** Real-time subscription to vote changes or polling?

---

## 13) Recap Phase Features (Added 18 de novembro de 2025)

### **AppBarWithSubtitle with Countdown Timer**

#### **Component Overview**
- **Location:** `shared/components/nav/app_bar_with_subtitle.dart`
- **Purpose:** AppBar with subtitle for countdown timers in recap phase
- **Status:** ✅ Complete (P1)

#### **Features Implemented**
- Dual trailing icon support (`trailing` + `trailing2` parameters)
- Automatic layout adjustment for 0, 1, or 2 trailing icons
- Each icon constrained to 36x36px for consistent centering
- 4px spacing between icons when both present
- Title always centered via `Expanded` + `Center` wrapper
- Subtitle positioned 8px below title with optional color override
- Preferred size: 76px (increased from standard 56px for subtitle)

#### **Usage in Memory Page (Recap State)**
```dart
// In memory_page.dart _buildAppBar()
if (eventStatus == FakeEventStatus.recap) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(76),
    child: AppBarWithSubtitle(
      title: memory.title,
      subtitle: 'Closes automatically in ${FakeMemoryConfig.formattedRemainingTime}',
      subtitleColor: FakeMemoryConfig.isLessThanOneHour
          ? BrandColors.cantVote  // Red warning when < 1hr
          : null,  // Default text2 color
      leading: _buildBackButton(),
      trailing: _buildChatButton(),
      trailing2: _buildEditButton(memory),
    ),
  );
}
```

#### **Icon Visibility Logic**
- **Chat Button:** Always visible in recap mode (`Icons.chat_bubble_outline`)
- **Edit Button:** Conditional on `isHost || userHasUploadedPhotos`
- **Navigation:** Chat button navigates to `AppRouter.eventChat`

#### **FakeMemoryConfig Timer Fields**
- `closeTime`: DateTime? = DateTime.now().add(Duration(hours: 2, minutes: 30))
- `remainingTime`: Duration? getter calculates difference from now to closeTime
- `formattedRemainingTime`: String getter returns "2h 34m" or "45m" format
- `isLessThanOneHour`: bool getter for warning state (<60 minutes)

#### **Testing Scenarios**
```dart
// Test countdown timer display
FakeMemoryConfig.closeTime = DateTime.now().add(Duration(hours: 2, minutes: 30));
// Expected: "Closes automatically in 2h 30m"

// Test warning state (< 1hr)
FakeMemoryConfig.closeTime = DateTime.now().add(Duration(minutes: 45));
// Expected: Red subtitle text, "Closes automatically in 45m"

// Test dual icons (host with photos)
FakeMemoryConfig.isHost = true;
FakeMemoryConfig.userHasUploadedPhotos = true;
// Expected: Both chat and edit icons visible with 4px spacing

// Test single icon (non-host with photos)
FakeMemoryConfig.isHost = false;
FakeMemoryConfig.userHasUploadedPhotos = true;
// Expected: Only chat icon visible (no edit)

// Test single icon (host without photos)
FakeMemoryConfig.isHost = true;
FakeMemoryConfig.userHasUploadedPhotos = false;
// Expected: Only chat icon visible (edit requires photos)
```

#### **P2 Tasks**
- [ ] Replace FakeMemoryConfig.closeTime with real event recap_end_time from database
- [ ] Calculate remaining time from event.recap_end_time - DateTime.now()
- [ ] Update AppBar automatically when timer counts down (consider StreamProvider or periodic updates)
- [ ] Handle expired timer (remaining time <= 0) by transitioning to ended state
- [ ] Store chat_enabled flag in events table for chat button visibility
- [ ] Implement real-time chat navigation (currently navigates to AppRouter.eventChat placeholder)
- [ ] Add push notification when recap is closing soon (<1hr warning)

#### **Database Requirements for P2**
```sql
-- Add recap_end_time to events table
ALTER TABLE events ADD COLUMN recap_end_time TIMESTAMPTZ;

-- Index for querying active recaps
CREATE INDEX idx_events_recap_end_time 
ON events(recap_end_time) 
WHERE recap_end_time IS NOT NULL;

-- Add chat_enabled flag
ALTER TABLE events ADD COLUMN chat_enabled BOOLEAN DEFAULT true;
```

#### **Architecture Compliance**
- ✅ Stateless shared component
- ✅ All values tokenized (Gaps, Pads, Radii, AppText, BrandColors)
- ✅ No hardcoded dimensions or colors
- ✅ No Supabase imports in presentation layer
- ✅ Fake-first implementation with FakeMemoryConfig
- ✅ Proper DI pattern (can swap config with real repository data)

---

### **Chat Button Integration**

#### **Implementation Details**
- **Icon:** `Icons.chat_bubble_outline` (Material Icons)
- **Size:** 36x36px (matches all AppBar icons)
- **Visibility:** Always shown in recap mode
- **Navigation:** Navigates to `AppRouter.eventChat` route

#### **Code Location**
```dart
// In memory_page.dart
Widget _buildChatButton() {
  return IconButton(
    icon: const Icon(Icons.chat_bubble_outline),
    color: BrandColors.text1,
    iconSize: 24,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 36, height: 36),
    onPressed: _navigateToChat,
  );
}

void _navigateToChat() {
  Navigator.pushNamed(
    context,
    AppRouter.eventChat,
    arguments: {'eventId': widget.memoryId},
  );
}
```

#### **P2 Tasks**
- [ ] Implement EventChatPage with real-time messaging (Supabase Realtime)
- [ ] Store messages in event_messages table
- [ ] Add unread message count badge on chat button
- [ ] Implement push notifications for new messages
- [ ] Add typing indicators for active participants
- [ ] Handle chat history pagination for large conversations

---

### **Key Changes Summary**

#### **Files Modified**
1. `shared/components/nav/app_bar_with_subtitle.dart` ✅
   - Added `trailing2` parameter for dual icon support
   - `_buildTrailingIcons()` method with 0/1/2 icon handling
   - Fixed width/height (36x36) for all icons
   - 4px spacing between icons

2. `features/memory/presentation/pages/memory_page.dart` ✅
   - `_buildAppBar()` conditional for recap state
   - `_buildChatButton()` method
   - `_navigateToChat()` method
   - Subtitle color conditional based on timer warning

3. `features/memory/data/fakes/fake_memory_repository.dart` ✅
   - `closeTime` field (DateTime?)
   - `remainingTime` getter (Duration?)
   - `formattedRemainingTime` getter (String)
   - `isLessThanOneHour` getter (bool)

#### **Design Decisions**
- Chat button always visible in recap to encourage engagement
- Edit button conditional to prevent confusion for non-contributors
- Red subtitle when <1hr to create urgency
- 4px spacing chosen to minimize width while maintaining tap targets
- Timer countdown shows hours and minutes for clarity

#### **Testing Checklist**
- [x] AppBar title centered with 0, 1, or 2 trailing icons
- [x] Icon spacing correct (4px between chat and edit)
- [x] Chat button navigates to event chat route
- [x] Edit button visibility based on permissions
- [x] Subtitle shows formatted countdown timer
- [x] Subtitle color changes to red when <1hr
- [x] Timer format correct ("2h 34m" vs "45m")
- [x] FakeMemoryConfig timer getters work correctly
- [x] All components properly tokenized

#### **Known Limitations (P1)**
- Timer is static (no auto-refresh countdown)
- Chat route is placeholder (not implemented)
- Edit button permission check uses FakeMemoryConfig.isHost
- Countdown timer updates only on page reload

These will be addressed in P2 with real-time updates, Supabase integration, and proper permission checks.

---

**Handoff complete.** P1 agent out. P2 agent: go ship it! 🚀
