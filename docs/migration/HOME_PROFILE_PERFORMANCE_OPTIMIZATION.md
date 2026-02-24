# Home & Profile Performance Optimization Plan

**Status:** 🟡 Pending Decision  
**Priority:** 🔴 High (Critical UX Issue)  
**Estimated Impact:** 70-90% reduction in loading time  
**Date:** 27 Dec 2025

---

## 📊 Current Performance Issues

### **Problem 1: Home Page - N+1 Query Cascade**
**File:** `lib/features/home/data/data_sources/home_event_remote_data_source.dart`

**Issue:**
```dart
// ❌ Current: For each event (10x), triggers 3+ Supabase queries
final eventsFutures = data.map((e) => homeEventFromMap(
  e as Map<String, dynamic>,
  onStatusMismatch: (eventId, newStatus) {
    updateEventStatus(eventId, newStatus).catchError(...);
  },
  currentUserId: userId,
  supabaseClient: client,
));
```

**Result:** 10 events × 3-5 queries = **30-50 sequential queries** ❌  
**Loading time:** 3-4 seconds

---

### **Problem 2: Profile Page - Sequential Signed URL Generation**
**File:** `lib/features/profile/data/repositories/profile_repository_impl.dart` (lines 33-42)

**Issue:**
```dart
// ❌ Current: Generates signed URLs in LOOP (no batching)
for (final model in memoryModels) {
  String? signedUrl;
  if (model.coverStoragePath != null) {
    signedUrl = await storageService.getSignedUrl(model.coverStoragePath!);
  }
  memories.add(model.toEntity(signedUrl: signedUrl));
}
```

**Result:** 10 memories × 300ms HTTP round-trip = **3 seconds** ❌  
**Loading time:** 4-5 seconds

---

### **Problem 3: Profile Memory Data Source - Triple Fallback Queries**
**File:** `lib/features/profile/data/data_sources/profile_memory_data_source.dart` (lines 48-108)

**Issue:**
```dart
// ❌ Current: For each event, runs 3 SEQUENTIAL fallback queries
for (final event in eventsResponse) {
  // Try 1: Query by cover_photo_id
  if (coverPhotoId != null) {
    final coverResponse = await client.from('group_photos')...
  }
  
  // Try 2: Query portrait photos
  if (coverStoragePath == null) {
    final portraitResponse = await client.from('group_photos')...
  }
  
  // Try 3: Query any photo
  if (coverStoragePath == null) {
    final anyPhoto = await client.from('group_photos')...
  }
}
```

**Result:** 10 events × 2-3 queries = **20-30 extra queries** ❌  
**Also affects:** `recent_memory_data_source.dart` (same pattern)

---

## 🎯 Proposed Solutions (3 Progressive Phases)

---

## **PHASE 1: Batch Signed URL Generation**

### **Impact:** 70% reduction in Profile page loading time  
### **Effort:** 2-3 hours  
### **Risk:** Low (isolated change in Storage Service)

### **What to Change:**

#### 1.1 Add Batch Method to StorageService

**File:** `lib/services/storage_service.dart`

**New method:**
```dart
/// Generate signed URLs for multiple storage paths in a single batch request
/// Returns a map of {storage_path: signed_url}
Future<Map<String, String>> getBatchSignedUrls(
  List<String> storagePaths, {
  String bucket = 'memory_groups',
  int expiresInSeconds = 3600,
}) async {
  if (storagePaths.isEmpty) return {};

  try {
    // Remove duplicates
    final uniquePaths = storagePaths.toSet().toList();
    
    // Batch request to Supabase Storage
    final results = await Future.wait(
      uniquePaths.map((path) => 
        _client.storage.from(bucket).createSignedUrl(path, expiresInSeconds)
      ),
    );

    // Build map
    final urlMap = <String, String>{};
    for (var i = 0; i < uniquePaths.length; i++) {
      if (results[i] != null) {
        urlMap[uniquePaths[i]] = results[i]!;
      }
    }

    return urlMap;
  } catch (e) {
    return {};
  }
}
```

---

#### 1.2 Refactor ProfileRepositoryImpl

**File:** `lib/features/profile/data/repositories/profile_repository_impl.dart`

