-- ============================================================================
-- MIGRATION: Chat Presence Tracking for Push Notification Filtering
-- ============================================================================
-- Purpose: Prevent push notifications when user is actively viewing the chat
-- Date: 2026-01-27
-- ============================================================================

-- ============================================================================
-- PART 1: Create chat_active_users table
-- ============================================================================

-- Table to track users actively viewing a chat
-- Used by notify_chat_message() to filter out active users from push notifications
CREATE TABLE IF NOT EXISTS public.chat_active_users (
  event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (event_id, user_id)
);

-- Comment for documentation
COMMENT ON TABLE public.chat_active_users IS 
'Tracks users actively viewing event chats. Used to prevent push notifications for messages in the chat they are currently viewing. Entries expire after 30 seconds of inactivity.';

-- Index for fast filtering in trigger (event_id + recent last_seen)
CREATE INDEX IF NOT EXISTS idx_chat_active_users_event_last_seen 
ON public.chat_active_users(event_id, last_seen DESC);

-- ============================================================================
-- PART 2: RLS Policies for chat_active_users
-- ============================================================================

-- Enable RLS
ALTER TABLE public.chat_active_users ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own active status (minimal exposure)
CREATE POLICY "Users can view own presence"
ON public.chat_active_users
FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can insert/update their own presence (for direct access if needed)
CREATE POLICY "Users can manage own presence"
ON public.chat_active_users
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- PART 3: Server-side RPCs for presence management
-- ============================================================================

-- RPC: Touch/update presence (UPSERT with server timestamp)
-- Called by Flutter client every 10 seconds as heartbeat
CREATE OR REPLACE FUNCTION public.touch_chat_presence(p_event_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;
  
  -- Upsert presence with server-side timestamp (more reliable than client)
  INSERT INTO chat_active_users (event_id, user_id, last_seen)
  VALUES (p_event_id, v_user_id, NOW())
  ON CONFLICT (event_id, user_id) 
  DO UPDATE SET last_seen = NOW();
END;
$$;

COMMENT ON FUNCTION public.touch_chat_presence(UUID) IS 
'Updates user presence in a chat. Called as heartbeat every 10 seconds by Flutter client. Uses server-side NOW() for reliable timestamps.';

-- RPC: Leave/clear presence (DELETE)
-- Called when user leaves chat page or app goes to background
CREATE OR REPLACE FUNCTION public.leave_chat_presence(p_event_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;
  
  -- Remove presence for this user in this chat
  DELETE FROM chat_active_users
  WHERE event_id = p_event_id AND user_id = v_user_id;
END;
$$;

COMMENT ON FUNCTION public.leave_chat_presence(UUID) IS 
'Removes user presence from a chat. Called when leaving chat page or app goes to background.';

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION public.touch_chat_presence(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.leave_chat_presence(UUID) TO authenticated;

-- ============================================================================
-- PART 4: Update notify_chat_message() trigger function
-- ============================================================================

-- Updated trigger function that filters out active users
CREATE OR REPLACE FUNCTION public.notify_chat_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_event_emoji TEXT;
  v_event_name TEXT;
  v_sender_name TEXT;
BEGIN
  BEGIN
    -- Get event details
    SELECT emoji, name INTO v_event_emoji, v_event_name
    FROM events
    WHERE id = NEW.event_id;
    
    -- Get sender name
    SELECT name INTO v_sender_name
    FROM users
    WHERE id = NEW.user_id;

    -- ✅ Set-based INSERT (no loop) with active user filtering
    -- Notifies all event participants EXCEPT:
    -- 1. The message sender (ep.user_id != NEW.user_id)
    -- 2. Users actively viewing this chat (NOT EXISTS in chat_active_users with recent last_seen)
    INSERT INTO notifications (
      recipient_user_id,
      type,
      category,
      priority,
      deeplink,
      event_id,
      event_emoji,
      user_name,
      event_name,
      note
    )
    SELECT 
      ep.user_id,
      'chatMessage',
      'push'::notification_category,
      'low'::notification_priority,
      'lazzo://events/' || NEW.event_id || '/chat',  -- ✅ FIXED: correct deeplink scheme
      NEW.event_id,
      v_event_emoji,
      v_sender_name,
      v_event_name,
      NEW.content  -- Full content (truncation handled by push service)
    FROM event_participants ep
    CROSS JOIN users sender
    WHERE sender.id = NEW.user_id
      AND ep.pevent_id = NEW.event_id
      AND ep.user_id != NEW.user_id -- Exclude sender
      -- ✅ NEW: Exclude users actively viewing this chat (last_seen within 30 seconds)
      AND NOT EXISTS (
        SELECT 1 
        FROM chat_active_users cau
        WHERE cau.event_id = NEW.event_id
          AND cau.user_id = ep.user_id
          AND cau.last_seen > NOW() - INTERVAL '30 seconds'
      )
    ON CONFLICT (dedup_key, dedup_bucket) DO NOTHING;  -- ✅ ADDED: prevent duplicates

    RETURN NEW;
  EXCEPTION
    WHEN OTHERS THEN
      -- ✅ CRITICAL: Never block message inserts due to notification failures
      -- Log error but continue (graceful degradation)
      RAISE WARNING 'notify_chat_message failed: %', SQLERRM;
      RETURN NEW;
  END;
END;
$$;

COMMENT ON FUNCTION public.notify_chat_message() IS 
'Trigger that creates push notifications when a chat message is sent.
UPDATED: Filters out users actively viewing the chat (last_seen < 30 seconds).
Uses set-based INSERT for performance. Exception handler prevents blocking message inserts.';

-- ============================================================================
-- PART 5: Cleanup duplicate indexes on chat_messages
-- ============================================================================

-- Identify and drop redundant indexes
-- Keep only: idx_chat_messages_event (or rename the best one)
-- Drop the duplicates with same definition

-- ============================================================================
-- CLEANUP: Remove ONLY duplicate indexes, keep existing ones
-- ============================================================================

-- First, check what exists:
-- SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'chat_messages';

-- Drop only confirmed duplicates (same definition as idx_chat_messages_event)
-- Uncomment after verifying they exist:
-- DROP INDEX IF EXISTS public.idx_chat_messages_event_created;
-- DROP INDEX IF EXISTS public.idx_chat_messages_event_id;

-- ✅ DO NOT create new indexes - existing idx_chat_messages_event is sufficient
-- The existing index (event_id, created_at DESC) covers all query patterns

-- ============================================================================
-- PART 6: Optional - Scheduled cleanup of stale presence entries
-- ============================================================================
-- Note: Requires pg_cron extension. Skip if not available.
-- Stale entries don't affect correctness (30s window handles it), but cleanup saves space.

-- Uncomment if pg_cron is available:
/*
SELECT cron.schedule(
  'cleanup-stale-chat-presence',
  '*/5 * * * *', -- Every 5 minutes
  $$DELETE FROM public.chat_active_users WHERE last_seen < NOW() - INTERVAL '2 minutes'$$
);
*/

-- ============================================================================
-- VERIFICATION QUERIES (run after migration)
-- ============================================================================

-- Verify table created:
-- SELECT * FROM chat_active_users LIMIT 5;

-- Verify indexes:
-- SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'chat_messages';
-- SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'chat_active_users';

-- Verify RPC functions:
-- SELECT proname, prosrc FROM pg_proc WHERE proname IN ('touch_chat_presence', 'leave_chat_presence');

-- Test notify_chat_message filter:
-- INSERT INTO chat_active_users VALUES ('event-uuid', 'user-uuid', NOW());
-- Then send a message and verify that user doesn't receive notification.

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
