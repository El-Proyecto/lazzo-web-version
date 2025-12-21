# Notifications System - Complete Implementation Guide

**Based on:** `notifications_catalog.md`  
**Status:** ✅ Ready for P2 Implementation  
**Date:** 2025-12-19  
**Last Updated:** 2025-12-19

---

## Implementation Status

### ✅ Completed (Flutter P1)
- All 29 notification types defined in enums
- NotificationModel parsing for all types
- Title & description generation for all types
- NotificationCard UI with action buttons for:
  - Group invites (Accept/Decline)
  - Confirm attendance (Not Going/Maybe/Going)
  - Single action buttons (Vote, Pay, Add Photos, Complete)
- Emoji mapping for all notification categories
- Deeplink structure defined

### 🚧 Pending (Backend P2)
- Database triggers implementation (20+ triggers)
- Scheduled cron jobs setup (5 jobs)
- RLS policies configuration
- Testing each notification type
- Push notification integration (Edge Function)

### 📝 Documentation Created
- `supabase_notifications_triggers.sql` - All database triggers & functions
- `NOTIFICATIONS_P2_SETUP_GUIDE.md` - Step-by-step setup & testing guide
- `NOTIFICATIONS_COMPLETE_IMPLEMENTATION.md` - This file (technical reference)

---

## Implementation Status

### ✅ Completed (1/29)
- `groupInviteReceived` - Full flow (DB → Flutter UI → Actions)

### 🚧 Defined but Not Implemented (28/29)
All notification types are defined in enums but lack:
- Database trigger/function to create notification
- UI rendering logic
- Action handlers (where applicable)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     NOTIFICATION FLOW                        │
├─────────────────────────────────────────────────────────────┤
│  1. EVENT HAPPENS (user action, time trigger)              │
│  2. SUPABASE TRIGGER/RPC creates notification row          │
│  3. FLUTTER queries notifications table                     │
│  4. NotificationModel.fromJson() → NotificationEntity      │
│  5. NotificationCard renders based on type                 │
│  6. User taps → deeplink navigation                        │
│  7. User takes action (Accept/Decline/Vote/etc)            │
│  8. Notification marked as read / deleted                   │
└─────────────────────────────────────────────────────────────┘
```

---

## Part 1: Database Schema (P2 - Supabase)

### Current `notifications` table (already exists)
```sql
-- From supabase_structure.sql
CREATE TABLE public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_user_id uuid NOT NULL REFERENCES users(id),
  type text NOT NULL,                    -- camelCase (e.g., 'groupInviteReceived')
  category text NOT NULL,                -- 'push', 'notifications', 'actions'
  priority text NOT NULL DEFAULT 'medium', -- 'low', 'medium', 'high'
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  
  -- Optional context fields (populate based on type)
  action_url text,
  deeplink text,
  group_id uuid REFERENCES groups(id),
  event_id uuid REFERENCES events(id),
  event_emoji text,
  user_name text,      -- For {user} placeholder
  group_name text,     -- For {group} placeholder
  event_name text,     -- For {event} placeholder
  amount text,         -- For {amount} placeholder
  hours text,          -- For {hours} placeholder
  mins text,           -- For {mins} placeholder
  date text,           -- For {date} placeholder
  time text,           -- For {time} placeholder
  place text,          -- For {place} placeholder
  device text,         -- For {device} placeholder
  note text,           -- For payment notes
  
  -- Deduplication
  dedup_bucket timestamptz NOT NULL DEFAULT (date_trunc('minute', now()) + interval '5 minutes'),
  dedup_key text DEFAULT ((recipient_user_id::text || ':' || type || ':' || COALESCE(group_id::text, '') || ':' || COALESCE(event_id::text, '')))
);

-- Index for fast lookups
CREATE INDEX idx_notifications_recipient ON notifications(recipient_user_id, is_read, created_at DESC);
CREATE INDEX idx_notifications_dedup ON notifications(dedup_key, dedup_bucket);
```

---

## Part 2: Notification Types Implementation

### Format per notification:
```markdown
### Type: notification_key

**Category:** push/notifications/actions  
**Priority:** high/medium/low  
**Trigger:** What event creates this notification  
**Context Fields:** Which fields to populate  
**Deeplink:** Where tap navigates  
**Actions:** Buttons/interactions (if applicable)  
**SQL Trigger/Function:** Supabase implementation  
**Flutter UI:** Special rendering (if needed)
```

---

## 1) PUSH Notifications (13 types)

### 1.1 groupInviteReceived ✅

**Category:** push  
**Priority:** high  
**Trigger:** User is invited to a group  
**Context Fields:** `user_name`, `group_name`, `group_id`  
**Deeplink:** `lazzo://group/{groupId}`  
**Actions:** Accept, Decline  
**Status:** ✅ IMPLEMENTED

**SQL Function:**
```sql
-- Already exists in accept_group_invite RPC
-- Notification is created manually or via separate trigger
```

**Flutter UI:** Special action buttons in NotificationCard (already done)

---

### 1.2 eventStartsSoon

