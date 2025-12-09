-- ============================================================================
-- Migration: Add ON DELETE CASCADE to all foreign keys referencing events(id)
-- ============================================================================
-- Date: 2025-12-09
-- Purpose: Allow event deletion without manual cleanup of related records
-- Impact: When an event is deleted, all related records are automatically deleted
--
-- CRITICAL: Run this migration in Supabase SQL Editor
-- Test in staging environment first!
-- ============================================================================

-- Step 1: Drop existing foreign key constraints
-- ============================================================================

-- 1.1 chat_messages.event_id
ALTER TABLE public.chat_messages
DROP CONSTRAINT IF EXISTS chat_messages_event_id_fkey;

-- 1.2 event_date_options.event_id
ALTER TABLE public.event_date_options
DROP CONSTRAINT IF EXISTS event_date_options_event_id_fkey;

-- 1.3 event_expenses.event_id
ALTER TABLE public.event_expenses
DROP CONSTRAINT IF EXISTS event_expenses_event_id_fkey;

-- 1.4 event_participants.pevent_id (references events.id)
ALTER TABLE public.event_participants
DROP CONSTRAINT IF EXISTS event_participants_pevent_id_fkey;

-- 1.5 group_photos.event_id
ALTER TABLE public.group_photos
DROP CONSTRAINT IF EXISTS group_photos_event_id_fkey;

-- 1.6 groups.event_id
ALTER TABLE public.groups
DROP CONSTRAINT IF EXISTS groups_event_id_fkey;

-- 1.7 location_suggestions.event_id
ALTER TABLE public.location_suggestions
DROP CONSTRAINT IF EXISTS location_suggestions_event_id_fkey;

-- 1.8 message_reads.event_id
ALTER TABLE public.message_reads
DROP CONSTRAINT IF EXISTS message_reads_event_id_fkey;

-- 1.9 photos.event_id
ALTER TABLE public.photos
DROP CONSTRAINT IF EXISTS photos_event_id_fkey;


-- Step 2: Re-add foreign key constraints WITH ON DELETE CASCADE
-- ============================================================================

-- 2.1 chat_messages.event_id
ALTER TABLE public.chat_messages
ADD CONSTRAINT chat_messages_event_id_fkey 
FOREIGN KEY (event_id) 
REFERENCES public.events(id) 
ON DELETE CASCADE;

-- 2.2 event_date_options.event_id (THE ONE CAUSING YOUR ERROR)
ALTER TABLE public.event_date_options
ADD CONSTRAINT event_date_options_event_id_fkey 
FOREIGN KEY (event_id) 
REFERENCES public.events(id) 
ON DELETE CASCADE;

-- 2.3 event_expenses.event_id
ALTER TABLE public.event_expenses
ADD CONSTRAINT event_expenses_event_id_fkey 
FOREIGN KEY (event_id) 
REFERENCES public.events(id) 
ON DELETE CASCADE;

-- 2.4 event_participants.pevent_id (references events.id)
ALTER TABLE public.event_participants
ADD CONSTRAINT event_participants_pevent_id_fkey 
FOREIGN KEY (pevent_id) 
REFERENCES public.events(id) 
ON DELETE CASCADE;

-- 2.5 group_photos.event_id
ALTER TABLE public.group_photos
ADD CONSTRAINT group_photos_event_id_fkey 
FOREIGN KEY (event_id) 
REFERENCES public.events(id) 
ON DELETE CASCADE;

-- 2.6 groups.event_id
-- NOTE: This should probably be SET NULL instead of CASCADE
-- Groups can exist without events, so we set event_id to NULL when event is deleted
ALTER TABLE public.groups
ADD CONSTRAINT groups_event_id_fkey 
FOREIGN KEY (event_id) 
REFERENCES public.events(id) 
ON DELETE SET NULL;

-- 2.7 location_suggestions.event_id
ALTER TABLE public.location_suggestions
ADD CONSTRAINT location_suggestions_event_id_fkey 
FOREIGN KEY (event_id) 
REFERENCES public.events(id) 
ON DELETE CASCADE;

-- 2.8 message_reads.event_id
ALTER TABLE public.message_reads
ADD CONSTRAINT message_reads_event_id_fkey 
FOREIGN KEY (event_id) 
REFERENCES public.events(id) 
ON DELETE CASCADE;

-- 2.9 photos.event_id
ALTER TABLE public.photos
ADD CONSTRAINT photos_event_id_fkey 
FOREIGN KEY (event_id) 
REFERENCES public.events(id) 
ON DELETE CASCADE;


-- Step 3: Verification
-- ============================================================================
-- Run this query to verify all CASCADE constraints are in place:

SELECT 
    tc.table_name, 
    kcu.column_name,
    rc.delete_rule,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints AS rc
  ON rc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND ccu.table_name = 'events'
  AND ccu.column_name = 'id'
ORDER BY tc.table_name;

-- Expected output should show delete_rule = 'CASCADE' for all except groups (SET NULL)


-- ============================================================================
-- Rollback Plan (if needed)
-- ============================================================================
-- If issues arise, re-run Step 1 to drop constraints,
-- then re-add WITHOUT ON DELETE CASCADE (original behavior)
-- ============================================================================