**Changes in `getCurrentUserProfile()` method (line 29-42):**

```dart
// ❌ BEFORE (10 sequential requests)
final memories = <MemoryEntity>[];
for (final model in memoryModels) {
  String? signedUrl;
  if (model.coverStoragePath != null) {
    signedUrl = await storageService.getSignedUrl(model.coverStoragePath!);
  }
  memories.add(model.toEntity(signedUrl: signedUrl));
}

// ✅ AFTER (1 batch request)
// Extract all storage paths
final storagePaths = memoryModels
    .where((m) => m.coverStoragePath != null)
    .map((m) => m.coverStoragePath!)
    .toList();

// Get all signed URLs in one batch
final signedUrlsMap = await storageService.getBatchSignedUrls(
  storagePaths,
  bucket: 'memory_groups',
);

// Build entities with signed URLs
final memories = memoryModels.map((model) {
  final signedUrl = model.coverStoragePath != null
      ? signedUrlsMap[model.coverStoragePath]
      : null;
  return model.toEntity(signedUrl: signedUrl);
}).toList();
```

**Same changes needed in:**
- `getProfileById()` method (same file, line 65-80)
- `getUserMemories()` method (same file, line 110-125)

---

#### 1.3 Refactor OtherProfileRepositoryImpl

**File:** `lib/features/profile/data/repositories/other_profile_repository_impl.dart`

**Changes in `getProfileById()` method (line 45-85):**

```dart
// ❌ BEFORE (loop with sequential requests)
for (final memoryData in sharedMemoriesData) {
  String? signedCoverUrl;
  final coverPath = memoryData['cover_storage_path'] as String?;
  
  if (coverPath != null && coverPath.isNotEmpty) {
    try {
      signedCoverUrl = await _storageService.getSignedUrl(
        coverPath,
        bucket: 'memory_groups',
        expiresInSeconds: 3600,
      );
    } catch (e) {
      signedCoverUrl = null;
    }
  }
  
  memoriesList.add(MemoryEntity(...));
}

// ✅ AFTER (batch request)
// Extract all cover paths
final coverPaths = sharedMemoriesData
    .map((m) => m['cover_storage_path'] as String?)
    .where((path) => path != null && path.isNotEmpty)
    .cast<String>()
    .toList();

// Get all signed URLs in batch
final signedUrlsMap = await _storageService.getBatchSignedUrls(
  coverPaths,
  bucket: 'memory_groups',
);

// Build entities
final memoriesList = <MemoryEntity>[];
for (final memoryData in sharedMemoriesData) {
  final coverPath = memoryData['cover_storage_path'] as String?;
  final signedCoverUrl = coverPath != null && coverPath.isNotEmpty
      ? signedUrlsMap[coverPath]
      : null;
  
  memoriesList.add(MemoryEntity(
    id: memoryData['id'] as String,
    title: memoryData['title'] as String? ?? 'Untitled',
    coverImageUrl: signedCoverUrl,
    date: memoryData['date'] != null 
        ? DateTime.parse(memoryData['date'] as String)
        : DateTime.now(),
    location: memoryData['location'] as String?,
  ));
}
```

---

#### 1.4 Refactor RecentMemoryRepositoryImpl

**File:** `lib/features/home/data/repositories/recent_memory_repository_impl.dart`

**Apply same pattern as ProfileRepositoryImpl:**
- Extract storage paths
- Batch request signed URLs
- Map results

---

### **Phase 1 Testing Checklist:**
- [ ] Profile page loads with memories showing correct cover images
- [ ] Other profile page loads shared memories correctly
- [ ] Home page recent memories section displays properly
- [ ] Signed URLs expire correctly after 1 hour
- [ ] Error handling works when storage paths are invalid
- [ ] Performance: Profile page loads in <2 seconds

**Expected Gain:** 3-4s → 0.8-1.5s ⚡

---

## **PHASE 2: Eliminate N+1 Queries with SQL COALESCE**

### **Impact:** 80% reduction in query count  
### **Effort:** 3-4 hours  
### **Risk:** Medium (SQL query changes, needs testing)

### **What to Change:**