**Category:** push  
**Priority:** high  
**Trigger:** Event starts in X minutes (scheduled job)  
**Context Fields:** `event_emoji`, `event_name`, `event_id`, `mins`  
**Deeplink:** `lazzo://event/{eventId}`  
**Actions:** None (informational)  

**SQL Function:**
```sql
CREATE OR REPLACE FUNCTION notify_event_starts_soon()
RETURNS void AS $$
BEGIN
  -- Find events starting in next 30 minutes that haven't been notified
  INSERT INTO notifications (
    recipient_user_id,
    type,
    category,
    priority,
    event_id,
    event_emoji,
    event_name,
    mins,
    deeplink
  )
  SELECT 
    ep.user_id,
    'eventStartsSoon',
    'push',
    'high',
    e.id,
    e.emoji,
    e.name,
    EXTRACT(EPOCH FROM (e.start_datetime - NOW())) / 60,
    'lazzo://event/' || e.id
  FROM events e
  JOIN event_participants ep ON ep.pevent_id = e.id
  WHERE e.start_datetime BETWEEN NOW() AND NOW() + interval '30 minutes'
    AND e.status = 'confirmed'
    AND ep.rsvp = 'going'
    AND NOT EXISTS (
      SELECT 1 FROM notifications n
      WHERE n.recipient_user_id = ep.user_id
        AND n.event_id = e.id
        AND n.type = 'eventStartsSoon'
        AND n.created_at > NOW() - interval '1 hour'
    );
END;
$$ LANGUAGE plpgsql;

-- Schedule with pg_cron every 10 minutes
SELECT cron.schedule('notify-events-starting', '*/10 * * * *', 'SELECT notify_event_starts_soon()');
```

**Flutter UI:** Default rendering (icon + message)

---

### 1.3 eventLive

**Category:** push  
**Priority:** high  
**Trigger:** Event start_datetime reached  
**Context Fields:** `event_emoji`, `event_name`, `event_id`  
**Deeplink:** `lazzo://event/{eventId}`  
**Actions:** None

**SQL Function:**
```sql
CREATE OR REPLACE FUNCTION notify_event_live()
RETURNS void AS $$
BEGIN
  INSERT INTO notifications (
    recipient_user_id,
    type,
    category,
    priority,
    event_id,
    event_emoji,
    event_name,
    deeplink
  )
  SELECT 
    ep.user_id,
    'eventLive',
    'push',
    'high',
    e.id,
    e.emoji,
    e.name,
    'lazzo://event/' || e.id
  FROM events e
  JOIN event_participants ep ON ep.pevent_id = e.id
  WHERE e.start_datetime BETWEEN NOW() - interval '5 minutes' AND NOW()
    AND e.status = 'confirmed'
    AND NOT EXISTS (
      SELECT 1 FROM notifications n
      WHERE n.recipient_user_id = ep.user_id
        AND n.event_id = e.id
        AND n.type = 'eventLive'
    );
END;
$$ LANGUAGE plpgsql;

-- Schedule every 5 minutes
SELECT cron.schedule('notify-events-live', '*/5 * * * *', 'SELECT notify_event_live()');
```

---

### 1.4 eventEndsSoon

**Category:** push  
**Priority:** medium  
**Trigger:** Event ends in X minutes  
**Context Fields:** `event_emoji`, `event_name`, `event_id`, `mins`  
**Deeplink:** `lazzo://event/{eventId}`  

**SQL:** Similar to eventStartsSoon, check `end_datetime`

---

### 1.5 eventExtended

**Category:** push  
**Priority:** medium  
**Trigger:** Event end_datetime is extended  
**Context Fields:** `event_emoji`, `event_name`, `event_id`, `mins` (extension duration)  
**Deeplink:** `lazzo://event/{eventId}`  

**SQL Trigger:**
```sql
CREATE OR REPLACE FUNCTION on_event_extended()
RETURNS trigger AS $$
DECLARE
  v_extension_mins INTEGER;
BEGIN
  -- Only if end_datetime changed and extended (not shortened)
  IF OLD.end_datetime IS DISTINCT FROM NEW.end_datetime 
     AND NEW.end_datetime > OLD.end_datetime THEN
    
    v_extension_mins := EXTRACT(EPOCH FROM (NEW.end_datetime - OLD.end_datetime)) / 60;
    
    INSERT INTO notifications (
      recipient_user_id,
      type,
      category,
      priority,
      event_id,
      event_emoji,
      event_name,
      mins,
      deeplink
    )
    SELECT 
      ep.user_id,
      'eventExtended',
      'push',
      'medium',
      NEW.id,
      NEW.emoji,
      NEW.name,
      v_extension_mins::text,
      'lazzo://event/' || NEW.id
    FROM event_participants ep
    WHERE ep.pevent_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER event_extended_notification
AFTER UPDATE ON events
FOR EACH ROW
EXECUTE FUNCTION on_event_extended();
```

---

### 1.6 uploadsOpen

**Category:** push  
**Priority:** medium  
**Trigger:** Event ends (uploads window opens)  
**Context Fields:** `event_emoji`, `event_name`, `event_id`, `hours` (window duration)  
**Deeplink:** `lazzo://event/{eventId}/uploads`  
**Actions:** "Add Photos" button

