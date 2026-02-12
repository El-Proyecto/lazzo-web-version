-- ============================================================================
-- LAZZO 2.0 MIGRATION — Remove Groups & Chat, Add Event Invite Links
-- ============================================================================
-- 
-- CONTEXT:
--   Lazzo 2.0 shifts from a group-centric model to an event-centric model.
--   Events are now standalone (not tied to groups). Invites are shared via
--   WhatsApp/Insta/SMS as links. Non-app users see a web landing page.
--   App users are auto-joined to the event.
--
-- MAJOR CHANGES:
--   1. Remove chat system (chat_messages, message_reads)
--   2. Remove group system (groups, group_members, group_invites, etc.)
--   3. Events become standalone (group_id removed)
--   4. New event_invite_links table for token-based invites
--   5. New event_guest_rsvps table for web RSVP (non-app users)
--   6. Photos renamed from group_photos → event_photos
--   7. Notifications cleaned of group references
--
-- ⚠️  THIS IS A DESTRUCTIVE MIGRATION. BACKUP YOUR DATABASE FIRST.
-- ⚠️  Run in a transaction. If anything fails, ROLLBACK.
-- ⚠️  Order matters: drop dependents first, then parents.
--
-- EXECUTION ORDER:
--   Phase 0: Safety & Backup check
--   Phase 1: Drop dependent objects (views, materialized views, triggers, functions)
--   Phase 2: Drop chat tables
--   Phase 3: Drop group tables
--   Phase 4: Alter events table (remove group_id)
--   Phase 5: Rename/restructure photos
--   Phase 6: Create new tables (event_invite_links, event_guest_rsvps)
--   Phase 7: Create new RPCs/functions
--   Phase 8: Create new views (replace group-dependent ones)
--   Phase 9: Update notifications
--   Phase 10: Update RLS policies
--   Phase 11: Cleanup unused types
--   Phase 13: Storage — Drop broken policies on storage.objects
--   Phase 14: Storage — Create new participant-based storage policies
--   Phase 15: Update event_photos RLS policies (renamed from group_photos)
--   Phase 16: Additional public schema policy cleanup (events, locations, users)
-- ============================================================================

BEGIN;

-- ============================================================================
-- PHASE 0: SAFETY CHECKS
-- ============================================================================

-- Verify we're running in a transaction
DO $$
BEGIN
  RAISE NOTICE 'LAZZO 2.0 MIGRATION: Starting. Make sure you have a backup!';
  RAISE NOTICE 'Timestamp: %', now();
END $$;


-- ============================================================================
-- PHASE 1: DROP DEPENDENT OBJECTS
-- ============================================================================
-- Drop views and materialized views that reference groups/chat first

-- Materialized views
DROP MATERIALIZED VIEW IF EXISTS public.group_hub_events_cache CASCADE;
DROP MATERIALIZED VIEW IF EXISTS public.group_photos_with_uploader CASCADE;

-- Views
DROP VIEW IF EXISTS public.group_hub_events_view CASCADE;
DROP VIEW IF EXISTS public.home_events_view CASCADE;
DROP VIEW IF EXISTS public.event_participants_summary_view CASCADE;

-- Drop triggers that reference groups/chat
DROP TRIGGER IF EXISTS on_chat_message_created ON public.chat_messages;
DROP TRIGGER IF EXISTS on_chat_mention ON public.chat_messages;
DROP TRIGGER IF EXISTS on_group_created ON public.groups;
DROP TRIGGER IF EXISTS on_group_invite ON public.group_invites;
DROP TRIGGER IF EXISTS on_group_invite_received ON public.group_invites;
DROP TRIGGER IF EXISTS on_group_member_added ON public.group_members;
DROP TRIGGER IF EXISTS on_group_member_added_notify ON public.group_members;
DROP TRIGGER IF EXISTS on_group_invite_accepted ON public.group_members;
DROP TRIGGER IF EXISTS on_event_created ON public.events;
DROP TRIGGER IF EXISTS add_group_members_trigger ON public.events;
DROP TRIGGER IF EXISTS add_new_member_trigger ON public.group_members;
DROP TRIGGER IF EXISTS auto_refresh_group_cache_trigger ON public.events;
DROP TRIGGER IF EXISTS auto_refresh_group_photos_trigger ON public.group_photos;

