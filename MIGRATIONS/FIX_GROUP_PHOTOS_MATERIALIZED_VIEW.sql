-- ============================================================================
-- Fix: Add unique indexes to materialized views for CONCURRENT refresh
-- ============================================================================
-- Date: 2025-12-09
-- Purpose: Allow REFRESH MATERIALIZED VIEW CONCURRENTLY to work
-- Error: "cannot refresh materialized view concurrently" - needs unique index
--
-- Background: When CASCADE DELETE on events was added, triggers that refresh
-- materialized views started failing because views lack unique indexes.
-- ============================================================================

-- ============================================================================
-- PART 1: Fix group_photos_with_uploader
-- ============================================================================

-- Step 1.1: Drop the existing materialized view
DROP MATERIALIZED VIEW IF EXISTS public.group_photos_with_uploader CASCADE;

-- Step 1.2: Recreate the materialized view
-- This view joins group_photos with users to include uploader details
CREATE MATERIALIZED VIEW public.group_photos_with_uploader AS
SELECT 
  gp.id,
  gp.event_id,
  gp.url,
  gp.storage_path,
  gp.captured_at,
  gp.uploader_id,
  gp.is_portrait,
  gp.created_at,
  gp.updated_at,
  u.name AS uploader_name,
  u.avatar_url AS uploader_avatar
FROM public.group_photos gp
LEFT JOIN public.users u ON gp.uploader_id = u.id;

-- Step 1.3: Create UNIQUE INDEX on the primary key column
-- This is REQUIRED for REFRESH MATERIALIZED VIEW CONCURRENTLY
CREATE UNIQUE INDEX group_photos_with_uploader_id_idx 
ON public.group_photos_with_uploader (id);

-- Step 1.4: Add additional indexes for query performance
CREATE INDEX group_photos_with_uploader_event_id_idx 
ON public.group_photos_with_uploader (event_id);

CREATE INDEX group_photos_with_uploader_uploader_id_idx 
ON public.group_photos_with_uploader (uploader_id);

-- Step 1.5: Initial refresh
REFRESH MATERIALIZED VIEW public.group_photos_with_uploader;


-- ============================================================================
-- PART 2: Fix group_hub_events_cache (if it exists)
-- ============================================================================

-- Step 2.1: Check if group_hub_events_cache exists and fix it
DO $$
DECLARE
  has_status_column BOOLEAN;