**SQL:** Trigger when event ends + status changes to 'uploads_open'

---

### 1.7 uploadsClosing

**Category:** push  
**Priority:** high  
**Trigger:** Uploads window closing soon (e.g., 2 hours left)  
**Context Fields:** `event_emoji`, `event_name`, `event_id`, `hours`  
**Deeplink:** `lazzo://event/{eventId}/uploads`  
**Actions:** "Add Photos" button

**SQL:** Scheduled job checking events with uploads_open status

---

### 1.8 memoryReady

**Category:** push  
**Priority:** high  
**Trigger:** Memory compilation completed  
**Context Fields:** `event_emoji`, `event_name`, `event_id`  
**Deeplink:** `lazzo://event/{eventId}`  

**SQL:** Triggered by memory generation service/RPC

---

### 1.9 paymentsRequest

**Category:** push  
**Priority:** high  
**Trigger:** User requests payment from another user  
**Context Fields:** `user_name`, `amount`, `note`  
**Deeplink:** `lazzo://payments`  
**Actions:** "Pay" button

**SQL Trigger:**
```sql
CREATE OR REPLACE FUNCTION on_payment_request()
RETURNS trigger AS $$
BEGIN
  INSERT INTO notifications (
    recipient_user_id,
    type,
    category,
    priority,
    user_name,
    amount,
    note,
    deeplink
  )
  SELECT 
    u.id,
    'paymentsRequest',
    'push',
    'high',
    requester.name,
    NEW.amount::text,
    NEW.note,
    'lazzo://payments'
  FROM users u
  CROSS JOIN users requester
  WHERE u.id = NEW.recipient_user_id
    AND requester.id = NEW.requester_user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Assuming a payment_requests table exists
CREATE TRIGGER payment_request_notification
AFTER INSERT ON payment_requests
FOR EACH ROW
EXECUTE FUNCTION on_payment_request();
```

---

### 1.10 paymentsAddedYouOwe

**Category:** push  
**Priority:** high  
**Trigger:** Expense added where user owes money  
**Context Fields:** `user_name`, `amount`, `event_name`, `event_id`  
**Deeplink:** `lazzo://payments`  

**SQL Trigger:**
```sql
CREATE OR REPLACE FUNCTION on_expense_added()
RETURNS trigger AS $$
BEGIN
  -- For each user who owes money in this split
  INSERT INTO notifications (
    recipient_user_id,
    type,
    category,
    priority,
    user_name,
    amount,
    event_name,
    event_id,
    deeplink
  )
  SELECT 
    es.user_id,
    'paymentsAddedYouOwe',
    'push',
    'high',
    creator.name,
    es.amount::text,
    e.name,
    ee.event_id,
    'lazzo://payments'
  FROM expense_splits es
  JOIN event_expenses ee ON ee.id = es.expense_id
  JOIN events e ON e.id = ee.event_id
  JOIN users creator ON creator.id = ee.created_by
  WHERE es.expense_id = NEW.id
    AND es.has_paid = FALSE;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER expense_added_notification
AFTER INSERT ON event_expenses
FOR EACH ROW
EXECUTE FUNCTION on_expense_added();
```

---

### 1.11 paymentsPaidYou

**Category:** push  
**Priority:** medium  
**Trigger:** User pays you  
**Context Fields:** `user_name`, `amount`  
**Deeplink:** `lazzo://payments`  

**SQL:** Trigger on expense_splits when has_paid = TRUE

---

### 1.12 chatMention

**Category:** push  
**Priority:** high  
**Trigger:** User mentioned in chat (@username)  
**Context Fields:** `user_name`, `event_name`, `event_id`  
**Deeplink:** `lazzo://event/{eventId}`  

**SQL Trigger:**
```sql
CREATE OR REPLACE FUNCTION on_chat_mention()
RETURNS trigger AS $$
BEGIN
  -- Parse @mentions from content (simplified - use regex in production)
  IF NEW.content ~ '@[a-zA-Z0-9_]+' THEN
    INSERT INTO notifications (
      recipient_user_id,
      type,
      category,
      priority,
      user_name,
      event_name,
      event_id,
      deeplink
    )
    SELECT 
      mentioned_user.id,
      'chatMention',
      'push',
      'high',
      sender.name,
      e.name,
      NEW.event_id,
      'lazzo://event/' || NEW.event_id
    FROM users mentioned_user
    CROSS JOIN users sender
    CROSS JOIN events e
    WHERE sender.id = NEW.user_id
      AND e.id = NEW.event_id
      AND NEW.content ~ ('@' || mentioned_user.name)  -- Match username
      AND mentioned_user.id != NEW.user_id;  -- Don't notify self
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER chat_mention_notification
AFTER INSERT ON chat_messages
FOR EACH ROW
EXECUTE FUNCTION on_chat_mention();
```

---

### 1.13 securityNewLogin

