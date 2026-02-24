-- ============================================================================
-- MIGRATION 002: Remove Event Chat, Add RSVP 'maybe', Schema Cleanup
-- ============================================================================
-- Date: 2026-02-12
-- Description:
--   1. Remove event chat system (chat_active_users table, chat functions)
--   2. Update views and functions to support RSVP 'maybe' status
--   3. Drop duplicate rsvp_status type (with tab character)
--   4. Rename legacy "group_photos" indexes/triggers to "event_photos"
--   5. Drop legacy push_tokens table (replaced by user_push_tokens)
--
-- Dependencies: Requires migration 001 to have been applied first.
-- ============================================================================

BEGIN;

-- ============================================================================
-- PHASE 1: REMOVE EVENT CHAT
-- Tables already dropped: chat_messages, message_reads (from previous cleanup)
-- Functions referencing them are now broken and must be removed.
-- chat_active_users table still exists and must be dropped.
-- ============================================================================

-- 1.1 Drop RLS policies on chat_active_users
DROP POLICY IF EXISTS "Users can manage own presence" ON chat_active_users;
DROP POLICY IF EXISTS "Users can view own presence" ON chat_active_users;

-- 1.2 Drop FK constraints on chat_active_users
ALTER TABLE IF EXISTS chat_active_users DROP CONSTRAINT IF EXISTS chat_active_users_event_id_fkey;
ALTER TABLE IF EXISTS chat_active_users DROP CONSTRAINT IF EXISTS chat_active_users_user_id_fkey;

-- 1.3 Drop indexes on chat_active_users
DROP INDEX IF EXISTS idx_chat_active_users_event_last_seen;

-- 1.4 Drop chat-related functions (reference tables that no longer exist)
DROP FUNCTION IF EXISTS pin_chat_message(uuid, uuid, boolean);
DROP FUNCTION IF EXISTS soft_delete_chat_message(uuid);
DROP FUNCTION IF EXISTS update_chat_messages_updated_at();
DROP FUNCTION IF EXISTS touch_chat_presence(uuid);
DROP FUNCTION IF EXISTS update_last_read_message(uuid, uuid);

-- 1.5 Drop chat_active_users table
DROP TABLE IF EXISTS chat_active_users CASCADE;

-- 1.6 Update cleanup_expired_notifications to remove chat references
CREATE OR REPLACE FUNCTION public.cleanup_expired_notifications() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  -- Remove EPHEMERAL notifications (temporary reminders/alerts)

  -- 1. Upload deadline notifications (no longer relevant after event ends)
  DELETE FROM notifications
  WHERE type IN ('uploadsOpen', 'uploadsClosing')
    AND event_id IN (
      SELECT id FROM events
      WHERE end_datetime IS NOT NULL
        AND end_datetime < NOW()
    )
    AND created_at < NOW() - INTERVAL '24 hours';

  -- 2. Event reminders (no longer relevant after event starts)
  DELETE FROM notifications
  WHERE type IN ('eventStartsSoon', 'eventStartingNow')
    AND created_at < NOW() - INTERVAL '2 hours';

  -- 3. Location sharing notifications (temporary)
  DELETE FROM notifications
  WHERE type IN ('locationLiveStarted', 'locationLiveStopped')
    AND created_at < NOW() - INTERVAL '24 hours';

  -- NEVER DELETE these types (permanent inbox history):
  -- - eventCreated (event history)
  -- - memoryShared (memories are permanent)
  -- - accountSecurity (audit trail)
END;
$$;


-- ============================================================================
-- PHASE 2: DROP DUPLICATE rsvp_status TYPE (with tab character)
-- The schema has a broken duplicate type "rsvp_status\t" that must be removed.
-- The correct rsvp_status type (with 'pending','yes','no','maybe') is kept.
-- ============================================================================

DROP TYPE IF EXISTS public."rsvp_status	";


-- ============================================================================
-- PHASE 3: UPDATE VIEWS TO SUPPORT RSVP 'maybe'
-- ============================================================================

