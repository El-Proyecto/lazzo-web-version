-- ========================================================================
-- FIX: Push notifications going to inbox during quiet hours
-- ========================================================================
-- PROBLEM: create_notification_secure() downgrades 'push' to 'notifications'
--          during quiet hours, causing ephemeral notifications (chat messages)
--          to appear in inbox.
--
-- SOLUTION: Skip push notifications entirely during quiet hours instead of
--           downgrading them to inbox.
-- ========================================================================

CREATE OR REPLACE FUNCTION public.create_notification_secure(
  p_recipient_user_id uuid,
  p_type text,
  p_category public.notification_category,
  p_priority public.notification_priority DEFAULT 'medium'::public.notification_priority,
  p_deeplink text DEFAULT NULL::text,
  p_group_id uuid DEFAULT NULL::uuid,
  p_event_id uuid DEFAULT NULL::uuid,
  p_event_emoji text DEFAULT NULL::text,
  p_user_name text DEFAULT NULL::text,
  p_group_name text DEFAULT NULL::text,
  p_event_name text DEFAULT NULL::text,
  p_amount text DEFAULT NULL::text,
  p_hours text DEFAULT NULL::text,
  p_mins text DEFAULT NULL::text,
  p_date text DEFAULT NULL::text,
  p_time text DEFAULT NULL::text,
  p_place text DEFAULT NULL::text,
  p_device text DEFAULT NULL::text,
  p_note text DEFAULT NULL::text,
  p_expense_id uuid DEFAULT NULL::uuid
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_notification_id UUID;
  v_should_notify BOOLEAN;
  v_is_muted BOOLEAN;
  v_in_quiet_hours BOOLEAN;
  v_push_enabled BOOLEAN;
BEGIN
  -- Check if user has muted this group (if group-related)
  IF p_group_id IS NOT NULL THEN
    SELECT is_muted INTO v_is_muted
    FROM group_user_settings
    WHERE user_id = p_recipient_user_id AND group_id = p_group_id;
    
    IF COALESCE(v_is_muted, FALSE) THEN
      RETURN NULL; -- Skip notification for muted group
    END IF;
  END IF;
  
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
          WHEN p_type = 'chatMessage' THEN chat_enabled
          WHEN p_type = 'chatMention' THEN chat_enabled
          WHEN p_type LIKE 'event%' THEN events_enabled
          WHEN p_type LIKE 'payment%' THEN payments_enabled
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
  
  -- ✅ FIX: Skip ephemeral push notifications during quiet hours
  -- Don't downgrade to inbox - ephemeral notifications should never persist
  IF v_in_quiet_hours AND p_category = 'push' THEN
    RETURN NULL; -- Skip notification entirely during quiet hours
  END IF;
  
  -- Skip entirely if category disabled
  IF NOT v_should_notify THEN
    RETURN NULL;
  END IF;
  
  -- Insert notification
  INSERT INTO notifications (
    recipient_user_id, type, category, priority, deeplink,
    group_id, event_id, event_emoji, user_name, group_name,
    event_name, amount, hours, mins, date, time, place, device, note,
    expense_id
  ) VALUES (
    p_recipient_user_id, p_type, p_category, p_priority, p_deeplink,
    p_group_id, p_event_id, p_event_emoji, p_user_name, p_group_name,
    p_event_name, p_amount, p_hours, p_mins, p_date, p_time, p_place, p_device, p_note,
    p_expense_id
  )
  ON CONFLICT (dedup_key, dedup_bucket) DO NOTHING
  RETURNING id INTO v_notification_id;
  
  RETURN v_notification_id; -- NULL if duplicate
END;
$$;

COMMENT ON FUNCTION public.create_notification_secure IS 'Creates notifications with server-side filtering (muting, quiet hours, etc). Push notifications are ephemeral and never downgraded to inbox.';