**Category:** push  
**Priority:** high  
**Trigger:** New device/location login detected  
**Context Fields:** `device` (e.g., "iPhone 14, Lisbon")  
**Deeplink:** `lazzo://profile/security`  

**SQL:** Triggered by auth service on login

---

## 2) NOTIFICATIONS (Feed only - 11 types)

### 2.1 groupInviteAccepted

**Category:** notifications  
**Priority:** low  
**Trigger:** Someone accepts group invite  
**Context Fields:** `user_name`, `group_name`, `group_id`  
**Deeplink:** `lazzo://group/{groupId}`  

**SQL:** Modify accept_group_invite RPC to notify group admins

```sql
-- Add to accept_group_invite RPC
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
  gm.user_id,
  'groupInviteAccepted',
  'notifications',
  'low',
  accepter.name,
  g.name,
  g.id,
  'lazzo://group/' || g.id
FROM group_members gm
CROSS JOIN users accepter
CROSS JOIN groups g
WHERE gm.group_id = p_group_id
  AND gm.role = 'admin'
  AND accepter.id = p_user_id
  AND g.id = p_group_id;
```

---

### 2.2 groupRenamed

**Category:** notifications  
**Priority:** low  
**Trigger:** Group name changed  
**Context Fields:** `group_name` (new name), `group_id`  
**Deeplink:** `lazzo://group/{groupId}`  

**SQL Trigger:**
```sql
CREATE OR REPLACE FUNCTION on_group_renamed()
RETURNS trigger AS $$
BEGIN
  IF OLD.name IS DISTINCT FROM NEW.name THEN
    INSERT INTO notifications (
      recipient_user_id,
      type,
      category,
      priority,
      group_name,
      group_id,
      deeplink
    )
    SELECT 
      gm.user_id,
      'groupRenamed',
      'notifications',
      'low',
      NEW.name,
      NEW.id,
      'lazzo://group/' || NEW.id
    FROM group_members gm
    WHERE gm.group_id = NEW.id
      AND gm.user_id != NEW.created_by;  -- Don't notify who renamed it
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER group_renamed_notification
AFTER UPDATE ON groups
FOR EACH ROW
EXECUTE FUNCTION on_group_renamed();
```

---

### 2.3 groupPhotoChanged

**Category:** notifications  
**Priority:** low  
**Trigger:** Group photo updated  
**Context Fields:** `group_name`, `group_id`  
**Deeplink:** `lazzo://group/{groupId}`  

**SQL:** Similar to groupRenamed, trigger on `photo_url` change

---

### 2.4 eventCreated

**Category:** notifications  
**Priority:** medium  
**Trigger:** New event created in group  
**Context Fields:** `event_emoji`, `event_name`, `group_name`, `event_id`  
**Deeplink:** `lazzo://event/{eventId}`  

**SQL Trigger:**
```sql
CREATE OR REPLACE FUNCTION on_event_created()
RETURNS trigger AS $$
BEGIN
  INSERT INTO notifications (
    recipient_user_id,
    type,
    category,
    priority,
    event_emoji,
    event_name,
    group_name,
    event_id,
    deeplink
  )
  SELECT 
    gm.user_id,
    'eventCreated',
    'notifications',
    'medium',
    NEW.emoji,
    NEW.name,
    g.name,
    NEW.id,
    'lazzo://event/' || NEW.id
  FROM group_members gm
  JOIN groups g ON g.id = NEW.group_id
  WHERE gm.group_id = NEW.group_id
    AND gm.user_id != NEW.created_by;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER event_created_notification
AFTER INSERT ON events
FOR EACH ROW
WHEN (NEW.group_id IS NOT NULL)
EXECUTE FUNCTION on_event_created();
```

---

### 2.5 eventDateSet

**Category:** notifications  
**Priority:** medium  
**Trigger:** Event date confirmed  
**Context Fields:** `event_emoji`, `event_name`, `date`, `time`, `event_id`  
**Deeplink:** `lazzo://event/{eventId}`  

**SQL:** Trigger when `start_datetime` changes from NULL to set

---

### 2.6 eventLocationSet

**Category:** notifications  
**Priority:** medium  
**Trigger:** Event location confirmed  
**Context Fields:** `event_emoji`, `event_name`, `place`, `event_id`  
**Deeplink:** `lazzo://event/{eventId}`  

**SQL:** Trigger when `location_id` changes from NULL to set

---

### 2.7 eventDetailsUpdated

**Category:** notifications  
**Priority:** low  
**Trigger:** Event info changed (name, emoji, description)  
**Context Fields:** `event_emoji`, `event_name`, `event_id`  
**Deeplink:** `lazzo://event/{eventId}`  

**SQL:** Trigger on UPDATE of events (any field except status)

---

### 2.8 eventCanceled

**Category:** notifications  
**Priority:** high  
**Trigger:** Event status → 'canceled'  
**Context Fields:** `event_emoji`, `event_name`, `group_id`  
**Deeplink:** `lazzo://group/{groupId}`  

**SQL:** Trigger when status changes to 'canceled'

---

### 2.9 eventRestored

