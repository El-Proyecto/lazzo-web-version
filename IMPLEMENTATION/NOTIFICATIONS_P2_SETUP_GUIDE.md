# Notifications System - P2 Backend Setup Guide

**Status:** Ready for Implementation  
**Date:** 2025-12-19  
**Responsible:** P2 Backend Team

---

## Overview

This document provides step-by-step instructions for implementing the complete notifications system (29 notification types) in Supabase.

---

## Prerequisites

✅ `notifications` table exists (confirmed in `supabase_structure.sql`)  
✅ All required tables exist (users, groups, events, group_invites, etc.)  
✅ Flutter enums defined (29 notification types in `notification_entity.dart`)  
✅ Flutter UI ready (notification_card.dart supports all action buttons)

---

## Part 1: Database Setup

### 1.1 Execute SQL File

**File:** `supabase_notifications_triggers.sql`

1. Open Supabase SQL Editor
2. Copy entire contents of `supabase_notifications_triggers.sql`
3. Execute the SQL
4. Verify no errors

**What gets created:**
- 1 helper function (`should_send_notification`)
- 20+ triggers for automatic notification creation
- 5+ scheduled functions for time-based notifications
- 1 cleanup function for expired notifications

---

### 1.2 Enable pg_cron Extension

```sql
CREATE EXTENSION IF NOT EXISTS pg_cron;
```

Verify:
```sql
SELECT * FROM pg_available_extensions WHERE name = 'pg_cron';
```

---

### 1.3 Schedule Cron Jobs

Execute these commands to schedule time-based notifications:

```sql
-- Event starts soon (every 10 minutes)
SELECT cron.schedule(
  'notify-events-starting',
  '*/10 * * * *',
  'SELECT notify_event_starts_soon()'
);

-- Event live (every 5 minutes)
SELECT cron.schedule(
  'notify-events-live',
  '*/5 * * * *',
  'SELECT notify_event_live()'
);

-- Event ends soon (every 10 minutes)
SELECT cron.schedule(
  'notify-events-ending',
  '*/10 * * * *',
  'SELECT notify_event_ends_soon()'
);

-- Uploads closing (every hour)
SELECT cron.schedule(
  'notify-uploads-closing',
  '0 * * * *',
  'SELECT notify_uploads_closing()'
);

-- Cleanup expired notifications (daily at 2 AM)
SELECT cron.schedule(
  'cleanup-notifications',
  '0 2 * * *',
  'SELECT cleanup_expired_notifications()'
);
```

Verify cron jobs:
```sql
SELECT * FROM cron.job;
```

---

### 1.4 Create RLS Policies

#### Policy 1: Users can read their own notifications
```sql
CREATE POLICY "Users can read own notifications"
ON notifications
FOR SELECT
USING (auth.uid() = recipient_user_id);
```

#### Policy 2: Users can update their own notifications (mark as read)
```sql
CREATE POLICY "Users can update own notifications"
ON notifications
FOR UPDATE
USING (auth.uid() = recipient_user_id);
```

#### Policy 3: Service role can insert notifications (for triggers)
```sql
-- Already handled by triggers running as SECURITY DEFINER
-- No additional policy needed
```

#### Policy 4: Users can delete their own notifications
```sql
CREATE POLICY "Users can delete own notifications"
ON notifications
FOR DELETE
USING (auth.uid() = recipient_user_id);
```

Enable RLS:
```sql
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
```

---

## Part 2: Testing

### 2.1 Test Group Invite Notification

**Setup:**
```sql
-- Create test users
INSERT INTO users (id, name, email) VALUES 
  ('11111111-1111-1111-1111-111111111111', 'Alice', 'alice@test.com'),
  ('22222222-2222-2222-2222-222222222222', 'Bob', 'bob@test.com');

-- Create test group
INSERT INTO groups (id, name, created_by) VALUES
  ('33333333-3333-3333-3333-333333333333', 'Test Group', '11111111-1111-1111-1111-111111111111');
```

