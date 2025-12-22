# Supabase RPC & Policies Needed

## 1. RLS Policy: Avatar URL Visibility for Group Members

**Problem:** Members cannot see profile pictures of other members in the same group.

**Root Causes:**
1. ❌ RLS policy may be blocking SELECT on `users.avatar_url`
2. ❌ Signed URLs may be expiring (buckets are private)
3. ❌ Storage bucket name mismatch (`users-profile-pic` vs `avatars`)

**Solution:** Create RLS policy on `users` table to allow SELECT of `avatar_url` when users share a group.

```sql
-- Policy: Allow users to see avatar_url of members in their groups
CREATE POLICY "users_can_view_avatars_of_group_members"
ON public.users
FOR SELECT
USING (
  -- User can see their own avatar
  auth.uid() = id
  OR
  -- User can see avatars of users in the same groups
  EXISTS (
    SELECT 1
    FROM public.group_members gm1
    INNER JOIN public.group_members gm2 ON gm1.group_id = gm2.group_id
    WHERE gm1.user_id = auth.uid()
      AND gm2.user_id = users.id
  )
);
```

**Alternative (more performant with indexes):**
```sql
-- Policy: Allow users to see avatar_url of members in their groups (optimized)
CREATE POLICY "users_can_view_avatars_of_group_members_v2"
ON public.users
FOR SELECT
USING (
  auth.uid() = id
  OR
  id IN (
    SELECT DISTINCT gm2.user_id
    FROM public.group_members gm1
    INNER JOIN public.group_members gm2 ON gm1.group_id = gm2.group_id
    WHERE gm1.user_id = auth.uid()
  )
);
```

**Required Indexes:**
```sql
-- Index for fast group membership lookup
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON public.group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON public.group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_composite ON public.group_members(user_id, group_id);
```

**Debug Prints Added to Flutter Code:**
```dart
[GroupDetailsRepo] 👥 Processing member: userId=..., isCurrentUser=...
[GroupDetailsRepo] 👥 Raw users data: {...}
[GroupDetailsRepo] 🖼️ Avatar path from DB: "..."
[GroupDetailsRepo] 🔒 Avatar path exists, generating signed URL...
[GroupDetailsRepo] ✅ Using existing URL: ... (if starts with http)
[GroupDetailsRepo] 🔄 Normalized path: "..." (removes leading /)
[GroupDetailsRepo] ✅ Signed URL created: ... (success)
[GroupDetailsRepo] ❌ Failed to create signed URL: ... (error)
[GroupDetailsRepo] ⚠️ No avatar path for user ... (null/empty)
```

**Storage Bucket Check:**
- Bucket name: `users-profile-pic` (used in code)
- Alternative: `avatars` (mentioned in other docs)
- **⚠️ Verify correct bucket name in Supabase Storage**

---

## 2. Materialized View: `home_events_view`

**Problem:** Only 1 pending event appears when there should be more from different groups.

**Root Cause:** The view `home_events_view` likely doesn't exist or is missing critical joins for event_participants and group_members.

**Solution:** Create materialized view that aggregates home events with user RSVP status.