**Category:** notifications  
**Priority:** medium  
**Trigger:** Event uncanceled  
**Context Fields:** `event_emoji`, `event_name`, `event_id`  
**Deeplink:** `lazzo://event/{eventId}`  

**SQL:** Trigger when status changes from 'canceled' to another state

---

### 2.10 eventConfirmed

**Category:** notifications  
**Priority:** medium  
**Trigger:** Event status → 'confirmed'  
**Context Fields:** `event_emoji`, `event_name`, `event_id`  
**Deeplink:** `lazzo://event/{eventId}`  

**SQL:** Trigger when status changes to 'confirmed'

---

### 2.11 suggestionAdded

**Category:** notifications  
**Priority:** low  
**Trigger:** User adds date/place suggestion  
**Context Fields:** `user_name`, `suggestion` (place name or date), `event_name`, `event_id`  
**Deeplink:** `lazzo://event/{eventId}`  

**SQL:** Trigger on INSERT to location_suggestions or event_date_options

---

## 3) ACTIONS (To-dos - 5 types)

### 3.1 voteDate

**Category:** actions  
**Priority:** high  
**Trigger:** Date voting opens  
**Context Fields:** `event_name`, `event_id`, `date` (closes date)  
**Deeplink:** `lazzo://event/{eventId}`  
**Actions:** "Vote" button → navigate to voting UI  
**TTL:** Expires when voting closes

**SQL:** Created when voting period starts (manual RPC or status change)

---

### 3.2 votePlace

**Category:** actions  
**Priority:** high  
**Trigger:** Place voting opens  
**Context Fields:** `event_name`, `event_id`, `date` (closes date)  
**Deeplink:** `lazzo://event/{eventId}`  
**Actions:** "Vote" button  
**TTL:** Expires when voting closes

---

### 3.3 confirmAttendance

**Category:** actions  
**Priority:** high  
**Trigger:** RSVP requested  
**Context Fields:** `event_name`, `event_id`, `date` (days left)  
**Deeplink:** `lazzo://event/{eventId}`  
**Actions:** "Going", "Maybe", "Not Going"  
**TTL:** Expires at event start

**SQL:**
```sql
-- When user invited to event
INSERT INTO notifications (
  recipient_user_id,
  type,
  category,
  priority,
  event_name,
  event_id,
  date,
  deeplink
)
VALUES (
  invited_user_id,
  'confirmAttendance',
  'actions',
  'high',
  event.name,
  event.id,
  EXTRACT(DAY FROM (event.start_datetime - NOW()))::text,
  'lazzo://event/' || event.id
);
```

**Flutter UI:** Show Going/Maybe/Not Going buttons inline

---

### 3.4 completeDetails

**Category:** actions  
**Priority:** medium  
**Trigger:** Event missing date or location  
**Context Fields:** `event_name`, `event_id`  
**Deeplink:** `lazzo://event/{eventId}`  
**Actions:** "Complete" button  
**Recipient:** Only event creator/admins

**SQL:** Created when event is created without date/location

---

### 3.5 addPhotos

**Category:** actions  
**Priority:** medium  
**Trigger:** Uploads window open  
**Context Fields:** `event_name`, `event_id`, `hours` (time left)  
**Deeplink:** `lazzo://event/{eventId}/uploads`  
**Actions:** "Add Photos" button  
**TTL:** Expires when uploads close

**SQL:** Same trigger as uploadsOpen but category='actions'

---

## Part 3: Flutter Implementation (P1)

### 3.1 Update NotificationModel parsing

Add all 29 types to `_parseNotificationType()`:

```dart
// lib/features/inbox/data/models/notification_model.dart

NotificationType _parseNotificationType(String type) {
  switch (type) {
    // PUSH (13 types)
    case 'groupInviteReceived': return NotificationType.groupInviteReceived;
    case 'eventStartsSoon': return NotificationType.eventStartsSoon;
    case 'eventLive': return NotificationType.eventLive;
    case 'eventEndsSoon': return NotificationType.eventEndsSoon;
    case 'eventExtended': return NotificationType.eventExtended;
    case 'uploadsOpen': return NotificationType.uploadsOpen;
    case 'uploadsClosing': return NotificationType.uploadsClosing;
    case 'memoryReady': return NotificationType.memoryReady;
    case 'paymentsRequest': return NotificationType.paymentsRequest;
    case 'paymentsAddedYouOwe': return NotificationType.paymentsAddedYouOwe;
    case 'paymentsPaidYou': return NotificationType.paymentsPaidYou;
    case 'chatMention': return NotificationType.chatMention;
    case 'securityNewLogin': return NotificationType.securityNewLogin;
    
    // NOTIFICATIONS (11 types)
    case 'groupInviteAccepted': return NotificationType.groupInviteAccepted;
    case 'groupRenamed': return NotificationType.groupRenamed;
    case 'groupPhotoChanged': return NotificationType.groupPhotoChanged;
    case 'eventCreated': return NotificationType.eventCreated;
    case 'eventDateSet': return NotificationType.eventDateSet;
    case 'eventLocationSet': return NotificationType.eventLocationSet;
    case 'eventDetailsUpdated': return NotificationType.eventDetailsUpdated;
    case 'eventCanceled': return NotificationType.eventCanceled;
    case 'eventRestored': return NotificationType.eventRestored;
    case 'eventConfirmed': return NotificationType.eventConfirmed;
    case 'suggestionAdded': return NotificationType.suggestionAdded;
    
    // ACTIONS (5 types)
    case 'voteDate': return NotificationType.voteDate;
    case 'votePlace': return NotificationType.votePlace;
    case 'confirmAttendance': return NotificationType.confirmAttendance;
    case 'completeDetails': return NotificationType.completeDetails;
    case 'addPhotos': return NotificationType.addPhotos;
    
    default: return NotificationType.general;
  }
}
```

