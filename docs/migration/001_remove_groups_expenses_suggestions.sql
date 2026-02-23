-- ============================================================================
-- MIGRATION: Remove Groups, Expenses, and Date/Location Suggestions
-- ============================================================================
-- Description: Cleans up the Supabase database by removing all objects related
--   to expenses, date/location suggestion polls, and group dependencies.
--   Events become fully standalone (no group_id).
--
-- Context: The app is pivoting from a group-centric to an event-centric model.
--   Some group/expense tables (groups, group_members, group_user_settings,
--   group_photos_with_uploader materialized view) were already dropped, but
--   many functions still reference them and are currently broken.
--
-- Run: Execute directly in Supabase SQL Editor.
-- Rollback: Restore from a full pg_dump taken before running this migration.
-- ============================================================================

BEGIN;

-- ============================================================================
-- PHASE 1: DROP TRIGGERS
-- Must go before dropping functions they reference
-- ============================================================================

-- Expense triggers
DROP TRIGGER IF EXISTS expense_paid_notification ON expense_splits;

-- Date suggestion triggers
DROP TRIGGER IF EXISTS date_suggestion_added_notification ON event_date_options;

-- Location suggestion triggers
DROP TRIGGER IF EXISTS location_suggestion_added_notification ON location_suggestions;
DROP TRIGGER IF EXISTS suggestion_added_notification ON location_suggestions;

-- event_photos triggers that call refresh_group_photos_view()
-- (the materialized view group_photos_with_uploader no longer exists)
DROP TRIGGER IF EXISTS trigger_refresh_photos_on_delete ON event_photos;
DROP TRIGGER IF EXISTS trigger_refresh_photos_on_insert ON event_photos;
DROP TRIGGER IF EXISTS trigger_refresh_photos_on_update ON event_photos;


-- ============================================================================
-- PHASE 2: DROP RLS POLICIES on tables about to be dropped
-- ============================================================================

-- event_date_options policies
DROP POLICY IF EXISTS edopts_delete ON event_date_options;
DROP POLICY IF EXISTS edopts_insert ON event_date_options;
DROP POLICY IF EXISTS edopts_select ON event_date_options;
DROP POLICY IF EXISTS edopts_update ON event_date_options;

-- event_date_votes policies
DROP POLICY IF EXISTS edvotes_delete ON event_date_votes;
DROP POLICY IF EXISTS edvotes_insert ON event_date_votes;
DROP POLICY IF EXISTS edvotes_select ON event_date_votes;
DROP POLICY IF EXISTS edvotes_update ON event_date_votes;

-- event_expenses policies
DROP POLICY IF EXISTS "Users can create expenses for their events" ON event_expenses;
DROP POLICY IF EXISTS "Users can view expenses from their events" ON event_expenses;
DROP POLICY IF EXISTS event_expenses_delete_policy ON event_expenses;
DROP POLICY IF EXISTS event_expenses_update_policy ON event_expenses;

-- expense_splits policies
DROP POLICY IF EXISTS "Users can insert expense splits for event participants" ON expense_splits;
DROP POLICY IF EXISTS "Users can view expense splits they are part of" ON expense_splits;
DROP POLICY IF EXISTS expense_splits_delete_policy ON expense_splits;
DROP POLICY IF EXISTS expense_splits_update_policy ON expense_splits;

-- location_suggestions policies
DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON location_suggestions;
DROP POLICY IF EXISTS "Event creators can delete location suggestions" ON location_suggestions;
DROP POLICY IF EXISTS "Event participants can create location suggestions" ON location_suggestions;
DROP POLICY IF EXISTS "Event participants can view location suggestions" ON location_suggestions;

-- location_suggestion_votes policies
DROP POLICY IF EXISTS event_participants_can_view_location_votes ON location_suggestion_votes;
DROP POLICY IF EXISTS event_participants_can_vote_on_location_suggestions ON location_suggestion_votes;
DROP POLICY IF EXISTS users_can_remove_own_location_votes ON location_suggestion_votes;

-- photos (legacy) policies — may not have named policies but RLS is enabled
-- memories (legacy) policies — same

-- ============================================================================
-- PHASE 3: DROP FK CONSTRAINTS referencing tables about to be dropped
-- ============================================================================

-- notifications.expense_id → event_expenses
ALTER TABLE IF EXISTS notifications DROP CONSTRAINT IF EXISTS notifications_expense_id_fkey;

