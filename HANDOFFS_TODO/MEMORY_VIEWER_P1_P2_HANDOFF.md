# Memory Viewer - P1 to P2 Handoff

**Date:** 27 October 2025  
**Feature:** Memory Viewer (Full-screen photo viewer)  
**Status:** ✅ P1 Complete - Ready for P2

---

## Overview

The Memory Viewer page allows users to view all photos from a memory in full-screen vertical scroll. When a user taps a photo on the memory page (either cover or grid), they navigate to this viewer opened at that specific photo.

**Access Point:** Tapping any photo in `MemoryPage` (covers or grid)

---

## P1 Deliverables ✅

### 1. Domain Layer

**Files Created:**
- `lib/features/memory/domain/usecases/get_memory_photos.dart`

**Contracts:**
```dart
class GetMemoryPhotos {
  Future<List<MemoryPhoto>> call(String memoryId)
  // Returns ordered list: covers first (by votes desc), then grid (by timestamp asc)
}
```

**Entity Used:**
- `MemoryEntity` (existing)
- `MemoryPhoto` (existing)

---

### 2. Presentation Layer

#### 2.1 Page
**File:** `lib/features/memory/presentation/pages/memory_viewer_page.dart`

**Features:**
- Full-screen vertical PageView
- Opens at initial photo (via `initialPhotoId` param)
- Photos ordered: covers first (by votes), then grid photos (by timestamp)
- Custom AppBar with event title, subtitle, back button, and play preview icon
- Loading/error states handled via `AsyncValue`

**Route Params:**
```dart
{
  'memoryId': String,    // Required
  'photoId': String?,    // Optional - photo to open at
}
```

#### 2.2 Widgets

**MemoryViewerAppBar** (`widgets/memory_viewer_app_bar.dart`)
- Custom AppBar similar to EventChatPage pattern
- Dynamic height based on subtitle presence
- Title: Event name
- Subtitle: "Location • Date" format
- Left: Back button (iOS-style arrow)
- Right: Play preview icon (play_circle_outline)

**PhotoViewerItem** (`widgets/photo_viewer_item.dart`)
- Individual photo item in vertical scroll
- Tap to toggle metadata overlay
- Auto-hide metadata after 3 seconds
- Metadata includes:
  - **Top-left:** Avatar + uploader name
  - **Top-right:** Download button
  - **Bottom-right:** Time (+ date if multi-day event)
- Gradient overlays (black 60% alpha) at top/bottom when metadata shown
- Loading states with progress indicator
- Error states with broken image icon

#### 2.3 Providers
**File:** `lib/features/memory/presentation/providers/memory_providers.dart`

**Added:**
```dart
final getMemoryPhotosUseCaseProvider = Provider<GetMemoryPhotos>
final memoryPhotosProvider = FutureProvider.family<List<MemoryPhoto>, String>
```

**DI Setup:**
- Uses existing `FakeMemoryRepository` by default
- Ready for P2 to swap in real Supabase implementation

---

### 3. Navigation

**Route Added:** `AppRouter.memoryViewer = '/memory-viewer'`

**Navigation from MemoryPage:**
```dart
Navigator.of(context).pushNamed(
  AppRouter.memoryViewer,
  arguments: {
    'memoryId': memoryId,
    'photoId': photoId,
  },
);
```

---

### 4. Shared Components Updated

**CoverMosaic** (`shared/components/sections/cover_mosaic.dart`)
- Updated `onPhotoTap` signature: `Function(String photoId)?`
- Passes photo ID to callback

**HybridPhotoGrid** (`shared/components/sections/hybrid_photo_grid.dart`)
- Updated `onPhotoTap` signature: `Function(String photoId)?`
- Passes photo ID to callback

---

## Design Implementation

### Layout (per `photos_layout_sizes.md`)

**Photo Sizing:**
- Full screen width
- Height calculated from photo aspect ratio
- Photos maintain original aspect ratio (no letterboxing)
- Center-crop fit

**Metadata Overlay:**
- Gradient backgrounds: `Colors.black.withValues(alpha: 0.6)`
- Gradient stops: `[0.0, 0.2, 0.8, 1.0]` (fade at edges)
- Avatar: 16px radius
- Download button: pill-shaped container with 8px padding
- Time pill: black 50% alpha background, 16px horizontal padding

**Typography:**
- Title (AppBar): `titleMediumEmph`, 18px, text1
- Subtitle (AppBar): `bodyMedium`, text2
- Uploader name: `bodyMedium`, 14px, w500, text1
- Time: `bodyMedium`, 12px, text1

**Spacing:**
- AppBar top padding: 12px
- AppBar horizontal padding: 16px (Insets.screenH)
- Subtitle gap: 8px (Gaps.xs)
- Metadata element padding: follows token system

---

## P2 Tasks 🔨

### 1. Data Layer Implementation

**Create Supabase Data Source:**
- File: `lib/features/memory/data/data_sources/memory_supabase_data_source.dart`
- No new queries needed (reuse existing memory fetch)

**No new repository needed:**
- `GetMemoryPhotos` use case already uses existing repository
- Just returns ordered list from `MemoryEntity.coverPhotos` + `MemoryEntity.gridPhotos`

### 2. Feature Implementation