### 3.2 Update title/description generators

Add message templates for all types:

```dart
String _generateDescription() {
  switch (type) {
    // PUSH
    case 'groupInviteReceived':
      return '${userName ?? 'Someone'} invited you to join ${groupName ?? 'a group'}';
    case 'eventStartsSoon':
      return '${eventEmoji ?? '🎉'} ${eventName ?? 'Event'} starts in ${mins ?? '?'} min.';
    case 'eventLive':
      return '${eventEmoji ?? '🎉'} ${eventName ?? 'Event'} is live now.';
    case 'eventEndsSoon':
      return '${eventEmoji ?? '🎉'} ${eventName ?? 'Event'} ends in ${mins ?? '?'} min.';
    case 'eventExtended':
      return '${eventEmoji ?? '🎉'} ${eventName ?? 'Event'} was extended by ${mins ?? '?'} min.';
    case 'uploadsOpen':
      return 'Add your photos to ${eventEmoji ?? '🎉'} ${eventName ?? 'event'} · ${hours ?? '?'}h left.';
    case 'uploadsClosing':
      return 'Last call to add photos to ${eventEmoji ?? '🎉'} ${eventName ?? 'event'} · ${hours ?? '?'}h left.';
    case 'memoryReady':
      return 'Your memory for ${eventEmoji ?? '🎉'} ${eventName ?? 'event'} is ready to share.';
    case 'paymentsRequest':
      return '${userName ?? 'Someone'} requested ${amount ?? '?'} for ${note ?? 'payment'}.';
    case 'paymentsAddedYouOwe':
      return '${userName ?? 'Someone'} added an expense in ${eventEmoji ?? '🎉'} ${eventName ?? 'event'}. You owe ${amount ?? '?'}.';
    case 'paymentsPaidYou':
      return '${userName ?? 'Someone'} paid you ${amount ?? '?'}.';
    case 'chatMention':
      return '${userName ?? 'Someone'} mentioned you in ${eventEmoji ?? '🎉'} ${eventName ?? 'event'}.';
    case 'securityNewLogin':
      return 'New sign-in on ${device ?? 'unknown device'}. Was this you?';
    
    // NOTIFICATIONS
    case 'groupInviteAccepted':
      return '${userName ?? 'Someone'} joined ${groupName ?? 'a group'}.';
    case 'groupRenamed':
      return '${groupName ?? 'A group'} has a new name.';
    case 'groupPhotoChanged':
      return '${groupName ?? 'A group'} has a new photo.';
    case 'eventCreated':
      return 'New event ${eventEmoji ?? '🎉'} ${eventName ?? ''} in ${groupName ?? 'a group'}.';
    case 'eventDateSet':
      return 'Date confirmed for ${eventEmoji ?? '🎉'} ${eventName ?? 'event'}: ${date ?? '?'}, ${time ?? '?'}.';
    case 'eventLocationSet':
      return 'Location confirmed for ${eventEmoji ?? '🎉'} ${eventName ?? 'event'}: ${place ?? '?'}.';
    case 'eventDetailsUpdated':
      return '${eventEmoji ?? '🎉'} ${eventName ?? 'Event'} was updated. Check the new details.';
    case 'eventCanceled':
      return '${eventEmoji ?? '🎉'} ${eventName ?? 'Event'} was canceled.';
    case 'eventRestored':
      return '${eventEmoji ?? '🎉'} ${eventName ?? 'Event'} is back on.';
    case 'eventConfirmed':
      return '${eventEmoji ?? '🎉'} ${eventName ?? 'Event'} is confirmed to happen.';
    case 'suggestionAdded':
      return '${userName ?? 'Someone'} suggested ${place ?? date ?? 'something'} for ${eventEmoji ?? '🎉'} ${eventName ?? 'event'}.';
    
    // ACTIONS
    case 'voteDate':
      return 'Vote a date · closes ${date ?? 'soon'}';
    case 'votePlace':
      return 'Vote a place · closes ${date ?? 'soon'}';
    case 'confirmAttendance':
      return 'Confirm attendance · ${date ?? '?'}d left';
    case 'completeDetails':
      return 'Complete event details (date/location)';
    case 'addPhotos':
      return 'Add photos · ${hours ?? '?'}h left';
    
    default:
      return 'You have a new notification';
  }
}
```

### 3.3 Update NotificationCard for action buttons

