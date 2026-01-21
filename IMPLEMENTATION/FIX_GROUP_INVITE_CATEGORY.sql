-- ========================================================================
-- FIX: Group Invite Notification Category
-- ========================================================================
-- PROBLEM: groupInviteReceived notifications have category 'push' but should be 'actions'
-- This causes them to be filtered out from the Inbox Actions tab
-- 
-- SOLUTION:
-- 1. Update the trigger to use 'actions' category instead of 'push'
-- 2. Update existing notifications in database
-- 
-- WHY: According to NOTIFICATIONS_REFERENCE.md, groupInviteReceived should be:
-- - Category: actions (not push)
-- - Display: Inbox Actions tab with Accept/Reject buttons
-- - Behavior: Persistent (not ephemeral)
-- ========================================================================

-- Step 1: Drop the old trigger
DROP TRIGGER IF EXISTS on_group_invite_notify ON group_invites;

-- Step 2: Update the function to use 'actions' category
CREATE OR REPLACE FUNCTION public.notify_group_invite_received()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- ✅ FIXED: Changed category from 'push' to 'actions'
  -- Only if user has notifications enabled
  IF should_send_notification(NEW.invited_id, NEW.group_id) THEN
    INSERT INTO notifications (
      recipient_user_id,
      type,
      category,
      priority,
      user_name,
      group_name,
      group_id,
      deeplink
    )
    SELECT 
      NEW.invited_id,
      'groupInviteReceived',
      'actions',  -- ✅ CHANGED: was 'push', now 'actions'
      'high',
      inviter.name,
      g.name,
      NEW.group_id,
      'lazzo://groups/' || NEW.group_id::text
    FROM users inviter
    JOIN groups g ON g.id = NEW.group_id
    WHERE inviter.id = NEW.invited_by;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Step 3: Recreate the trigger
CREATE TRIGGER on_group_invite_notify
  AFTER INSERT ON group_invites
  FOR EACH ROW
  EXECUTE FUNCTION notify_group_invite_received();

-- Step 4: Update existing groupInviteReceived notifications to use 'actions' category
UPDATE notifications
SET category = 'actions'
WHERE type = 'groupInviteReceived'
  AND category = 'push';

-- Step 5: Verify the changes
SELECT 
  id,
  recipient_user_id,
  type,
  category,
  user_name,
  group_name,
  created_at
FROM notifications
WHERE type = 'groupInviteReceived'
ORDER BY created_at DESC
LIMIT 10;

-- Expected output:
-- All groupInviteReceived notifications should have category = 'actions'