-- Drop functions related to chat
DROP FUNCTION IF EXISTS public.notify_chat_message() CASCADE;
DROP FUNCTION IF EXISTS public.notify_chat_mention() CASCADE;
DROP FUNCTION IF EXISTS public.get_messages_with_read_status(uuid, uuid, integer) CASCADE;
DROP FUNCTION IF EXISTS public.get_unread_message_count(uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS public.leave_chat_presence(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.get_event_participants_count(uuid, uuid) CASCADE;

-- Drop functions related to groups
DROP FUNCTION IF EXISTS public.accept_group_invite(uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS public.accept_group_invite_by_token(text) CASCADE;
DROP FUNCTION IF EXISTS public.create_group_invite_link(uuid, integer) CASCADE;
DROP FUNCTION IF EXISTS public.get_or_create_group_invite_link(uuid, integer) CASCADE;
DROP FUNCTION IF EXISTS public.get_group_member_count(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_group() CASCADE;
DROP FUNCTION IF EXISTS public.is_admin(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.is_group_creator(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.is_member(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.leave_group(uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS public.add_event_participants(uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS public.add_group_members_to_event() CASCADE;
DROP FUNCTION IF EXISTS public.add_new_member_to_group_events() CASCADE;
DROP FUNCTION IF EXISTS public.auto_refresh_group_cache() CASCADE;
DROP FUNCTION IF EXISTS public.auto_refresh_group_photos_view() CASCADE;
DROP FUNCTION IF EXISTS public.notify_group_invite() CASCADE;
DROP FUNCTION IF EXISTS public.notify_group_invite_accepted() CASCADE;
DROP FUNCTION IF EXISTS public.notify_group_invite_received() CASCADE;
DROP FUNCTION IF EXISTS public.notify_group_member_added() CASCADE;

-- Drop functions that reference group_id heavily (will be recreated without group refs)
DROP FUNCTION IF EXISTS public.notify_event_created() CASCADE;
DROP FUNCTION IF EXISTS public.get_recent_memories_with_covers(uuid[], timestamptz) CASCADE;
DROP FUNCTION IF EXISTS public.get_user_memories_with_covers(uuid[]) CASCADE;


-- ============================================================================
-- PHASE 2: DROP CHAT TABLES
-- ============================================================================

DROP TABLE IF EXISTS public.message_reads CASCADE;
DROP TABLE IF EXISTS public.chat_messages CASCADE;


-- ============================================================================
-- PHASE 3: DROP GROUP TABLES
-- ============================================================================

-- Drop in dependency order (children first)
DROP TABLE IF EXISTS public.group_user_settings CASCADE;
DROP TABLE IF EXISTS public.group_invite_links CASCADE;
DROP TABLE IF EXISTS public.group_invites CASCADE;
DROP TABLE IF EXISTS public.group_messages CASCADE;
DROP TABLE IF EXISTS public.group_members CASCADE;

-- Now we can drop notifications FK to groups (alter first)
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_group_id_fkey;
ALTER TABLE public.notifications DROP COLUMN IF EXISTS group_id;
ALTER TABLE public.notifications DROP COLUMN IF EXISTS group_name;

-- Drop events FK to groups
ALTER TABLE public.events DROP CONSTRAINT IF EXISTS events_group_id_fkey;

-- Drop groups table (after removing all FKs)
DROP TABLE IF EXISTS public.groups CASCADE;


-- ============================================================================
-- PHASE 4: ALTER EVENTS TABLE
-- ============================================================================

-- Remove group_id from events (events are now standalone)
ALTER TABLE public.events DROP COLUMN IF EXISTS group_id;

-- Add description field for events (useful for web landing page)
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS description text;

-- Add max_participants (optional, for capacity control)
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS max_participants integer;

-- Ensure cover_photo_id FK is correct (now references event_photos after rename)
-- We'll handle this after the rename in Phase 5


-- ============================================================================
-- PHASE 5: RENAME PHOTOS (group_photos → event_photos)
-- ============================================================================

-- Rename the table
ALTER TABLE IF EXISTS public.group_photos RENAME TO event_photos;

-- Rename constraints to match new table name
ALTER TABLE public.event_photos RENAME CONSTRAINT group_photos_pkey TO event_photos_pkey;
ALTER TABLE public.event_photos RENAME CONSTRAINT group_photos_event_id_fkey TO event_photos_event_id_fkey;
ALTER TABLE public.event_photos RENAME CONSTRAINT group_photos_uploader_id_fkey TO event_photos_uploader_id_fkey;

-- Update cover_photo FK on events
ALTER TABLE public.events DROP CONSTRAINT IF EXISTS events_cover_photo_id_fkey;
ALTER TABLE public.events ADD CONSTRAINT events_cover_photo_id_fkey 
  FOREIGN KEY (cover_photo_id) REFERENCES public.event_photos(id);


-- ============================================================================
-- PHASE 6: CREATE NEW TABLES
-- ============================================================================

-- 6.1: Event Invite Links (token-based invites shared via WhatsApp/Insta/SMS)
CREATE TABLE IF NOT EXISTS public.event_invite_links (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  created_by uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  token text NOT NULL,
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  
  -- Metadata
  share_channel text, -- 'whatsapp', 'instagram', 'sms', 'copy', etc.
  open_count integer NOT NULL DEFAULT 0
);

-- Index for fast token lookup (only valid/non-revoked)
CREATE UNIQUE INDEX IF NOT EXISTS idx_event_invite_links_token
  ON public.event_invite_links(token)
  WHERE revoked_at IS NULL;

-- Index for finding valid links per event
CREATE INDEX IF NOT EXISTS idx_event_invite_links_event_valid
  ON public.event_invite_links(event_id, expires_at)
  WHERE revoked_at IS NULL;

-- 6.2: Event Guest RSVPs (for non-app users via web landing page)
CREATE TABLE IF NOT EXISTS public.event_guest_rsvps (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  invite_token text NOT NULL,
  guest_name text NOT NULL,
  guest_phone text,               -- optional contact for follow-up
  rsvp text NOT NULL DEFAULT 'going',  -- 'going' | 'not_going' | 'maybe'
  plus_one integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT valid_rsvp CHECK (rsvp IN ('going', 'not_going', 'maybe'))
);

CREATE INDEX IF NOT EXISTS idx_event_guest_rsvps_event
  ON public.event_guest_rsvps(event_id);

CREATE INDEX IF NOT EXISTS idx_event_guest_rsvps_token
  ON public.event_guest_rsvps(invite_token);

-- Trigger for updated_at
CREATE TRIGGER event_guest_rsvps_updated_at
  BEFORE UPDATE ON public.event_guest_rsvps
  FOR EACH ROW EXECUTE FUNCTION public._touch_updated_at();

-- 6.3: Invite Analytics (track funnel: link created → opened → RSVP)
CREATE TABLE IF NOT EXISTS public.invite_analytics (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  invite_token text,
  action text NOT NULL, -- 'link_created', 'link_opened_web', 'link_opened_app', 'rsvp_web', 'rsvp_app', 'auto_join_app'
  user_id uuid REFERENCES public.users(id),  -- NULL for anonymous/web visitors
  metadata jsonb DEFAULT '{}'::jsonb,         -- user agent, referrer, etc.
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_invite_analytics_event
  ON public.invite_analytics(event_id, action);

CREATE INDEX IF NOT EXISTS idx_invite_analytics_token
  ON public.invite_analytics(invite_token)
  WHERE invite_token IS NOT NULL;


-- ============================================================================
-- PHASE 7: CREATE NEW RPCs / FUNCTIONS
-- ============================================================================

-- 7.1: Get or create event invite link
CREATE OR REPLACE FUNCTION public.get_or_create_event_invite_link(
  p_event_id uuid,
  p_expires_in_hours integer DEFAULT 48,
  p_share_channel text DEFAULT NULL
)
RETURNS TABLE(token text, expires_at timestamptz, created_at timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
  v_existing_token text;
  v_existing_expires timestamptz;
  v_existing_created timestamptz;
  v_new_token text;
  v_new_expires timestamptz;
  v_event_exists boolean;
  v_is_participant boolean;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Verify event exists
  SELECT EXISTS(SELECT 1 FROM public.events WHERE id = p_event_id) INTO v_event_exists;
  IF NOT v_event_exists THEN
    RAISE EXCEPTION 'Event not found';
  END IF;

  -- Verify user is organizer or participant
  SELECT EXISTS(
    SELECT 1 FROM public.event_participants 
    WHERE pevent_id = p_event_id AND user_id = v_user_id
  ) INTO v_is_participant;
  
  IF NOT v_is_participant AND NOT EXISTS(
    SELECT 1 FROM public.events WHERE id = p_event_id AND created_by = v_user_id
  ) THEN
    RAISE EXCEPTION 'Not authorized to create invite for this event';
  END IF;

  -- Try to reuse existing valid token
  SELECT eil.token, eil.expires_at, eil.created_at
  INTO v_existing_token, v_existing_expires, v_existing_created
  FROM public.event_invite_links eil
  WHERE eil.event_id = p_event_id
    AND eil.revoked_at IS NULL
    AND eil.expires_at > now()
  ORDER BY eil.created_at DESC
  LIMIT 1;

  IF v_existing_token IS NOT NULL THEN
    RETURN QUERY SELECT v_existing_token, v_existing_expires, v_existing_created;
    RETURN;
  END IF;

  -- Generate new token
  v_new_token := public.generate_url_safe_token();
  v_new_expires := now() + (p_expires_in_hours || ' hours')::interval;

  INSERT INTO public.event_invite_links (event_id, created_by, token, expires_at, share_channel)
  VALUES (p_event_id, v_user_id, v_new_token, v_new_expires, p_share_channel);

  RETURN QUERY SELECT v_new_token, v_new_expires, now();
END;
$$;

COMMENT ON FUNCTION public.get_or_create_event_invite_link IS 
  'Creates or reuses an event invite link. Returns existing valid token if available, otherwise generates a new one. Only event participants/organizers can create links.';


-- 7.2: Accept event invite by token (for app users — auto-join)
CREATE OR REPLACE FUNCTION public.accept_event_invite_by_token(p_token text)
RETURNS TABLE(event_id uuid, event_name text, event_emoji text)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
  v_event_id uuid;
  v_event_name text;
  v_event_emoji text;
  v_link_valid boolean;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Validate token
  SELECT eil.event_id INTO v_event_id
  FROM public.event_invite_links eil
  WHERE eil.token = p_token
    AND eil.revoked_at IS NULL
    AND eil.expires_at > now();

  IF v_event_id IS NULL THEN
    RAISE EXCEPTION 'Invalid or expired invite link';
  END IF;

  -- Get event info
  SELECT e.name, e.emoji INTO v_event_name, v_event_emoji
  FROM public.events e WHERE e.id = v_event_id;

  -- Add as participant (idempotent)
  INSERT INTO public.event_participants (pevent_id, user_id, rsvp)
  VALUES (v_event_id, v_user_id, 'pending'::rsvp_status)
  ON CONFLICT (pevent_id, user_id) DO NOTHING;

  -- Increment open count
  UPDATE public.event_invite_links
  SET open_count = open_count + 1
  WHERE token = p_token AND revoked_at IS NULL;

  -- Track analytics
  INSERT INTO public.invite_analytics (event_id, invite_token, action, user_id)
  VALUES (v_event_id, p_token, 'auto_join_app', v_user_id);

  RETURN QUERY SELECT v_event_id, v_event_name, v_event_emoji;
END;
$$;

COMMENT ON FUNCTION public.accept_event_invite_by_token IS 
  'Accepts an event invite by token. Adds the authenticated user as a participant. Idempotent — calling twice won''t duplicate.';


-- 7.3: Guest RSVP via web (for non-app users)
CREATE OR REPLACE FUNCTION public.upsert_event_guest_rsvp_by_token(
  p_token text,
  p_guest_name text,
  p_rsvp text DEFAULT 'going',
  p_plus_one integer DEFAULT 0,
  p_guest_phone text DEFAULT NULL
)
RETURNS TABLE(event_id uuid, event_name text, rsvp_id uuid)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_event_id uuid;
  v_event_name text;
  v_rsvp_id uuid;
BEGIN
  -- Validate token
  SELECT eil.event_id INTO v_event_id
  FROM public.event_invite_links eil
  WHERE eil.token = p_token
    AND eil.revoked_at IS NULL
    AND eil.expires_at > now();

  IF v_event_id IS NULL THEN
    RAISE EXCEPTION 'Invalid or expired invite link';
  END IF;

  -- Get event name
  SELECT e.name INTO v_event_name FROM public.events e WHERE e.id = v_event_id;

  -- Upsert guest RSVP (one RSVP per name+token combo)
  INSERT INTO public.event_guest_rsvps (event_id, invite_token, guest_name, rsvp, plus_one, guest_phone)
  VALUES (v_event_id, p_token, p_guest_name, p_rsvp, p_plus_one, p_guest_phone)
  ON CONFLICT ON CONSTRAINT event_guest_rsvps_pkey DO UPDATE
    SET rsvp = EXCLUDED.rsvp,
        plus_one = EXCLUDED.plus_one,
        guest_phone = EXCLUDED.guest_phone,
        updated_at = now()
  RETURNING id INTO v_rsvp_id;

  -- Track analytics
  INSERT INTO public.invite_analytics (event_id, invite_token, action, metadata)
  VALUES (v_event_id, p_token, 'rsvp_web', jsonb_build_object('guest_name', p_guest_name, 'rsvp', p_rsvp));

  RETURN QUERY SELECT v_event_id, v_event_name, v_rsvp_id;
END;
$$;

COMMENT ON FUNCTION public.upsert_event_guest_rsvp_by_token IS 
  'Allows non-app guests to RSVP to an event via the web landing page using the invite token.';


-- 7.4: Get event by token (for web landing page — server-side)
CREATE OR REPLACE FUNCTION public.get_event_by_invite_token(p_token text)
RETURNS TABLE(
  event_id uuid,
  event_name text,
  event_emoji text,
  event_description text,
  start_datetime timestamptz,
  end_datetime timestamptz,
  location_name text,
  location_address text,
  location_lat numeric,
  location_lng numeric,
  organizer_name text,
  organizer_avatar text,
  status text,
  participant_count bigint,
  going_count bigint,
  guest_going_count bigint,
  cover_photo_url text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_event_id uuid;
BEGIN
  -- Validate token
  SELECT eil.event_id INTO v_event_id
  FROM public.event_invite_links eil
  WHERE eil.token = p_token
    AND eil.revoked_at IS NULL
    AND eil.expires_at > now();

  IF v_event_id IS NULL THEN
    RAISE EXCEPTION 'Invalid or expired invite link';
  END IF;

  -- Track web open
  INSERT INTO public.invite_analytics (event_id, invite_token, action)
  VALUES (v_event_id, p_token, 'link_opened_web');

  -- Return event data for the web page
  RETURN QUERY
  SELECT
    e.id AS event_id,
    e.name AS event_name,
    e.emoji AS event_emoji,
    e.description AS event_description,
    e.start_datetime,
    e.end_datetime,
    l.display_name AS location_name,
    l.formatted_address AS location_address,
    l.latitude AS location_lat,
    l.longitude AS location_lng,
    u.name AS organizer_name,
    u.avatar_url AS organizer_avatar,
    e.status::text,
    (SELECT count(*) FROM public.event_participants ep WHERE ep.pevent_id = e.id)::bigint AS participant_count,
    (SELECT count(*) FROM public.event_participants ep WHERE ep.pevent_id = e.id AND ep.rsvp = 'yes'::rsvp_status)::bigint AS going_count,
    (SELECT count(*) FROM public.event_guest_rsvps gr WHERE gr.event_id = e.id AND gr.rsvp = 'going')::bigint AS guest_going_count,
    ep_cover.url AS cover_photo_url
  FROM public.events e
  LEFT JOIN public.locations l ON l.id = e.location_id
  LEFT JOIN public.users u ON u.id = e.created_by
  LEFT JOIN public.event_photos ep_cover ON ep_cover.id = e.cover_photo_id
  WHERE e.id = v_event_id;
END;
$$;

COMMENT ON FUNCTION public.get_event_by_invite_token IS 
  'Returns event details for the web landing page. Token-gated: no token = no data. Used by Next.js server-side.';


-- 7.5: Revoke event invite link
CREATE OR REPLACE FUNCTION public.revoke_event_invite_link(p_token text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
  v_event_id uuid;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Only event creator can revoke
  SELECT eil.event_id INTO v_event_id
  FROM public.event_invite_links eil
  JOIN public.events e ON e.id = eil.event_id
  WHERE eil.token = p_token
    AND e.created_by = v_user_id;

  IF v_event_id IS NULL THEN
    RAISE EXCEPTION 'Not authorized or link not found';
  END IF;

  UPDATE public.event_invite_links
  SET revoked_at = now()
  WHERE token = p_token;
END;
$$;


-- ============================================================================
-- PHASE 8: RECREATE VIEWS (without group references)
-- ============================================================================

-- 8.1: Home events view (simplified, no groups)
CREATE OR REPLACE VIEW public.home_events_view WITH (security_invoker='on') AS
WITH participant_agg AS (
  SELECT
    ep.pevent_id AS event_id,
    count(ep.user_id) AS participants_total,
    count(ep.user_id) FILTER (WHERE ep.rsvp IN ('yes'::rsvp_status)) AS going_count,
    count(ep.user_id) FILTER (WHERE ep.rsvp IN ('no'::rsvp_status)) AS not_going_count,
    count(ep.user_id) FILTER (WHERE ep.rsvp IS NULL OR ep.rsvp = 'pending'::rsvp_status) AS no_response_count,
    count(ep.user_id) FILTER (WHERE ep.rsvp IN ('yes'::rsvp_status, 'no'::rsvp_status)) AS voters_total,
    COALESCE(jsonb_agg(
      jsonb_build_object('user_id', ep.user_id, 'display_name', p.name, 'avatar_url', p.avatar_url, 'voted_at', ep.confirmed_at)
    ) FILTER (WHERE ep.rsvp = 'yes'::rsvp_status), '[]'::jsonb) AS going_users,
    COALESCE(jsonb_agg(
      jsonb_build_object('user_id', ep.user_id, 'display_name', p.name, 'avatar_url', p.avatar_url, 'voted_at', ep.confirmed_at)
    ) FILTER (WHERE ep.rsvp = 'no'::rsvp_status), '[]'::jsonb) AS not_going_users,
    COALESCE(jsonb_agg(
      jsonb_build_object('user_id', ep.user_id, 'display_name', p.name, 'avatar_url', p.avatar_url)
    ) FILTER (WHERE ep.rsvp IS NULL OR ep.rsvp = 'pending'::rsvp_status), '[]'::jsonb) AS no_response_users
  FROM public.event_participants ep
  LEFT JOIN public.users p ON p.id = ep.user_id
  GROUP BY ep.pevent_id
)
SELECT
  ep.user_id,
  COALESCE(ep.rsvp::text, 'pending') AS user_rsvp,
  ep.confirmed_at AS voted_at,
  e.id AS event_id,
  e.name AS event_name,
  e.emoji,
  e.description,
  e.start_datetime,
  e.end_datetime,
  e.location_id,
  l.display_name AS location_name,
  e.created_by AS organizer_id,
  e.status AS event_status,
  CASE
    WHEN e.status = 'living'::event_state THEN 4
    WHEN e.status = 'recap'::event_state THEN 3
    WHEN e.status = 'confirmed'::event_state THEN 2
    WHEN e.status = 'pending'::event_state THEN 1
    ELSE 0
  END AS priority,
  agg.participants_total,
  agg.voters_total,
  agg.no_response_count,
  agg.going_count,
  agg.not_going_count,
  agg.going_users,
  agg.not_going_users,
  agg.no_response_users,
  -- Guest counts from web RSVPs
  COALESCE(guest.guest_going, 0) AS guest_going_count,
  COALESCE(guest.guest_total, 0) AS guest_total_count
FROM public.event_participants ep
JOIN public.events e ON e.id = ep.pevent_id
LEFT JOIN public.locations l ON l.id = e.location_id
LEFT JOIN participant_agg agg ON agg.event_id = e.id
LEFT JOIN LATERAL (
  SELECT
    count(*) FILTER (WHERE gr.rsvp = 'going') AS guest_going,
    count(*) AS guest_total
  FROM public.event_guest_rsvps gr
  WHERE gr.event_id = e.id
) guest ON true
WHERE e.status = 'pending'::event_state
   OR (
     (e.start_datetime IS NULL OR e.end_datetime IS NULL OR e.start_datetime >= now() OR e.end_datetime >= now() OR e.end_datetime >= now() - interval '24 hours')
     AND e.status::text <> 'ended'
   )
ORDER BY
  CASE
    WHEN e.status = 'living'::event_state THEN 4
    WHEN e.status = 'recap'::event_state THEN 3
    WHEN e.status = 'confirmed'::event_state THEN 2
    WHEN e.status = 'pending'::event_state THEN 1
    ELSE 0
  END DESC,
  e.start_datetime;

-- 8.2: Event participants summary view (simplified)
CREATE OR REPLACE VIEW public.event_participants_summary_view AS
SELECT
  e.id AS event_id,
  e.name AS event_name,
  e.start_datetime,
  e.end_datetime,
  e.location_id,
  e.created_by AS organizer_id,
  e.status AS event_status,
  e.emoji,
  e.created_at,
  count(ep.user_id) AS participants_total,
  count(ep.user_id) FILTER (WHERE ep.rsvp IN ('yes'::rsvp_status, 'no'::rsvp_status)) AS voters_total,
  count(ep.user_id) FILTER (WHERE ep.rsvp IS NULL OR ep.rsvp = 'pending'::rsvp_status) AS missing_responses,
  count(ep.user_id) FILTER (WHERE ep.rsvp = 'yes'::rsvp_status) AS going_count,
  count(ep.user_id) FILTER (WHERE ep.rsvp = 'no'::rsvp_status) AS not_going_count,
  array_agg(ep.user_id) AS participant_user_ids
FROM public.events e
LEFT JOIN public.event_participants ep ON ep.pevent_id = e.id
GROUP BY e.id;

-- 8.3: Recreate event_photos materialized view (renamed from group_photos_with_uploader)
CREATE MATERIALIZED VIEW public.event_photos_with_uploader AS
SELECT
  ep.id,
  ep.event_id,
  ep.url,
  ep.storage_path,
  ep.captured_at,
  ep.uploader_id,
  ep.is_portrait,
  ep.created_at,
  ep.updated_at,
  u.name AS uploader_name,
  u.avatar_url AS uploader_avatar
FROM public.event_photos ep
LEFT JOIN public.users u ON ep.uploader_id = u.id
WITH NO DATA;

-- Refresh immediately
REFRESH MATERIALIZED VIEW public.event_photos_with_uploader;

-- Create unique index for concurrent refresh
CREATE UNIQUE INDEX IF NOT EXISTS idx_event_photos_uploader_id 
  ON public.event_photos_with_uploader(id);


-- ============================================================================
-- PHASE 9: UPDATE NOTIFICATIONS
-- ============================================================================

-- Remove group-specific notification types (cleanup old data)
DELETE FROM public.notifications 
WHERE type IN (
  'groupInviteReceived',
  'groupInviteAccepted', 
  'groupMemberAdded',
  'groupCreated',
  'chatMessage',
  'chatMention'
);

-- Update notification settings: remove chat column
ALTER TABLE public.user_notification_settings DROP COLUMN IF EXISTS push_enabled_for_chat;

-- Add invite notification setting
ALTER TABLE public.user_notification_settings 
  ADD COLUMN IF NOT EXISTS push_enabled_for_invites boolean NOT NULL DEFAULT true;


-- ============================================================================
-- PHASE 10: RLS POLICIES
-- ============================================================================

-- 10.1: Event invite links RLS
ALTER TABLE public.event_invite_links ENABLE ROW LEVEL SECURITY;

-- Participants & organizers can view links for their events
CREATE POLICY "Event participants can view invite links"
  ON public.event_invite_links FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.event_participants ep
      WHERE ep.pevent_id = event_invite_links.event_id
        AND ep.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.events e
      WHERE e.id = event_invite_links.event_id
        AND e.created_by = auth.uid()
    )
  );

-- Participants & organizers can create links
CREATE POLICY "Event members can create invite links"
  ON public.event_invite_links FOR INSERT
  WITH CHECK (
    created_by = auth.uid()
    AND (
      EXISTS (
        SELECT 1 FROM public.event_participants ep
        WHERE ep.pevent_id = event_invite_links.event_id
          AND ep.user_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM public.events e
        WHERE e.id = event_invite_links.event_id
          AND e.created_by = auth.uid()
      )
    )
  );

-- 10.2: Event guest RSVPs RLS
ALTER TABLE public.event_guest_rsvps ENABLE ROW LEVEL SECURITY;

-- Anyone with a valid token can insert (handled by RPC, but allow service role)
CREATE POLICY "Service role manages guest RSVPs"
  ON public.event_guest_rsvps FOR ALL
  USING (true)
  WITH CHECK (true);

-- Event participants can view guest RSVPs for their events
CREATE POLICY "Event participants can view guest RSVPs"
  ON public.event_guest_rsvps FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.event_participants ep
      WHERE ep.pevent_id = event_guest_rsvps.event_id
        AND ep.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.events e
      WHERE e.id = event_guest_rsvps.event_id
        AND e.created_by = auth.uid()
    )
  );

-- 10.3: Invite analytics RLS
ALTER TABLE public.invite_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Event organizer can view analytics"
  ON public.invite_analytics FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.events e
      WHERE e.id = invite_analytics.event_id
        AND e.created_by = auth.uid()
    )
  );

-- Insert allowed for all (tracked by RPCs)
CREATE POLICY "Analytics insertable by anyone"
  ON public.invite_analytics FOR INSERT
  WITH CHECK (true);


-- ============================================================================
-- PHASE 11: CLEANUP UNUSED TYPES
-- ============================================================================

-- These types were group-related and are no longer needed
-- Note: DROP TYPE only works if nothing references them
DROP TYPE IF EXISTS public.group_state CASCADE;
DROP TYPE IF EXISTS public.member_role CASCADE;
DROP TYPE IF EXISTS public.message_type CASCADE;


-- ============================================================================
-- PHASE 12: UPDATE REMAINING FUNCTIONS
-- ============================================================================

-- 12.1: Recreate handle_new_event without group references
CREATE OR REPLACE FUNCTION public.handle_new_event()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  IF NEW.created_by IS NULL THEN
    RAISE EXCEPTION 'created_by is required';
  END IF;

  -- Insert creator as host participant
  INSERT INTO public.event_participants (pevent_id, user_id, rsvp)
  VALUES (NEW.id, NEW.created_by, 'yes'::rsvp_status)
  ON CONFLICT (pevent_id, user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- Recreate the trigger
CREATE TRIGGER on_event_created
  AFTER INSERT ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_event();

-- 12.2: Update is_member_of_event (still useful)
CREATE OR REPLACE FUNCTION public.is_member_of_event(eid uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = 'public'
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.event_participants
    WHERE pevent_id = eid AND user_id = auth.uid()
  );
$$;

-- 12.3: Recreate memories functions without group references
CREATE OR REPLACE FUNCTION public.get_recent_memories_with_covers(
  p_user_id uuid,
  p_start_date timestamptz
)
RETURNS TABLE(
  id uuid,
  name text,
  start_datetime timestamptz,
  end_datetime timestamptz,
  display_name text,
  cover_storage_path text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = 'public'
AS $$
  SELECT
    e.id,
    e.name,
    e.start_datetime,
    e.end_datetime,
    COALESCE(e.name, 'Untitled Event') AS display_name,
    COALESCE(
      (SELECT ep.storage_path FROM event_photos ep WHERE ep.id = e.cover_photo_id),
      (SELECT ep.storage_path FROM event_photos ep WHERE ep.event_id = e.id AND ep.is_portrait = true ORDER BY ep.created_at LIMIT 1),
      (SELECT ep.storage_path FROM event_photos ep WHERE ep.event_id = e.id ORDER BY ep.created_at LIMIT 1)
    ) AS cover_storage_path
  FROM events e
  JOIN event_participants part ON part.pevent_id = e.id
  WHERE part.user_id = p_user_id
    AND e.status IN ('recap'::event_state, 'ended'::event_state)
    AND e.end_datetime >= p_start_date
  ORDER BY e.end_datetime DESC
  LIMIT 20;
$$;

COMMENT ON FUNCTION public.get_recent_memories_with_covers(uuid, timestamptz) IS 
  'Fetches recent memories (ended events) for a user. Lazzo 2.0: no longer group-based, queries by participant membership directly.';

CREATE OR REPLACE FUNCTION public.get_user_memories_with_covers(p_user_id uuid)
RETURNS TABLE(
  id uuid,
  name text,
  end_datetime timestamptz,
  status text,
  display_name text,
  cover_storage_path text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = 'public'
AS $$
  SELECT
    e.id,
    e.name,
    e.end_datetime,
    e.status::text,
    COALESCE(e.name, 'Untitled Event') AS display_name,
    COALESCE(
      (SELECT ep.storage_path FROM event_photos ep WHERE ep.id = e.cover_photo_id),
      (SELECT ep.storage_path FROM event_photos ep WHERE ep.event_id = e.id AND ep.is_portrait = true ORDER BY ep.created_at LIMIT 1),
      (SELECT ep.storage_path FROM event_photos ep WHERE ep.event_id = e.id ORDER BY ep.created_at LIMIT 1)
    ) AS cover_storage_path
  FROM events e
  JOIN event_participants part ON part.pevent_id = e.id
  WHERE part.user_id = p_user_id
    AND e.status IN ('living'::event_state, 'recap'::event_state, 'ended'::event_state)
  ORDER BY e.end_datetime DESC;
$$;

COMMENT ON FUNCTION public.get_user_memories_with_covers(uuid) IS 
  'Fetches all memories for a user with cover photos. Lazzo 2.0: queries by participant membership instead of group membership.';


-- ============================================================================
-- PHASE 13: STORAGE — DROP BROKEN POLICIES ON storage.objects
-- ============================================================================
-- Many storage policies reference group_members/groups which are now dropped.
-- We must remove them and replace with event_participants-based policies.
--
-- Buckets affected:
--   - group-photos  (6 policies, 2 reference group_members)
--   - memory_groups (7 policies, 5 reference group_members)
--   - users-profile-pic (1 policy references group_members)
--
-- Buckets already OK (use event_participants):
--   - event-photos ✅
--   - thumbs ✅

-- 13.1: Drop ALL storage policies on 'group-photos' bucket
DROP POLICY IF EXISTS "Group admins can delete photos" ON storage.objects;
DROP POLICY IF EXISTS "Group admins can update photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete group photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update group photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload group photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can view group photos" ON storage.objects;

-- 13.2: Drop ALL storage policies on 'memory_groups' bucket
DROP POLICY IF EXISTS "Allow group members to read photos" ON storage.objects;
DROP POLICY IF EXISTS "Group members can upload event photos" ON storage.objects;
DROP POLICY IF EXISTS "Group members can view event photos" ON storage.objects;
DROP POLICY IF EXISTS "Members can upload photos to their group events" ON storage.objects;
DROP POLICY IF EXISTS "Members can view photos from their groups" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own event photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own photos" ON storage.objects;

-- 13.3: Drop avatar policy that references group_members
DROP POLICY IF EXISTS "group_members_can_view_avatars" ON storage.objects;


-- ============================================================================
-- PHASE 14: STORAGE — CREATE NEW PARTICIPANT-BASED POLICIES
-- ============================================================================

-- ----- 14.1: 'group-photos' bucket (LEGACY — keep for existing files) -----
-- Files already stored here stay accessible. New uploads use 'event-photos'.
-- Path convention was: groupId/eventId/userId/file.jpg
-- After migration, we allow read access based on event_participants or event ownership.

CREATE POLICY "legacy-group-photos: participants can read"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'group-photos'
    AND (
      -- Allow if user is participant of any event (broad read for legacy)
      auth.role() = 'authenticated'
    )
  );

CREATE POLICY "legacy-group-photos: owner can delete own files"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'group-photos'
    AND (storage.foldername(name))[3] = (auth.uid())::text
  );

-- No new uploads to legacy bucket
-- (new photos go to 'event-photos' bucket)

-- ----- 14.2: 'memory_groups' bucket (LEGACY — keep for existing files) -----
-- Path convention was: groupId/eventId/userId/file.jpg

CREATE POLICY "legacy-memory-groups: participants can read"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'memory_groups'
    AND EXISTS (
      SELECT 1 FROM public.event_participants ep
      WHERE ep.pevent_id = ((storage.foldername(objects.name))[2])::uuid
        AND ep.user_id = auth.uid()
    )
  );

CREATE POLICY "legacy-memory-groups: participant can upload to own folder"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'memory_groups'
    AND (storage.foldername(name))[3] = (auth.uid())::text
    AND EXISTS (
      SELECT 1 FROM public.event_participants ep
      WHERE ep.pevent_id = ((storage.foldername(name))[2])::uuid
        AND ep.user_id = auth.uid()
    )
  );

CREATE POLICY "legacy-memory-groups: user can delete own files"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'memory_groups'
    AND (storage.foldername(name))[3] = (auth.uid())::text
  );

CREATE POLICY "legacy-memory-groups: user can update own files"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'memory_groups'
    AND (storage.foldername(name))[3] = (auth.uid())::text
  );

-- ----- 14.3: 'users-profile-pic' — replace group-based avatar visibility -----
-- In Lazzo 2.0, users can see avatars of people they share events with
CREATE POLICY "event_participants_can_view_avatars"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'users-profile-pic'
    AND (
      -- Own avatar
      (storage.foldername(name))[1] = (auth.uid())::text
      OR
      -- Avatars of users who share an event with me
      EXISTS (
        SELECT 1
        FROM public.event_participants ep1
        JOIN public.event_participants ep2 ON ep1.pevent_id = ep2.pevent_id
        WHERE ep1.user_id = auth.uid()
          AND (ep2.user_id)::text = (storage.foldername(objects.name))[1]
      )
    )
  );


-- ============================================================================
-- PHASE 15: UPDATE event_photos RLS POLICIES (renamed from group_photos)
-- ============================================================================
-- The table was renamed in Phase 5, but RLS policies still reference
-- group_members which is now dropped. Drop old policies and recreate.

-- Drop old policies (they were attached to group_photos, now on event_photos)
DROP POLICY IF EXISTS "Allow group members to view photos" ON public.event_photos;
DROP POLICY IF EXISTS "Group members can upload event photos" ON public.event_photos;
DROP POLICY IF EXISTS "Group members can view event photos" ON public.event_photos;
DROP POLICY IF EXISTS "Members can add photos to their groups" ON public.event_photos;
DROP POLICY IF EXISTS "Users can delete their own photos" ON public.event_photos;
DROP POLICY IF EXISTS "Users can update their own photos" ON public.event_photos;
DROP POLICY IF EXISTS "users_can_view_group_photos" ON public.event_photos;

-- Ensure RLS is still enabled
ALTER TABLE public.event_photos ENABLE ROW LEVEL SECURITY;

-- New participant-based policies for event_photos
CREATE POLICY "Event participants can view photos"
  ON public.event_photos FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.event_participants ep
      WHERE ep.pevent_id = event_photos.event_id
        AND ep.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.events e
      WHERE e.id = event_photos.event_id
        AND e.created_by = auth.uid()
    )
  );

CREATE POLICY "Event participants can upload photos"
  ON public.event_photos FOR INSERT
  TO authenticated
  WITH CHECK (
    uploader_id = auth.uid()
    AND (
      EXISTS (
        SELECT 1 FROM public.event_participants ep
        WHERE ep.pevent_id = event_photos.event_id
          AND ep.user_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM public.events e
        WHERE e.id = event_photos.event_id
          AND e.created_by = auth.uid()
      )
    )
  );

CREATE POLICY "Users can delete own event photos"
  ON public.event_photos FOR DELETE
  TO authenticated
  USING (uploader_id = auth.uid());

CREATE POLICY "Users can update own event photos"
  ON public.event_photos FOR UPDATE
  TO authenticated
  USING (uploader_id = auth.uid())
  WITH CHECK (uploader_id = auth.uid());

CREATE POLICY "Event creator can manage all photos"
  ON public.event_photos FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.events e
      WHERE e.id = event_photos.event_id
        AND e.created_by = auth.uid()
    )
  );