```dart
// lib/features/inbox/presentation/widgets/notification_card.dart

Widget _buildActionButtons(BuildContext context) {
  final type = notification.type;
  
  // Group invite (already done)
  if (type == NotificationType.groupInviteReceived) {
    return _buildAcceptDeclineButtons();
  }
  
  // Attendance confirmation
  if (type == NotificationType.confirmAttendance) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _handleRsvp('not_going'),
            child: Text('Not Going'),
          ),
        ),
        SizedBox(width: Gaps.sm),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _handleRsvp('maybe'),
            child: Text('Maybe'),
          ),
        ),
        SizedBox(width: Gaps.sm),
        Expanded(
          child: FilledButton(
            onPressed: () => _handleRsvp('going'),
            child: Text('Going'),
          ),
        ),
      ],
    );
  }
  
  // Single action button for other types
  if (_hasActionButton(type)) {
    return FilledButton(
      onPressed: () => onActionTap?.call(),
      child: Text(_getActionButtonText(type)),
    );
  }
  
  return SizedBox.shrink();
}

bool _hasActionButton(NotificationType type) {
  return [
    NotificationType.uploadsOpen,
    NotificationType.uploadsClosing,
    NotificationType.addPhotos,
    NotificationType.voteDate,
    NotificationType.votePlace,
    NotificationType.completeDetails,
    NotificationType.paymentsRequest,
  ].contains(type);
}

String _getActionButtonText(NotificationType type) {
  switch (type) {
    case NotificationType.uploadsOpen:
    case NotificationType.uploadsClosing:
    case NotificationType.addPhotos:
      return 'Add Photos';
    case NotificationType.voteDate:
    case NotificationType.votePlace:
      return 'Vote';
    case NotificationType.completeDetails:
      return 'Complete';
    case NotificationType.paymentsRequest:
      return 'Pay';
    default:
      return 'Open';
  }
}
```

### 3.4 Handle deeplinks

```dart
// lib/routes/app_router.dart

void handleDeeplink(String deeplink) {
  final uri = Uri.parse(deeplink);
  
  switch (uri.host) {
    case 'group':
      final groupId = uri.pathSegments.first;
      navigatorKey.currentState?.pushNamed('/group-details', arguments: groupId);
      break;
    
    case 'event':
      final eventId = uri.pathSegments.first;
      if (uri.pathSegments.contains('uploads')) {
        navigatorKey.currentState?.pushNamed('/event-uploads', arguments: eventId);
      } else {
        navigatorKey.currentState?.pushNamed('/event-detail', arguments: eventId);
      }
      break;
    
    case 'payments':
      navigatorKey.currentState?.pushNamed('/payments');
      break;
    
    case 'profile':
      if (uri.pathSegments.contains('security')) {
        navigatorKey.currentState?.pushNamed('/profile/security');
      } else {
        navigatorKey.currentState?.pushNamed('/profile');
      }
      break;
  }
}
```

---

## Part 4: Testing Strategy

### 4.1 Database Tests (P2)

```sql
-- Test each trigger/function
-- Example for groupInviteReceived

-- Setup
INSERT INTO users (id, name, email) VALUES 
  ('user1-uuid', 'Alice', 'alice@test.com'),
  ('user2-uuid', 'Bob', 'bob@test.com');

INSERT INTO groups (id, name, created_by) VALUES
  ('group1-uuid', 'Test Group', 'user1-uuid');

-- Execute
INSERT INTO group_invites (group_id, invited_id, invited_by) VALUES
  ('group1-uuid', 'user2-uuid', 'user1-uuid');

-- Verify notification created
SELECT * FROM notifications 
WHERE recipient_user_id = 'user2-uuid' 
  AND type = 'groupInviteReceived';
-- Should return 1 row

-- Cleanup
DELETE FROM notifications WHERE recipient_user_id = 'user2-uuid';
DELETE FROM group_invites WHERE group_id = 'group1-uuid';
DELETE FROM groups WHERE id = 'group1-uuid';
DELETE FROM users WHERE id IN ('user1-uuid', 'user2-uuid');
```

### 4.2 Flutter Tests (P1)

```dart
// Test notification parsing
void main() {
  group('NotificationModel', () {
    test('parses groupInviteReceived correctly', () {
      final json = {
        'id': 'notif-1',
        'type': 'groupInviteReceived',
        'category': 'push',
        'priority': 'high',
        'user_name': 'Alice',
        'group_name': 'Test Group',
        'group_id': 'group-1',
        'is_read': false,
        'created_at': '2025-12-19T10:00:00Z',
      };
      
      final model = NotificationModel.fromJson(json);
      final entity = model.toEntity();
      
      expect(entity.type, NotificationType.groupInviteReceived);
      expect(entity.category, NotificationCategory.push);
      expect(entity.userName, 'Alice');
      expect(entity.groupName, 'Test Group');
    });
    
    // Repeat for all 29 types
  });
}
```

---

## Part 5: Implementation Priority