#### 2.1 Optimize ProfileMemoryDataSource

**File:** `lib/features/profile/data/data_sources/profile_memory_data_source.dart`

**Replace entire `getUserMemories()` method (lines 12-115):**

```dart
/// Fetch all memories (ended/recap events) for a user
/// Returns events where user is a member, with cover photos (OPTIMIZED: single query)
Future<List<Map<String, dynamic>>> getUserMemories(String userId) async {
  try {
    // 1) Find all groups where user is a member
    final groupsResponse = await client
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId);

    if (groupsResponse.isEmpty) {
      return [];
    }

    final groupIds = groupsResponse
        .map((row) => row['group_id'] as String)
        .toList();

    // 2) Query events with COALESCE for automatic cover fallback
    // ✅ NEW: Single query with SQL-level fallback (no loops!)
    final eventsResponse = await client
        .rpc('get_user_memories_with_covers', params: {
          'p_group_ids': groupIds,
        });

    return List<Map<String, dynamic>>.from(eventsResponse);
  } catch (e) {
    rethrow;
  }
}
```

---

#### 2.2 Create Supabase RPC Function

**Location:** Supabase SQL Editor (P2 task, but provide SQL here)

**Function to create:**

```sql
-- RPC function to fetch user memories with cover photo fallback
-- Replaces 30+ queries with 1 optimized query

CREATE OR REPLACE FUNCTION get_user_memories_with_covers(p_group_ids uuid[])
RETURNS TABLE (
  id uuid,
  name text,
  end_datetime timestamptz,
  display_name text,
  cover_storage_path text
) 
LANGUAGE sql
STABLE
AS $$
  SELECT 
    e.id,
    e.name,
    e.end_datetime,
    l.display_name,
    COALESCE(
      -- Try 1: Use cover_photo_id if set
      (SELECT gp.storage_path 
       FROM group_photos gp 
       WHERE gp.id = e.cover_photo_id 
       LIMIT 1),
      
      -- Try 2: Get first portrait photo
      (SELECT gp.storage_path 
       FROM group_photos gp 
       WHERE gp.event_id = e.id 
         AND gp.is_portrait = true 
       ORDER BY gp.captured_at ASC 
       LIMIT 1),
      
      -- Try 3: Get any photo
      (SELECT gp.storage_path 
       FROM group_photos gp 
       WHERE gp.event_id = e.id 
       ORDER BY gp.captured_at ASC 
       LIMIT 1)
    ) as cover_storage_path
  FROM events e
  LEFT JOIN locations l ON e.location_id = l.id
  WHERE e.group_id = ANY(p_group_ids)
    AND e.status IN ('recap', 'ended')
  ORDER BY e.end_datetime DESC;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_user_memories_with_covers TO authenticated;
```

---

#### 2.3 Optimize RecentMemoryDataSource

**File:** `lib/features/home/data/data_sources/recent_memory_data_source.dart`

**Replace `getRecentMemories()` method (lines 11-120):**

```dart
/// Fetch memories from the last 30 days for the current user
/// OPTIMIZED: Single query with SQL-level cover fallback
Future<List<Map<String, dynamic>>> getRecentMemories(String userId) async {
  try {
    // Get date 30 days ago
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    // Get user's groups
    final userGroupsResponse = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId);

    if (userGroupsResponse.isEmpty) {
      return [];
    }

    final userGroupIds = (userGroupsResponse as List)
        .map((m) => m['group_id'] as String)
        .toList();

    // ✅ NEW: Single optimized query with RPC
    final response = await _client
        .rpc('get_recent_memories_with_covers', params: {
          'p_user_group_ids': userGroupIds,
          'p_start_date': thirtyDaysAgo.toIso8601String(),
        });

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    rethrow;
  }
}
```

**Corresponding RPC function:**

