--
-- PostgreSQL database dump
--

\restrict ddlLiktetbXH0oVF3N0Ho84yXUQetLy5t8HgO0a3HvWUrtJSTAEdPxXIdjEKEte

-- Dumped from database version 17.4
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: event_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.event_role AS ENUM (
    'host',
    'participant'
);


--
-- Name: event_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.event_state AS ENUM (
    'pending',
    'confirmed',
    'living',
    'recap',
    'ended'
);


--
-- Name: notification_category; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.notification_category AS ENUM (
    'push',
    'notifications',
    'actions'
);


--
-- Name: notification_priority; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.notification_priority AS ENUM (
    'low',
    'medium',
    'high'
);


--
-- Name: report_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.report_status AS ENUM (
    'pending',
    'in_review',
    'resolved'
);


--
-- Name: rsvp_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.rsvp_status AS ENUM (
    'pending',
    'yes',
    'no',
    'maybe'
);


--
-- Name: suggestion_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.suggestion_status AS ENUM (
    'pending',
    'in_review',
    'implemented',
    'declined'
);


--
-- Name: _touch_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._touch_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.updated_at := now();
  return new;
end $$;


--
-- Name: accept_event_invite_by_token(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accept_event_invite_by_token(p_token text) RETURNS TABLE(event_id uuid, event_name text, event_emoji text)
    LANGUAGE plpgsql SECURITY DEFINER
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


--
-- Name: FUNCTION accept_event_invite_by_token(p_token text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.accept_event_invite_by_token(p_token text) IS 'Accepts an event invite by token. Adds the authenticated user as a participant. Idempotent — calling twice won''t duplicate.';


--
-- Name: check_and_end_expired_recaps(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_and_end_expired_recaps() RETURNS TABLE(event_id uuid, event_name text, participants_notified integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_event_record RECORD;
  v_notification_count integer;
BEGIN
  -- Find and update all expired recaps
  FOR v_event_record IN
    SELECT id, name
    FROM events
    WHERE status = 'recap'
      AND end_datetime IS NOT NULL
      AND (end_datetime + INTERVAL '24 hours') < NOW()
  LOOP
    -- Update status to ended (will trigger handle_event_ended automatically)
    UPDATE events
    SET status = 'ended',
        updated_at = NOW()
    WHERE id = v_event_record.id;

    -- Count notifications that will be created by trigger
    SELECT COUNT(*) INTO v_notification_count
    FROM event_participants
    WHERE pevent_id = v_event_record.id;

    -- Return info about this event
    event_id := v_event_record.id;
    event_name := v_event_record.name;
    participants_notified := v_notification_count;
    
    RETURN NEXT;
    
    RAISE NOTICE 'Ended expired recap for event % (% participants)', v_event_record.name, v_notification_count;
  END LOOP;
END;
$$;


--
-- Name: FUNCTION check_and_end_expired_recaps(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.check_and_end_expired_recaps() IS 'Checks for expired recap periods (end_datetime + 24h < now) and transitions them to ended status. Called by existing edge functions like notify-uploads-closing. Trigger automatically sends notifications.';


--
-- Name: cleanup_expired_notifications(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cleanup_expired_notifications() RETURNS void
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


--
-- Name: create_notification_secure(uuid, text, public.notification_category, public.notification_priority, text, uuid, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_notification_secure(p_recipient_user_id uuid, p_type text, p_category public.notification_category, p_priority public.notification_priority DEFAULT 'medium'::public.notification_priority, p_deeplink text DEFAULT NULL::text, p_event_id uuid DEFAULT NULL::uuid, p_event_emoji text DEFAULT NULL::text, p_user_name text DEFAULT NULL::text, p_event_name text DEFAULT NULL::text, p_hours text DEFAULT NULL::text, p_mins text DEFAULT NULL::text, p_date text DEFAULT NULL::text, p_time text DEFAULT NULL::text, p_place text DEFAULT NULL::text, p_device text DEFAULT NULL::text, p_note text DEFAULT NULL::text) RETURNS uuid
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


--
-- Name: FUNCTION create_notification_secure(p_recipient_user_id uuid, p_type text, p_category public.notification_category, p_priority public.notification_priority, p_deeplink text, p_event_id uuid, p_event_emoji text, p_user_name text, p_event_name text, p_hours text, p_mins text, p_date text, p_time text, p_place text, p_device text, p_note text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.create_notification_secure(p_recipient_user_id uuid, p_type text, p_category public.notification_category, p_priority public.notification_priority, p_deeplink text, p_event_id uuid, p_event_emoji text, p_user_name text, p_event_name text, p_hours text, p_mins text, p_date text, p_time text, p_place text, p_device text, p_note text) IS 'Creates notifications with server-side filtering (quiet hours, category prefs). Push notifications are ephemeral and never downgraded to inbox.';


--
-- Name: create_user_settings_for_new_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_user_settings_for_new_user() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;


--
-- Name: ensure_reviewer_user(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ensure_reviewer_user(p_reviewer_email text, p_reviewer_name text DEFAULT 'Apple Reviewer'::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Check if user already exists in public.users
    SELECT id INTO v_user_id
    FROM public.users
    WHERE email = lower(p_reviewer_email);
    
    IF v_user_id IS NOT NULL THEN
        RETURN v_user_id;
    END IF;
    
    -- Check if exists in auth.users
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE email = lower(p_reviewer_email);
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Reviewer must first be created in auth.users via Supabase Dashboard';
    END IF;
    
    -- Create public.users row
    INSERT INTO public.users (id, email, name)
    VALUES (v_user_id, lower(p_reviewer_email), p_reviewer_name)
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        updated_at = NOW();
    
    RETURN v_user_id;
END;
$$;


--
-- Name: generate_invite_token(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_invite_token(p_bytes integer DEFAULT 18) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare
  raw text;
begin
  -- base64 com ajustes para URL-safe: + -> -, / -> _, remove =
  raw := encode(gen_random_bytes(p_bytes), 'base64');
  raw := replace(raw, '+', '-');
  raw := replace(raw, '/', '_');
  raw := replace(raw, '=', '');
  return raw;
end;
$$;


--
-- Name: generate_url_safe_token(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_url_safe_token() RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..24 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN result;
END;
$$;


--
-- Name: get_event_by_invite_token(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_event_by_invite_token(p_token text) RETURNS TABLE(event_id uuid, event_name text, event_emoji text, event_description text, start_datetime timestamp with time zone, end_datetime timestamp with time zone, location_name text, location_address text, location_lat numeric, location_lng numeric, organizer_name text, organizer_avatar text, status text, participant_count bigint, going_count bigint, guest_going_count bigint, cover_photo_url text)
    LANGUAGE plpgsql SECURITY DEFINER
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


--
-- Name: FUNCTION get_event_by_invite_token(p_token text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.get_event_by_invite_token(p_token text) IS 'Returns event details for the web landing page. Token-gated: no token = no data. Used by Next.js server-side.';


--
-- Name: get_or_create_event_invite_link(uuid, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_or_create_event_invite_link(p_event_id uuid, p_expires_in_hours integer DEFAULT 48, p_share_channel text DEFAULT NULL::text) RETURNS TABLE(token text, expires_at timestamp with time zone, created_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
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


--
-- Name: FUNCTION get_or_create_event_invite_link(p_event_id uuid, p_expires_in_hours integer, p_share_channel text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.get_or_create_event_invite_link(p_event_id uuid, p_expires_in_hours integer, p_share_channel text) IS 'Creates or reuses an event invite link. Returns existing valid token if available, otherwise generates a new one. Only event participants/organizers can create links.';


--
-- Name: get_recent_memories_with_covers(uuid, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_recent_memories_with_covers(p_user_id uuid, p_start_date timestamp with time zone) RETURNS TABLE(id uuid, name text, start_datetime timestamp with time zone, end_datetime timestamp with time zone, display_name text, cover_storage_path text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
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


--
-- Name: FUNCTION get_recent_memories_with_covers(p_user_id uuid, p_start_date timestamp with time zone); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.get_recent_memories_with_covers(p_user_id uuid, p_start_date timestamp with time zone) IS 'Fetches recent memories (ended events) for a user. Lazzo 2.0: no longer group-based, queries by participant membership directly.';


--
-- Name: get_user_memories_with_covers(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_user_memories_with_covers(p_user_id uuid) RETURNS TABLE(id uuid, name text, end_datetime timestamp with time zone, status text, display_name text, cover_storage_path text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
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


--
-- Name: FUNCTION get_user_memories_with_covers(p_user_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.get_user_memories_with_covers(p_user_id uuid) IS 'Fetches all memories for a user with cover photos. Lazzo 2.0: queries by participant membership instead of group membership.';


--
-- Name: handle_event_ended(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_event_ended() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  -- Only trigger if status changed TO 'ended'
  IF NEW.status = 'ended' AND (OLD.status IS DISTINCT FROM 'ended') THEN
    -- Log the transition
    RAISE NOTICE 'Event % transitioned to ended (from %)', NEW.id, OLD.status;
    
    -- Send "Memory Ready" notifications to all participants
    PERFORM notify_memory_ready(NEW.id);
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: FUNCTION handle_event_ended(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.handle_event_ended() IS 'Trigger function that automatically sends "Memory Ready" notifications when an event transitions to ended status (from living/recap). Called by event_status_ended_trigger.';


--
-- Name: handle_new_event(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_event() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
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


--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  INSERT INTO public.users (id, email)
  VALUES (new.id, new.email);
  RETURN new;
END;
$$;


--
-- Name: is_member_of_event(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_member_of_event(eid uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.event_participants
    WHERE pevent_id = eid AND user_id = auth.uid()
  );
$$;


--
-- Name: log_reviewer_access(text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.log_reviewer_access(p_email text, p_action text DEFAULT 'login'::text, p_ip_address text DEFAULT NULL::text, p_user_agent text DEFAULT NULL::text, p_notes text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_session_id UUID;
BEGIN
    INSERT INTO public.reviewer_auth_sessions (
        reviewer_email,
        action,
        ip_address,
        user_agent,
        session_id,
        notes
    ) VALUES (
        p_email,
        p_action,
        p_ip_address,
        p_user_agent,
        auth.uid(),
        p_notes
    )
    RETURNING id INTO v_session_id;
    
    RETURN v_session_id;
END;
$$;


--
-- Name: notify_event_canceled(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_event_canceled() RETURNS trigger
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


--
-- Name: notify_event_confirmed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_event_confirmed() RETURNS trigger
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


--
-- Name: notify_event_date_set(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_event_date_set() RETURNS trigger
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


--
-- Name: notify_event_details_updated(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_event_details_updated() RETURNS trigger
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


--
-- Name: notify_event_ends_soon(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_event_ends_soon() RETURNS void
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


--
-- Name: notify_event_extended(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_event_extended() RETURNS trigger
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


--
-- Name: notify_event_live(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_event_live() RETURNS void
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


--
-- Name: notify_event_location_set(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_event_location_set() RETURNS trigger
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


--
-- Name: notify_event_starts_soon(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_event_starts_soon() RETURNS void
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


--
-- Name: notify_events_ending_soon(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_events_ending_soon() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  event_record RECORD;
  participant_record RECORD;
BEGIN
  -- VALIDAÇÃO: Só processa eventos LIVING que acabam em 10-15 minutos
  FOR event_record IN
    SELECT id, name, emoji, end_datetime
    FROM events
    WHERE status = 'living'  -- ✅ CRÍTICO: Só eventos ao vivo
      AND end_datetime BETWEEN NOW() + INTERVAL '10 minutes' AND NOW() + INTERVAL '15 minutes'
  LOOP
    -- Send to all participants
    FOR participant_record IN
      SELECT user_id 
      FROM event_participants 
      WHERE pevent_id = event_record.id
    LOOP
      PERFORM create_notification_secure(
        p_recipient_user_id := participant_record.user_id,
        p_type := 'eventEndsSoon',
        p_category := 'push',
        p_priority := 'high',
        p_deeplink := 'lazzo://events/' || event_record.id::text,
        p_event_id := event_record.id,
        p_event_name := event_record.name,
        p_event_emoji := event_record.emoji,
        p_mins := '15'
      );
    END LOOP;
  END LOOP;
END;
$$;


--
-- Name: notify_memory_ready(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_memory_ready(p_event_id uuid) RETURNS void
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


--
-- Name: FUNCTION notify_memory_ready(p_event_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.notify_memory_ready(p_event_id uuid) IS 'Sends "Memory Ready" push notifications to all event participants. Only sends if at least 1 photo exists in event_photos. Called by handle_event_ended() trigger.';


--
-- Name: notify_participants_before_delete(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_participants_before_delete() RETURNS trigger
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


--
-- Name: notify_security_new_login(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_security_new_login(p_user_id uuid, p_device text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO notifications (
    recipient_user_id,
    type,
    category,
    priority,
    device,
    deeplink
  )
  VALUES (
    p_user_id,
    'securityNewLogin',
    'push',
    'high',
    p_device,
    'lazzo://profile/security'
  );
END;
$$;


--
-- Name: notify_uploads_closing(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_uploads_closing() RETURNS void
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


--
-- Name: notify_uploads_closing_soon(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_uploads_closing_soon() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  event_record RECORD;
  participant_record RECORD;
  hours_remaining INTEGER;
BEGIN
  -- VALIDAÇÃO: Só processa eventos RECAP com uploads fechando em 55-65 minutos
  FOR event_record IN
    SELECT 
      e.id, 
      e.name, 
      e.emoji, 
      e.end_datetime,
      (e.end_datetime + INTERVAL '24 hours') as close_time
    FROM events e
    WHERE e.status = 'recap'  -- ✅ CRÍTICO: Só eventos em recap
      AND (e.end_datetime + INTERVAL '24 hours') BETWEEN NOW() + INTERVAL '55 minutes' AND NOW() + INTERVAL '65 minutes'
  LOOP
    hours_remaining := 1;
    
    -- Send to all participants
    FOR participant_record IN
      SELECT user_id 
      FROM event_participants 
      WHERE pevent_id = event_record.id
    LOOP
      PERFORM create_notification_secure(
        p_recipient_user_id := participant_record.user_id,
        p_type := 'uploadsClosing',
        p_category := 'push',
        p_priority := 'high',
        p_deeplink := 'lazzo://events/' || event_record.id::text || '/upload',
        p_event_id := event_record.id,
        p_event_name := event_record.name,
        p_event_emoji := event_record.emoji,
        p_hours := hours_remaining::text
      );
    END LOOP;
  END LOOP;
END;
$$;


--
-- Name: notify_uploads_open(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_uploads_open() RETURNS trigger
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


--
-- Name: reset_event_votes_if_expired(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reset_event_votes_if_expired(p_event_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_is_expired BOOLEAN;
BEGIN
  -- Check if event is expired
  SELECT (status = 'pending' AND start_datetime IS NOT NULL AND start_datetime < NOW())
  INTO v_is_expired
  FROM events
  WHERE id = p_event_id;
  
  -- If expired, reset votes
  IF v_is_expired THEN
    UPDATE event_participants
    SET rsvp = 'pending'
    WHERE pevent_id = p_event_id
      AND rsvp != 'pending';
    RETURN TRUE;
  END IF;
  
  RETURN FALSE;
END;
$$;


--
-- Name: reset_expired_event_votes(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reset_expired_event_votes() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  -- Reset RSVP to 'pending' for events that are:
  -- 1. Still in 'pending' status (never confirmed)
  -- 2. Have a start_datetime that has passed
  -- 3. Currently have non-pending votes
  UPDATE event_participants ep
  SET rsvp = 'pending'
  FROM events e
  WHERE ep.pevent_id = e.id
    AND e.status = 'pending'
    AND e.start_datetime IS NOT NULL
    AND e.start_datetime < NOW()
    AND ep.rsvp != 'pending';
    
  -- Log the number of votes reset (optional, for monitoring)
  RAISE NOTICE 'Reset % expired event votes', (SELECT COUNT(*)
    FROM event_participants ep
    JOIN events e ON ep.pevent_id = e.id
    WHERE e.status = 'pending'
      AND e.start_datetime IS NOT NULL
      AND e.start_datetime < NOW()
      AND ep.rsvp != 'pending'
  );
END;
$$;


--
-- Name: FUNCTION reset_expired_event_votes(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.reset_expired_event_votes() IS 'Resets all RSVP votes to pending for events that expired (status=pending + start_datetime passed). 
Run via pg_cron or manually when needed. Safe to run repeatedly (idempotent)';


--
-- Name: revoke_event_invite_link(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.revoke_event_invite_link(p_token text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
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


--
-- Name: revoke_reviewer_access(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.revoke_reviewer_access(p_reviewer_email text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Log revocation
    INSERT INTO public.reviewer_auth_sessions (
        reviewer_email,
        action,
        notes
    ) VALUES (
        p_reviewer_email,
        'access_revoked',
        'Manual revocation by admin'
    );
    
    -- Note: To fully revoke, you must also:
    -- 1. Delete from auth.users via Supabase Dashboard
    -- 2. Or change password via Dashboard
    
    RETURN TRUE;
END;
$$;


--
-- Name: send_event_rsvp_reminders(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.send_event_rsvp_reminders() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  -- Criar notificações para eventos que começam em 25-35 minutos
  -- (janela de 10 min para garantir que não perde o timing)
  INSERT INTO notifications (
    recipient_user_id,
    type,
    category,
    priority,
    event_name,
    event_emoji,
    event_id,
    mins,
    deeplink
  )
  SELECT 
    ep.user_id,                                    -- participantes
    'eventRsvpReminder',                           -- tipo
    'push',                                        -- categoria PUSH (ephemeral)
    'high',                                        -- prioridade
    e.name,                                        -- nome do evento
    e.emoji,                                       -- emoji do evento
    e.id,                                          -- event_id
    EXTRACT(EPOCH FROM (e.start_datetime - NOW())) / 60, -- minutos restantes
    'lazzo://events/' || e.id                     -- deeplink
  FROM events e
  JOIN event_participants ep ON ep.pevent_id = e.id
  WHERE e.start_datetime IS NOT NULL
    AND e.start_datetime > NOW()
    AND e.start_datetime <= NOW() + INTERVAL '35 minutes'
    AND e.start_datetime >= NOW() + INTERVAL '25 minutes'
    AND ep.rsvp = 'pending'                       -- só quem não confirmou
    AND e.status IN ('confirmed', 'planning')     -- eventos ativos
  ON CONFLICT (dedup_key, dedup_bucket) DO NOTHING;
  
END;
$$;


--
-- Name: FUNCTION send_event_rsvp_reminders(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.send_event_rsvp_reminders() IS 'Cron job que envia lembretes 30 mins antes do evento para quem não confirmou RSVP.
Push notification: "Birthday Party starts in 30 min - Please confirm attendance"
Executar a cada 5 minutos.';


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


--
-- Name: should_send_notification(uuid); Type: FUNCTION; Schema: public; Owner: -
--

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


--
-- Name: sync_public_user_from_auth(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_public_user_from_auth() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  meta jsonb;
  v_name text; v_city text; v_bd date; v_notify boolean; v_avatar text;
begin
  begin
    meta     := coalesce(new.raw_user_meta_data, new.user_metadata, '{}'::jsonb);
    v_name   := nullif(coalesce(meta->>'name',meta->>'full_name',meta->>'display_name'),'');
    v_city   := nullif(meta->>'city','');
    v_avatar := nullif(meta->>'avatar_url','');

    begin v_bd := nullif(meta->>'birth_date','')::date; exception when others then v_bd := null; end;
    begin v_notify := coalesce((meta->>'notify_birthday')::boolean,false); exception when others then v_notify := false; end;

    insert into public.users (id, name, email, city, birth_date, notify_birthday, avatar_url)
    values (new.id, v_name, new.email, v_city, v_bd, v_notify, v_avatar)
    on conflict (id) do update
      set email           = excluded.email,
          name            = coalesce(excluded.name, public.users.name),
          city            = coalesce(excluded.city, public.users.city),
          birth_date      = coalesce(excluded.birth_date, public.users.birth_date),
          notify_birthday = coalesce(excluded.notify_birthday, public.users.notify_birthday),
          avatar_url      = coalesce(excluded.avatar_url, public.users.avatar_url);
  exception when others then
    raise warning 'sync_public_user_from_auth failed for % (%): %',
      new.id, new.email, sqlerrm;
  end;
  return new;
end $$;


--
-- Name: trigger_reset_expired_rsvp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trigger_reset_expired_rsvp() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  -- Only run if event is pending and start_datetime just passed
  IF NEW.status = 'pending' 
     AND NEW.start_datetime IS NOT NULL 
     AND NEW.start_datetime < NOW() 
  THEN
    -- Reset RSVPs for this specific event
    UPDATE event_participants
    SET 
      rsvp = 'pending',
      confirmed_at = NULL,
      updated_at = NOW()
    WHERE 
      pevent_id = NEW.id
      AND rsvp != 'pending';
  END IF;
  
  RETURN NEW;
END;
$$;


--
-- Name: trigger_send_push(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trigger_send_push() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  -- Only trigger for 'push' category notifications
  IF NEW.category = 'push' THEN
    -- Call APNs Edge Function asynchronously via pg_net
    -- IMPORTANT: Replace YOUR_SERVICE_ROLE_KEY with actual service role key from Supabase Dashboard
    PERFORM
      net.http_post(
        url := 'https://pgpryaelqhspwhplttzb.supabase.co/functions/v1/send-push-notification-apns',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBncHJ5YWVscWhzcHdocGx0dHpiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzM2NjQzNSwiZXhwIjoyMDY4OTQyNDM1fQ.-FNS3LqPOapG4_yfrJ0jFvnNvOs9ho6asuED7LOJbGs'
        ),
        body := jsonb_build_object('notificationId', NEW.id)
      );
  END IF;
  
  RETURN NEW;
END;
$$;


--
-- Name: update_expired_recaps(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_expired_recaps() RETURNS TABLE(updated_event_id uuid, event_name text, ended_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  updated_count integer := 0;
BEGIN
  -- Update events where:
  -- 1. Status is 'recap'
  -- 2. end_datetime + 24 hours has passed
  UPDATE events
  SET status = 'ended'
  WHERE status = 'recap'
    AND end_datetime IS NOT NULL
    AND (end_datetime + INTERVAL '24 hours') < NOW()
  RETURNING id, name, NOW()
  INTO updated_event_id, event_name, ended_at;

  -- Get count of updated rows
  GET DIAGNOSTICS updated_count = ROW_COUNT;

  -- Log the update (optional - for monitoring)
  RAISE NOTICE 'Auto-ended % recap events that expired', updated_count;

  -- Return updated events for logging/monitoring
  RETURN QUERY
  SELECT id, name, NOW() as ended_at
  FROM events
  WHERE status = 'ended'
    AND end_datetime IS NOT NULL
    AND (end_datetime + INTERVAL '24 hours') < NOW()
    AND updated_at > (NOW() - INTERVAL '1 minute'); -- Only recently updated
END;
$$;


--
-- Name: FUNCTION update_expired_recaps(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.update_expired_recaps() IS 'Automatically transitions events from recap to ended status when recap window (end_datetime + 24h) expires. Called by pg_cron job every 5 minutes.';


--
-- Name: update_problem_reports_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_problem_reports_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


--
-- Name: update_user_settings_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_user_settings_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


--
-- Name: update_user_suggestions_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_user_suggestions_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


--
-- Name: upsert_event_guest_rsvp_by_token(text, text, text, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.upsert_event_guest_rsvp_by_token(p_token text, p_guest_name text, p_rsvp text DEFAULT 'going'::text, p_plus_one integer DEFAULT 0, p_guest_phone text DEFAULT NULL::text) RETURNS TABLE(event_id uuid, event_name text, rsvp_id uuid)
    LANGUAGE plpgsql SECURITY DEFINER
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


--
-- Name: FUNCTION upsert_event_guest_rsvp_by_token(p_token text, p_guest_name text, p_rsvp text, p_plus_one integer, p_guest_phone text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.upsert_event_guest_rsvp_by_token(p_token text, p_guest_name text, p_rsvp text, p_plus_one integer, p_guest_phone text) IS 'Allows non-app guests to RSVP to an event via the web landing page using the invite token.';


--
-- Name: user_exists_by_email(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.user_exists_by_email(p_email text) RETURNS boolean
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1
    from public.users
    where email = lower(p_email)
  );
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: event_guest_rsvps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_guest_rsvps (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid NOT NULL,
    invite_token text NOT NULL,
    guest_name text NOT NULL,
    guest_phone text,
    rsvp text DEFAULT 'going'::text NOT NULL,
    plus_one integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT valid_rsvp CHECK ((rsvp = ANY (ARRAY['going'::text, 'not_going'::text, 'maybe'::text])))
);


--
-- Name: event_invite_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_invite_links (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid NOT NULL,
    created_by uuid NOT NULL,
    token text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    share_channel text,
    open_count integer DEFAULT 0 NOT NULL
);


--
-- Name: event_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_participants (
    pevent_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid DEFAULT auth.uid() NOT NULL,
    rsvp public.rsvp_status DEFAULT 'pending'::public.rsvp_status NOT NULL,
    confirmed_at timestamp with time zone DEFAULT now() NOT NULL,
    notif_time timestamp with time zone
);


--
-- Name: event_participants_summary_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.event_participants_summary_view AS
SELECT
    NULL::uuid AS event_id,
    NULL::text AS event_name,
    NULL::timestamp with time zone AS start_datetime,
    NULL::timestamp with time zone AS end_datetime,
    NULL::uuid AS location_id,
    NULL::uuid AS organizer_id,
    NULL::public.event_state AS event_status,
    NULL::text AS emoji,
    NULL::timestamp with time zone AS created_at,
    NULL::bigint AS participants_total,
    NULL::bigint AS voters_total,
    NULL::bigint AS missing_responses,
    NULL::bigint AS going_count,
    NULL::bigint AS not_going_count,
    NULL::bigint AS maybe_count,
    NULL::uuid[] AS participant_user_ids;


--
-- Name: event_photos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_photos (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    event_id uuid NOT NULL,
    url text NOT NULL,
    storage_path text NOT NULL,
    captured_at timestamp with time zone DEFAULT now() NOT NULL,
    uploader_id uuid NOT NULL,
    is_portrait boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text DEFAULT 'NULL'::text NOT NULL,
    email text NOT NULL,
    birth_date date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    city text,
    "Notify_birthday" boolean DEFAULT false,
    updated_at timestamp with time zone DEFAULT now(),
    avatar_url text
);


--
-- Name: TABLE users; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.users IS 'Table that keeps our Users'' information';


--
-- Name: event_photos_with_uploader; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.event_photos_with_uploader AS
 SELECT ep.id,
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
   FROM (public.event_photos ep
     LEFT JOIN public.users u ON ((ep.uploader_id = u.id)))
  WITH NO DATA;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text,
    start_datetime timestamp with time zone,
    end_datetime timestamp with time zone,
    location_id uuid,
    created_by uuid NOT NULL,
    status public.event_state DEFAULT 'pending'::public.event_state NOT NULL,
    emoji text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    cover_photo_id uuid,
    description text,
    max_participants integer
);


--
-- Name: TABLE events; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.events IS 'Table that holds standalone events';


--
-- Name: locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    display_name text,
    formatted_address text NOT NULL,
    latitude numeric(10,8) NOT NULL,
    longitude numeric(11,8) NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    created_by uuid
);


--
-- Name: home_events_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.home_events_view WITH (security_invoker='on') AS
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


--
-- Name: invite_analytics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invite_analytics (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid NOT NULL,
    invite_token text,
    action text NOT NULL,
    user_id uuid,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    recipient_user_id uuid NOT NULL,
    type text NOT NULL,
    category public.notification_category NOT NULL,
    priority public.notification_priority DEFAULT 'medium'::public.notification_priority NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    action_url text,
    deeplink text,
    event_id uuid,
    event_emoji text,
    user_name text,
    event_name text,
    hours text,
    mins text,
    date text,
    "time" text,
    place text,
    device text,
    note text,
    dedup_bucket timestamp with time zone DEFAULT (date_trunc('minute'::text, now()) + '00:05:00'::interval) NOT NULL
);


--
-- Name: problem_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.problem_reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    category text NOT NULL,
    description text NOT NULL,
    status public.report_status DEFAULT 'pending'::public.report_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT problem_reports_category_check CHECK ((category = ANY (ARRAY['Sign up / Login'::text, 'Create or join event'::text, 'Upload photos & memories'::text, 'Share memories'::text, 'Notifications'::text, 'Other'::text]))),
    CONSTRAINT problem_reports_description_check CHECK (((char_length(description) >= 10) AND (char_length(description) <= 500)))
);


--
-- Name: reviewer_auth_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reviewer_auth_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reviewer_email text NOT NULL,
    login_at timestamp with time zone DEFAULT now(),
    ip_address text,
    user_agent text,
    session_id uuid,
    action text DEFAULT 'login'::text,
    notes text
);


--
-- Name: user_notification_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_notification_settings (
    user_id uuid NOT NULL,
    push_enabled boolean DEFAULT true NOT NULL,
    quiet_hours_enabled boolean DEFAULT false NOT NULL,
    quiet_hours_start time without time zone,
    quiet_hours_end time without time zone,
    push_enabled_for_invites boolean DEFAULT true NOT NULL,
    push_enabled_for_events boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: user_push_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_push_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    device_token text NOT NULL,
    platform text NOT NULL,
    environment text NOT NULL,
    device_name text,
    app_version text,
    is_active boolean DEFAULT true NOT NULL,
    last_used_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT user_push_tokens_environment_check CHECK ((environment = ANY (ARRAY['production'::text, 'sandbox'::text]))),
    CONSTRAINT user_push_tokens_platform_check CHECK ((platform = ANY (ARRAY['ios'::text, 'android'::text])))
);


--
-- Name: user_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_settings (
    user_id uuid NOT NULL,
    notifications_enabled boolean DEFAULT true NOT NULL,
    language text DEFAULT 'en'::text NOT NULL,
    early_access_invites integer DEFAULT 3 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT user_settings_language_check CHECK ((language = ANY (ARRAY['en'::text, 'pt'::text])))
);


--
-- Name: user_suggestions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_suggestions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    description text NOT NULL,
    status public.suggestion_status DEFAULT 'pending'::public.suggestion_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT user_suggestions_description_check CHECK (((char_length(description) >= 10) AND (char_length(description) <= 500)))
);


--
-- Name: event_guest_rsvps event_guest_rsvps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_guest_rsvps
    ADD CONSTRAINT event_guest_rsvps_pkey PRIMARY KEY (id);


--
-- Name: event_invite_links event_invite_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_invite_links
    ADD CONSTRAINT event_invite_links_pkey PRIMARY KEY (id);


--
-- Name: event_participants event_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_participants
    ADD CONSTRAINT event_participants_pkey PRIMARY KEY (pevent_id, user_id);


--
-- Name: event_photos event_photos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_photos
    ADD CONSTRAINT event_photos_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: invite_analytics invite_analytics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invite_analytics
    ADD CONSTRAINT invite_analytics_pkey PRIMARY KEY (id);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: problem_reports problem_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.problem_reports
    ADD CONSTRAINT problem_reports_pkey PRIMARY KEY (id);


--
-- Name: reviewer_auth_sessions reviewer_auth_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviewer_auth_sessions
    ADD CONSTRAINT reviewer_auth_sessions_pkey PRIMARY KEY (id);


--
-- Name: user_push_tokens unique_device_token; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_push_tokens
    ADD CONSTRAINT unique_device_token UNIQUE (device_token, platform);


--
-- Name: user_notification_settings user_notification_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notification_settings
    ADD CONSTRAINT user_notification_settings_pkey PRIMARY KEY (user_id);


--
-- Name: user_push_tokens user_push_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_push_tokens
    ADD CONSTRAINT user_push_tokens_pkey PRIMARY KEY (id);


--
-- Name: user_settings user_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_settings
    ADD CONSTRAINT user_settings_pkey PRIMARY KEY (user_id);


--
-- Name: user_suggestions user_suggestions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_suggestions
    ADD CONSTRAINT user_suggestions_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_phone_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_ep_event; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ep_event ON public.event_participants USING btree (pevent_id);


--
-- Name: idx_ep_event_rsvp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ep_event_rsvp ON public.event_participants USING btree (pevent_id, rsvp);


--
-- Name: idx_ep_event_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ep_event_user ON public.event_participants USING btree (pevent_id, user_id);


--
-- Name: idx_ep_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ep_user ON public.event_participants USING btree (user_id);


--
-- Name: idx_event_guest_rsvps_event; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_event_guest_rsvps_event ON public.event_guest_rsvps USING btree (event_id);


--
-- Name: idx_event_guest_rsvps_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_event_guest_rsvps_token ON public.event_guest_rsvps USING btree (invite_token);


--
-- Name: idx_event_invite_links_event_valid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_event_invite_links_event_valid ON public.event_invite_links USING btree (event_id, expires_at) WHERE (revoked_at IS NULL);


--
-- Name: idx_event_invite_links_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_event_invite_links_token ON public.event_invite_links USING btree (token) WHERE (revoked_at IS NULL);


--
-- Name: idx_event_participants_event; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_event_participants_event ON public.event_participants USING btree (pevent_id);


--
-- Name: idx_event_participants_event_rsvp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_event_participants_event_rsvp ON public.event_participants USING btree (pevent_id, rsvp);


--
-- Name: idx_event_participants_event_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_event_participants_event_user ON public.event_participants USING btree (pevent_id, user_id);


--
-- Name: idx_event_participants_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_event_participants_user ON public.event_participants USING btree (user_id);


--
-- Name: idx_event_photos_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_event_photos_created_at ON public.event_photos USING btree (created_at DESC);


--
-- Name: idx_event_photos_event_captured; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_event_photos_event_captured ON public.event_photos USING btree (event_id, captured_at DESC);


--
-- Name: idx_event_photos_uploader; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_event_photos_uploader ON public.event_photos USING btree (uploader_id);


--
-- Name: idx_event_photos_uploader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_event_photos_uploader_id ON public.event_photos_with_uploader USING btree (id);


--
-- Name: idx_events_cover_photo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_events_cover_photo ON public.events USING btree (cover_photo_id);


--
-- Name: idx_events_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_events_state ON public.events USING btree (status);


--
-- Name: idx_invite_analytics_event; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invite_analytics_event ON public.invite_analytics USING btree (event_id, action);


--
-- Name: idx_invite_analytics_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invite_analytics_token ON public.invite_analytics USING btree (invite_token) WHERE (invite_token IS NOT NULL);


--
-- Name: idx_notifications_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_category ON public.notifications USING btree (recipient_user_id, category, created_at DESC);


--
-- Name: idx_notifications_event; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_event ON public.notifications USING btree (event_id, created_at DESC) WHERE (event_id IS NOT NULL);


--
-- Name: idx_notifications_recipient; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_recipient ON public.notifications USING btree (recipient_user_id, created_at DESC);


--
-- Name: idx_notifications_unread; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_unread ON public.notifications USING btree (recipient_user_id, is_read, created_at DESC) WHERE (is_read = false);


--
-- Name: idx_problem_reports_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_problem_reports_created_at ON public.problem_reports USING btree (created_at DESC);


--
-- Name: idx_problem_reports_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_problem_reports_status ON public.problem_reports USING btree (status);


--
-- Name: idx_problem_reports_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_problem_reports_user_id ON public.problem_reports USING btree (user_id);


--
-- Name: idx_reviewer_sessions_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reviewer_sessions_email ON public.reviewer_auth_sessions USING btree (reviewer_email);


--
-- Name: idx_reviewer_sessions_login_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reviewer_sessions_login_at ON public.reviewer_auth_sessions USING btree (login_at DESC);


--
-- Name: idx_user_push_tokens_last_used; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_push_tokens_last_used ON public.user_push_tokens USING btree (last_used_at) WHERE (is_active = true);


--
-- Name: idx_user_push_tokens_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_push_tokens_user_id ON public.user_push_tokens USING btree (user_id, is_active);


--
-- Name: idx_user_settings_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_settings_user_id ON public.user_settings USING btree (user_id);


--
-- Name: idx_user_suggestions_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_suggestions_created_at ON public.user_suggestions USING btree (created_at DESC);


--
-- Name: idx_user_suggestions_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_suggestions_status ON public.user_suggestions USING btree (status);


--
-- Name: idx_user_suggestions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_suggestions_user_id ON public.user_suggestions USING btree (user_id);


--
-- Name: idx_users_avatar; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_avatar ON public.users USING btree (avatar_url) WHERE (avatar_url IS NOT NULL);


--
-- Name: users_email_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_uidx ON public.users USING btree (lower(email));


--
-- Name: event_participants_summary_view _RETURN; Type: RULE; Schema: public; Owner: -
--

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


--
-- Name: events event_canceled_notification; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER event_canceled_notification BEFORE DELETE ON public.events FOR EACH ROW EXECUTE FUNCTION public.notify_event_canceled();


--
-- Name: events event_confirmed_notification; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER event_confirmed_notification AFTER UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.notify_event_confirmed();


--
-- Name: events event_date_set_notification; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER event_date_set_notification AFTER UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.notify_event_date_set();


--
-- Name: events event_details_updated_notification; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER event_details_updated_notification AFTER UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.notify_event_details_updated();


--
-- Name: events event_extended_notification; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER event_extended_notification AFTER UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.notify_event_extended();


--
-- Name: event_guest_rsvps event_guest_rsvps_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER event_guest_rsvps_updated_at BEFORE UPDATE ON public.event_guest_rsvps FOR EACH ROW EXECUTE FUNCTION public._touch_updated_at();


--
-- Name: events event_location_set_notification; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER event_location_set_notification AFTER UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.notify_event_location_set();


--
-- Name: events event_status_ended_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER event_status_ended_trigger AFTER UPDATE OF status ON public.events FOR EACH ROW WHEN ((new.status = 'ended'::public.event_state)) EXECUTE FUNCTION public.handle_event_ended();


--
-- Name: TRIGGER event_status_ended_trigger ON events; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TRIGGER event_status_ended_trigger ON public.events IS 'Automatically sends "Memory Ready" notifications when event status changes to ended. Handles both manual (host action) and automatic (scheduled) transitions.';


--
-- Name: events notify_before_event_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER notify_before_event_delete BEFORE DELETE ON public.events FOR EACH ROW EXECUTE FUNCTION public.notify_participants_before_delete();


--
-- Name: events on_event_created; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER on_event_created AFTER INSERT ON public.events FOR EACH ROW EXECUTE FUNCTION public.handle_new_event();


--
-- Name: events on_event_update_reset_expired_rsvp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER on_event_update_reset_expired_rsvp AFTER UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.trigger_reset_expired_rsvp();


--
-- Name: notifications on_notification_insert_send_push; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER on_notification_insert_send_push AFTER INSERT ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.trigger_send_push();


--
-- Name: users trigger_create_user_settings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_create_user_settings AFTER INSERT ON public.users FOR EACH ROW EXECUTE FUNCTION public.create_user_settings_for_new_user();


--
-- Name: problem_reports trigger_update_problem_reports_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_problem_reports_updated_at BEFORE UPDATE ON public.problem_reports FOR EACH ROW EXECUTE FUNCTION public.update_problem_reports_updated_at();


--
-- Name: user_settings trigger_update_user_settings_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_user_settings_updated_at BEFORE UPDATE ON public.user_settings FOR EACH ROW EXECUTE FUNCTION public.update_user_settings_updated_at();


--
-- Name: user_suggestions trigger_update_user_suggestions_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_user_suggestions_updated_at BEFORE UPDATE ON public.user_suggestions FOR EACH ROW EXECUTE FUNCTION public.update_user_suggestions_updated_at();


--
-- Name: event_photos update_event_photos_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_event_photos_updated_at BEFORE UPDATE ON public.event_photos FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: events update_events_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: events uploads_open_notification; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER uploads_open_notification AFTER UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.notify_uploads_open();


--
-- Name: users users_touch_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER users_touch_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public._touch_updated_at();


--
-- Name: event_guest_rsvps event_guest_rsvps_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_guest_rsvps
    ADD CONSTRAINT event_guest_rsvps_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: event_invite_links event_invite_links_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_invite_links
    ADD CONSTRAINT event_invite_links_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: event_invite_links event_invite_links_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_invite_links
    ADD CONSTRAINT event_invite_links_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: event_participants event_participants_pevent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_participants
    ADD CONSTRAINT event_participants_pevent_id_fkey FOREIGN KEY (pevent_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: event_participants event_participants_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_participants
    ADD CONSTRAINT event_participants_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: event_photos event_photos_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_photos
    ADD CONSTRAINT event_photos_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: event_photos event_photos_uploader_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_photos
    ADD CONSTRAINT event_photos_uploader_id_fkey FOREIGN KEY (uploader_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: events events_cover_photo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_cover_photo_id_fkey FOREIGN KEY (cover_photo_id) REFERENCES public.event_photos(id);


--
-- Name: events events_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: events events_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id);


--
-- Name: invite_analytics invite_analytics_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invite_analytics
    ADD CONSTRAINT invite_analytics_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: invite_analytics invite_analytics_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invite_analytics
    ADD CONSTRAINT invite_analytics_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: locations locations_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: notifications notifications_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE SET NULL;


--
-- Name: notifications notifications_recipient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_recipient_user_id_fkey FOREIGN KEY (recipient_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: problem_reports problem_reports_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.problem_reports
    ADD CONSTRAINT problem_reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_notification_settings user_notification_settings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notification_settings
    ADD CONSTRAINT user_notification_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_push_tokens user_push_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_push_tokens
    ADD CONSTRAINT user_push_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_settings user_settings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_settings
    ADD CONSTRAINT user_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_suggestions user_suggestions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_suggestions
    ADD CONSTRAINT user_suggestions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: invite_analytics Analytics insertable by anyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Analytics insertable by anyone" ON public.invite_analytics FOR INSERT WITH CHECK (true);


--
-- Name: users Enable insert for authenticated users only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable insert for authenticated users only" ON public.users FOR INSERT WITH CHECK ((auth.uid() = id));


--
-- Name: users Enable read access for own user; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for own user" ON public.users FOR SELECT USING ((auth.uid() = id));


--
-- Name: event_photos Event creator can manage all photos; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Event creator can manage all photos" ON public.event_photos FOR DELETE TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.events e
  WHERE ((e.id = event_photos.event_id) AND (e.created_by = auth.uid())))));


--
-- Name: events Event creator or admin can delete events; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Event creator or admin can delete events" ON public.events FOR DELETE TO authenticated USING ((created_by = auth.uid()));


--
-- Name: event_invite_links Event members can create invite links; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Event members can create invite links" ON public.event_invite_links FOR INSERT WITH CHECK (((created_by = auth.uid()) AND ((EXISTS ( SELECT 1
   FROM public.event_participants ep
  WHERE ((ep.pevent_id = event_invite_links.event_id) AND (ep.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
   FROM public.events e
  WHERE ((e.id = event_invite_links.event_id) AND (e.created_by = auth.uid())))))));


--
-- Name: invite_analytics Event organizer can view analytics; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Event organizer can view analytics" ON public.invite_analytics FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.events e
  WHERE ((e.id = invite_analytics.event_id) AND (e.created_by = auth.uid())))));


--
-- Name: events Event participants can update event cover; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Event participants can update event cover" ON public.events FOR UPDATE TO authenticated USING (((created_by = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.event_participants ep
  WHERE ((ep.pevent_id = events.id) AND (ep.user_id = auth.uid())))))) WITH CHECK (((created_by = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.event_participants ep
  WHERE ((ep.pevent_id = events.id) AND (ep.user_id = auth.uid()))))));


--
-- Name: event_photos Event participants can upload photos; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Event participants can upload photos" ON public.event_photos FOR INSERT TO authenticated WITH CHECK (((uploader_id = auth.uid()) AND ((EXISTS ( SELECT 1
   FROM public.event_participants ep
  WHERE ((ep.pevent_id = event_photos.event_id) AND (ep.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
   FROM public.events e
  WHERE ((e.id = event_photos.event_id) AND (e.created_by = auth.uid())))))));


--
-- Name: events Event participants can view events; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Event participants can view events" ON public.events FOR SELECT TO authenticated USING (((created_by = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.event_participants ep
  WHERE ((ep.pevent_id = events.id) AND (ep.user_id = auth.uid()))))));


--
-- Name: event_guest_rsvps Event participants can view guest RSVPs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Event participants can view guest RSVPs" ON public.event_guest_rsvps FOR SELECT USING (((EXISTS ( SELECT 1
   FROM public.event_participants ep
  WHERE ((ep.pevent_id = event_guest_rsvps.event_id) AND (ep.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
   FROM public.events e
  WHERE ((e.id = event_guest_rsvps.event_id) AND (e.created_by = auth.uid()))))));


--
-- Name: event_invite_links Event participants can view invite links; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Event participants can view invite links" ON public.event_invite_links FOR SELECT USING (((EXISTS ( SELECT 1
   FROM public.event_participants ep
  WHERE ((ep.pevent_id = event_invite_links.event_id) AND (ep.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
   FROM public.events e
  WHERE ((e.id = event_invite_links.event_id) AND (e.created_by = auth.uid()))))));


--
-- Name: event_photos Event participants can view photos; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Event participants can view photos" ON public.event_photos FOR SELECT TO authenticated USING (((EXISTS ( SELECT 1
   FROM public.event_participants ep
  WHERE ((ep.pevent_id = event_photos.event_id) AND (ep.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
   FROM public.events e
  WHERE ((e.id = event_photos.event_id) AND (e.created_by = auth.uid()))))));


--
-- Name: notifications Service role can insert notifications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role can insert notifications" ON public.notifications FOR INSERT WITH CHECK (((auth.role() = 'service_role'::text) OR (current_setting('role'::text, true) = 'service_role'::text)));


--
-- Name: user_push_tokens Service role full access to push tokens; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role full access to push tokens" ON public.user_push_tokens USING (((auth.jwt() ->> 'role'::text) = 'service_role'::text));


--
-- Name: event_guest_rsvps Service role manages guest RSVPs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role manages guest RSVPs" ON public.event_guest_rsvps USING (true) WITH CHECK (true);


--
-- Name: reviewer_auth_sessions Service role only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role only" ON public.reviewer_auth_sessions USING (false);


--
-- Name: event_photos Users can delete own event photos; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete own event photos" ON public.event_photos FOR DELETE TO authenticated USING ((uploader_id = auth.uid()));


--
-- Name: notifications Users can delete own notifications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete own notifications" ON public.notifications FOR DELETE USING ((auth.uid() = recipient_user_id));


--
-- Name: user_push_tokens Users can delete own push tokens; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete own push tokens" ON public.user_push_tokens FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: user_settings Users can delete own settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete own settings" ON public.user_settings FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: events Users can delete their own events; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete their own events" ON public.events FOR DELETE USING ((created_by = auth.uid()));


--
-- Name: event_participants Users can insert own RSVP; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own RSVP" ON public.event_participants FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()));


--
-- Name: user_push_tokens Users can insert own push tokens; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own push tokens" ON public.user_push_tokens FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: problem_reports Users can insert own reports; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own reports" ON public.problem_reports FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_notification_settings Users can insert own settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own settings" ON public.user_notification_settings FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_settings Users can insert own settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own settings" ON public.user_settings FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_suggestions Users can insert own suggestions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own suggestions" ON public.user_suggestions FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: notifications Users can mark own notifications as read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can mark own notifications as read" ON public.notifications FOR UPDATE USING ((auth.uid() = recipient_user_id)) WITH CHECK ((auth.uid() = recipient_user_id));


--
-- Name: users Users can read avatar_url; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read avatar_url" ON public.users FOR SELECT TO authenticated USING (true);


--
-- Name: locations Users can read locations of their events; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read locations of their events" ON public.locations FOR SELECT TO authenticated USING ((id IN ( SELECT DISTINCT e.location_id
   FROM (public.events e
     JOIN public.event_participants ep ON ((e.id = ep.pevent_id)))
  WHERE (ep.user_id = auth.uid()))));


--
-- Name: problem_reports Users can read own reports; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read own reports" ON public.problem_reports FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: user_settings Users can read own settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read own settings" ON public.user_settings FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: user_suggestions Users can read own suggestions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read own suggestions" ON public.user_suggestions FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: users Users can read user profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read user profiles" ON public.users FOR SELECT TO authenticated USING (true);


--
-- Name: event_participants Users can update own RSVP; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own RSVP" ON public.event_participants FOR UPDATE TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));


--
-- Name: event_photos Users can update own event photos; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own event photos" ON public.event_photos FOR UPDATE TO authenticated USING ((uploader_id = auth.uid())) WITH CHECK ((uploader_id = auth.uid()));


--
-- Name: user_push_tokens Users can update own push tokens; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own push tokens" ON public.user_push_tokens FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: user_notification_settings Users can update own settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own settings" ON public.user_notification_settings FOR UPDATE USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_settings Users can update own settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own settings" ON public.user_settings FOR UPDATE USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: events Users can update their own events; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own events" ON public.events FOR UPDATE USING ((created_by = auth.uid())) WITH CHECK ((created_by = auth.uid()));


--
-- Name: users Users can update their own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own profile" ON public.users FOR UPDATE USING ((auth.uid() = id)) WITH CHECK ((auth.uid() = id));


--
-- Name: locations Users can view locations for their events; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view locations for their events" ON public.locations FOR SELECT TO authenticated USING (((id IN ( SELECT DISTINCT e.location_id
   FROM (public.events e
     JOIN public.event_participants ep ON ((e.id = ep.pevent_id)))
  WHERE (ep.user_id = auth.uid()))) OR (created_by = auth.uid())));


--
-- Name: users Users can view other profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view other profiles" ON public.users FOR SELECT USING (true);


--
-- Name: notifications Users can view own notifications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING ((auth.uid() = recipient_user_id));


--
-- Name: user_push_tokens Users can view own push tokens; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own push tokens" ON public.user_push_tokens FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: user_notification_settings Users can view own settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own settings" ON public.user_notification_settings FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: event_participants ep_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY ep_delete ON public.event_participants FOR DELETE USING ((user_id = auth.uid()));


--
-- Name: event_participants ep_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY ep_select ON public.event_participants FOR SELECT USING (public.is_member_of_event(pevent_id));


--
-- Name: event_guest_rsvps; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.event_guest_rsvps ENABLE ROW LEVEL SECURITY;

--
-- Name: event_invite_links; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.event_invite_links ENABLE ROW LEVEL SECURITY;

--
-- Name: event_participants; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.event_participants ENABLE ROW LEVEL SECURITY;

--
-- Name: event_photos; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.event_photos ENABLE ROW LEVEL SECURITY;

--
-- Name: events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

--
-- Name: events events_insert_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY events_insert_own ON public.events FOR INSERT WITH CHECK ((created_by = auth.uid()));


--
-- Name: events events_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY events_select_own ON public.events FOR SELECT USING ((created_by = auth.uid()));


--
-- Name: invite_analytics; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.invite_analytics ENABLE ROW LEVEL SECURITY;

--
-- Name: locations loc_delete_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY loc_delete_own ON public.locations FOR DELETE USING ((created_by = auth.uid()));


--
-- Name: locations loc_insert_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY loc_insert_own ON public.locations FOR INSERT WITH CHECK ((created_by = auth.uid()));


--
-- Name: locations loc_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY loc_select_own ON public.locations FOR SELECT USING ((created_by = auth.uid()));


--
-- Name: locations loc_update_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY loc_update_own ON public.locations FOR UPDATE USING ((created_by = auth.uid())) WITH CHECK ((created_by = auth.uid()));


--
-- Name: locations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;

--
-- Name: notifications; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

--
-- Name: problem_reports; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.problem_reports ENABLE ROW LEVEL SECURITY;

--
-- Name: reviewer_auth_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.reviewer_auth_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: user_notification_settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: user_push_tokens; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_push_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: user_settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: user_suggestions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_suggestions ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

--
-- Name: users users_can_view_avatars_of_event_participants; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY users_can_view_avatars_of_event_participants ON public.users FOR SELECT TO authenticated USING (((auth.uid() = id) OR (id IN ( SELECT DISTINCT ep2.user_id
   FROM (public.event_participants ep1
     JOIN public.event_participants ep2 ON ((ep1.pevent_id = ep2.pevent_id)))
  WHERE (ep1.user_id = auth.uid())))));


--
-- PostgreSQL database dump complete
--

\unrestrict ddlLiktetbXH0oVF3N0Ho84yXUQetLy5t8HgO0a3HvWUrtJSTAEdPxXIdjEKEte