-- 3.1 Recreate home_events_view with 'maybe' support
CREATE OR REPLACE VIEW public.home_events_view WITH (security_invoker='on') AS
 WITH participant_agg AS (
         SELECT ep_1.pevent_id AS event_id,
            count(ep_1.user_id) AS participants_total,
            count(ep_1.user_id) FILTER (WHERE (ep_1.rsvp = 'yes'::public.rsvp_status)) AS going_count,
            count(ep_1.user_id) FILTER (WHERE (ep_1.rsvp = 'no'::public.rsvp_status)) AS not_going_count,
            count(ep_1.user_id) FILTER (WHERE (ep_1.rsvp = 'maybe'::public.rsvp_status)) AS maybe_count,
            count(ep_1.user_id) FILTER (WHERE ((ep_1.rsvp IS NULL) OR (ep_1.rsvp = 'pending'::public.rsvp_status))) AS no_response_count,
            count(ep_1.user_id) FILTER (WHERE (ep_1.rsvp = ANY (ARRAY['yes'::public.rsvp_status, 'no'::public.rsvp_status, 'maybe'::public.rsvp_status]))) AS voters_total,
            COALESCE(jsonb_agg(jsonb_build_object('user_id', ep_1.user_id, 'display_name', p.name, 'avatar_url', p.avatar_url, 'voted_at', ep_1.confirmed_at)) FILTER (WHERE (ep_1.rsvp = 'yes'::public.rsvp_status)), '[]'::jsonb) AS going_users,
            COALESCE(jsonb_agg(jsonb_build_object('user_id', ep_1.user_id, 'display_name', p.name, 'avatar_url', p.avatar_url, 'voted_at', ep_1.confirmed_at)) FILTER (WHERE (ep_1.rsvp = 'no'::public.rsvp_status)), '[]'::jsonb) AS not_going_users,
            COALESCE(jsonb_agg(jsonb_build_object('user_id', ep_1.user_id, 'display_name', p.name, 'avatar_url', p.avatar_url, 'voted_at', ep_1.confirmed_at)) FILTER (WHERE (ep_1.rsvp = 'maybe'::public.rsvp_status)), '[]'::jsonb) AS maybe_users,
            COALESCE(jsonb_agg(jsonb_build_object('user_id', ep_1.user_id, 'display_name', p.name, 'avatar_url', p.avatar_url)) FILTER (WHERE ((ep_1.rsvp IS NULL) OR (ep_1.rsvp = 'pending'::public.rsvp_status))), '[]'::jsonb) AS no_response_users
           FROM (public.event_participants ep_1
             LEFT JOIN public.users p ON ((p.id = ep_1.user_id)))
          GROUP BY ep_1.pevent_id
        )
 SELECT ep.user_id,
    COALESCE((ep.rsvp)::text, 'pending'::text) AS user_rsvp,
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
            WHEN (e.status = 'living'::public.event_state) THEN 4
            WHEN (e.status = 'recap'::public.event_state) THEN 3
            WHEN (e.status = 'confirmed'::public.event_state) THEN 2
            WHEN (e.status = 'pending'::public.event_state) THEN 1
            ELSE 0
        END AS priority,
    agg.participants_total,
    agg.voters_total,
    agg.no_response_count,
    agg.going_count,
    agg.not_going_count,
    agg.maybe_count,
    agg.going_users,
    agg.not_going_users,
    agg.maybe_users,
    agg.no_response_users,
    COALESCE(guest.guest_going, (0)::bigint) AS guest_going_count,
    COALESCE(guest.guest_maybe, (0)::bigint) AS guest_maybe_count,
    COALESCE(guest.guest_total, (0)::bigint) AS guest_total_count
   FROM ((((public.event_participants ep
     JOIN public.events e ON ((e.id = ep.pevent_id)))
     LEFT JOIN public.locations l ON ((l.id = e.location_id)))
     LEFT JOIN participant_agg agg ON ((agg.event_id = e.id)))
     LEFT JOIN LATERAL ( SELECT count(*) FILTER (WHERE (gr.rsvp = 'going'::text)) AS guest_going,
            count(*) FILTER (WHERE (gr.rsvp = 'maybe'::text)) AS guest_maybe,
            count(*) AS guest_total
           FROM public.event_guest_rsvps gr
          WHERE (gr.event_id = e.id)) guest ON (true))
  WHERE ((e.status = 'pending'::public.event_state) OR (((e.start_datetime IS NULL) OR (e.end_datetime IS NULL) OR (e.start_datetime >= now()) OR (e.end_datetime >= now()) OR (e.end_datetime >= (now() - '24:00:00'::interval))) AND ((e.status)::text <> 'ended'::text)))
  ORDER BY
        CASE
            WHEN (e.status = 'living'::public.event_state) THEN 4
            WHEN (e.status = 'recap'::public.event_state) THEN 3
            WHEN (e.status = 'confirmed'::public.event_state) THEN 2
            WHEN (e.status = 'pending'::public.event_state) THEN 1
            ELSE 0
        END DESC, e.start_datetime;