```sql
-- RPC function for recent memories (last 30 days)
CREATE OR REPLACE FUNCTION get_recent_memories_with_covers(
  p_user_group_ids uuid[],
  p_start_date timestamptz
)
RETURNS TABLE (
  id uuid,
  name text,
  start_datetime timestamptz,
  end_datetime timestamptz,
  display_name text,
  cover_storage_path text,
  group_id uuid
) 
LANGUAGE sql
STABLE
AS $$
  SELECT 
    e.id,
    e.name,
    e.start_datetime,
    e.end_datetime,
    l.display_name,
    COALESCE(
      (SELECT gp.storage_path FROM group_photos gp WHERE gp.id = e.cover_photo_id LIMIT 1),
      (SELECT gp.storage_path FROM group_photos gp WHERE gp.event_id = e.id AND gp.is_portrait = true ORDER BY gp.captured_at ASC LIMIT 1),
      (SELECT gp.storage_path FROM group_photos gp WHERE gp.event_id = e.id ORDER BY gp.captured_at ASC LIMIT 1)
    ) as cover_storage_path,
    e.group_id
  FROM events e
  LEFT JOIN locations l ON e.location_id = l.id
  WHERE e.group_id = ANY(p_user_group_ids)
    AND e.status IN ('recap', 'ended')
    AND e.end_datetime >= p_start_date
  ORDER BY e.end_datetime DESC
  LIMIT 20;
$$;

GRANT EXECUTE ON FUNCTION get_recent_memories_with_covers TO authenticated;
```

---

#### 2.4 Optimize Home Events Query (if needed)

**File:** `lib/features/home/data/data_sources/home_event_remote_data_source.dart`

**Analysis needed:** Check what `homeEventFromMap` does internally. If it triggers queries, consider:
- Creating a materialized view `home_events_view_optimized`
- Or RPC function that pre-joins all necessary data

---

### **Phase 2 Testing Checklist:**
- [ ] Supabase RPC functions created successfully
- [ ] Profile memories load with correct covers
- [ ] Home recent memories show correct images
- [ ] Fallback logic works (portrait → any photo)
- [ ] Events without photos handled gracefully
- [ ] Query performance: <500ms for 20 events
- [ ] RLS policies allow RPC execution

**Expected Gain:** 20-30 queries → 1-2 queries ⚡

---

## **PHASE 3: Client-Side Caching with Riverpod**

### **Impact:** 90% reduction on repeated page visits  
### **Effort:** 2 hours  
### **Risk:** Low (configuration only, easily reversible)

### **What to Change:**

#### 3.1 Add Cache Extension to Riverpod

**File:** Create `lib/core/extensions/ref_extensions.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Extension to add caching capability to providers
extension RefCache on Ref {
  /// Keep provider alive for specified duration
  /// After duration expires, provider auto-disposes on next rebuild
  void cacheFor(Duration duration) {
    final link = keepAlive();
    
    // Schedule disposal after duration
    final timer = Timer(duration, () {
      link.close();
    });
    
    // Cancel timer if provider is manually disposed before duration
    onDispose(() {
      timer.cancel();
    });
  }
}
```

---

#### 3.2 Update Home Event Providers

**File:** `lib/features/home/presentation/providers/home_event_providers.dart`

**Changes:**

```dart
// ✅ Import extension
import '../../../../core/extensions/ref_extensions.dart';

// ❌ BEFORE: Auto-dispose on every page exit
final nextEventControllerProvider = 
    FutureProvider.autoDispose<HomeEventEntity?>((ref) async {
  final useCase = ref.watch(getNextEventProvider);
  return await useCase();
});

// ✅ AFTER: Cache for 5 minutes
final nextEventControllerProvider = 
    FutureProvider<HomeEventEntity?>((ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  final useCase = ref.watch(getNextEventProvider);
  return await useCase();
});

// Apply to all relevant providers:
// - confirmedEventsControllerProvider
// - homeEventsControllerProvider
// - livingAndRecapEventsControllerProvider
// - paymentSummariesControllerProvider
// - recentMemoriesControllerProvider
```

---

#### 3.3 Update Profile Providers

**File:** `lib/features/profile/presentation/providers/profile_providers.dart`

**Changes:**

```dart
import '../../../../core/extensions/ref_extensions.dart';

// ❌ BEFORE
final profileByIdProvider = 
    FutureProvider.family.autoDispose<ProfileEntity, String>((ref, userId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfileById(userId);
});

// ✅ AFTER: Cache for 5 minutes
final profileByIdProvider = 
    FutureProvider.family<ProfileEntity, String>((ref, userId) async {
  ref.cacheFor(const Duration(minutes: 5));
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfileById(userId);
});

// Apply to:
// - currentUserProfileProvider (10 min cache)
// - userMemoriesProvider (5 min cache)
```

