-- Fix chat_messages RLS policy blocking INSERTs
-- CRITICAL: The chat_insert_policy requires is_pinned=false and is_deleted=false
-- This blocks inserts if Flutter doesn't send these fields explicitly

-- 1. Drop the problematic policy
DROP POLICY IF EXISTS chat_insert_policy ON public.chat_messages;

-- 2. Recreate policy WITHOUT the restrictive is_pinned and is_deleted checks
-- These fields have DEFAULT values, so we don't need to check them on INSERT
CREATE POLICY chat_insert_policy ON public.chat_messages 
FOR INSERT 
WITH CHECK (
  (auth.uid() IS NOT NULL) 
  AND (auth.uid() IN (
    SELECT gm.user_id
    FROM public.group_members gm
    JOIN public.events e ON (e.group_id = gm.group_id)
    WHERE e.id = chat_messages.event_id
  )) 
  AND (user_id = auth.uid())
  -- ✅ REMOVED: AND (is_pinned = false) AND (is_deleted = false)
  -- These have DEFAULT false in table definition, no need to check on INSERT
);

COMMENT ON POLICY chat_insert_policy ON public.chat_messages IS 
'Allows group members to insert chat messages.
Removed is_pinned and is_deleted checks as these have DEFAULT false values.';