-- memories → photos
ALTER TABLE IF EXISTS memories DROP CONSTRAINT IF EXISTS memories_photo_id_fkey;
ALTER TABLE IF EXISTS memories DROP CONSTRAINT IF EXISTS memories_user_id_fkey;

-- photos FKs
ALTER TABLE IF EXISTS photos DROP CONSTRAINT IF EXISTS photos_event_id_fkey;
ALTER TABLE IF EXISTS photos DROP CONSTRAINT IF EXISTS photos_uploaded_by_fkey;

-- expense_splits FKs
ALTER TABLE IF EXISTS expense_splits DROP CONSTRAINT IF EXISTS expense_splits_expense_id_fkey;
ALTER TABLE IF EXISTS expense_splits DROP CONSTRAINT IF EXISTS expense_splits_user_id_fkey;

-- event_expenses FKs
ALTER TABLE IF EXISTS event_expenses DROP CONSTRAINT IF EXISTS event_expenses_created_by_fkey;
ALTER TABLE IF EXISTS event_expenses DROP CONSTRAINT IF EXISTS event_expenses_event_id_fkey;
ALTER TABLE IF EXISTS event_expenses DROP CONSTRAINT IF EXISTS event_expenses_paid_by_fkey;

-- event_date_votes FKs
ALTER TABLE IF EXISTS event_date_votes DROP CONSTRAINT IF EXISTS event_date_votes_option_id_fkey;
ALTER TABLE IF EXISTS event_date_votes DROP CONSTRAINT IF EXISTS event_date_votes_user_id_fkey;

-- event_date_options FKs
ALTER TABLE IF EXISTS event_date_options DROP CONSTRAINT IF EXISTS event_date_options_created_by_fkey;
ALTER TABLE IF EXISTS event_date_options DROP CONSTRAINT IF EXISTS event_date_options_event_id_fkey;

-- location_suggestion_votes FKs
ALTER TABLE IF EXISTS location_suggestion_votes DROP CONSTRAINT IF EXISTS location_suggestion_votes_suggestion_id_fkey;
ALTER TABLE IF EXISTS location_suggestion_votes DROP CONSTRAINT IF EXISTS location_suggestion_votes_user_id_fkey;

-- location_suggestions FKs
ALTER TABLE IF EXISTS location_suggestions DROP CONSTRAINT IF EXISTS location_suggestions_event_id_fkey;
ALTER TABLE IF EXISTS location_suggestions DROP CONSTRAINT IF EXISTS location_suggestions_user_id_fkey;


-- ============================================================================
-- PHASE 4: DROP VIEWS
-- ============================================================================

DROP VIEW IF EXISTS user_event_expenses;


-- ============================================================================
-- PHASE 5: DROP FUNCTIONS (expense, suggestion, group-related)
-- ============================================================================

-- Expense notification functions
DROP FUNCTION IF EXISTS notify_expense_added();
DROP FUNCTION IF EXISTS notify_expense_split_added();
DROP FUNCTION IF EXISTS notify_expense_split_simple();
DROP FUNCTION IF EXISTS notify_payments_added_you_owe();
DROP FUNCTION IF EXISTS notify_payments_paid_you();
DROP FUNCTION IF EXISTS notify_payment_received();
DROP FUNCTION IF EXISTS validate_expense();
DROP FUNCTION IF EXISTS populate_expense_notification_data();

-- Date/location suggestion functions
DROP FUNCTION IF EXISTS notify_date_suggestion_added();
DROP FUNCTION IF EXISTS notify_location_suggestion_added();
DROP FUNCTION IF EXISTS notify_suggestion_added();
DROP FUNCTION IF EXISTS decrement_poll_vote_count(uuid);
DROP FUNCTION IF EXISTS increment_poll_vote_count(uuid);

-- Group-related functions (tables already dropped)
DROP FUNCTION IF EXISTS refresh_group_hub_cache();
DROP FUNCTION IF EXISTS refresh_group_photos_view();
DROP FUNCTION IF EXISTS remove_group_member(uuid, uuid);
DROP FUNCTION IF EXISTS revoke_group_invite_link(text);


-- ============================================================================
-- PHASE 6: DROP TABLES
-- (order respects FK dependencies: children first, then parents)
-- ============================================================================

