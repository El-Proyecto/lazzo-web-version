-- Refresh event phase when opening invite link (align with Edge Function transition-event-phases).
-- Harden RSVP: only pending/confirmed may vote.

CREATE OR REPLACE FUNCTION public.refresh_event_automatic_phases_for_event(p_event_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_start timestamptz;
  v_end timestamptz;
  v_status public.event_state;
  v_now timestamptz := now();
  v_i integer := 0;
BEGIN
  <<phase_loop>>
  LOOP
    v_i := v_i + 1;
    EXIT phase_loop WHEN v_i > 8;

    SELECT e.start_datetime, e.end_datetime, e.status
    INTO v_start, v_end, v_status
    FROM public.events e
    WHERE e.id = p_event_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RETURN;
    END IF;

    IF v_status = 'pending'::public.event_state THEN
      IF v_start IS NOT NULL AND v_start <= v_now THEN
        UPDATE public.events
        SET status = 'expired'::public.event_state, updated_at = v_now
        WHERE id = p_event_id AND status = 'pending'::public.event_state;
      END IF;
      EXIT phase_loop;

    ELSIF v_status = 'confirmed'::public.event_state THEN
      IF v_start IS NOT NULL AND v_start <= v_now THEN
        UPDATE public.events
        SET status = 'living'::public.event_state, updated_at = v_now
        WHERE id = p_event_id AND status = 'confirmed'::public.event_state;
        CONTINUE;
      END IF;
      EXIT phase_loop;

    ELSIF v_status = 'living'::public.event_state THEN
      IF v_end IS NOT NULL AND v_end <= v_now THEN
        UPDATE public.events
        SET status = 'recap'::public.event_state, updated_at = v_now
        WHERE id = p_event_id AND status = 'living'::public.event_state;
        CONTINUE;
      END IF;
      EXIT phase_loop;

    ELSIF v_status = 'recap'::public.event_state THEN
      IF v_end IS NOT NULL AND v_end <= v_now - interval '24 hours' THEN
        UPDATE public.events
        SET status = 'ended'::public.event_state, updated_at = v_now
        WHERE id = p_event_id AND status = 'recap'::public.event_state;
      END IF;
      EXIT phase_loop;

    ELSE
      EXIT phase_loop;
    END IF;
  END LOOP phase_loop;
END;
$$;

COMMENT ON FUNCTION public.refresh_event_automatic_phases_for_event(uuid) IS
  'Applies automatic event_state transitions for one event (pending→expired, confirmed→living, living→recap, recap→ended). Matches Edge Function transition-event-phases.';

CREATE OR REPLACE FUNCTION public.get_event_by_invite_token(p_token text)
RETURNS TABLE(
  event_id uuid,
  event_name text,
  event_emoji text,
  event_description text,
  start_datetime timestamp with time zone,
  end_datetime timestamp with time zone,
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
SET search_path = public
AS $$
DECLARE
  v_event_id uuid;
BEGIN
  SELECT eil.event_id INTO v_event_id
  FROM public.event_invite_links eil
  WHERE eil.token = p_token
    AND eil.revoked_at IS NULL
    AND eil.expires_at > now();

  IF v_event_id IS NULL THEN
    RAISE EXCEPTION 'Invalid or expired invite link';
  END IF;

  PERFORM public.refresh_event_automatic_phases_for_event(v_event_id);

  INSERT INTO public.invite_analytics (event_id, invite_token, action)
  VALUES (v_event_id, p_token, 'link_opened_web');

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
    (SELECT count(*) FROM public.event_participants ep WHERE ep.pevent_id = e.id AND ep.rsvp = 'yes'::public.rsvp_status)::bigint AS going_count,
    (SELECT count(*) FROM public.event_guest_rsvps gr WHERE gr.event_id = e.id AND gr.rsvp = 'going')::bigint AS guest_going_count,
    ep_cover.url AS cover_photo_url
  FROM public.events e
  LEFT JOIN public.locations l ON l.id = e.location_id
  LEFT JOIN public.users u ON u.id = e.created_by
  LEFT JOIN public.event_photos ep_cover ON ep_cover.id = e.cover_photo_id
  WHERE e.id = v_event_id;
END;
$$;

COMMENT ON FUNCTION public.get_event_by_invite_token(text) IS
  'Returns event details for the web landing page. Token-gated: no token = no data. Refreshes automatic phase transitions before returning. Used by Next.js server-side and client polling.';

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
SET search_path = public
AS $$
#variable_conflict use_column
DECLARE
  v_event_id uuid;
  v_event_name text;
  v_rsvp_id uuid;
  v_auth_email text;
  v_event_status public.event_state;
BEGIN
  SELECT eil.event_id INTO v_event_id
  FROM public.event_invite_links eil
  WHERE eil.token = p_token
    AND eil.revoked_at IS NULL
    AND eil.expires_at > now();

  IF v_event_id IS NULL THEN
    RAISE EXCEPTION 'Invalid or expired invite link';
  END IF;

  PERFORM public.refresh_event_automatic_phases_for_event(v_event_id);

  SELECT e.status INTO v_event_status
  FROM public.events e
  WHERE e.id = v_event_id;

  IF v_event_status NOT IN ('pending'::public.event_state, 'confirmed'::public.event_state) THEN
    RAISE EXCEPTION 'Voting is closed for this event';
  END IF;

  IF coalesce(trim(p_guest_phone), '') <> '' THEN
    IF auth.uid() IS NULL THEN
      RAISE EXCEPTION 'Authentication required to RSVP with email';
    END IF;

    v_auth_email := lower(coalesce(auth.jwt() ->> 'email', ''));
    IF v_auth_email = '' OR v_auth_email <> lower(trim(p_guest_phone)) THEN
      RAISE EXCEPTION 'Authenticated email does not match RSVP email';
    END IF;
  END IF;

  SELECT e.name INTO v_event_name
  FROM public.events e
  WHERE e.id = v_event_id;

  IF p_guest_phone IS NOT NULL AND p_guest_phone <> '' THEN
    INSERT INTO public.event_guest_rsvps (event_id, invite_token, guest_name, rsvp, plus_one, guest_phone)
    VALUES (v_event_id, p_token, p_guest_name, p_rsvp, p_plus_one, p_guest_phone)
    ON CONFLICT (event_id, guest_phone)
    DO UPDATE SET
      guest_name = excluded.guest_name,
      rsvp = excluded.rsvp,
      plus_one = excluded.plus_one,
      invite_token = excluded.invite_token,
      updated_at = now()
    RETURNING id INTO v_rsvp_id;
  ELSE
    INSERT INTO public.event_guest_rsvps (event_id, invite_token, guest_name, rsvp, plus_one, guest_phone)
    VALUES (v_event_id, p_token, p_guest_name, p_rsvp, p_plus_one, p_guest_phone)
    RETURNING id INTO v_rsvp_id;
  END IF;

  INSERT INTO public.invite_analytics (event_id, invite_token, action, metadata)
  VALUES (v_event_id, p_token, 'rsvp_web', jsonb_build_object('guest_name', p_guest_name, 'rsvp', p_rsvp));

  RETURN QUERY SELECT v_event_id, v_event_name, v_rsvp_id;
END;
$$;

COMMENT ON FUNCTION public.upsert_event_guest_rsvp_by_token(text, text, text, integer, text) IS
  'Allows non-app guests to RSVP via the web landing page while event is pending or confirmed. Deduplicates by (event_id, guest_phone/email) when email is provided.';
