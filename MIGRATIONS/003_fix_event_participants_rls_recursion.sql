-- ============================================================================
-- MIGRATION 003: Fix infinite recursion in event_participants RLS policies
-- ============================================================================
-- Date: 2026-02-12
-- Description:
--   Fixes "infinite recursion detected in policy for relation event_participants"
--   error that occurs during OTP verification (and any other auth-related flow).
--
-- ROOT CAUSE:
--   event_participants has DUPLICATE policies with circular references:
--
--   1. `ep_select` calls `is_member_of_event()` which SELECTs from
--      `event_participants` → triggers `ep_select` again → infinite loop
--
--   2. `"Users can view event_participants"` has a self-referencing EXISTS
--      subquery on `event_participants` → also triggers itself → infinite loop
--
--   3. `ep_insert` calls `is_member_of_event()` → same recursion, PLUS it
--      blocks first-time joining (user isn't a member yet when they join)
--
--   4. `ep_update` calls `is_member_of_event()` → same recursion
--
-- FIX:
--   1. Recreate `is_member_of_event()` as SECURITY DEFINER so the inner
--      query bypasses RLS (standard PostgreSQL pattern for this)
--   2. Drop duplicate/recursive policies, keep clean simple ones
--   3. Result: 4 clean policies, no recursion
--
-- IMPACT:
--   This also fixes all other policies that query event_participants:
--   - "Event participants can view events" (on events)
--   - "Event participants can update event cover" (on events)
--   - "Event participants can upload photos" (on event_photos)
--   - "Event participants can view photos" (on event_photos)
--   - "Event participants can view guest RSVPs" (on event_guest_rsvps)
--   - "Event participants can view invite links" (on event_invite_links)
--   - "Event members can create invite links" (on event_invite_links)
--   - "Users can read locations of their events" (on locations)
--   - "Users can view locations for their events" (on locations)
--   - "users_can_view_avatars_of_event_participants" (on users)
-- ============================================================================

BEGIN;

-- ============================================================================
-- STEP 1: Recreate is_member_of_event() as SECURITY DEFINER
-- This is the key fix. The function now bypasses RLS when querying
-- event_participants internally, breaking the recursion chain.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.is_member_of_event(eid uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.event_participants
    WHERE pevent_id = eid AND user_id = auth.uid()
  );
$$;


-- ============================================================================
-- STEP 2: Drop recursive/duplicate policies on event_participants
-- ============================================================================

-- 2.1 Drop self-referencing SELECT policy (causes recursion independently)
DROP POLICY IF EXISTS "Users can view event_participants" ON event_participants;

-- 2.2 Drop ep_insert (uses is_member_of_event which blocks first-time joining;
-- "Users can insert own RSVP" is simpler and sufficient)
DROP POLICY IF EXISTS ep_insert ON event_participants;

-- 2.3 Drop ep_update (redundant with "Users can update own RSVP")
DROP POLICY IF EXISTS ep_update ON event_participants;


-- ============================================================================
-- STEP 3: Verify remaining policies
-- After cleanup, event_participants should have exactly 4 policies:
--
--   SELECT:  ep_select          → is_member_of_event(pevent_id)  [SECURITY DEFINER]
--   INSERT:  Users can insert own RSVP  → user_id = auth.uid()
--   UPDATE:  Users can update own RSVP  → user_id = auth.uid()
--   DELETE:  ep_delete           → user_id = auth.uid()
-- ============================================================================

-- Verify: list all policies on event_participants
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'event_participants'
ORDER BY cmd, policyname;
-- Expected: 4 rows (ep_select, Users can insert own RSVP, Users can update own RSVP, ep_delete)

-- Verify: is_member_of_event is now SECURITY DEFINER
SELECT proname, prosecdef
FROM pg_proc
WHERE proname = 'is_member_of_event';
-- Expected: prosecdef = true

COMMIT;


-- ============================================================================
-- NOTES
-- ============================================================================
--
-- BEFORE (7 policies, 3 recursive):
--   ep_select          SELECT  is_member_of_event()     ← RECURSIVE (fixed by SECURITY DEFINER)
--   "Users can view…"  SELECT  EXISTS(self-reference)   ← RECURSIVE (dropped)
--   ep_insert          INSERT  is_member_of_event()     ← RECURSIVE + blocks joining (dropped)
--   "Users can insert…" INSERT user_id = auth.uid()     ← OK (kept)
--   ep_update          UPDATE  is_member_of_event()     ← RECURSIVE (dropped)
--   "Users can update…" UPDATE user_id = auth.uid()     ← OK (kept)
--   ep_delete          DELETE  user_id = auth.uid()     ← OK (kept)
--
-- AFTER (4 policies, 0 recursive):
--   ep_select          SELECT  is_member_of_event()     (SECURITY DEFINER, no recursion)
--   "Users can insert…" INSERT user_id = auth.uid()     (simple, allows joining)
--   "Users can update…" UPDATE user_id = auth.uid()     (simple, own RSVP only)
--   ep_delete          DELETE  user_id = auth.uid()     (simple, own row only)
--