-- ============================================================================
-- PHASE 16: STORAGE — ADDITIONAL PUBLIC SCHEMA POLICY CLEANUP
-- ============================================================================
-- Other public schema RLS policies that reference group_members/groups
-- and are now broken. These are on tables that stay (events, chat_messages, etc.)

-- Events: drop group-based policies (replaced by participant + owner policies)
DROP POLICY IF EXISTS "Users can view events from their groups" ON public.events;
DROP POLICY IF EXISTS "Group members can update event cover" ON public.events;
DROP POLICY IF EXISTS "group members can select group events" ON public.events;
DROP POLICY IF EXISTS "events_delete_policy" ON public.events;

-- Recreate event policies (participant-based)
CREATE POLICY "Event participants can view events"
  ON public.events FOR SELECT
  TO authenticated
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.event_participants ep
      WHERE ep.pevent_id = events.id AND ep.user_id = auth.uid()
    )
  );

CREATE POLICY "Event participants can update event cover"
  ON public.events FOR UPDATE
  TO authenticated
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.event_participants ep
      WHERE ep.pevent_id = events.id AND ep.user_id = auth.uid()
    )
  )
  WITH CHECK (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.event_participants ep
      WHERE ep.pevent_id = events.id AND ep.user_id = auth.uid()
    )
  );