DROP TABLE IF EXISTS expense_splits CASCADE;
DROP TABLE IF EXISTS event_expenses CASCADE;
DROP TABLE IF EXISTS location_suggestion_votes CASCADE;
DROP TABLE IF EXISTS location_suggestions CASCADE;
DROP TABLE IF EXISTS event_date_votes CASCADE;
DROP TABLE IF EXISTS event_date_options CASCADE;
DROP TABLE IF EXISTS memories CASCADE;
DROP TABLE IF EXISTS photos CASCADE;


-- ============================================================================
-- PHASE 7: DROP TYPES (only if no longer referenced)
-- ============================================================================

DROP TYPE IF EXISTS expense_status;
DROP TYPE IF EXISTS split_method;
DROP TYPE IF EXISTS poll_type;
DROP TYPE IF EXISTS photo_type;


-- ============================================================================
-- PHASE 8: ALTER notifications TABLE
-- Remove expense_id column and (if they exist) group_id/group_name columns
-- ============================================================================

ALTER TABLE notifications DROP COLUMN IF EXISTS expense_id;
ALTER TABLE notifications DROP COLUMN IF EXISTS group_id;
ALTER TABLE notifications DROP COLUMN IF EXISTS group_name;
ALTER TABLE notifications DROP COLUMN IF EXISTS amount;

-- Drop expense-related index
DROP INDEX IF EXISTS idx_notifications_expense_id;

-- Clean up existing expense/payment notifications (historical data)
DELETE FROM notifications WHERE type IN (
  'expenseAdded',
  'expenseSplitAdded',
  'paymentsAddedYouOwe',
  'paymentsPaidYou',
  'paymentReceived',
  'paymentRequest',
  'dateSuggestionAdded',
  'locationSuggestionAdded',
  'suggestionAdded'
);


-- ============================================================================
-- PHASE 9: ALTER user_notification_settings TABLE
-- Remove push_enabled_for_payments column
-- ============================================================================

ALTER TABLE user_notification_settings DROP COLUMN IF EXISTS push_enabled_for_payments;


-- ============================================================================
-- PHASE 10: ALTER problem_reports TABLE
-- Update CHECK constraint to remove 'Payments & expenses' category
-- ============================================================================

ALTER TABLE problem_reports DROP CONSTRAINT IF EXISTS problem_reports_category_check;
ALTER TABLE problem_reports ADD CONSTRAINT problem_reports_category_check CHECK (
  category = ANY (ARRAY[
    'Sign up / Login'::text,
    'Create or join event'::text,
    'Upload photos & memories'::text,
    'Share memories'::text,
    'Notifications'::text,
    'Other'::text
  ])
);


-- ============================================================================
-- PHASE 11: UPDATE events TABLE COMMENT
-- ============================================================================

COMMENT ON TABLE events IS 'Table that holds standalone events';


-- ============================================================================
-- PHASE 12: RECREATE/MODIFY FUNCTIONS
-- Remove all group_id references and fix broken functions
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 12.1: should_send_notification — remove group_id parameter entirely
-- ---------------------------------------------------------------------------
DROP FUNCTION IF EXISTS should_send_notification(uuid, uuid);