**Download Photo Button:**
- Currently shows placeholder snackbar
- Implement actual download to device
- Use `StorageService` or image_gallery_saver package
- Show success/error feedback

**Play Preview Button:**
- Currently shows placeholder snackbar
- Implement auto-play slideshow mode
- Suggested: 3-second intervals, tap to pause/resume
- Consider full-screen mode (hide AppBar/metadata)

**Multi-day Event Detection:**
- Logic already in place (`_isMultiDayEvent`)
- Verify it works correctly with real data
- Format: "5 Jul • 14:30" vs just "14:30"

### 3. DI Override

**In `main.dart`:**
```dart
// No new override needed - uses existing memoryRepositoryProvider
// Verify real data flows through correctly
```

### 4. Testing & Polish

**Test Cases:**
- Open viewer from cover photo → correct initial position
- Open viewer from grid photo → correct initial position
- Metadata tap toggle → shows/hides correctly
- Metadata auto-hide → 3-second timer works
- Multi-day event → date shows in time pill
- Single-day event → only time shows
- Download button → saves photo to device
- Play preview → slideshow mode activates
- Back button → returns to memory page
- Loading states → spinner shows while fetching
- Error states → clear error message displayed

**Edge Cases:**
- Empty photos list (shouldn't happen but handle gracefully)
- Network failure during image load → broken image icon shows
- Very tall/wide aspect ratios → no overflow
- Rapid tap toggle → no animation glitches

---

## Quality Gates ✅

**Architecture:**
- ✅ No Supabase imports in domain layer
- ✅ No Supabase imports in presentation layer
- ✅ All tokens used (no hardcoded hex/dimensions except micro optical fixes)
- ✅ Stateless widgets where appropriate
- ✅ AsyncValue for loading/error states
- ✅ Complete DI coverage (uses existing fake repository)

**Code Quality:**
- ✅ `const` constructors where possible
- ✅ Proper error handling
- ✅ No TODO comments without context
- ✅ All imports used
- ✅ Follows naming conventions (snake_case files, PascalCase classes)

**UI/UX:**
- ✅ Follows design spec from `photos_layout_sizes.md`
- ✅ All metadata elements present
- ✅ Touch targets meet 44px minimum
- ✅ Accessibility considerations (contrast, text size)
- ✅ Loading and error states designed

---

## Known Limitations & Future Enhancements

**Current:**
- Download button placeholder
- Play preview placeholder
- No zoom/pinch support
- No video support (spec is photos only for MVP)

**Future (out of MVP scope):**
- Pinch-to-zoom on photos
- Share individual photo
- Delete photo (host only)
- Vote on photos from viewer
- Add photo to favorites
- Video playback support

---

## Files Modified/Created

### Created:
- `lib/features/memory/domain/usecases/get_memory_photos.dart`
- `lib/features/memory/presentation/pages/memory_viewer_page.dart`
- `lib/features/memory/presentation/widgets/memory_viewer_app_bar.dart`
- `lib/features/memory/presentation/widgets/photo_viewer_item.dart`

### Modified:
- `lib/features/memory/presentation/providers/memory_providers.dart` (added providers)
- `lib/features/memory/presentation/pages/memory_page.dart` (added navigation)
- `lib/routes/app_router.dart` (added route)
- `lib/shared/components/sections/cover_mosaic.dart` (updated onPhotoTap signature)
- `lib/shared/components/sections/hybrid_photo_grid.dart` (updated onPhotoTap signature)

---

## Testing the Feature

**To preview:**
1. Run app: `flutter run`
2. Navigate to Memory page (route: `/memory`)
3. Tap any photo (cover or grid)
4. Viewer opens at tapped photo
5. Scroll vertically to see all photos (covers first, then grid)
6. Tap photo to toggle metadata
7. Wait 3 seconds → metadata auto-hides
8. Tap back button → returns to memory page

**Fake Data:**
- Uses `FakeMemoryRepository`
- Configurable via `FakeMemoryConfig` in `fake_memory_repository.dart`
- Default: 1 portrait cover + 1 landscape cover + mixed grid photos

---

## Questions for P2

1. **Download destination:** Should photos go to gallery or app-specific folder?
2. **Download permissions:** Any platform-specific permission flows needed?
3. **Play preview UX:** Auto-advance every 3s or configurable?
4. **Multi-day format:** Confirm date format "5 Jul • 14:30" is correct for all locales
5. **Analytics:** Track photo views, download events, preview usage?

---

## P1 Sign-off

✅ **Domain contracts defined and documented**  
✅ **UI components built and tokenized**  
✅ **State management with Riverpod providers**  
✅ **Fake repository integration**  
✅ **Navigation implemented**  
✅ **Quality gates passed**  
✅ **Handoff document complete**

**Next:** P2 implements data layer (download/preview) and DI override for production.

---

**P1 Developer Notes:**
- Metadata overlay uses `AnimatedOpacity` for smooth fade
- Timer management in `PhotoViewerItem` properly disposed
- `PageView` with vertical scroll feels natural for photo browsing
- Initial page index calculation handles missing `photoId` gracefully
- Event date subtitle format reuses pattern from `MemoryPage` and `EventChatPage`

**End of P1 Handoff** 🚀
