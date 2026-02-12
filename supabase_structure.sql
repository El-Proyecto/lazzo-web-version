-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.chat_active_users (
  event_id uuid NOT NULL,
  user_id uuid NOT NULL,
  last_seen timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT chat_active_users_pkey PRIMARY KEY (event_id, user_id),
  CONSTRAINT chat_active_users_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id),
  CONSTRAINT chat_active_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.event_date_options (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL,
  starts_at timestamp with time zone NOT NULL,
  ends_at timestamp with time zone NOT NULL,
  created_by uuid,
  created_at timestamp with time zone DEFAULT now(),
  is_initial boolean DEFAULT false,
  CONSTRAINT event_date_options_pkey PRIMARY KEY (id),
  CONSTRAINT event_date_options_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id),
  CONSTRAINT event_date_options_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id)
);
CREATE TABLE public.event_date_votes (
  option_id uuid NOT NULL,
  user_id uuid NOT NULL DEFAULT auth.uid(),
  voted_at timestamp with time zone DEFAULT now(),
  event_id uuid NOT NULL,
  CONSTRAINT event_date_votes_pkey PRIMARY KEY (option_id, user_id),
  CONSTRAINT event_date_votes_option_id_fkey FOREIGN KEY (option_id) REFERENCES public.event_date_options(id),
  CONSTRAINT event_date_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.event_expenses (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  event_id uuid NOT NULL,
  title text NOT NULL,
  total_amount numeric NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  created_by uuid,
  paid_by uuid NOT NULL,
  CONSTRAINT event_expenses_pkey PRIMARY KEY (id),
  CONSTRAINT event_expenses_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id),
  CONSTRAINT event_expenses_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id),
  CONSTRAINT event_expenses_paid_by_fkey FOREIGN KEY (paid_by) REFERENCES public.users(id)
);
CREATE TABLE public.event_guest_rsvps (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL,
  invite_token text NOT NULL,
  guest_name text NOT NULL,
  guest_phone text,
  rsvp text NOT NULL DEFAULT 'going'::text CHECK (rsvp = ANY (ARRAY['going'::text, 'not_going'::text, 'maybe'::text])),
  plus_one integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT event_guest_rsvps_pkey PRIMARY KEY (id),
  CONSTRAINT event_guest_rsvps_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id)
);
CREATE TABLE public.event_invite_links (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL,
  created_by uuid NOT NULL,
  token text NOT NULL,
  expires_at timestamp with time zone NOT NULL,
  revoked_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  share_channel text,
  open_count integer NOT NULL DEFAULT 0,
  CONSTRAINT event_invite_links_pkey PRIMARY KEY (id),
  CONSTRAINT event_invite_links_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id),
  CONSTRAINT event_invite_links_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.event_participants (
  pevent_id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid(),
  rsvp USER-DEFINED NOT NULL DEFAULT 'pending'::rsvp_status,
  confirmed_at timestamp with time zone NOT NULL DEFAULT now(),
  notif_time timestamp with time zone,
  CONSTRAINT event_participants_pkey PRIMARY KEY (pevent_id, user_id),
  CONSTRAINT event_participants_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT event_participants_pevent_id_fkey FOREIGN KEY (pevent_id) REFERENCES public.events(id)
);
CREATE TABLE public.event_photos (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  event_id uuid NOT NULL,
  url text NOT NULL,
  storage_path text NOT NULL,
  captured_at timestamp with time zone NOT NULL DEFAULT now(),
  uploader_id uuid NOT NULL,
  is_portrait boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT event_photos_pkey PRIMARY KEY (id),
  CONSTRAINT event_photos_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id),
  CONSTRAINT event_photos_uploader_id_fkey FOREIGN KEY (uploader_id) REFERENCES public.users(id)
);
CREATE TABLE public.events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text,
  start_datetime timestamp with time zone,
  end_datetime timestamp with time zone,
  location_id uuid,
  created_by uuid NOT NULL,
  status USER-DEFINED NOT NULL DEFAULT 'pending'::event_state,
  emoji text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  cover_photo_id uuid,
  description text,
  max_participants integer,
  CONSTRAINT events_pkey PRIMARY KEY (id),
  CONSTRAINT events_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id),
  CONSTRAINT events_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id),
  CONSTRAINT events_cover_photo_id_fkey FOREIGN KEY (cover_photo_id) REFERENCES public.event_photos(id)
);
CREATE TABLE public.expense_splits (
  expense_id uuid NOT NULL,
  user_id uuid NOT NULL,
  amount numeric NOT NULL,
  has_paid boolean DEFAULT false,
  CONSTRAINT expense_splits_pkey PRIMARY KEY (expense_id, user_id),
  CONSTRAINT expense_splits_expense_id_fkey FOREIGN KEY (expense_id) REFERENCES public.event_expenses(id),
  CONSTRAINT expense_splits_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.invite_analytics (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL,
  invite_token text,
  action text NOT NULL,
  user_id uuid,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT invite_analytics_pkey PRIMARY KEY (id),
  CONSTRAINT invite_analytics_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id),
  CONSTRAINT invite_analytics_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.location_suggestion_votes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  suggestion_id uuid NOT NULL,
  user_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT location_suggestion_votes_pkey PRIMARY KEY (id),
  CONSTRAINT location_suggestion_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT location_suggestion_votes_suggestion_id_fkey FOREIGN KEY (suggestion_id) REFERENCES public.location_suggestions(id)
);
CREATE TABLE public.location_suggestions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL,
  user_id uuid NOT NULL,
  location_name text NOT NULL,
  address text,
  latitude double precision,
  longitude double precision,
  created_at timestamp with time zone DEFAULT now(),
  is_initial boolean DEFAULT false,
  CONSTRAINT location_suggestions_pkey PRIMARY KEY (id),
  CONSTRAINT location_suggestions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT location_suggestions_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id)
);
CREATE TABLE public.locations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  display_name text,
  formatted_address text NOT NULL,
  latitude numeric NOT NULL,
  longitude numeric NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  created_by uuid,
  CONSTRAINT locations_pkey PRIMARY KEY (id),
  CONSTRAINT locations_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.memories (
  mem_id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  photo_id uuid NOT NULL,
  mem_title text NOT NULL,
  mem_location text NOT NULL,
  mem_date text NOT NULL,
  visibility boolean NOT NULL DEFAULT false,
  CONSTRAINT memories_pkey PRIMARY KEY (mem_id),
  CONSTRAINT memories_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT memories_photo_id_fkey FOREIGN KEY (photo_id) REFERENCES public.photos(photo_id)
);
CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  recipient_user_id uuid NOT NULL,
  type text NOT NULL,
  category USER-DEFINED NOT NULL,
  priority USER-DEFINED NOT NULL DEFAULT 'medium'::notification_priority,
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  action_url text,
  deeplink text,
  event_id uuid,
  event_emoji text,
  user_name text,
  event_name text,
  amount text,
  hours text,
  mins text,
  date text,
  time text,
  place text,
  device text,
  note text,
  dedup_bucket timestamp with time zone NOT NULL DEFAULT (date_trunc('minute'::text, now()) + '00:05:00'::interval),
  expense_id uuid,
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_recipient_user_id_fkey FOREIGN KEY (recipient_user_id) REFERENCES public.users(id),
  CONSTRAINT notifications_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id),
  CONSTRAINT notifications_expense_id_fkey FOREIGN KEY (expense_id) REFERENCES public.event_expenses(id)
);
CREATE TABLE public.photos (
  photo_id uuid NOT NULL DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL UNIQUE,
  uploaded_by uuid NOT NULL UNIQUE,
  storage_path text NOT NULL UNIQUE,
  width bigint,
  height bigint,
  date text NOT NULL,
  CONSTRAINT photos_pkey PRIMARY KEY (photo_id),
  CONSTRAINT photos_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(id),
  CONSTRAINT photos_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id)
);
CREATE TABLE public.problem_reports (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  category text NOT NULL CHECK (category = ANY (ARRAY['Sign up / Login'::text, 'Create or join event'::text, 'Upload photos & memories'::text, 'Share memories'::text, 'Payments & expenses'::text, 'Notifications'::text, 'Other'::text])),
  description text NOT NULL CHECK (char_length(description) >= 10 AND char_length(description) <= 500),
  status USER-DEFINED NOT NULL DEFAULT 'pending'::report_status,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT problem_reports_pkey PRIMARY KEY (id),
  CONSTRAINT problem_reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.push_tokens (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  token text NOT NULL,
  platform text NOT NULL CHECK (platform = ANY (ARRAY['ios'::text, 'android'::text, 'web'::text])),
  device_name text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  last_used_at timestamp with time zone,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT push_tokens_pkey PRIMARY KEY (id),
  CONSTRAINT push_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.reviewer_auth_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  reviewer_email text NOT NULL,
  login_at timestamp with time zone DEFAULT now(),
  ip_address text,
  user_agent text,
  session_id uuid,
  action text DEFAULT 'login'::text,
  notes text,
  CONSTRAINT reviewer_auth_sessions_pkey PRIMARY KEY (id)
);
CREATE TABLE public.user_notification_settings (
  user_id uuid NOT NULL,
  push_enabled boolean NOT NULL DEFAULT true,
  quiet_hours_enabled boolean NOT NULL DEFAULT false,
  quiet_hours_start time without time zone,
  quiet_hours_end time without time zone,
  push_enabled_for_invites boolean NOT NULL DEFAULT true,
  push_enabled_for_events boolean NOT NULL DEFAULT true,
  push_enabled_for_payments boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_notification_settings_pkey PRIMARY KEY (user_id),
  CONSTRAINT user_notification_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.user_push_tokens (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  device_token text NOT NULL,
  platform text NOT NULL CHECK (platform = ANY (ARRAY['ios'::text, 'android'::text])),
  environment text NOT NULL CHECK (environment = ANY (ARRAY['production'::text, 'sandbox'::text])),
  device_name text,
  app_version text,
  is_active boolean NOT NULL DEFAULT true,
  last_used_at timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_push_tokens_pkey PRIMARY KEY (id),
  CONSTRAINT user_push_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.user_settings (
  user_id uuid NOT NULL,
  notifications_enabled boolean NOT NULL DEFAULT true,
  language text NOT NULL DEFAULT 'en'::text CHECK (language = ANY (ARRAY['en'::text, 'pt'::text])),
  early_access_invites integer NOT NULL DEFAULT 3,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_settings_pkey PRIMARY KEY (user_id),
  CONSTRAINT user_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.user_suggestions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  description text NOT NULL CHECK (char_length(description) >= 10 AND char_length(description) <= 500),
  status USER-DEFINED NOT NULL DEFAULT 'pending'::suggestion_status,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_suggestions_pkey PRIMARY KEY (id),
  CONSTRAINT user_suggestions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.users (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL DEFAULT 'NULL'::text,
  email text NOT NULL UNIQUE,
  birth_date date,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  city text,
  Notify_birthday boolean DEFAULT false,
  updated_at timestamp with time zone DEFAULT now(),
  avatar_url text,
  CONSTRAINT users_pkey PRIMARY KEY (id)
);