**Trigger notification:**
```sql
-- Invite Bob to group (should create groupInviteReceived notification)
INSERT INTO group_invites (group_id, invited_id, invited_by) VALUES
  ('33333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111');
```

**Verify:**
```sql
SELECT 
  type,
  category,
  priority,
  user_name,
  group_name,
  deeplink,
  created_at
FROM notifications 
WHERE recipient_user_id = '22222222-2222-2222-2222-222222222222'
  AND type = 'groupInviteReceived';
```

**Expected result:**
- 1 row returned
- type = 'groupInviteReceived' (camelCase)
- category = 'push'
- priority = 'high'
- user_name = 'Alice'
- group_name = 'Test Group'
- deeplink = 'lazzo://group/33333333-3333-3333-3333-333333333333'

**Cleanup:**
```sql
DELETE FROM notifications WHERE recipient_user_id = '22222222-2222-2222-2222-222222222222';
DELETE FROM group_invites WHERE group_id = '33333333-3333-3333-3333-333333333333';
DELETE FROM groups WHERE id = '33333333-3333-3333-3333-333333333333';
DELETE FROM users WHERE id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');
```

---

### 2.2 Test Event Created Notification

**Setup:**
```sql
-- Create test group with members
INSERT INTO groups (id, name, created_by) VALUES
  ('33333333-3333-3333-3333-333333333333', 'Test Group', '11111111-1111-1111-1111-111111111111');

INSERT INTO group_members (group_id, user_id, role) VALUES
  ('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'admin'),
  ('33333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222', 'member');
```

**Trigger notification:**
```sql
-- Create event (should notify Bob)
INSERT INTO events (id, name, emoji, group_id, created_by) VALUES
  ('44444444-4444-4444-4444-444444444444', 'Beach Day', '🏖️', '33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111');
```

**Verify:**
```sql
SELECT 
  type,
  category,
  event_emoji,
  event_name,
  group_name,
  deeplink
FROM notifications 
WHERE recipient_user_id = '22222222-2222-2222-2222-222222222222'
  AND type = 'eventCreated';
```

**Expected result:**
- type = 'eventCreated'
- category = 'notifications'
- priority = 'medium'
- event_emoji = '🏖️'
- event_name = 'Beach Day'
- group_name = 'Test Group'
- deeplink = 'lazzo://event/44444444-4444-4444-4444-444444444444'

---

### 2.3 Test Scheduled Notifications

**Test event starts soon:**
```sql
-- Create event starting in 15 minutes
INSERT INTO events (id, name, emoji, status, start_datetime, created_by) VALUES
  ('55555555-5555-5555-5555-555555555555', 'Dinner', '🍽️', 'confirmed', NOW() + interval '15 minutes', '11111111-1111-1111-1111-111111111111');

-- Add participant
INSERT INTO event_participants (pevent_id, user_id, rsvp) VALUES
  ('55555555-5555-5555-5555-555555555555', '22222222-2222-2222-2222-222222222222', 'going');

-- Manually trigger function (cron will do this automatically every 10 min)
SELECT notify_event_starts_soon();
```

**Verify:**
```sql
SELECT 
  type,
  category,
  priority,
  event_name,
  mins,
  deeplink
FROM notifications 
WHERE recipient_user_id = '22222222-2222-2222-2222-222222222222'
  AND type = 'eventStartsSoon';
```

**Expected result:**
- type = 'eventStartsSoon'
- category = 'push'
- priority = 'high'
- mins ≈ '15' (may vary slightly)

---

### 2.4 Test Deduplication

**Attempt to create duplicate notification:**
```sql
-- Create same notification twice within 5 minutes
INSERT INTO notifications (recipient_user_id, type, category, priority, group_id, event_id)
VALUES 
  ('22222222-2222-2222-2222-222222222222', 'eventCreated', 'notifications', 'medium', '33333333-3333-3333-3333-333333333333', '44444444-4444-4444-4444-444444444444'),
  ('22222222-2222-2222-2222-222222222222', 'eventCreated', 'notifications', 'medium', '33333333-3333-3333-3333-333333333333', '44444444-4444-4444-4444-444444444444');
```