### Phase 1 (Critical - 1 week)
- [x] `groupInviteReceived` (already done)
- [ ] `eventStartsSoon` (scheduled job)
- [ ] `eventLive` (scheduled job)
- [ ] `confirmAttendance` (action required)
- [ ] `eventCreated` (high engagement)

### Phase 2 (Important - 1 week)
- [ ] `paymentsAddedYouOwe` (payments core)
- [ ] `paymentsRequest` (payments core)
- [ ] `paymentsPaidYou` (payments core)
- [ ] `uploadsOpen` (uploads core)
- [ ] `uploadsClosing` (uploads core)
- [ ] `addPhotos` (action)

### Phase 3 (Engagement - 1 week)
- [ ] `chatMention` (chat engagement)
- [ ] `eventExtended` (time changes)
- [ ] `eventEndsSoon` (time awareness)
- [ ] `memoryReady` (memory feature)
- [ ] `voteDate` (action)
- [ ] `votePlace` (action)

### Phase 4 (Informational - 1 week)
- [ ] `groupInviteAccepted` (social)
- [ ] `groupRenamed` (updates)
- [ ] `groupPhotoChanged` (updates)
- [ ] `eventDateSet` (updates)
- [ ] `eventLocationSet` (updates)
- [ ] `eventDetailsUpdated` (updates)
- [ ] `eventCanceled` (important)
- [ ] `eventRestored` (important)
- [ ] `eventConfirmed` (important)
- [ ] `suggestionAdded` (voting)

### Phase 5 (Nice to have - 1 week)
- [ ] `securityNewLogin` (security)
- [ ] `completeDetails` (admin action)

---

## Part 6: Deduplication & TTL

### Deduplication (already in schema)
```sql
-- Existing fields:
dedup_bucket timestamptz DEFAULT (date_trunc('minute', now()) + interval '5 minutes')
dedup_key text DEFAULT (recipient_user_id || ':' || type || ':' || group_id || ':' || event_id)

-- Constraint to prevent duplicates within 5 min window:
CREATE UNIQUE INDEX idx_notifications_dedup_unique
ON notifications(dedup_key, dedup_bucket)
WHERE is_read = FALSE;
```

### TTL (automatic cleanup)
```sql
CREATE OR REPLACE FUNCTION cleanup_expired_notifications()
RETURNS void AS $$
BEGIN
  -- Delete read notifications older than 30 days
  DELETE FROM notifications
  WHERE is_read = TRUE
    AND created_at < NOW() - interval '30 days';
  
  -- Delete expired action notifications
  DELETE FROM notifications
  WHERE category = 'actions'
    AND created_at < NOW() - interval '7 days';
    
  -- Delete notifications for deleted events
  DELETE FROM notifications
  WHERE event_id IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM events WHERE id = notifications.event_id);
    
  -- Delete notifications for deleted groups
  DELETE FROM notifications
  WHERE group_id IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM groups WHERE id = notifications.group_id);
END;
$$ LANGUAGE plpgsql;

-- Schedule daily cleanup
SELECT cron.schedule('cleanup-notifications', '0 2 * * *', 'SELECT cleanup_expired_notifications()');
```

---

## Part 7: Push Notifications Integration

### 7.1 Backend (P2)

```sql
-- When notification created with category='push', send push via Firebase/APNs
CREATE OR REPLACE FUNCTION send_push_notification()
RETURNS trigger AS $$
BEGIN
  IF NEW.category = 'push' THEN
    -- Call edge function to send push via Firebase
    PERFORM net.http_post(
      url := 'https://[project-id].supabase.co/functions/v1/send-push',
      body := jsonb_build_object(
        'user_id', NEW.recipient_user_id,
        'title', NEW.type,  -- Flutter will localize
        'body', NEW.type,   -- Flutter will localize
        'data', jsonb_build_object(
          'notification_id', NEW.id,
          'deeplink', NEW.deeplink
        )
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER notification_push_send
AFTER INSERT ON notifications
FOR EACH ROW
WHEN (NEW.category = 'push')
EXECUTE FUNCTION send_push_notification();
```

### 7.2 Flutter (P1)

```dart
// Handle background push notifications
FirebaseMessaging.onBackgroundMessage((message) async {
  final notificationId = message.data['notification_id'];
  final deeplink = message.data['deeplink'];
  
  // Store for later navigation
  await LocalStorage.savePendingDeeplink(deeplink);
});

// Handle foreground push
FirebaseMessaging.onMessage.listen((message) {
  // Show in-app notification
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message.notification?.body ?? '')),
  );
  
  // Refresh notifications list
  ref.read(notificationsProvider.notifier).refresh();
});
```

---

## Summary

**Total:** 29 notification types  
**Status:** 1 implemented, 28 pending  
**Architecture:** Complete (DB schema + Flutter entities ready)  
**Estimated effort:** 5 weeks (5 phases)  

**Next steps:**
1. P2: Implement Phase 1 triggers (5 types)
2. P1: Update Flutter UI for Phase 1 rendering
3. Test end-to-end flow
4. Repeat for remaining phases

**Dependencies:**
- pg_cron extension for scheduled notifications
- Edge function for push notification sending
- Firebase/APNs setup for push delivery