```sql
-- Materialized view for home events (optimized for performance)
-- Creates ONE ROW per event per user (not multiple rows per participant)
CREATE MATERIALIZED VIEW IF NOT EXISTS public.home_events_view AS
SELECT 
  e.id AS event_id,
  e.name AS event_name,
  e.emoji,
  e.group_id,
  g.name AS group_name,
  e.start_datetime,
  e.end_datetime,
  l.display_name AS location_name,
  e.status AS event_status,
  
  -- User-specific data (creates one row per user per event)
  ep_user.user_id,
  ep_user.rsvp AS user_rsvp,
  ep_user.confirmed_at AS voted_at,
  
  -- Aggregations across ALL participants of the event
  COUNT(DISTINCT CASE WHEN ep_all.rsvp = 'yes' THEN ep_all.user_id END) AS going_count,
  COUNT(DISTINCT ep_all.user_id) AS participants_total,
  COUNT(DISTINCT CASE WHEN ep_all.rsvp IN ('yes', 'no') THEN ep_all.user_id END) AS voters_total,
  
  -- JSON arrays of users by RSVP status (aggregated from ALL participants)
  jsonb_agg(
    DISTINCT CASE 
      WHEN ep_all.rsvp = 'yes' THEN 
        jsonb_build_object(
          'user_id', ep_all.user_id,
          'name', u_all.name,
          'avatar_url', u_all.avatar_url
        )
      END
  ) FILTER (WHERE ep_all.rsvp = 'yes') AS going_users,
  
  jsonb_agg(
    DISTINCT CASE 
      WHEN ep_all.rsvp = 'no' THEN 
        jsonb_build_object(
          'user_id', ep_all.user_id,
          'name', u_all.name,
          'avatar_url', u_all.avatar_url
        )
      END
  ) FILTER (WHERE ep_all.rsvp = 'no') AS not_going_users,
  
  jsonb_agg(
    DISTINCT CASE 
      WHEN ep_all.rsvp NOT IN ('yes', 'no') OR ep_all.rsvp IS NULL THEN 
        jsonb_build_object(
          'user_id', ep_all.user_id,
          'name', u_all.name,
          'avatar_url', u_all.avatar_url
        )
      END
  ) FILTER (WHERE ep_all.rsvp NOT IN ('yes', 'no') OR ep_all.rsvp IS NULL) AS no_response_users

FROM public.events e
-- Join to get THIS user's participation (creates one row per user per event)
INNER JOIN public.event_participants ep_user ON ep_user.pevent_id = e.id
-- Join to get ALL participants for aggregations
LEFT JOIN public.event_participants ep_all ON ep_all.pevent_id = e.id
-- Join other tables
LEFT JOIN public.groups g ON g.id = e.group_id
LEFT JOIN public.locations l ON l.id = e.location_id
LEFT JOIN public.users u_all ON u_all.id = ep_all.user_id

WHERE e.status IN ('pending', 'confirmed', 'living', 'recap')

GROUP BY 
  e.id,
  e.name,
  e.emoji,
  e.group_id,
  g.name,
  e.start_datetime,
  e.end_datetime,
  l.display_name,
  e.status,
  -- Only group by THIS user's data (not all participants)
  ep_user.user_id,
  ep_user.rsvp,
  ep_user.confirmed_at;

-- Create index for fast lookups
CREATE INDEX IF NOT EXISTS idx_home_events_view_user_id ON public.home_events_view(user_id);
CREATE INDEX IF NOT EXISTS idx_home_events_view_status ON public.home_events_view(event_status);
CREATE INDEX IF NOT EXISTS idx_home_events_view_rsvp ON public.home_events_view(user_rsvp);
CREATE INDEX IF NOT EXISTS idx_home_events_view_composite ON public.home_events_view(user_id, event_status, user_rsvp);

-- Refresh function (call this after event/participant changes)
CREATE OR REPLACE FUNCTION refresh_home_events_view()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.home_events_view;
END;
$$ LANGUAGE plpgsql;
```

**Auto-refresh trigger** (optional, for real-time updates):
```sql
-- Trigger to refresh view when events or participants change
CREATE OR REPLACE FUNCTION trigger_refresh_home_events_view()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM refresh_home_events_view();
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER events_changed
AFTER INSERT OR UPDATE OR DELETE ON public.events
FOR EACH STATEMENT
EXECUTE FUNCTION trigger_refresh_home_events_view();

CREATE TRIGGER participants_changed
AFTER INSERT OR UPDATE OR DELETE ON public.event_participants
FOR EACH STATEMENT
EXECUTE FUNCTION trigger_refresh_home_events_view();
```

---

## 3. Materialized View: `group_photos_with_uploader` 

**Problem:** Error when viewing photos in group_hub details.

**Root Cause:** 
1. ❌ The view `group_photos_with_uploader` **does NOT have `group_id` field**
2. ❌ The Flutter code was trying to query `.eq('group_id', groupId)` on a view that doesn't have that column
3. ✅ **FIXED:** Now queries `events` table first to get `event_ids`, then queries view with `.inFilter('event_id', eventIds)`