**Expected behavior:**
- Second INSERT should fail with unique constraint violation
- Deduplication prevents spam within 5-minute window

---

### 2.5 Test Cleanup Function

```sql
-- Create old read notification (31 days ago)
INSERT INTO notifications (recipient_user_id, type, category, priority, is_read, created_at)
VALUES 
  ('22222222-2222-2222-2222-222222222222', 'general', 'notifications', 'low', TRUE, NOW() - interval '31 days');

-- Run cleanup
SELECT cleanup_expired_notifications();

-- Verify old notification was deleted
SELECT COUNT(*) FROM notifications 
WHERE recipient_user_id = '22222222-2222-2222-2222-222222222222'
  AND created_at < NOW() - interval '30 days';
```

**Expected result:** 0 rows (old notification deleted)

---

## Part 3: Performance Optimization

### 3.1 Add Indexes (if not already exist)

```sql
-- Fast lookups by recipient
CREATE INDEX IF NOT EXISTS idx_notifications_recipient 
ON notifications(recipient_user_id, is_read, created_at DESC);

-- Deduplication enforcement
CREATE UNIQUE INDEX IF NOT EXISTS idx_notifications_dedup_unique
ON notifications(dedup_key, dedup_bucket)
WHERE is_read = FALSE;

-- Cleanup queries
CREATE INDEX IF NOT EXISTS idx_notifications_cleanup
ON notifications(created_at, is_read, category);

-- Event/group foreign keys
CREATE INDEX IF NOT EXISTS idx_notifications_event
ON notifications(event_id) WHERE event_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notifications_group
ON notifications(group_id) WHERE group_id IS NOT NULL;
```

### 3.2 Monitor Query Performance

```sql
-- Check slow queries
SELECT * FROM pg_stat_statements 
WHERE query LIKE '%notifications%' 
ORDER BY total_exec_time DESC 
LIMIT 10;
```

---

## Part 4: Known Issues & Limitations

### 4.1 Chat Mentions (@username)

**Issue:** Current regex for @mentions is basic and may not match all usernames correctly.

**Improvement needed:**
```sql
-- Better regex pattern
NEW.content ~* ('(?:^|\\s)@' || mentioned_user.name || '(?:\\s|$)')
```

### 4.2 Payment Request Trigger

**Issue:** Assumes `payment_requests` table exists (not confirmed in schema).

**Action:** Either:
1. Create `payment_requests` table with proper structure
2. Use `event_expenses` table differently
3. Implement payment requests via RPC function

### 4.3 Memory Ready Notification

**Issue:** Requires manual RPC call after memory compilation.

**Action:** Memory generation service must call:
```sql
SELECT notify_memory_ready('event-id-here');
```

### 4.4 Quiet Hours Implementation

**Issue:** `should_send_notification()` checks quiet hours but doesn't account for user timezone.

**Improvement:** Store user timezone in `user_notification_settings` and compare with `CURRENT_TIME AT TIME ZONE user_timezone`.

---

## Part 5: Monitoring & Maintenance

### 5.1 Monitor Cron Jobs

```sql
-- Check cron job execution history
SELECT jobid, jobname, status, return_message, start_time, end_time
FROM cron.job_run_details
ORDER BY start_time DESC
LIMIT 20;

-- Check for failed jobs
SELECT * FROM cron.job_run_details
WHERE status != 'succeeded'
ORDER BY start_time DESC;
```

### 5.2 Notification Statistics

```sql
-- Notifications sent per day (last 7 days)
SELECT 
  DATE(created_at) as date,
  type,
  category,
  COUNT(*) as count
FROM notifications
WHERE created_at >= NOW() - interval '7 days'
GROUP BY DATE(created_at), type, category
ORDER BY date DESC, count DESC;

-- Most common notification types
SELECT 
  type,
  category,
  COUNT(*) as count,
  ROUND(AVG(CASE WHEN is_read THEN 1 ELSE 0 END) * 100, 2) as read_percentage
FROM notifications
WHERE created_at >= NOW() - interval '30 days'
GROUP BY type, category
ORDER BY count DESC;

-- Unread notifications per user
SELECT 
  u.name,
  COUNT(*) as unread_count
FROM notifications n
JOIN users u ON u.id = n.recipient_user_id
WHERE n.is_read = FALSE
GROUP BY u.id, u.name
ORDER BY unread_count DESC
LIMIT 10;
```

