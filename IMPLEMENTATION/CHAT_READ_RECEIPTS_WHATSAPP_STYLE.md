# Chat Read Receipts - WhatsApp Style Implementation

## Overview
Update the chat read receipts to show WhatsApp-style indicators:
- **Single gray checkmark**: Message sent (not read by anyone)
- **Single green checkmark**: Message read by at least one person
- **Double green checkmarks**: Message read by EVERYONE in the group

## Part 1: Supabase Changes (P2 Developer)

### Update SQL Function

The current function returns `is_read_by_someone`. We need to add `is_read_by_everyone`.

**Apply this SQL to Supabase:**

```sql
-- Drop and recreate the function with both fields
DROP FUNCTION IF EXISTS public.get_messages_with_read_status(uuid, uuid, integer);

CREATE OR REPLACE FUNCTION public.get_messages_with_read_status(
  p_event_id uuid, 
  p_current_user_id uuid, 
  p_limit integer DEFAULT 50
) 
RETURNS TABLE(
  id uuid, 
  event_id uuid, 
  user_id uuid, 
  content text, 
  created_at timestamp with time zone, 
  is_pinned boolean, 
  is_deleted boolean, 
  reply_to_id uuid, 
  updated_at timestamp with time zone, 
  user_name text, 
  user_avatar text, 
  is_read_by_someone boolean,
  is_read_by_everyone boolean
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_total_other_participants integer;
BEGIN
  -- Count participants excluding sender (for "read by everyone" calculation)
  -- Note: event_participants uses pevent_id, not event_id
  SELECT COUNT(*) INTO v_total_other_participants
  FROM event_participants ep
  WHERE ep.pevent_id = p_event_id
    AND ep.user_id != p_current_user_id;

  RETURN QUERY
  SELECT 
    cm.id,
    cm.event_id,
    cm.user_id,
    cm.content,
    cm.created_at,
    cm.is_pinned,
    cm.is_deleted,
    cm.reply_to_id,
    cm.updated_at,
    u.name AS user_name,
    u.avatar_url AS user_avatar,
    -- is_read_by_someone: TRUE if at least one other participant has read this message
    EXISTS (
      SELECT 1
      FROM message_reads mr
      INNER JOIN chat_messages last_read ON (last_read.id = mr.last_read_message_id)
      WHERE mr.event_id = cm.event_id
        AND mr.user_id != cm.user_id
        AND last_read.created_at >= cm.created_at
    ) AS is_read_by_someone,
    -- is_read_by_everyone: TRUE only if ALL other participants have read this message
    CASE 
      WHEN v_total_other_participants = 0 THEN true  -- No other participants = consider "read"
      ELSE (
        SELECT COUNT(*) = v_total_other_participants
        FROM message_reads mr
        INNER JOIN chat_messages last_read ON (last_read.id = mr.last_read_message_id)
        INNER JOIN event_participants ep ON (ep.user_id = mr.user_id AND ep.pevent_id = p_event_id)
        WHERE mr.event_id = cm.event_id
          AND mr.user_id != cm.user_id
          AND last_read.created_at >= cm.created_at
      )
    END AS is_read_by_everyone
  FROM chat_messages cm
  LEFT JOIN users u ON u.id = cm.user_id
  WHERE cm.event_id = p_event_id
    AND cm.is_deleted = false
  ORDER BY cm.created_at DESC
  LIMIT p_limit;
END;
$$;

COMMENT ON FUNCTION public.get_messages_with_read_status(uuid, uuid, integer) 
IS 'Returns messages with WhatsApp-style read status:
- is_read_by_someone: TRUE when at least one participant has read
- is_read_by_everyone: TRUE when ALL participants have read (double checkmarks)';
```

### Testing
```sql
-- Test the function
SELECT id, content, is_read_by_someone, is_read_by_everyone
FROM get_messages_with_read_status(
  'your-event-id'::uuid,
  'your-user-id'::uuid,
  10
);
```

## Part 2: Flutter Changes (Already Implemented)

### Files Updated:
1. **chat_message.dart** (entity) - Added `isReadByEveryone` field
2. **chat_message_model.dart** - Added parsing for `is_read_by_everyone` from SQL
3. **chat_message_bubble.dart** - Updated UI logic:
   - Clock icon: pending
   - Single gray checkmark: sent, not read
   - Single green checkmark: read by someone
   - Double green checkmarks: read by everyone
4. **chat_preview_widget.dart** - Added `isReadByEveryone` to preview model
5. **event_page.dart** - Pass `isReadByEveryone` to previews
6. **event_living_page.dart** - Pass `isReadByEveryone` to previews

### Icon Logic:
```dart
Icon(
  message.isPending
      ? Icons.access_time  // Clock - pending
      : (message.isReadByEveryone
          ? Icons.done_all  // ✓✓ Double - everyone read
          : (message.isReadBySomeone
              ? Icons.done  // ✓ Single green - someone read
              : Icons.done)), // ✓ Single gray - sent
  color: message.isPending
      ? BrandColors.text2.withValues(alpha: 0.5)
      : (message.isReadBySomeone
          ? BrandColors.planning  // Green
          : BrandColors.text2),  // Gray
)
```

## Acceptance Criteria
- [ ] SQL function updated in Supabase
- [ ] Messages show single gray checkmark when sent
- [ ] Messages show single green checkmark when at least one person reads
- [ ] Messages show double green checkmarks when everyone reads
- [ ] Real-time updates work correctly
