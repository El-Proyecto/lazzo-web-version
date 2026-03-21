-- Harden guest RSVP writes: require authenticated email to match payload email.
-- This prevents bypassing OTP by calling the RPC directly with arbitrary emails.

create or replace function public.upsert_event_guest_rsvp_by_token(
  p_token text,
  p_guest_name text,
  p_rsvp text default 'going',
  p_plus_one integer default 0,
  p_guest_phone text default null
)
returns table(event_id uuid, event_name text, rsvp_id uuid)
language plpgsql
security definer
as $$
#variable_conflict use_column
declare
  v_event_id uuid;
  v_event_name text;
  v_rsvp_id uuid;
  v_auth_email text;
begin
  -- Validate token
  select eil.event_id into v_event_id
  from public.event_invite_links eil
  where eil.token = p_token
    and eil.revoked_at is null
    and eil.expires_at > now();

  if v_event_id is null then
    raise exception 'Invalid or expired invite link';
  end if;

  -- When an email is provided, require a matching authenticated email.
  if coalesce(trim(p_guest_phone), '') <> '' then
    if auth.uid() is null then
      raise exception 'Authentication required to RSVP with email';
    end if;

    v_auth_email := lower(coalesce(auth.jwt() ->> 'email', ''));
    if v_auth_email = '' or v_auth_email <> lower(trim(p_guest_phone)) then
      raise exception 'Authenticated email does not match RSVP email';
    end if;
  end if;

  -- Get event name
  select e.name into v_event_name
  from public.events e
  where e.event_id = v_event_id;

  -- Upsert RSVP by (event_id, guest_phone) when email provided, otherwise insert
  if p_guest_phone is not null and p_guest_phone <> '' then
    insert into public.event_guest_rsvps (event_id, invite_token, guest_name, rsvp, plus_one, guest_phone)
    values (v_event_id, p_token, p_guest_name, p_rsvp, p_plus_one, p_guest_phone)
    on conflict (event_id, guest_phone)
    do update set
      guest_name = excluded.guest_name,
      rsvp = excluded.rsvp,
      plus_one = excluded.plus_one,
      invite_token = excluded.invite_token,
      updated_at = now()
    returning id into v_rsvp_id;
  else
    insert into public.event_guest_rsvps (event_id, invite_token, guest_name, rsvp, plus_one, guest_phone)
    values (v_event_id, p_token, p_guest_name, p_rsvp, p_plus_one, p_guest_phone)
    returning id into v_rsvp_id;
  end if;

  -- Track analytics
  insert into public.invite_analytics (event_id, invite_token, action, metadata)
  values (v_event_id, p_token, 'rsvp_web', jsonb_build_object('guest_name', p_guest_name, 'rsvp', p_rsvp));

  return query select v_event_id, v_event_name, v_rsvp_id;
end;
$$;