CREATE POLICY "Event creator or admin can delete events"
  ON public.events FOR DELETE
  TO authenticated
  USING (created_by = auth.uid());

-- Location suggestions: drop group-based policies
DROP POLICY IF EXISTS "Group members can create location suggestions" ON public.location_suggestions;
DROP POLICY IF EXISTS "Group members can view location suggestions" ON public.location_suggestions;
DROP POLICY IF EXISTS "Event creators can delete all location suggestions for their ev" ON public.location_suggestions;

-- Recreate location suggestion policies (participant-based)
CREATE POLICY "Event participants can create location suggestions"
  ON public.location_suggestions FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.event_participants ep
      WHERE ep.pevent_id = location_suggestions.event_id
        AND ep.user_id = auth.uid()
    )
  );

CREATE POLICY "Event participants can view location suggestions"
  ON public.location_suggestions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.event_participants ep
      WHERE ep.pevent_id = location_suggestions.event_id
        AND ep.user_id = auth.uid()
    )
  );

CREATE POLICY "Event creators can delete location suggestions"
  ON public.location_suggestions FOR DELETE
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.events e
      WHERE e.id = location_suggestions.event_id
        AND e.created_by = auth.uid()
    )
  );

-- Locations: drop group-based view policy
DROP POLICY IF EXISTS "Users can view locations for accessible events" ON public.locations;

