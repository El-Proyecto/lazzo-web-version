# Home & Profile Performance Optimization - Implementation Summary

**Date:** 2025-01-XX  
**Status:** ✅ Implementation Complete (Testing Pending P2 Deployment)  
**Performance Goal:** Reduce page load times from 3-5 seconds → <1 second (70-85% reduction)

---

## Overview

Implemented comprehensive performance optimizations for Home and Profile pages by eliminating N+1 query patterns and sequential signed URL generation. Solution consists of two phases:

- **Phase 1:** Client-side batch URL generation (parallel HTTP requests)
- **Phase 2:** Database-level RPC functions with COALESCE fallback (eliminate N+1 queries)

---

## Implementation Details

### Phase 1: Batch Signed URL Generation ✅

**Problem:** Sequential HTTP requests for signed URLs (300ms × 10 photos = 3 seconds)

**Solution:** Parallel batch processing using `Future.wait()`

#### Files Modified:

1. **lib/services/storage_service.dart**
   - Added `getBatchSignedUrls()` method
   - Accepts `List<String>` paths, returns `Map<String, String>` (path → URL)
   - Uses `Future.wait()` for parallel execution
   - Handles path normalization (removes leading `/`)
   - Graceful error recovery (individual URL failures don't block others)

2. **lib/features/profile/data/repositories/profile_repository_impl.dart**
   - Refactored 4 methods: `getCurrentUserProfile()`, `getProfileById()`, `updateProfile()`, `getUserMemories()`
   - Pattern: Extract paths → Batch request → Map results
   - Reduced 10+ sequential calls → 1 batch call

3. **lib/features/profile/data/repositories/other_profile_repository_impl.dart**
   - Refactored `getOtherUserProfile()`
   - Batch processing for shared memories cover photos
   - Reduced 10+ sequential calls → 1 batch call

4. **lib/features/home/data/repositories/recent_memory_repository_impl.dart**
   - Refactored `getRecentMemories()`
   - Separated model conversion from URL generation
   - Applied batch processing pattern

**Performance Impact:**
- Before: 10 photos × 300ms = 3 seconds
- After: 1 batch request × 300ms = 300ms
- **~90% reduction in URL generation time**

---

### Phase 2: SQL RPC Functions with COALESCE Fallback ✅

**Problem:** N+1 query cascade (10 events × 3 fallback queries = 30+ sequential DB queries)

**Solution:** Single RPC function with automatic fallback using SQL `COALESCE`

#### SQL Functions Created (for P2 Deployment):

##### 1. `get_user_memories_with_covers(p_user_id UUID, p_group_ids UUID[])`
```sql
-- Replaces 30+ sequential queries with 1 call
-- Returns events with best available cover photo using COALESCE:
-- 1. cover_photo_id (if set)
-- 2. First portrait photo
-- 3. Any photo
```

##### 2. `get_recent_memories_with_covers(p_user_id UUID, p_since_date TIMESTAMPTZ)`
```sql
-- Replaces 20+ sequential queries with 1 call
-- Filters events by:
-- - User's group membership
-- - Status: 'recap' or 'ended'
-- - 30-day time window
-- - Has valid cover photo
```

**Documentation:** See [IMPLEMENTATION/SQL_FUNCTIONS_FOR_P2.md](../IMPLEMENTATION/SQL_FUNCTIONS_FOR_P2.md) for complete deployment guide.

#### Files Modified:

1. **lib/features/profile/data/data_sources/profile_memory_data_source.dart**
   - Replaced `getUserMemories()` method
   - Old: ~100 lines with 3 nested loops (group_members → events → 3× fallback queries per event)
   - New: ~20 lines with single RPC call
   - Reduced 30+ queries → 2 queries (group_members + RPC)

2. **lib/features/home/data/data_sources/recent_memory_data_source.dart**
   - Replaced `getRecentMemories()` method
   - Old: ~110 lines with sequential fallback logic per event
   - New: ~30 lines with single RPC call
   - Reduced 20+ queries → 1 query (RPC includes membership check)

**Performance Impact:**
- Before: 30-50 sequential DB queries per page load
- After: 1-2 RPC calls per page load
- **~95% reduction in database round-trips**

---

## Architecture Compliance ✅

- ✅ Changes isolated to **Data Layer** (repositories + data sources)
- ✅ **No** presentation layer modifications required
- ✅ **No** domain entity changes
- ✅ Preserved Clean Architecture separation
- ✅ All components stateless and tokenized
- ✅ No print statements in production code
- ✅ Error handling with graceful fallbacks

---

## Testing Requirements

### P2 Team - Database Deployment (BLOCKER)

**Required Actions:**
1. Deploy 2 SQL RPC functions from `IMPLEMENTATION/SQL_FUNCTIONS_FOR_P2.md`
2. Grant execute permissions to authenticated users
3. Verify RLS policies work with functions
4. Test functions with sample data

**Validation Queries:**
```sql
-- Test get_user_memories_with_covers
SELECT * FROM get_user_memories_with_covers(
  '<test_user_id>'::UUID,
  ARRAY['<group1_id>'::UUID, '<group2_id>'::UUID]
);

-- Test get_recent_memories_with_covers
SELECT * FROM get_recent_memories_with_covers(
  '<test_user_id>'::UUID,
  NOW() - INTERVAL '30 days'
);
```

### P1 Team - Client Testing (After P2 Deployment)

**Profile Page:**
- [ ] Load user profile → verify <1 second load time
- [ ] Check "My Memories" section → verify photos appear correctly
- [ ] Test cover photo fallback (portrait → any photo)
- [ ] Verify error handling when no photos exist

**Home Page:**
- [ ] Load recent memories → verify <1 second load time
- [ ] Check 30-day time window filtering
- [ ] Verify only events with covers appear
- [ ] Test empty state (no recent memories)

**Other User Profile:**
- [ ] Load other user profile → verify batch URL generation
- [ ] Check shared memories display correctly

**Performance Metrics:**
- [ ] Measure page load times (target: <1s)
- [ ] Count database queries in Supabase logs (target: 1-2 queries)
- [ ] Verify signed URL generation time (target: <500ms)

---

## Expected Results

### Before Optimization:
- **Profile Page:** 3-5 seconds load time
  - 10 events × 3 fallback queries = 30 DB queries
  - 10 photos × 300ms signed URL = 3 seconds HTTP
- **Home Page:** 3-5 seconds load time
  - 20 events × 3 fallback queries = 60 DB queries
  - 20 photos × 300ms signed URL = 6 seconds HTTP

### After Optimization:
- **Profile Page:** <1 second load time
  - 2 DB queries (group_members + RPC)
  - 1 batch signed URL request (300ms)
- **Home Page:** <1 second load time
  - 1 DB query (RPC includes membership check)
  - 1 batch signed URL request (300ms)

### Performance Improvements:
- **Database queries:** 30-60 queries → 1-2 queries (~95% reduction)
- **HTTP requests:** 10-20 sequential → 1 batch (~90% reduction)
- **Total load time:** 3-5 seconds → <1 second (~80% reduction)

---

## Rollback Plan (If Issues Arise)

### Phase 2 Rollback (SQL Functions):
If RPC functions cause issues, revert data source files:

```bash
# Revert to pre-RPC version
git checkout HEAD~1 -- lib/features/profile/data/data_sources/profile_memory_data_source.dart
git checkout HEAD~1 -- lib/features/home/data/data_sources/recent_memory_data_source.dart
```

**Impact:** Returns to sequential fallback queries but keeps Phase 1 batch URL optimization.

### Phase 1 Rollback (Batch URLs):
If batch processing causes issues, revert repository files:

```bash
# Revert all repository changes
git checkout HEAD~5 -- lib/features/profile/data/repositories/profile_repository_impl.dart
git checkout HEAD~5 -- lib/features/profile/data/repositories/other_profile_repository_impl.dart
git checkout HEAD~5 -- lib/features/home/data/repositories/recent_memory_repository_impl.dart
git checkout HEAD~5 -- lib/services/storage_service.dart
```

**Impact:** Returns to sequential signed URL generation (slower performance).

### Full Rollback:
```bash
# Revert all optimization changes
git revert <commit_range>
```

---

## Next Steps

1. **[P2 TEAM - BLOCKER]** Deploy SQL functions from `IMPLEMENTATION/SQL_FUNCTIONS_FOR_P2.md`
2. **[P2 TEAM]** Test functions in Supabase SQL Editor with real data
3. **[P2 TEAM]** Grant execute permissions to authenticated users
4. **[P2 TEAM]** Notify P1 when deployment complete
5. **[P1 TEAM]** Run client-side testing checklist above
6. **[P1 TEAM]** Measure performance metrics (page load times, query counts)
7. **[P1 TEAM]** Monitor Sentry/logs for any errors in first 24h
8. **[BOTH TEAMS]** Review results and iterate if needed

---

## Related Documents

- **Original Plan:** [MIGRATIONS/HOME_PROFILE_PERFORMANCE_OPTIMIZATION.md](HOME_PROFILE_PERFORMANCE_OPTIMIZATION.md)
- **SQL Deployment Guide:** [IMPLEMENTATION/SQL_FUNCTIONS_FOR_P2.md](../IMPLEMENTATION/SQL_FUNCTIONS_FOR_P2.md)
- **Database Schema:** [supabase_structure.sql](../../supabase_structure.sql) and [supabase_schema.sql](../../supabase_schema.sql)
- **Architecture Guide:** [agents.md](../../agents.md)

---

## Conclusion

All code changes implemented successfully. Optimization leverages:
- ✅ Parallel HTTP requests (Phase 1)
- ✅ SQL-level optimization with COALESCE (Phase 2)
- ✅ Graceful error handling and fallbacks
- ✅ Zero breaking changes to presentation layer

**Status:** Ready for P2 database deployment and testing.

**Estimated Performance Improvement:** 70-85% reduction in page load times (3-5s → <1s).