BEGIN
  -- Check if the materialized view exists
  IF EXISTS (
    SELECT 1 
    FROM pg_matviews 
    WHERE schemaname = 'public' 
    AND matviewname = 'group_hub_events_cache'
  ) THEN
    -- Drop existing unique index if any
    DROP INDEX IF EXISTS public.group_hub_events_cache_event_id_idx CASCADE;
    
    -- Create UNIQUE INDEX on event_id (assuming it's the primary key)
    CREATE UNIQUE INDEX group_hub_events_cache_event_id_idx 
    ON public.group_hub_events_cache (event_id);
    
    -- Add index on group_id (always safe)
    CREATE INDEX IF NOT EXISTS group_hub_events_cache_group_id_idx 
    ON public.group_hub_events_cache (group_id);
    
    -- Check if status column exists before creating index on it
    SELECT EXISTS (
      SELECT 1 
      FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'group_hub_events_cache' 
      AND column_name = 'status'
    ) INTO has_status_column;
    
    IF has_status_column THEN
      CREATE INDEX IF NOT EXISTS group_hub_events_cache_status_idx 
      ON public.group_hub_events_cache (status);
      RAISE NOTICE '✓ Created index on status column';
    ELSE
      RAISE NOTICE '⚠ status column does not exist, skipping index';
    END IF;
    
    -- Refresh the view
    REFRESH MATERIALIZED VIEW public.group_hub_events_cache;
    
    RAISE NOTICE '✓ Fixed group_hub_events_cache materialized view';
  ELSE
    RAISE NOTICE '⚠ group_hub_events_cache does not exist, skipping';
  END IF;
END $$;

-- ============================================================================
-- PART 3: Update triggers to use CONCURRENTLY (if they exist)
-- ============================================================================

-- Step 3.1: Update auto_refresh_group_photos trigger function (if exists)
-- This ensures the trigger uses REFRESH MATERIALIZED VIEW CONCURRENTLY
CREATE OR REPLACE FUNCTION public.auto_refresh_group_photos_view()
RETURNS TRIGGER AS $$
BEGIN
  -- Use CONCURRENTLY to allow concurrent reads during refresh
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.group_photos_with_uploader;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Step 3.2: Create or replace trigger on group_photos table
DROP TRIGGER IF EXISTS refresh_group_photos_view ON public.group_photos;
CREATE TRIGGER refresh_group_photos_view
AFTER INSERT OR UPDATE OR DELETE ON public.group_photos
FOR EACH STATEMENT
EXECUTE FUNCTION public.auto_refresh_group_photos_view();

-- Step 3.3: Create or replace trigger on users table (for uploader info)
DROP TRIGGER IF EXISTS refresh_group_photos_view_on_user ON public.users;
CREATE TRIGGER refresh_group_photos_view_on_user
AFTER UPDATE OF name, avatar_url ON public.users
FOR EACH STATEMENT
EXECUTE FUNCTION public.auto_refresh_group_photos_view();


-- ============================================================================
-- PART 4: Verification
-- ============================================================================

-- Step 4.1: Check that unique indexes exist on all materialized views
SELECT 
  i.schemaname,
  i.tablename AS matviewname,
  i.indexname,
  i.indexdef
FROM pg_indexes i
WHERE i.schemaname = 'public'
  AND i.tablename IN ('group_photos_with_uploader', 'group_hub_events_cache')
  AND i.indexname LIKE '%_id_idx'
ORDER BY i.tablename, i.indexname;

-- Step 4.2: List all materialized views and their indexes
SELECT 
  mv.schemaname,
  mv.matviewname,
  COUNT(idx.indexname) as index_count,
  STRING_AGG(
    CASE WHEN idx.indexdef LIKE '%UNIQUE%' 
    THEN '✓ ' || idx.indexname 
    ELSE '  ' || idx.indexname 
    END, 
    E'\n'
  ) as indexes
FROM pg_matviews mv
LEFT JOIN pg_indexes idx 
  ON idx.schemaname = mv.schemaname 
  AND idx.tablename = mv.matviewname
WHERE mv.schemaname = 'public'
GROUP BY mv.schemaname, mv.matviewname
ORDER BY mv.matviewname;

-- Step 4.3: Test concurrent refresh (should work now without errors)
REFRESH MATERIALIZED VIEW CONCURRENTLY public.group_photos_with_uploader;

-- If group_hub_events_cache exists, test it too
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_matviews 
    WHERE schemaname = 'public' AND matviewname = 'group_hub_events_cache'
  ) THEN
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.group_hub_events_cache;
    RAISE NOTICE '✓ group_hub_events_cache refreshed successfully';
  END IF;
END $$;


-- ============================================================================
-- Notes & Best Practices
-- ============================================================================
-- 
-- UNIQUE INDEX Requirements for REFRESH CONCURRENTLY:
-- 1. Must have NO WHERE clause (no partial index)
-- 2. Must contain unique values (typically primary key from base table)
-- 3. Column(s) must be NOT NULL
-- 4. Works best with single-column indexes (id, event_id, etc.)
--
-- Why CONCURRENTLY is better:
-- - Allows SELECT queries while refresh is happening
-- - No table lock during refresh
-- - Essential for production databases with active users
--
-- Trade-offs:
-- - CONCURRENTLY is slower than regular refresh (builds new data, then swaps)
-- - Requires more disk space temporarily (old + new data)
-- - Worth it for production environments
--
-- When to refresh:
-- - After INSERT/UPDATE/DELETE on base tables (via triggers)
-- - Periodic refresh (e.g., every 5-15 minutes via cron)
-- - On-demand when critical data changes
--
-- ============================================================================