-- Recreate location view policy (participant-based, no group JOIN)
CREATE POLICY "Users can view locations for their events"
  ON public.locations FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT DISTINCT e.location_id
      FROM public.events e
      JOIN public.event_participants ep ON e.id = ep.pevent_id
      WHERE ep.user_id = auth.uid()
    )
    OR created_by = auth.uid()
  );

-- Users: drop group-based avatar views
DROP POLICY IF EXISTS "users_can_view_avatars_of_group_members" ON public.users;

-- Recreate avatar visibility (see event co-participants)
CREATE POLICY "users_can_view_avatars_of_event_participants"
  ON public.users FOR SELECT
  TO authenticated
  USING (
    auth.uid() = id
    OR id IN (
      SELECT DISTINCT ep2.user_id
      FROM public.event_participants ep1
      JOIN public.event_participants ep2 ON ep1.pevent_id = ep2.pevent_id
      WHERE ep1.user_id = auth.uid()
    )
  );

-- event_participants: drop group-based view policy
DROP POLICY IF EXISTS "Users can view event_participants" ON public.event_participants;

-- Recreate event_participants view policy
CREATE POLICY "Users can view event_participants"
  ON public.event_participants FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.event_participants ep
      WHERE ep.pevent_id = event_participants.pevent_id
        AND ep.user_id = auth.uid()
    )
  );


-- ============================================================================
-- DONE
-- ============================================================================

COMMIT;

-- Post-migration verification queries (run manually):
--
-- 1. Check no group tables remain:
--    SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE 'group%';
--
-- 2. Check no chat tables remain:
--    SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE 'chat%' OR tablename = 'message_reads';
--
-- 3. Verify new tables exist:
--    SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename IN ('event_invite_links', 'event_guest_rsvps', 'invite_analytics');
--
-- 4. Verify events no longer has group_id:
--    SELECT column_name FROM information_schema.columns WHERE table_name = 'events' AND column_name = 'group_id';
--    -- Should return 0 rows
--
-- 5. Test invite flow:
--    SELECT * FROM get_or_create_event_invite_link('<some_event_id>');
--    SELECT * FROM get_event_by_invite_token('<token>');