**Your current view structure:**
```sql
-- Your view is missing group_id!
create materialized view public.group_photos_with_uploader as
select
  gp.id,
  gp.event_id,  -- Has event_id
  gp.url,
  gp.storage_path,
  gp.captured_at,
  gp.uploader_id,
  gp.is_portrait,
  gp.created_at,
  gp.updated_at,
  u.name as uploader_name,
  u.avatar_url as uploader_avatar
from
  group_photos gp
  left join users u on gp.uploader_id = u.id;
-- Missing: left join events e on gp.event_id = e.id
-- Missing: e.group_id field
```

**Solution Option 1: Update view to include group_id (RECOMMENDED)**
```sql
-- Drop and recreate view with group_id
DROP MATERIALIZED VIEW IF EXISTS public.group_photos_with_uploader;

CREATE MATERIALIZED VIEW public.group_photos_with_uploader AS
SELECT 
  gp.id,
  gp.event_id,
  gp.url,
  gp.storage_path,
  gp.captured_at,
  gp.uploader_id,
  gp.is_portrait,
  gp.created_at,
  gp.updated_at,
  u.name AS uploader_name,
  u.avatar_url AS uploader_avatar,
  e.group_id  -- ✅ ADD THIS
FROM public.group_photos gp
LEFT JOIN public.users u ON gp.uploader_id = u.id
LEFT JOIN public.events e ON gp.event_id = e.id;  -- ✅ ADD THIS JOIN

-- Index for fast group_id lookups
CREATE INDEX IF NOT EXISTS idx_group_photos_with_uploader_group_id 
ON public.group_photos_with_uploader(group_id);

-- Index for event_id (backup)
CREATE INDEX IF NOT EXISTS idx_group_photos_with_uploader_event_id 
ON public.group_photos_with_uploader(event_id);
```

**Solution Option 2: Keep current code (ALREADY IMPLEMENTED)**
The Flutter code now works around the missing `group_id` by:
1. Querying `events` table to get all `event_ids` for the group
2. Using `.inFilter('event_id', eventIds)` on the view

**Debug Prints Added:**
```dart
[GroupPhotosDataSource] 📸 Fetching photos for group: {groupId}
[GroupPhotosDataSource] 🎯 Found X events in group
[GroupPhotosDataSource] ✅ Found Y photos
[GroupPhotosDataSource] 🖼️ Photo: id=..., event=..., uploader=...
[GroupPhotosDataSource] ❌ Error fetching photos: {error}
```

**RLS Policy for group_photos:**
```sql
-- Policy: Allow users to view photos from their group events
CREATE POLICY "users_can_view_group_photos"
ON public.group_photos
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.events e
    INNER JOIN public.event_participants ep ON ep.pevent_id = e.id
    WHERE e.id = group_photos.event_id
      AND ep.user_id = auth.uid()
  )
);
```

---

## 4. Debug Query: Check Pending Events

Run this to see all pending events for a user:

```sql
-- Replace 'USER_ID_HERE' with actual user ID
SELECT 
  e.id,
  e.name,
  e.status,
  g.name AS group_name,
  ep.rsvp AS user_rsvp,
  ep.confirmed_at AS voted_at
FROM public.events e
INNER JOIN public.event_participants ep ON ep.pevent_id = e.id
LEFT JOIN public.groups g ON g.id = e.group_id
WHERE ep.user_id = 'USER_ID_HERE'
  AND e.status = 'pending'
ORDER BY e.start_datetime;
```

**Expected behavior:**
- Should return ALL pending events from all groups the user is a participant in
- Not filtered by RSVP status (per user requirement)

---

## Summary of Actions Needed (P2 Team)

1. ✅ **Create RLS policy** for `users.avatar_url` visibility
2. ✅ **Create materialized view** `home_events_view` with proper joins
3. ✅ **Create indexes** for performance optimization
4. ✅ **Verify** `group_photos_with_uploader` view exists
5. ✅ **Create RLS policy** for `group_photos` table
6. ⚠️ **Test** pending events query returns events from all groups

**Performance considerations:**
- Materialized views refresh on schedule (every 5 min) or trigger-based
- Use `REFRESH MATERIALIZED VIEW CONCURRENTLY` to avoid locking
- Indexes are critical for `.eq('user_id', ...)` queries