CREATE FUNCTION public.should_send_notification(p_user_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Check global push settings
  IF NOT EXISTS (
    SELECT 1 FROM user_notification_settings
    WHERE user_id = p_user_id AND push_enabled = TRUE
  ) THEN
    RETURN FALSE;
  END IF;

  -- Check quiet hours
  DECLARE
    v_quiet_enabled boolean;
    v_quiet_start time;
    v_quiet_end time;
    v_current_time time;
  BEGIN
    SELECT quiet_hours_enabled, quiet_hours_start, quiet_hours_end
    INTO v_quiet_enabled, v_quiet_start, v_quiet_end
    FROM user_notification_settings
    WHERE user_id = p_user_id;

    IF v_quiet_enabled THEN
      v_current_time := CURRENT_TIME;
      IF v_current_time BETWEEN v_quiet_start AND v_quiet_end THEN
        RETURN FALSE;
      END IF;
    END IF;
  END;

  RETURN TRUE;
END;
$$;

-- ---------------------------------------------------------------------------
-- 12.2: create_notification_secure — remove group/expense params
-- ---------------------------------------------------------------------------
-- First drop the old function (signature changed)
DROP FUNCTION IF EXISTS create_notification_secure(
  uuid, text, public.notification_category, public.notification_priority,
  text, uuid, uuid, text, text, text, text, text, text, text, text, text,
  text, text, text, uuid
);

CREATE FUNCTION public.create_notification_secure(
  p_recipient_user_id uuid,
  p_type text,
  p_category public.notification_category,
  p_priority public.notification_priority DEFAULT 'medium'::public.notification_priority,
  p_deeplink text DEFAULT NULL::text,
  p_event_id uuid DEFAULT NULL::uuid,
  p_event_emoji text DEFAULT NULL::text,
  p_user_name text DEFAULT NULL::text,
  p_event_name text DEFAULT NULL::text,
  p_hours text DEFAULT NULL::text,
  p_mins text DEFAULT NULL::text,
  p_date text DEFAULT NULL::text,
  p_time text DEFAULT NULL::text,
  p_place text DEFAULT NULL::text,
  p_device text DEFAULT NULL::text,
  p_note text DEFAULT NULL::text
) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_notification_id UUID;
  v_should_notify BOOLEAN;
  v_in_quiet_hours BOOLEAN;
  v_push_enabled BOOLEAN;
BEGIN
  -- Check user notification settings
  SELECT
    push_enabled,
    CASE
      WHEN quiet_hours_enabled THEN
        CURRENT_TIME BETWEEN quiet_hours_start AND quiet_hours_end
      ELSE FALSE
    END AS in_quiet_hours,
    CASE p_category
      WHEN 'push' THEN
        CASE
          WHEN p_type LIKE 'event%' THEN push_enabled_for_events
          WHEN p_type LIKE 'invite%' THEN push_enabled_for_invites
          ELSE TRUE
        END
      ELSE TRUE -- Feed/actions notifications always allowed
    END AS category_enabled
  INTO v_push_enabled, v_in_quiet_hours, v_should_notify
  FROM user_notification_settings
  WHERE user_id = p_recipient_user_id;

  -- Default to enabled if no settings found
  IF NOT FOUND THEN
    v_push_enabled := TRUE;
    v_in_quiet_hours := FALSE;
    v_should_notify := TRUE;
  END IF;

  -- Skip ephemeral push notifications during quiet hours
  IF v_in_quiet_hours AND p_category = 'push' THEN
    RETURN NULL;
  END IF;

  -- Skip entirely if category disabled
  IF NOT v_should_notify THEN
    RETURN NULL;
  END IF;

  -- Insert notification
  INSERT INTO notifications (
    recipient_user_id, type, category, priority, deeplink,
    event_id, event_emoji, user_name,
    event_name, hours, mins, date, time, place, device, note
  ) VALUES (
    p_recipient_user_id, p_type, p_category, p_priority, p_deeplink,
    p_event_id, p_event_emoji, p_user_name,
    p_event_name, p_hours, p_mins, p_date, p_time, p_place, p_device, p_note
  )
  ON CONFLICT (dedup_key, dedup_bucket) DO NOTHING
  RETURNING id INTO v_notification_id;

  RETURN v_notification_id;
END;
$$;

COMMENT ON FUNCTION public.create_notification_secure IS
  'Creates notifications with server-side filtering (quiet hours, category prefs). Push notifications are ephemeral and never downgraded to inbox.';

-- ---------------------------------------------------------------------------
-- 12.3: notify_event_confirmed — remove group_id from should_send call
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_event_confirmed() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF OLD.status != 'confirmed' AND NEW.status = 'confirmed' THEN
    INSERT INTO notifications (
      recipient_user_id,
      type,
      category,
      priority,
      event_emoji,
      event_name,
      event_id,
      deeplink
    )
    SELECT
      ep.user_id,
      'eventConfirmed',
      'notifications',
      'medium',
      NEW.emoji,
      NEW.name,
      NEW.id,
      'lazzo://event/' || NEW.id::text
    FROM event_participants ep
    WHERE ep.pevent_id = NEW.id
      AND should_send_notification(ep.user_id);
  END IF;

  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- 12.4: notify_event_date_set — remove group_id
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_event_date_set() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF OLD.start_datetime IS NULL AND NEW.start_datetime IS NOT NULL THEN
    INSERT INTO notifications (
      recipient_user_id,
      type,
      category,
      priority,
      event_emoji,
      event_name,
      date,
      time,
      event_id,
      deeplink
    )
    SELECT
      ep.user_id,
      'eventDateSet',
      'notifications',
      'medium',
      NEW.emoji,
      NEW.name,
      TO_CHAR(NEW.start_datetime, 'Mon DD'),
      TO_CHAR(NEW.start_datetime, 'HH24:MI'),
      NEW.id,
      'lazzo://event/' || NEW.id::text
    FROM event_participants ep
    WHERE ep.pevent_id = NEW.id
      AND ep.user_id != NEW.created_by
      AND should_send_notification(ep.user_id);
  END IF;

  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- 12.5: notify_event_details_updated — remove group_id
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_event_details_updated() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (OLD.name IS DISTINCT FROM NEW.name
      OR OLD.emoji IS DISTINCT FROM NEW.emoji)
     AND OLD.status = NEW.status THEN

    INSERT INTO notifications (
      recipient_user_id,
      type,
      category,
      priority,
      event_emoji,
      event_name,
      event_id,
      deeplink
    )
    SELECT
      ep.user_id,
      'eventDetailsUpdated',
      'notifications',
      'low',
      NEW.emoji,
      NEW.name,
      NEW.id,
      'lazzo://event/' || NEW.id::text
    FROM event_participants ep
    WHERE ep.pevent_id = NEW.id
      AND ep.user_id != NEW.created_by
      AND should_send_notification(ep.user_id);
  END IF;

  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- 12.6: notify_event_ends_soon — remove group_id
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_event_ends_soon() RETURNS void
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
    'eventEndsSoon',
    'push',
    'medium',
    e.emoji,
    e.name,
    ROUND(EXTRACT(EPOCH FROM (e.end_datetime - NOW())) / 60)::text,
    e.id,
    'lazzo://event/' || e.id::text
  FROM events e
  JOIN event_participants ep ON ep.pevent_id = e.id
  WHERE e.end_datetime BETWEEN NOW() AND NOW() + interval '30 minutes'
    AND e.status IN ('confirmed', 'live')
    AND should_send_notification(ep.user_id)
    AND NOT EXISTS (
      SELECT 1 FROM notifications n
      WHERE n.recipient_user_id = ep.user_id
        AND n.event_id = e.id
        AND n.type = 'eventEndsSoon'
        AND n.created_at > NOW() - interval '1 hour'
    );
END;
$$;

-- ---------------------------------------------------------------------------
-- 12.7: notify_event_extended — remove group_id
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_event_extended() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_extension_mins INTEGER;
BEGIN
  IF OLD.end_datetime IS DISTINCT FROM NEW.end_datetime
     AND NEW.end_datetime > OLD.end_datetime THEN

    v_extension_mins := EXTRACT(EPOCH FROM (NEW.end_datetime - OLD.end_datetime)) / 60;

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
      'eventExtended',
      'push',
      'medium',
      NEW.emoji,
      NEW.name,
      v_extension_mins::text,
      NEW.id,
      'lazzo://event/' || NEW.id::text
    FROM event_participants ep
    WHERE ep.pevent_id = NEW.id
      AND should_send_notification(ep.user_id);
  END IF;

  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- 12.8: notify_event_live — remove group_id
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_event_live() RETURNS void
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
    event_id,
    deeplink
  )
  SELECT
    ep.user_id,
    'eventLive',
    'push',
    'high',
    e.emoji,
    e.name,
    e.id,
    'lazzo://event/' || e.id::text
  FROM events e
  JOIN event_participants ep ON ep.pevent_id = e.id
  WHERE e.start_datetime BETWEEN NOW() - interval '5 minutes' AND NOW()
    AND e.status = 'confirmed'
    AND should_send_notification(ep.user_id)
    AND NOT EXISTS (
      SELECT 1 FROM notifications n
      WHERE n.recipient_user_id = ep.user_id
        AND n.event_id = e.id
        AND n.type = 'eventLive'
    );
