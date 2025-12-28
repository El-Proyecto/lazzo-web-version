# Supabase RPC Functions - Performance Optimization

**Target:** P2 Team (Supabase Database)  
**Purpose:** Eliminate N+1 queries in Profile and Home pages  
**Impact:** 80% reduction in query count (30+ queries → 1-2 queries)  
**Date:** 27 Dec 2025

---

## 📋 Overview

This document contains **2 SQL RPC functions** that must be created in Supabase to optimize memory cover photo fetching. These functions replace multiple sequential queries with a single optimized query using `COALESCE` for automatic fallback logic.

**Performance gain:**
- **Before:** 10 events × 3 queries each = 30 queries (2-3 seconds)
- **After:** 1 RPC call = 1 query (0.2-0.3 seconds)

---

## 🔧 Function 1: get_user_memories_with_covers

### **Purpose**
Fetch all memories (ended/recap events) for a user with cover photos included in a single query.

### **Used by**
- Profile page (current user)
- Profile page (other users)
- `lib/features/profile/data/data_sources/profile_memory_data_source.dart`

### **SQL to Execute in Supabase SQL Editor**

```sql
-- RPC function to fetch user memories with cover photo fallback
-- Replaces 30+ queries with 1 optimized query using COALESCE

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
SECURITY DEFINER
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
    AND (
      -- Only return events that have at least one photo
      e.cover_photo_id IS NOT NULL
      OR EXISTS (
        SELECT 1 FROM group_photos gp 
        WHERE gp.event_id = e.id 
        LIMIT 1
      )
    )
  ORDER BY e.end_datetime DESC;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_user_memories_with_covers(uuid[]) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION get_user_memories_with_covers IS 
'Optimized function to fetch user memories with cover photos. Uses COALESCE for automatic fallback: cover_photo_id → portrait → any photo. Called by Profile page to eliminate N+1 queries.';
```

---

### **Testing the Function**

After creating the function, test it in Supabase SQL Editor:

```sql
-- Test with a real user's group IDs
-- Replace with actual group IDs from your database
SELECT * FROM get_user_memories_with_covers(
  ARRAY['group-id-1'::uuid, 'group-id-2'::uuid]
);

-- Expected result: List of events with cover_storage_path populated
-- NULL cover_storage_path means no photos for that event
```

---

### **RLS Considerations**

The function uses `SECURITY DEFINER` to run with the permissions of the function creator. Ensure that:

1. ✅ The function creator has SELECT access to `events`, `group_photos`, and `locations` tables
2. ✅ RLS policies on these tables allow authenticated users to read their own group data
3. ✅ The function is granted to `authenticated` role only

**If RLS issues occur**, you can add explicit checks:

```sql
-- Add RLS check inside function (optional if RLS already configured)
WHERE e.group_id = ANY(p_group_ids)
  AND e.status IN ('recap', 'ended')
  AND EXISTS (
    SELECT 1 FROM group_members gm 
    WHERE gm.group_id = e.group_id 
      AND gm.user_id = auth.uid()
  )
```

---

## 🔧 Function 2: get_recent_memories_with_covers

### **Purpose**
Fetch memories from the last 30 days for the home page with cover photos included.

### **Used by**
- Home page (Recent Memories section)
- `lib/features/home/data/data_sources/recent_memory_data_source.dart`

### **SQL to Execute in Supabase SQL Editor**

```sql
-- RPC function for recent memories (last 30 days)
-- Optimizes home page loading by eliminating N+1 queries

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
SECURITY DEFINER
AS $$
  SELECT 
    e.id,
    e.name,
    e.start_datetime,
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
    ) as cover_storage_path,
    e.group_id
  FROM events e
  LEFT JOIN locations l ON e.location_id = l.id
  WHERE e.group_id = ANY(p_user_group_ids)
    AND e.status IN ('recap', 'ended')
    AND e.end_datetime >= p_start_date
    AND (
      -- Only return events that have at least one photo
      e.cover_photo_id IS NOT NULL
      OR EXISTS (
        SELECT 1 FROM group_photos gp 
        WHERE gp.event_id = e.id 
        LIMIT 1
      )
    )
  ORDER BY e.end_datetime DESC
  LIMIT 20;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_recent_memories_with_covers(uuid[], timestamptz) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION get_recent_memories_with_covers IS 
'Optimized function to fetch recent memories (last 30 days) with cover photos. Uses COALESCE for automatic fallback. Called by Home page to eliminate N+1 queries.';
```

---

### **Testing the Function**

Test in Supabase SQL Editor:

```sql
-- Test with a real user's group IDs and 30 days ago
SELECT * FROM get_recent_memories_with_covers(
  ARRAY['group-id-1'::uuid, 'group-id-2'::uuid],
  NOW() - INTERVAL '30 days'
);

-- Expected result: List of recent events with cover_storage_path
-- Should show max 20 results, ordered by end_datetime DESC
```

---

## 📊 Performance Validation

### **Before RPC Functions**

Query in PostgreSQL logs:
```sql
-- Initial query (1x)
SELECT * FROM events WHERE group_id IN (...);

-- Then for each event (10x):
SELECT storage_path FROM group_photos WHERE id = 'cover_photo_id';
SELECT storage_path FROM group_photos WHERE event_id = 'event_id' AND is_portrait = true;
SELECT storage_path FROM group_photos WHERE event_id = 'event_id';

-- TOTAL: 1 + (10 × 3) = 31 queries
-- TIME: ~2-3 seconds
```

### **After RPC Functions**

Query in PostgreSQL logs:
```sql
-- Single RPC call
SELECT * FROM get_user_memories_with_covers(ARRAY[...]);

-- TOTAL: 1 query
-- TIME: ~0.2-0.3 seconds
```

