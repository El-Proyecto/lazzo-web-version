-- =============================================================================
-- ACTIONS SCHEMA — For Post-Beta (Stored Actions)
-- =============================================================================
-- 
-- CONTEXT: For beta, actions are computed on-the-fly from event/participant data.
-- This schema is for when we need persistent actions (dismissals, scheduled
-- reminders, team actions, analytics).
--
-- DO NOT RUN THIS IN BETA — it's a reference for Phase 2+ implementation.
-- =============================================================================

-- Enum for action types
CREATE TYPE action_type AS ENUM (
  'remind_maybe_voters',
  'confirm_event',
  'add_event_details',
  'review_guests',
  'add_photos'
);

-- Enum for action status
CREATE TYPE action_status AS ENUM (
  'pending',
  'completed',
  'dismissed'
);

-- Enum for action priority
CREATE TYPE action_priority AS ENUM (
  'low',
  'medium',
  'high',
  'urgent'
);

-- =============================================================================
-- TABLE: dismissed_actions (Lightweight — Beta Phase 2)
-- =============================================================================
-- Tracks which computed actions a user has dismissed.
-- This is the MINIMAL table needed to add dismissal persistence.
-- Actions themselves are still computed from event data.
-- =============================================================================

CREATE TABLE public.dismissed_actions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  -- Composite key: type + event_id uniquely identifies a computed action
  action_type action_type NOT NULL,
  event_id uuid NOT NULL,
  dismissed_at timestamp with time zone NOT NULL DEFAULT now(),
  
  CONSTRAINT dismissed_actions_pkey PRIMARY KEY (id),
  CONSTRAINT dismissed_actions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
  CONSTRAINT dismissed_actions_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE,
  -- One dismissal per user per action type per event
  CONSTRAINT dismissed_actions_unique UNIQUE (user_id, action_type, event_id)
);

-- Index for fast lookups by user
CREATE INDEX idx_dismissed_actions_user_id ON public.dismissed_actions (user_id);

-- RLS: Users can only see/manage their own dismissals
ALTER TABLE public.dismissed_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own dismissed actions"
  ON public.dismissed_actions
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can dismiss actions"
  ON public.dismissed_actions
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can un-dismiss actions"
  ON public.dismissed_actions
  FOR DELETE
  USING (auth.uid() = user_id);


-- =============================================================================
-- TABLE: actions (Full — Phase 3 / Future)
-- =============================================================================
-- Full stored actions table for when we need:
-- - Scheduled/triggered action creation
-- - Team/group actions (not just host)
-- - Action analytics and tracking
-- - Complex action workflows
-- =============================================================================

-- CREATE TABLE public.actions (
--   id uuid NOT NULL DEFAULT gen_random_uuid(),
--   user_id uuid NOT NULL,
--   event_id uuid NOT NULL,
--   type action_type NOT NULL,
--   status action_status NOT NULL DEFAULT 'pending',
--   priority action_priority NOT NULL DEFAULT 'medium',
--   title text NOT NULL,
--   subtitle text,
--   context_info text,
--   due_date timestamp with time zone,
--   completed_at timestamp with time zone,
--   dismissed_at timestamp with time zone,
--   metadata jsonb DEFAULT '{}'::jsonb,
--   created_at timestamp with time zone NOT NULL DEFAULT now(),
--   updated_at timestamp with time zone NOT NULL DEFAULT now(),
--   
--   CONSTRAINT actions_pkey PRIMARY KEY (id),
--   CONSTRAINT actions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
--   CONSTRAINT actions_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE
-- );

-- -- Indexes for the full actions table
-- CREATE INDEX idx_actions_user_status ON public.actions (user_id, status);
-- CREATE INDEX idx_actions_event_id ON public.actions (event_id);
-- CREATE INDEX idx_actions_due_date ON public.actions (due_date) WHERE status = 'pending';
-- CREATE INDEX idx_actions_type ON public.actions (type);

-- -- RLS policies for full actions table
-- ALTER TABLE public.actions ENABLE ROW LEVEL SECURITY;

-- CREATE POLICY "Users can view own actions"
--   ON public.actions FOR SELECT USING (auth.uid() = user_id);

-- CREATE POLICY "System can create actions"
--   ON public.actions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- CREATE POLICY "Users can update own actions"
--   ON public.actions FOR UPDATE USING (auth.uid() = user_id);


-- =============================================================================
-- FUNCTION: get_host_action_data (Helper for computed actions)
-- =============================================================================
-- Returns raw data needed to compute actions for a host.
-- Called from the Flutter data layer to build ActionEntity objects.
-- =============================================================================

CREATE OR REPLACE FUNCTION get_host_action_data(host_user_id uuid)
RETURNS TABLE (
  event_id uuid,
  event_name text,
  event_emoji text,
  event_status text,
  start_datetime timestamptz,
  end_datetime timestamptz,
  location_id uuid,
  total_participants bigint,
  maybe_count bigint,
  pending_count bigint,
  host_photo_count bigint
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    e.id AS event_id,
    e.name AS event_name,
    e.emoji AS event_emoji,
    e.status::text AS event_status,
    e.start_datetime,
    e.end_datetime,
    e.location_id,
    -- Participant counts
    COUNT(ep.user_id) AS total_participants,
    COUNT(ep.user_id) FILTER (WHERE ep.rsvp = 'maybe') AS maybe_count,
    COUNT(ep.user_id) FILTER (WHERE ep.rsvp = 'pending') AS pending_count,
    -- Host photo count
    (SELECT COUNT(*) FROM event_photos ph 
     WHERE ph.event_id = e.id AND ph.uploader_id = host_user_id) AS host_photo_count
  FROM events e
  LEFT JOIN event_participants ep ON ep.pevent_id = e.id
  WHERE e.created_by = host_user_id
    AND e.status IN ('pending', 'confirmed', 'living')
  GROUP BY e.id, e.name, e.emoji, e.status, e.start_datetime, e.end_datetime, e.location_id
  ORDER BY 
    CASE e.status 
      WHEN 'living' THEN 1 
      WHEN 'confirmed' THEN 2 
      WHEN 'pending' THEN 3 
    END,
    e.start_datetime ASC NULLS LAST;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION get_host_action_data(uuid) TO authenticated;


-- =============================================================================
-- USAGE NOTES
-- =============================================================================
-- 
-- For Beta (Computed Actions):
--   1. Call get_host_action_data(user_id) from Flutter data source
--   2. Map results to ActionEntity objects based on conditions:
--      - maybe_count > 0 on pending/confirmed → remindMaybeVoters
--      - status = 'pending' AND start_datetime IS NULL → addEventDetails
--      - status = 'pending' AND location_id IS NULL → addEventDetails
--      - status = 'confirmed' AND maybe_count > 0 AND start within 3 days → reviewGuests
--      - status = 'living' AND host_photo_count = 0 → addPhotos
--   3. Sort by priority/urgency in Flutter
--
-- For Phase 2 (Dismissals):
--   1. Also create dismissed_actions table
--   2. After computing actions, filter out any matching dismissed_actions
--   3. When user dismisses, INSERT into dismissed_actions
--
-- For Phase 3 (Full Stored Actions):
--   1. Uncomment the full actions table
--   2. Create triggers on events/event_participants to auto-generate actions
--   3. Migrate computed logic to DB triggers
-- =============================================================================