---

#### 3.4 Smart Cache Invalidation

**Add manual invalidation when data changes:**

**Example in EditProfilePage:**

```dart
// After successful profile update
await ref.read(updateProfileUseCaseProvider)(updatedProfile);

// Invalidate cache to force refresh
ref.invalidate(currentUserProfileProvider);
ref.invalidate(profileByIdProvider(currentUserId));
```

---

### **Phase 3 Testing Checklist:**
- [ ] First page visit fetches from Supabase
- [ ] Second visit within 5 minutes uses cache (instant load)
- [ ] Cache expires correctly after duration
- [ ] Manual invalidation works on data updates
- [ ] Memory usage is acceptable (no leaks)
- [ ] Pull-to-refresh invalidates cache properly

**Expected Gain:** 2nd visit = 0.1s (cached) ⚡

---

## 📊 Combined Impact Summary

| Metric | Current | After Phase 1 | After Phase 2 | After Phase 3 |
|--------|---------|---------------|---------------|---------------|
| **Home (1st visit)** | 3-4s | 2.5s | **0.8s** ⚡ | 0.8s |
| **Home (2nd visit)** | 3-4s | 2.5s | 0.8s | **0.1s** ⚡⚡ |
| **Profile (1st visit)** | 4-5s | **1.5s** ⚡ | **0.7s** ⚡ | 0.7s |
| **Profile (2nd visit)** | 4-5s | 1.5s | 0.7s | **0.1s** ⚡⚡ |
| **Query count** | 30-50 | 15-25 | **1-3** ⚡⚡⚡ | 1-3 (or 0 cached) |

---

## 🎯 Recommended Approach

### **Option A: Quick Win (Phase 1 Only)**
- ✅ Fastest to implement (2-3 hours)
- ✅ 70% improvement immediately
- ✅ No Supabase changes needed
- ✅ Low risk, easy rollback
- ❌ Doesn't fix N+1 query problem

**Best for:** Urgent fix needed before year-end

---

### **Option B: Complete Fix (Phase 1 + 2)**
- ✅ 85% improvement overall
- ✅ Addresses root causes
- ✅ Scalable for future growth
- ⚠️ Requires P2 team for SQL functions
- ⚠️ More testing needed

**Best for:** Sustainable long-term solution

---

### **Option C: Full Stack (All 3 Phases)**
- ✅ 90% improvement + instant repeat visits
- ✅ Best user experience
- ✅ Production-ready performance
- ⚠️ Most effort (8-10 hours total)
- ⚠️ Requires coordination with P2

**Best for:** Building high-quality app

---

## 🚨 Breaking Changes & Risks

### **Phase 1:**
- ⚠️ New dependency: `getBatchSignedUrls` must be added to StorageService
- ⚠️ All repositories using signed URLs must be updated
- ✅ Rollback: Keep old methods, add new ones, switch gradually

### **Phase 2:**
- 🔴 **P2 Required:** SQL functions must be created in Supabase
- ⚠️ RLS policies must allow RPC execution
- ⚠️ Function signatures must match exactly
- ✅ Rollback: Keep old data sources, feature flag to switch

### **Phase 3:**
- ⚠️ Memory usage increases slightly (cached data)
- ⚠️ Stale data possible if cache not invalidated properly
- ✅ Rollback: Change providers back to `autoDispose`

---

## 📝 Implementation Order

### **If choosing Option B (Recommended):**

1. **Day 1 Morning:** Phase 1 Implementation
   - Add `getBatchSignedUrls` to StorageService
   - Refactor ProfileRepositoryImpl
   - Refactor OtherProfileRepositoryImpl
   - Test Profile page

2. **Day 1 Afternoon:** Phase 1 Completion
   - Refactor RecentMemoryRepositoryImpl
   - Test Home page recent memories
   - Performance testing
   - Code review