### 5.3 Performance Metrics

```sql
-- Average notification delivery time (trigger execution)
SELECT 
  schemaname,
  tablename,
  proname as trigger_function,
  calls,
  total_time,
  mean_time
FROM pg_stat_user_functions
WHERE proname LIKE 'notify_%'
ORDER BY mean_time DESC;
```

---

## Part 6: Rollback Plan

If critical issues arise after deployment:

### 6.1 Disable All Triggers

```sql
-- Disable notification triggers (keeps data, stops new notifications)
ALTER TABLE group_invites DISABLE TRIGGER group_invite_notification;
ALTER TABLE group_members DISABLE TRIGGER group_member_joined_notification;
ALTER TABLE groups DISABLE TRIGGER group_renamed_notification;
ALTER TABLE groups DISABLE TRIGGER group_photo_changed_notification;
ALTER TABLE events DISABLE TRIGGER event_created_notification;
ALTER TABLE events DISABLE TRIGGER event_date_set_notification;
ALTER TABLE events DISABLE TRIGGER event_location_set_notification;
ALTER TABLE events DISABLE TRIGGER event_details_updated_notification;
ALTER TABLE events DISABLE TRIGGER event_confirmed_notification;
ALTER TABLE events DISABLE TRIGGER event_canceled_notification;
ALTER TABLE events DISABLE TRIGGER event_restored_notification;
ALTER TABLE events DISABLE TRIGGER event_extended_notification;
ALTER TABLE events DISABLE TRIGGER uploads_open_notification;
ALTER TABLE events DISABLE TRIGGER add_photos_action_notification;
ALTER TABLE event_expenses DISABLE TRIGGER expense_added_notification;
ALTER TABLE expense_splits DISABLE TRIGGER expense_paid_notification;
ALTER TABLE chat_messages DISABLE TRIGGER chat_mention_notification;
ALTER TABLE location_suggestions DISABLE TRIGGER suggestion_added_notification;
ALTER TABLE event_date_options DISABLE TRIGGER date_suggestion_added_notification;
```

### 6.2 Pause Cron Jobs

```sql
-- Unschedule cron jobs (can be re-enabled later)
SELECT cron.unschedule('notify-events-starting');
SELECT cron.unschedule('notify-events-live');
SELECT cron.unschedule('notify-events-ending');
SELECT cron.unschedule('notify-uploads-closing');
SELECT cron.unschedule('cleanup-notifications');
```

### 6.3 Re-enable After Fix

```sql
-- Re-enable triggers
ALTER TABLE group_invites ENABLE TRIGGER group_invite_notification;
-- (repeat for all triggers)

-- Re-schedule cron jobs
SELECT cron.schedule('notify-events-starting', '*/10 * * * *', 'SELECT notify_event_starts_soon()');
-- (repeat for all jobs)
```

---

## Part 7: Next Steps

After successful implementation:

1. **Flutter Integration:**
   - Test deeplink navigation to event/group pages
   - Verify action buttons work (Accept/Decline, Vote, RSVP, etc.)
   - Test mark-as-read functionality

2. **Push Notifications:**
   - Create Edge Function to send push via Firebase/APNs
   - Trigger on `INSERT` to notifications where `category='push'`
   - Pass `notification_id` and `deeplink` to client

3. **I18n:**
   - Replace hardcoded English messages with i18n keys
   - Support Portuguese translations

4. **Analytics:**
   - Track notification open rate
   - Track action button click-through rate
   - Identify low-engagement notification types

---

## Contact

Questions or issues? Contact:
- **P1 Team:** Flutter/UI implementation
- **P2 Team:** Database/triggers/backend
- **Documentation:** `NOTIFICATIONS_COMPLETE_IMPLEMENTATION.md`