-- 3.2 Recreate event_participants_summary_view with 'maybe' support
CREATE OR REPLACE VIEW public.event_participants_summary_view AS
 SELECT e.id AS event_id,
    e.name AS event_name,
    e.start_datetime,
    e.end_datetime,
    e.location_id,
    e.created_by AS organizer_id,
    e.status AS event_status,
    e.emoji,
    e.created_at,
    count(ep.user_id) AS participants_total,
    count(ep.user_id) FILTER (WHERE (ep.rsvp = ANY (ARRAY['yes'::public.rsvp_status, 'no'::public.rsvp_status, 'maybe'::public.rsvp_status]))) AS voters_total,
    count(ep.user_id) FILTER (WHERE ((ep.rsvp IS NULL) OR (ep.rsvp = 'pending'::public.rsvp_status))) AS missing_responses,
    count(ep.user_id) FILTER (WHERE (ep.rsvp = 'yes'::public.rsvp_status)) AS going_count,
    count(ep.user_id) FILTER (WHERE (ep.rsvp = 'no'::public.rsvp_status)) AS not_going_count,
    count(ep.user_id) FILTER (WHERE (ep.rsvp = 'maybe'::public.rsvp_status)) AS maybe_count,
    array_agg(ep.user_id) AS participant_user_ids
   FROM (public.events e
     LEFT JOIN public.event_participants ep ON ((ep.pevent_id = e.id)))
  GROUP BY e.id;


-- ============================================================================
-- PHASE 4: UPDATE NOTIFICATION FUNCTIONS FOR 'maybe' RSVP
-- Functions that filter by rsvp = 'yes' should also notify 'maybe' users
-- where appropriate (e.g., event canceled, event starts soon).
-- ============================================================================

-- 4.1 notify_event_canceled: notify 'yes' AND 'maybe' participants
CREATE OR REPLACE FUNCTION public.notify_event_canceled() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  participant_record RECORD;
BEGIN
  IF OLD.status != 'canceled' AND NEW.status = 'canceled' THEN
    FOR participant_record IN
      SELECT ep.user_id, u.name
      FROM event_participants ep
      JOIN users u ON u.id = ep.user_id
      WHERE ep.pevent_id = OLD.id
        AND ep.rsvp IN ('yes', 'maybe')
        AND ep.user_id != OLD.created_by
    LOOP
      INSERT INTO notifications (
        recipient_user_id,
        type,
        category,
        event_id,
        event_name,
        event_emoji
      ) VALUES (
        participant_record.user_id,
        'eventCanceled',
        'push',
        OLD.id,
        OLD.name,
        OLD.emoji
      );
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$;

-- 4.2 notify_participants_before_delete: notify 'yes' AND 'maybe' participants
CREATE OR REPLACE FUNCTION public.notify_participants_before_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  participant_record RECORD;
BEGIN
  FOR participant_record IN
    SELECT ep.user_id, u.name as user_name
    FROM event_participants ep
    JOIN users u ON u.id = ep.user_id
    WHERE ep.pevent_id = OLD.id
      AND ep.rsvp IN ('yes', 'maybe')
      AND ep.user_id != OLD.created_by
  LOOP
    INSERT INTO notifications (
      recipient_user_id,
      type,
      category,
      priority,
      event_id,
      event_name,
      event_emoji,
      created_at
    ) VALUES (
      participant_record.user_id,
      'eventCanceled',
      'push',
      'high',
      OLD.id,
      OLD.name,
      OLD.emoji,
      NOW()
    );
  END LOOP;

  RETURN OLD;
END;
$$;

-- 4.3 notify_event_starts_soon: also notify 'maybe' users (they might attend)
CREATE OR REPLACE FUNCTION public.notify_event_starts_soon() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO notifications (
    recipient_user_id,
    type,
    category,
    priority,
    event_emoji,
    event_name,
    mins,
    event_id,
    deeplink
  )
  SELECT
    ep.user_id,
    'eventStartsSoon',
    'push',
    'high',
    e.emoji,
    e.name,
    ROUND(EXTRACT(EPOCH FROM (e.start_datetime - NOW())) / 60)::text,
    e.id,
    'lazzo://event/' || e.id::text
  FROM events e
  JOIN event_participants ep ON ep.pevent_id = e.id
  WHERE e.start_datetime BETWEEN NOW() AND NOW() + interval '30 minutes'
    AND e.status = 'confirmed'
    AND ep.rsvp IN ('yes', 'maybe')
    AND should_send_notification(ep.user_id)
    AND NOT EXISTS (
      SELECT 1 FROM notifications n
      WHERE n.recipient_user_id = ep.user_id
        AND n.event_id = e.id
        AND n.type = 'eventStartsSoon'
        AND n.created_at > NOW() - interval '1 hour'
    );
