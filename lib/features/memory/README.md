# Memory Feature - P1 Implementation Complete

## Overview
The Memory page displays a completed event's photos with an adaptive layout following the spec in `photos_layout_sizes.md`.

## Structure (Top to Bottom)
1. **Header**: Back button, "Memory" title, Share button
2. **Cover Mosaic**: 1-3 cover photos with adaptive layout based on orientation
3. **Event Info**: Title with emoji + subtitle (location • date)
4. **Photo Grid**: All non-cover photos in 3-column responsive grid

## P1 Deliverables ✅

### Domain Layer
- ✅ `domain/entities/memory_entity.dart` - Core entity with photo sorting logic
- ✅ `domain/repositories/memory_repository.dart` - Repository interface
- ✅ `domain/usecases/get_memory.dart` - Fetch memory use case
- ✅ `domain/usecases/share_memory.dart` - Share memory use case

### Shared Components (Reusable)
- ✅ `shared/components/sections/cover_mosaic.dart` - Adaptive cover photo mosaic (1-3 photos)
- ✅ `shared/components/sections/photo_grid.dart` - Responsive 3-column photo grid

### Presentation Layer
- ✅ `presentation/pages/memory_page.dart` - Main memory page
- ✅ `presentation/providers/memory_providers.dart` - Riverpod providers

### Data Layer (Fake)
- ✅ `data/fakes/fake_memory_repository.dart` - Fake implementation with sample data

### Navigation
- ✅ Route added to `app_router.dart` as `/memory`
- ✅ Page set as initial route in `app.dart` for preview

## Cover Mosaic Layout Logic
The mosaic follows the exact spec from `photos_layout_sizes.md`:
- 4×2 grid (4 columns, 2 rows of equal square cells)
- Padding: 16px (left/right)
- Gap: 8px between tiles
- Portrait photos: 1×2 cells
- Landscape photos: 2×1 cells
- Big/hero photos: 2×2 cells
- Deterministic placement based on count + orientation patterns

### Layout Patterns
**1 cover**: Big (2×2) centered
**2 covers**: 
- [V,H]: V left + H top-center
- [H,V]: H top-left + V right
- [V,V]: Big left + V right
- [H,H]: H top-left + H top-right

**3 covers**: 6 specific patterns (see code comments)

## Photo Grid Layout
- 3 columns (portrait mode)
- Portrait photos: 4:5 aspect ratio (1 column wide)
- Landscape photos: 16:9 aspect ratio (2 columns wide)
- Gap: 8px between tiles
- Padding: 16px left/right
- Sorted by capture timestamp (oldest first)

## Entity Design
`MemoryEntity`:
- Separates covers from grid photos automatically
- Covers sorted by: votes DESC → prefer portrait → newer timestamp
- Maximum 3 covers
- Grid photos sorted by capture timestamp ASC

`MemoryPhoto`:
- Includes multiple derivatives (thumbnail 512px, cover 1024px, full url)
- Aspect ratio stored for layout calculations
- Vote count for cover selection
- Uploader info

## Fake Data
`FakeMemoryRepository` provides:
- 1 sample memory ("Beach Day" in Marrakech)
- Mix of portrait (4:5) and landscape (16:9) photos
- Varied vote counts to test cover selection
- Uses picsum.photos for placeholder images

## Current Behavior
- Memory page loads with fake data (memory-1)
- Cover mosaic adapts to photo orientations
- Grid displays remaining photos
- Share button triggers mock share action
- All states handled: loading, error, empty

## For P2: Data Layer Implementation

### Tasks
1. **Create Supabase data source** (`data/data_sources/memory_remote_data_source.dart`):
   - Query memories table with joins to photos
   - Fetch photo metadata (votes, uploader, derivatives)
   - Implement share URL generation (or native share trigger)

2. **Create DTO models** (`data/models/`):
   - `memory_model.dart` - Maps Supabase row to MemoryEntity
   - `memory_photo_model.dart` - Maps photo row to MemoryPhoto
   - Handle JSON parsing, defaults, null safety

3. **Implement repository** (`data/repositories/memory_repository_impl.dart`):
   - Use data source for queries
   - Map DTOs to entities
   - Handle errors gracefully

4. **DI Override** in `main.dart`:
   ```dart
   memoryRepositoryProvider.overrideWith(
     (ref) => MemoryRepositoryImpl(
       MemoryRemoteDataSource(Supabase.instance.client),
     ),
   );
   ```

### Database Schema (Expected)
```sql
-- memories table
id, event_id, title, emoji, location, event_date, created_at

-- memory_photos table
id, memory_id, url, thumbnail_url, cover_url, aspect_ratio, 
vote_count, captured_at, uploader_id, uploader_name
```

### Supabase Queries (Suggested)
```dart
// Get memory with photos
final data = await client
  .from('memories')
  .select('*, memory_photos(*)')
  .eq('id', memoryId)
  .single();

// Or join manually if needed
final memory = await client.from('memories').select().eq('id', memoryId).single();
final photos = await client.from('memory_photos').select().eq('memory_id', memoryId);
```

### RLS Considerations
- Users can only view memories from groups they belong to
- Check event/group membership in RLS policies
- Read-only access for memories (no updates after creation)

### Image Derivatives
Photos should have multiple sizes:
- `thumbnail_url`: 512px (for grid)
- `cover_url`: 1024px (for cover mosaic)
- `url`: Full resolution (for viewer/share)

Generated via Supabase Storage transforms or upload pipeline.

## Testing Checklist (P2)
- [ ] Memory loads from Supabase
- [ ] Cover selection matches spec (votes → portrait → timestamp)
- [ ] Cover layouts render correctly for all patterns
- [ ] Grid photos exclude covers
- [ ] Grid photos sorted by capture time
- [ ] Share triggers native share or generates URL
- [ ] Loading/error/empty states work
- [ ] Images load with proper derivatives
- [ ] RLS prevents unauthorized access

## Known Issues / Future Enhancements
- Share currently shows snackbar; needs native share integration
- No photo viewer on tap (add later)
- No video support (MVP scope)
- No photo metadata overlay (uploader, votes)
- No filters/sorting options

## Files Created
```
lib/features/memory/
├── domain/
│   ├── entities/memory_entity.dart
│   ├── repositories/memory_repository.dart
│   └── usecases/
│       ├── get_memory.dart
│       └── share_memory.dart
├── data/
│   └── fakes/fake_memory_repository.dart
└── presentation/
    ├── pages/memory_page.dart
    └── providers/memory_providers.dart

lib/shared/components/sections/
├── cover_mosaic.dart
└── photo_grid.dart
```

## Dependencies
- `flutter_riverpod` (state management)
- `intl` (date formatting)
- All design tokens from `shared/constants/` and `shared/themes/`

---
**Status**: P1 complete. Ready for P2 Supabase integration.
**Preview**: Set `initialRoute` to `AppRouter.memory` in `app.dart`.