END;
$$;

-- ---------------------------------------------------------------------------
-- 12.9: notify_event_location_set — remove group_id
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_event_location_set() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF OLD.location_id IS NULL AND NEW.location_id IS NOT NULL THEN
    INSERT INTO notifications (
      recipient_user_id,
      type,
      category,
      priority,
      event_emoji,
      event_name,
      place,
      event_id,
      deeplink
    )
    SELECT
      ep.user_id,
      'eventLocationSet',
      'notifications',
      'medium',
      NEW.emoji,
      NEW.name,
      l.display_name,
      NEW.id,
      'lazzo://event/' || NEW.id::text
    FROM event_participants ep
    JOIN locations l ON l.id = NEW.location_id
    WHERE ep.pevent_id = NEW.id
      AND ep.user_id != NEW.created_by
      AND should_send_notification(ep.user_id);
  END IF;

  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- 12.10: notify_event_starts_soon — remove group_id, fix rsvp value
-- ---------------------------------------------------------------------------
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
    AND ep.rsvp = 'yes'
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

-- ---------------------------------------------------------------------------
-- 12.11: notify_event_canceled — remove group_id from INSERT
-- ---------------------------------------------------------------------------
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
        AND ep.rsvp = 'yes'
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

-- ---------------------------------------------------------------------------
-- 12.12: notify_participants_before_delete — remove group references
-- ---------------------------------------------------------------------------
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
      AND ep.rsvp = 'yes'
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