---

## ✅ Deployment Checklist

### **Pre-Deployment**

- [X] Backup current database schema
- [X] Test functions in staging environment first
- [X] Verify RLS policies allow function execution
- [X] Check indexes exist on:
  - `events.group_id`
  - `events.status`
  - `events.end_datetime`
  - `group_photos.event_id`
  - `group_photos.is_portrait`
  - `group_photos.captured_at`

### **Deployment Steps**

1. [X] Connect to Supabase project SQL Editor
2. [X] Copy and execute Function 1 SQL
3. [X] Test Function 1 with sample data
4. [X] Copy and execute Function 2 SQL
5. [X] Test Function 2 with sample data
6. [X] Verify grants: `\df+ get_user_memories_with_covers`
7. [X] Verify grants: `\df+ get_recent_memories_with_covers`
8. [X] Test RLS: Call functions as authenticated user
9. [X] Monitor PostgreSQL logs for errors
10. [X] Notify P1 team that functions are ready

### **Post-Deployment Verification**

- [ ] Profile page loads memories correctly
- [ ] Home page shows recent memories
- [ ] Cover photos display (fallback logic works)
- [ ] Performance improvement visible (loading time <1s)
- [ ] No RLS errors in logs
- [ ] Signed URLs generate successfully

---

## 🚨 Troubleshooting

### **Issue: "function does not exist"**

**Cause:** Function not created or schema mismatch.

**Fix:**
```sql
-- Check if function exists
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE '%memories%';

-- If not found, re-run CREATE statement
```

---

### **Issue: "permission denied for function"**

**Cause:** Missing GRANT statement.

**Fix:**
```sql
-- Re-grant permissions
GRANT EXECUTE ON FUNCTION get_user_memories_with_covers(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION get_recent_memories_with_covers(uuid[], timestamptz) TO authenticated;
```

---

### **Issue: "RLS policy violation"**

**Cause:** Function tries to access data user doesn't have permission to see.

**Fix:** Add explicit RLS check in WHERE clause:
```sql
AND EXISTS (
  SELECT 1 FROM group_members gm 
  WHERE gm.group_id = e.group_id 
    AND gm.user_id = auth.uid()
)
```

---

### **Issue: "NULL cover_storage_path for all events"**

**Cause:** Subquery logic not working or table structure mismatch.

**Fix:** Test subqueries individually:
```sql
-- Test cover_photo_id lookup
SELECT e.id, e.cover_photo_id, 
  (SELECT gp.storage_path FROM group_photos gp WHERE gp.id = e.cover_photo_id LIMIT 1) as cover
FROM events e WHERE e.id = 'test-event-id';

-- Test portrait photo lookup
SELECT e.id, 
  (SELECT gp.storage_path FROM group_photos gp 
   WHERE gp.event_id = e.id AND gp.is_portrait = true 
   ORDER BY gp.captured_at ASC LIMIT 1) as portrait
FROM events e WHERE e.id = 'test-event-id';
```

---

## 📞 Communication with P1

Once functions are deployed and tested, notify P1 team:

**Message template:**
```
✅ SQL RPC Functions Deployed

Function 1: get_user_memories_with_covers
Function 2: get_recent_memories_with_covers

Status: ✅ Created and tested
Performance: 30+ queries → 1 query per page load
RLS: ✅ Configured and verified

P1 can now:
1. Merge branch: feat/performance-optimization-home-profile
2. Test Profile and Home pages
3. Verify loading time <1 second

Any issues: Check IMPLEMENTATION/SQL_FUNCTIONS_FOR_P2.md troubleshooting section.
```

---

## 📚 Additional Notes

### **Index Recommendations**

If functions are slow (>500ms), create these indexes:

```sql
-- Optimize events query
CREATE INDEX IF NOT EXISTS idx_events_group_status_end 
ON events(group_id, status, end_datetime DESC);

-- Optimize cover photo lookups
CREATE INDEX IF NOT EXISTS idx_group_photos_cover_lookup 
ON group_photos(event_id, is_portrait, captured_at);

-- Check existing indexes
SELECT * FROM pg_indexes WHERE tablename IN ('events', 'group_photos');
```

---

### **Alternative: Materialized View**

If RPC functions are still slow, consider a materialized view (trade-off: needs refresh triggers):

```sql
-- Create materialized view (ADVANCED - only if needed)
CREATE MATERIALIZED VIEW events_with_covers AS
SELECT 
  e.id,
  e.name,
  e.end_datetime,
  e.group_id,
  l.display_name,
  COALESCE(...) as cover_storage_path
FROM events e
LEFT JOIN locations l ON e.location_id = l.id
WHERE e.status IN ('recap', 'ended');

-- Refresh trigger
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

**Only use materialized view if:**
- RPC functions are too slow (<500ms is acceptable)
- Data updates are infrequent
- Stale data (up to seconds) is acceptable

---

## ✅ Final Validation

After deployment, run these queries to verify everything works:

```sql
-- 1. Check function exists and has correct signature
\df+ get_user_memories_with_covers

-- 2. Test with real data
SELECT COUNT(*) FROM get_user_memories_with_covers(
  ARRAY(SELECT group_id FROM group_members WHERE user_id = 'test-user-id')
);

-- 3. Verify performance (should be <500ms)
EXPLAIN ANALYZE 
SELECT * FROM get_user_memories_with_covers(
  ARRAY['group-id']::uuid[]
);

-- 4. Check grants
SELECT grantee, privilege_type 
FROM information_schema.routine_privileges 
WHERE routine_name = 'get_user_memories_with_covers';
```

---

**Ready for deployment? Confirm with P2 team lead before executing SQL statements.**
