-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.chat_messages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL,
  user_id uuid NOT NULL,
  content text NOT NULL,
  read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  is_pinned boolean DEFAULT false,
  is_deleted boolean DEFAULT false,
  reply_to_id uuid,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT chat_messages_pkey PRIMARY KEY (id),
  CONSTRAINT chat_messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT chat_messages_reply_to_id_fkey FOREIGN KEY (reply_to_id) REFERENCES public.chat_messages(id),
  CONSTRAINT chat_messages_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id)
);
CREATE TABLE public.event_date_options (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL,
  starts_at timestamp with time zone NOT NULL,
  ends_at timestamp with time zone NOT NULL,
  created_by uuid,
  created_at timestamp with time zone DEFAULT now(),
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
  CONSTRAINT edv_option_same_event FOREIGN KEY (option_id) REFERENCES public.event_date_options(id),
  CONSTRAINT edv_option_same_event FOREIGN KEY (event_id) REFERENCES public.event_date_options(id),
  CONSTRAINT edv_option_same_event FOREIGN KEY (option_id) REFERENCES public.event_date_options(event_id),
  CONSTRAINT edv_option_same_event FOREIGN KEY (event_id) REFERENCES public.event_date_options(event_id),
  CONSTRAINT event_date_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.event_expenses (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  event_id uuid NOT NULL,
  title text NOT NULL,
  total_amount numeric NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  created_by uuid,
  CONSTRAINT event_expenses_pkey PRIMARY KEY (id),
  CONSTRAINT event_expenses_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id),
  CONSTRAINT event_expenses_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
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
  group_id uuid,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  cover_photo_id uuid,
  CONSTRAINT events_pkey PRIMARY KEY (id),
  CONSTRAINT events_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id),
  CONSTRAINT events_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id),
  CONSTRAINT events_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id),
  CONSTRAINT events_cover_photo_id_fkey FOREIGN KEY (cover_photo_id) REFERENCES public.group_photos(id)
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
CREATE TABLE public.group_invites (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  group_id uuid,
  invited_id uuid NOT NULL,
  invited_by uuid,
  group_url text UNIQUE,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT group_invites_pkey PRIMARY KEY (id),
  CONSTRAINT group_invites_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id),
  CONSTRAINT group_invites_invited_by_fkey FOREIGN KEY (invited_by) REFERENCES public.users(id),
  CONSTRAINT group_invites_invited_id_fkey FOREIGN KEY (invited_id) REFERENCES public.users(id)
);
CREATE TABLE public.group_members (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL,
  user_id uuid NOT NULL,
  role USER-DEFINED NOT NULL DEFAULT 'member'::member_role CHECK (role = ANY (ARRAY['admin'::member_role, 'member'::member_role])),
  joined_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT group_members_pkey PRIMARY KEY (id),
  CONSTRAINT group_members_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id),
  CONSTRAINT group_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.group_messages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL UNIQUE,
  sender_id uuid NOT NULL,
  text text,
  created_at timestamp with time zone DEFAULT now(),
  type USER-DEFINED NOT NULL DEFAULT 'text'::message_type,
  CONSTRAINT group_messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id),
  CONSTRAINT group_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id)
);
CREATE TABLE public.group_photos (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  event_id uuid NOT NULL,
  url text NOT NULL,
  storage_path text NOT NULL,
  captured_at timestamp with time zone NOT NULL DEFAULT now(),
  uploader_id uuid NOT NULL,
  is_portrait boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT group_photos_pkey PRIMARY KEY (id),
  CONSTRAINT group_photos_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id),
  CONSTRAINT group_photos_uploader_id_fkey FOREIGN KEY (uploader_id) REFERENCES public.users(id)
);
CREATE TABLE public.group_user_settings (
  group_id uuid NOT NULL,
  user_id uuid NOT NULL,
  is_pinned boolean NOT NULL DEFAULT false,
  is_muted boolean NOT NULL DEFAULT false,
  group_state text NOT NULL DEFAULT 'active'::text,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT group_user_settings_pkey PRIMARY KEY (group_id, user_id),
  CONSTRAINT group_user_settings_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id),
  CONSTRAINT group_user_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.groups (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL CHECK (char_length(name) >= 2 AND char_length(name) <= 100),
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  expense uuid,
  event_id uuid,
  memory_id uuid,
  members_can_invite boolean DEFAULT false,
  members_can_create_events boolean DEFAULT false,
  members_can_add_members boolean DEFAULT false,
  photo_url text,
  qr_code text,
  photo_updated_at timestamp with time zone,
  group_url text,
  CONSTRAINT groups_pkey PRIMARY KEY (id),
  CONSTRAINT groups_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id),
  CONSTRAINT groups_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id),
  CONSTRAINT groups_memory_id_fkey FOREIGN KEY (memory_id) REFERENCES public.memories(mem_id)
);
CREATE TABLE public.location_suggestion_votes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  suggestion_id uuid NOT NULL,
  user_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT location_suggestion_votes_pkey PRIMARY KEY (id),
  CONSTRAINT location_suggestion_votes_suggestion_id_fkey FOREIGN KEY (suggestion_id) REFERENCES public.location_suggestions(id),
  CONSTRAINT location_suggestion_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
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
  CONSTRAINT location_suggestions_pkey PRIMARY KEY (id),
  CONSTRAINT location_suggestions_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id),
  CONSTRAINT location_suggestions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
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
CREATE TABLE public.message_reads (
  user_id uuid NOT NULL,
  event_id uuid NOT NULL,
  last_read_message_id uuid,
  last_read_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT message_reads_pkey PRIMARY KEY (user_id, event_id),
  CONSTRAINT message_reads_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT message_reads_last_read_message_id_fkey FOREIGN KEY (last_read_message_id) REFERENCES public.chat_messages(id),
  CONSTRAINT message_reads_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id)
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
  group_id uuid,
  event_id uuid,
  event_emoji text,
  user_name text,
  group_name text,
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
  dedup_key text DEFAULT (((((((recipient_user_id)::text || ':'::text) || type) || ':'::text) || COALESCE((group_id)::text, ''::text)) || ':'::text) || COALESCE((event_id)::text, ''::text)),
  expense_id uuid,
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_recipient_user_id_fkey FOREIGN KEY (recipient_user_id) REFERENCES public.users(id),
  CONSTRAINT notifications_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id),
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
CREATE TABLE public.user_notification_settings (
  user_id uuid NOT NULL,
  push_enabled boolean NOT NULL DEFAULT true,
  quiet_hours_enabled boolean NOT NULL DEFAULT false,
  quiet_hours_start time without time zone,
  quiet_hours_end time without time zone,
  push_enabled_for_invites boolean NOT NULL DEFAULT true,
  push_enabled_for_events boolean NOT NULL DEFAULT true,
  push_enabled_for_payments boolean NOT NULL DEFAULT true,
  push_enabled_for_chat boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_notification_settings_pkey PRIMARY KEY (user_id),
  CONSTRAINT user_notification_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
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