-- ---------------------------------------------------------------------------
-- 12.13: notify_uploads_open — remove group_id
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_uploads_open() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_window_hours INTEGER := 24;
BEGIN
  IF OLD.status != 'recap' AND NEW.status = 'recap' THEN
    INSERT INTO notifications (
      recipient_user_id,
      type,
      category,
      priority,
      event_emoji,
      event_name,
      hours,
      event_id,
      deeplink
    )
    SELECT
      ep.user_id,
      'uploadsOpen',
      'push',
      'medium',
      NEW.emoji,
      NEW.name,
      v_window_hours::text,
      NEW.id,
      'lazzo://event/' || NEW.id::text || '/uploads'
    FROM event_participants ep
    WHERE ep.pevent_id = NEW.id
      AND should_send_notification(ep.user_id);
  END IF;

  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- 12.14: notify_uploads_closing — remove group_id
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_uploads_closing() RETURNS void
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
    hours,
    event_id,
    deeplink
  )
  SELECT
    ep.user_id,
    'uploadsClosing',
    'push',
    'high',
    e.emoji,
    e.name,
    '2',
    e.id,
    'lazzo://event/' || e.id::text || '/uploads'
  FROM events e
  JOIN event_participants ep ON ep.pevent_id = e.id
  WHERE e.status = 'uploads_open'
    AND e.end_datetime + interval '23 hours' BETWEEN NOW() AND NOW() + interval '1 hour'
    AND should_send_notification(ep.user_id)
    AND NOT EXISTS (
      SELECT 1 FROM notifications n
      WHERE n.recipient_user_id = ep.user_id
        AND n.event_id = e.id
        AND n.type = 'uploadsClosing'
    );
END;
$$;