3. **Day 2 Morning:** Phase 2 P2 Coordination
   - Send SQL functions to P2 team
   - Wait for Supabase deployment
   - Test RPC functions in Supabase console

4. **Day 2 Afternoon:** Phase 2 Client Implementation
   - Update ProfileMemoryDataSource
   - Update RecentMemoryDataSource
   - Integration testing
   - Performance validation

---

## ✅ Acceptance Criteria

### **Phase 1 Complete When:**
- [ ] Profile page loads in <2 seconds (first visit)
- [ ] No console errors related to storage URLs
- [ ] All cover images display correctly
- [ ] Code follows architecture guidelines (Data layer only)
- [ ] No print statements in production code

### **Phase 2 Complete When:**
- [ ] SQL functions created and tested in Supabase
- [ ] Query count reduced from 30+ to 1-3
- [ ] Profile page loads in <1 second (first visit)
- [ ] Home page loads in <1 second (first visit)
- [ ] Fallback logic works (cover → portrait → any photo)
- [ ] RLS policies allow authenticated users to execute functions

### **Phase 3 Complete When:**
- [ ] Second page visit loads instantly (<0.2s)
- [ ] Cache invalidates after specified duration
- [ ] Manual refresh invalidates cache properly
- [ ] No memory leaks detected
- [ ] Pull-to-refresh works correctly

---

## 🔍 Monitoring & Validation

### **Performance Metrics to Track:**

```dart
// Add to HomePage and ProfilePage
@override
void initState() {
  super.initState();
  final stopwatch = Stopwatch()..start();
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    stopwatch.stop();
    // Only in debug mode
    assert(() {
      print('[Performance] Page loaded in ${stopwatch.elapsedMilliseconds}ms');
      return true;
    }());
  });
}
```

**Targets:**
- Profile page: <1000ms (Phase 1), <700ms (Phase 2)
- Home page: <1200ms (Phase 1), <800ms (Phase 2)
- Query count: <5 per page load

---

## 📚 Additional Considerations

### **Alternative: Create Materialized View (Instead of RPC)**

**Pros:**
- Faster than RPC (pre-computed)
- No function calls needed
- Can add indexes for speed

**Cons:**
- Needs refresh trigger
- More storage space
- Stale data between refreshes

**SQL Example:**
```sql
CREATE MATERIALIZED VIEW events_with_covers AS
SELECT 
  e.id,
  e.name,
  e.end_datetime,
  l.display_name,
  COALESCE(
    (SELECT gp.storage_path FROM group_photos gp WHERE gp.id = e.cover_photo_id LIMIT 1),
    (SELECT gp.storage_path FROM group_photos gp WHERE gp.event_id = e.id AND gp.is_portrait = true ORDER BY gp.captured_at ASC LIMIT 1),
    (SELECT gp.storage_path FROM group_photos gp WHERE gp.event_id = e.id ORDER BY gp.captured_at ASC LIMIT 1)
  ) as cover_storage_path
FROM events e
LEFT JOIN locations l ON e.location_id = l.id
WHERE e.status IN ('recap', 'ended');

-- Refresh on every photo insert/update/delete
CREATE OR REPLACE FUNCTION refresh_events_with_covers()
RETURNS TRIGGER AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY events_with_covers;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER refresh_events_covers_trigger
AFTER INSERT OR UPDATE OR DELETE ON group_photos
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_events_with_covers();
```

---

## 🚀 Ready to Implement?

**Decision needed:** Which option to proceed with?

- **Option A (Phase 1 only):** 2-3 hours, 70% improvement, no P2 coordination
- **Option B (Phase 1+2):** 6-8 hours, 85% improvement, requires P2 SQL functions ⭐ **Recommended**
- **Option C (All phases):** 8-10 hours, 90% improvement, complete solution

**Next steps after decision:**
1. Confirm chosen approach
2. Coordinate with P2 if Phase 2 selected
3. Create feature branch: `feat/performance-optimization-home-profile`
4. Implement changes systematically
5. Test each phase before moving to next
6. Monitor performance metrics post-deployment

---

**Contact P2 for Phase 2:** Share SQL functions from sections 2.2 and 2.3 for Supabase deployment.