END;
$$;


-- ============================================================================
-- PHASE 5: RENAME LEGACY "group_photos" INDEXES AND TRIGGERS
-- These reference event_photos but still carry the old "group" naming.
-- ============================================================================

-- 5.1 Rename indexes
ALTER INDEX IF EXISTS idx_group_photos_created RENAME TO idx_event_photos_created_at;
ALTER INDEX IF EXISTS idx_group_photos_event_captured RENAME TO idx_event_photos_event_captured;
ALTER INDEX IF EXISTS idx_group_photos_uploader RENAME TO idx_event_photos_uploader;

-- 5.2 Rename trigger
ALTER TRIGGER update_group_photos_updated_at ON event_photos RENAME TO update_event_photos_updated_at;


-- ============================================================================
-- PHASE 6: DROP LEGACY push_tokens TABLE
-- Replaced by user_push_tokens which has richer fields (environment,
-- app_version, unique constraint on device_token+platform).
-- ============================================================================

-- 6.1 Drop RLS policies
DROP POLICY IF EXISTS "Users can delete own tokens" ON push_tokens;
DROP POLICY IF EXISTS "Users can insert own tokens" ON push_tokens;
DROP POLICY IF EXISTS "Users can update own tokens" ON push_tokens;
DROP POLICY IF EXISTS "Users can view own tokens" ON push_tokens;

-- 6.2 Drop indexes
DROP INDEX IF EXISTS idx_push_tokens_user;

-- 6.3 Drop FK constraints
ALTER TABLE IF EXISTS push_tokens DROP CONSTRAINT IF EXISTS push_tokens_user_id_fkey;

-- 6.4 Drop table
DROP TABLE IF EXISTS push_tokens CASCADE;


-- ============================================================================
-- PHASE 7: VERIFY — Queries to confirm changes
-- ============================================================================

-- Chat objects removed:
SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    AND tablename IN ('chat_active_users', 'chat_messages', 'message_reads', 'push_tokens');
-- Expected: 0 rows

-- Chat functions removed:
SELECT proname FROM pg_proc WHERE proname IN (
    'pin_chat_message', 'soft_delete_chat_message',
    'update_chat_messages_updated_at', 'touch_chat_presence',
    'update_last_read_message'
);
-- Expected: 0 rows

-- Duplicate rsvp_status type removed:
SELECT typname FROM pg_type WHERE typname LIKE 'rsvp_status%';
-- Expected: 1 row (only 'rsvp_status', not 'rsvp_status\t')

-- rsvp_status has 'maybe':
SELECT enumlabel FROM pg_enum
    JOIN pg_type ON pg_enum.enumtypid = pg_type.oid
    WHERE typname = 'rsvp_status'
    ORDER BY enumsortorder;
-- Expected: pending, yes, no, maybe


COMMIT;


-- ============================================================================
-- NOTES
-- ============================================================================
--
-- WHAT WAS REMOVED:
--   - chat_active_users table (with RLS, policies, indexes, FKs)
--   - 5 chat functions: pin_chat_message, soft_delete_chat_message,
--     update_chat_messages_updated_at, touch_chat_presence, update_last_read_message
--   - push_tokens table (legacy, replaced by user_push_tokens)
--   - Duplicate "rsvp_status\t" type (with tab character)
--
-- WHAT WAS MODIFIED:
--   - home_events_view: added maybe_count, maybe_users, guest_maybe_count columns
--   - event_participants_summary_view: added maybe_count, voters_total includes 'maybe'
--   - notify_event_canceled(): now notifies 'maybe' participants too
--   - notify_participants_before_delete(): now notifies 'maybe' participants too
--   - notify_event_starts_soon(): now sends reminders to 'maybe' participants
--   - cleanup_expired_notifications(): removed chat notification type references
--   - 3 indexes renamed: idx_group_photos_* → idx_event_photos_*
--   - 1 trigger renamed: update_group_photos_updated_at → update_event_photos_updated_at
--
-- NOT CHANGED (still valid):
--   - notify_event_confirmed(): only notifies all participants via should_send_notification()
--   - notify_event_date_set/details_updated/location_set/extended(): notify all participants
--   - notify_event_ends_soon/live(): notify all participants regardless of RSVP
--   - rsvp_status enum: already had 'maybe' from migration 001
--   - event_guest_rsvps: already had 'maybe' in CHECK constraint
--