-- ---------------------------------------------------------------------------
-- 12.15: notify_memory_ready — use event_photos instead of group_photos
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_memory_ready(p_event_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_photo_count INTEGER;
BEGIN
  -- Check if any photos exist for this event
  SELECT COUNT(*) INTO v_photo_count
  FROM public.event_photos
  WHERE event_id = p_event_id;

  IF v_photo_count = 0 THEN
    RAISE NOTICE 'Event % has no photos, skipping memory ready notification', p_event_id;
    RETURN;
  END IF;

  -- Photos exist, send notifications to all participants
  INSERT INTO notifications (
    recipient_user_id,
    type,
    category,
    priority,
    event_emoji,
    event_name,
    event_id,
    deeplink
  )
  SELECT
    ep.user_id,
    'memoryReady',
    'push',
    'high',
    e.emoji,
    e.name,
    e.id,
    'lazzo://event/' || e.id::text
  FROM events e
  JOIN event_participants ep ON ep.pevent_id = e.id
  WHERE e.id = p_event_id
    AND should_send_notification(ep.user_id);

  RAISE NOTICE 'Event % has % photos, sent memory ready notifications', p_event_id, v_photo_count;
END;
$$;

COMMENT ON FUNCTION public.notify_memory_ready(uuid) IS
  'Sends "Memory Ready" push notifications to all event participants. Only sends if at least 1 photo exists in event_photos. Called by handle_event_ended() trigger.';

-- ---------------------------------------------------------------------------
-- 12.16: cleanup_expired_notifications — remove payment type comments
-- ---------------------------------------------------------------------------
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
  -- - chatMention, chatReply (conversation context)
  -- - memoryShared (memories are permanent)
  -- - accountSecurity (audit trail)
END;
$$;


-- ============================================================================
-- PHASE 13: VERIFY — Run these SELECT queries to confirm cleanup
-- (Do NOT run inside the transaction — run after COMMIT)
-- ============================================================================

-- Uncomment and run manually after COMMIT:
SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    AND tablename IN ('event_expenses','expense_splits','event_date_options',
        'event_date_votes','location_suggestions','location_suggestion_votes',
        'memories','photos');
-- Expected: 0 rows

SELECT typname FROM pg_type WHERE typname IN ('expense_status','split_method','poll_type','photo_type');
-- Expected: 0 rows

SELECT column_name FROM information_schema.columns
    WHERE table_name = 'notifications' AND column_name IN ('expense_id','group_id','group_name','amount');
-- Expected: 0 rows

SELECT column_name FROM information_schema.columns
    WHERE table_name = 'user_notification_settings' AND column_name = 'push_enabled_for_payments';
-- Expected: 0 rows

SELECT proname FROM pg_proc WHERE proname IN (
    'notify_expense_added','notify_expense_split_added','notify_expense_split_simple',
    'notify_payments_added_you_owe','notify_payments_paid_you','notify_payment_received',
    'validate_expense','populate_expense_notification_data',
    'notify_date_suggestion_added','notify_location_suggestion_added','notify_suggestion_added',
    'decrement_poll_vote_count','increment_poll_vote_count',
    'refresh_group_hub_cache','refresh_group_photos_view',
    'remove_group_member','revoke_group_invite_link'
);
-- Expected: 0 rows


COMMIT;


-- ============================================================================
-- SUGGESTIONS FOR IMPROVEMENT (run separately, not part of the migration)
-- ============================================================================
--
-- 1. RENAME "group_photos" INDEXES on event_photos:
--    These indexes work correctly but have misleading names from the old schema.
--
--    ALTER INDEX idx_group_photos_created RENAME TO idx_event_photos_created;
--    ALTER INDEX idx_group_photos_event_captured RENAME TO idx_event_photos_event_captured;
--    ALTER INDEX idx_group_photos_uploader RENAME TO idx_event_photos_uploader;
--
-- 2. ADD push_enabled_for_chat COLUMN:
--    The create_notification_secure function previously referenced
--    push_enabled_for_chat which doesn't exist in user_notification_settings.
--    Consider adding it:
--
--    ALTER TABLE user_notification_settings
--      ADD COLUMN push_enabled_for_chat boolean DEFAULT true NOT NULL;
--
-- 3. ADD push_enabled_for_memories COLUMN:
--    For fine-grained control over memory-ready notifications:
--
--    ALTER TABLE user_notification_settings
--      ADD COLUMN push_enabled_for_memories boolean DEFAULT true NOT NULL;
--
-- 4. FIX notify_event_starts_soon rsvp filter:
--    The function used ep.rsvp = 'going' (old enum value). This migration
--    already fixed it to 'yes'. Verify the rsvp_status enum values match.
--
-- 5. CLEAN UP is_member_of_event():
--    This function was only used by RLS policies on the now-dropped
--    event_date_options/votes tables and event_participants.
--    It's still valid for event_participants policies — keep it.
--
-- 6. CONSIDER creating event_photos_with_uploader VIEW:
--    The old group_photos_with_uploader materialized view was dropped.
--    If the app needs photo data with uploader info, create a simple view:
--
--    CREATE VIEW event_photos_with_uploader AS
--    SELECT ep.*, u.name as uploader_name, u.avatar_url as uploader_avatar
--    FROM event_photos ep
--    JOIN users u ON u.id = ep.uploader_id;
--
-- 7. REVIEW send_event_rsvp_reminders():
--    This function may reference group_members or group_id. Check and fix
--    if needed (not modified in this migration as it wasn't clearly broken).
--
-- 8. DROP UNUSED TABLES if confirmed not needed:
--    - push_tokens (seems replaced by user_push_tokens)
--    - reviewer_auth_sessions (if no longer used)
--
-- 9. STORAGE CLEANUP:
--    If there are Supabase Storage buckets for expenses or group photos,
--    consider cleaning those up separately via the Supabase dashboard.
--
-- ============================================================================
