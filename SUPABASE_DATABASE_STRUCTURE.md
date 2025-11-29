# Lazzo — Supabase Database Structure

**Audience:** Developers and AI agents working with the Lazzo backend.  
**Purpose:** Complete reference for the Supabase database schema, including tables, relationships, indexes, triggers, views, and optimization guidelines.

> **Status:** This database is serving a live beta application and is subject to ongoing changes and optimizations. Tables marked with ⚠️ are pending implementation or significant updates based on incomplete P2 handoffs.

---

## Database Overview

The Lazzo database supports a private, group-based event planning and memory-sharing application. The schema follows these core domains:

1. **Users & Auth** — User profiles and authentication
2. **Groups** — Private friend groups with members, settings, and invites
3. **Events** — Event planning, scheduling, lifecycle management (planning → live → ended)
4. **Locations** — Event locations with coordinates and polling
5. **Chat & Messages** — Event-scoped and group-scoped messaging with read tracking
6. **Photos & Memories** — Event photos, uploads, and post-event memory compilation
7. **Expenses & Payments** — Event expense tracking, splits, and settlement (⚠️ pending full implementation)
8. **Notifications & Inbox** — User notifications and action items (⚠️ pending implementation)

**Current status:** 21 tables (including `location_suggestions`), 4 views (1 materialized), multiple triggers and RLS policies. Database serves live beta application with ongoing optimizations.

---

## Performance & Optimization Guidelines

When working with this database, always prioritize:

### 1. Query Optimization
- **Select only required columns** — Never use `SELECT *` in production queries
- **Use indexed columns** for filtering, sorting, and joins
- **Always add LIMIT** to paginated queries
- **Leverage materialized views** (e.g., `group_hub_events_cache`) for complex aggregations
- **Batch operations** where possible to reduce round trips

### 2. Schema Design Best Practices
- **Denormalize strategically** — Use materialized views for read-heavy aggregations
- **Foreign keys with CASCADE** — Ensure data integrity and simplify cleanup
- **Constraints at DB level** — Validate data (e.g., `ends_at > starts_at`) in schema
- **Use UUIDs** for all primary keys to avoid collisions in distributed systems

### 3. Caching Strategies
- **Materialized views** for expensive queries (refresh via triggers)
- **Client-side caching** with Riverpod providers (cache entities, not raw data)
- **Local database** (consider SQLite/Isar) for offline-first features
- **Stale-while-revalidate** pattern for non-critical data

### 4. Efficient Indexing
- **Composite indexes** for common query patterns (e.g., `event_id + created_at DESC`)
- **Partial indexes** for filtered queries (e.g., `WHERE is_deleted = false`)
- **Index maintenance** — Monitor index usage; drop unused indexes
- **B-tree indexes** for equality and range queries; consider GiST/GIN for specialized needs

### 5. Local Database Usage
- **Cache frequently accessed data** (user profile, group list, recent events)
- **Optimistic updates** — Update local first, sync to Supabase async
- **Conflict resolution** — Use `updated_at` timestamps for last-write-wins
- **Selective sync** — Only sync active/visible groups and events

### 6. Payload Size Minimization
- **Paginate all lists** (events, messages, photos) with `limit + offset` or cursor-based
- **Compress images** before upload (see `image_compression_service.dart`)
- **JSON field pruning** — Only include non-null fields in responses
- **Use storage CDN** for images; never fetch full blobs via API

---

## Custom Enum Types

Supabase uses PostgreSQL custom enum types for several fields. These enforce type safety at the database level:

1. **`rsvp_status`** — Event participant RSVP states
   - Values: `'going'`, `'cant'`, `'pending'`
   - Used in: `event_participants.rsvp`

2. **`event_state`** — Event lifecycle states
   - Values: `'pending'`, `'planning'`, `'confirmed'`, `'live'`, `'ended'`, `'cancelled'`
   - Used in: `events.status`

3. **`member_role`** — Group member roles
   - Values: `'admin'`, `'member'`
   - Used in: `group_members.role`

4. **`message_type`** — Message content types
   - Values: `'text'` (others TBD: `'image'`, `'file'`, etc.)
   - Used in: `group_messages.type`

**Important:** When querying or inserting, cast string values to the enum type:
```sql
-- Correct
INSERT INTO event_participants (pevent_id, user_id, rsvp) VALUES ($1, $2, 'going'::rsvp_status);

-- Also correct (Supabase client handles casting)
await supabase.from('event_participants').insert({ pevent_id: id, user_id: userId, rsvp: 'going' });
```

---

## Core Tables

**Complete table list (21 tables):**
1. `users` ⚠️ — User profiles and authentication
2. `groups` — Private friend groups
3. `group_members` — Group membership and roles
4. `group_invites` ⚠️ — Time-limited invite links
5. `group_user_settings` — Per-user, per-group preferences
6. `group_messages` ⚠️ — Group-scoped messaging
7. `events` — Core event entity (planning/live/ended)
8. `event_participants` — User RSVP and participation
9. `event_date_options` — Date/time polling options
10. `event_date_votes` — User votes on dates
11. `locations` — Event locations with coordinates
12. `location_suggestions` ⚠️ — User location suggestions for events
13. `location_suggestion_votes` ⚠️ — Votes on location suggestions
14. `chat_messages` — Event-scoped chat
15. `message_reads` ⚠️ — Message read receipts (for group_messages)
16. `group_photos` — Event photos and uploads
17. `photos` ⚠️ — Alternative photo table (may be legacy)
18. `memories` ⚠️ — Post-event memory compilation
19. `event_expenses` ⚠️ — Expense tracking
20. `expense_splits` ⚠️ — Per-user expense splits
21. `notifications` ⚠️ — User notifications

---

### users ⚠️ (Pending full implementation)

**Purpose:** User profiles and authentication data.

**Status:** ⚠️ Core structure exists but will be expanded for profile features (see `PROFILE_P1_P2_HANDOFF.md`, `EDIT_PROFILE_P1_P2_HANDOFF.md`, `OTHER_PROFILE_P1_P2_HANDOFF.md`).

**Expected fields:**
- `id` (uuid, PK)
- `email` (text, unique)
- `username` (text, unique, nullable initially)
- `display_name` (text)
- `avatar_url` (text, nullable)
- `phone` (text, nullable, for future payment integrations)
- `bio` (text, nullable)
- `created_at` (timestamptz)
- `updated_at` (timestamptz)

**Relationships:**
- Referenced by `group_members.user_id`
- Referenced by `event_participants.user_id`
- Referenced by `chat_messages.user_id`
- Referenced by `group_photos.uploader_id`
- Referenced by `events.created_by`

**Notes:**
- Auth handled by Supabase Auth; this table extends profile data
- Privacy: users can control profile visibility per group

---

### groups

**Purpose:** Private friend groups that contain events, members, and shared memories.

**Schema:**
```sql
CREATE TABLE groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  cover_photo_url text,
  created_by uuid NOT NULL REFERENCES users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT groups_name_length CHECK (char_length(name) >= 1 AND char_length(name) <= 100)
);
```

**Indexes:**
- `idx_groups_created_by` on `created_by`
- `idx_groups_created_at` on `created_at DESC`

**Triggers:**
- `on_group_created` — Adds creator as first member (admin role)
- `update_groups_updated_at` — Auto-updates `updated_at` on row changes

**Relationships:**
- Has many `group_members`
- Has many `events`
- Has many `group_photos`
- Has many `group_invites`

**Query patterns:**
- List user's groups: `SELECT * FROM groups WHERE id IN (SELECT group_id FROM group_members WHERE user_id = $1) ORDER BY updated_at DESC LIMIT 20`
- Group detail: `SELECT * FROM groups WHERE id = $1`

**RLS:** Must be a group member to read/write.

---

### group_members

**Purpose:** Many-to-many relationship between users and groups with role-based access.

**Schema:**
```sql
CREATE TABLE group_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(group_id, user_id)
);
```

**Indexes:**
- `idx_group_members_user_id` on `user_id`

**Relationships:**
- Belongs to `groups`
- Belongs to `users`

**Query patterns:**
- Check membership: `SELECT EXISTS(SELECT 1 FROM group_members WHERE group_id = $1 AND user_id = $2)`
- List group members: `SELECT user_id, role FROM group_members WHERE group_id = $1`

**RLS:** Users can read their own memberships; admins can manage group members.

---

### group_invites ⚠️ (Needs refinement)

**Purpose:** Time-limited invite links for joining groups.

**Status:** ⚠️ Basic structure exists; needs enhancement for QR codes and expiry handling (see `EDIT_GROUP_P1_P2_HANDOFF.md`).

**Schema:**
```sql
CREATE TABLE group_invites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  invite_code text UNIQUE NOT NULL,
  created_by uuid NOT NULL REFERENCES users(id),
  expires_at timestamptz NOT NULL,
  max_uses int,
  current_uses int DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);
```

**Query patterns:**
- Validate invite: `SELECT * FROM group_invites WHERE invite_code = $1 AND expires_at > now() AND (max_uses IS NULL OR current_uses < max_uses)`
- Increment usage: `UPDATE group_invites SET current_uses = current_uses + 1 WHERE id = $1`

**Notes:**
- Default expiry: 48 hours from creation
- Deep links format: `lazzo://invite/{invite_code}`

---

### group_user_settings

**Purpose:** Per-user, per-group notification and display preferences.

**Schema:**
```sql
CREATE TABLE group_user_settings (
  group_id uuid NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  is_pinned boolean NOT NULL DEFAULT false,
  is_muted boolean NOT NULL DEFAULT false,
  group_state text NOT NULL DEFAULT 'active',
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (group_id, user_id)
);
```

**Query patterns:**
- Get user settings for group: `SELECT * FROM group_user_settings WHERE group_id = $1 AND user_id = $2`

**RLS:** Users can only read/write their own settings.

---

### events

**Purpose:** Core event entity representing planning, live, and recap phases.

**Schema:**
```sql
CREATE TABLE events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid REFERENCES groups(id) ON DELETE CASCADE,
  name text,
  emoji text,
  status event_state NOT NULL DEFAULT 'pending',
  start_datetime timestamptz,
  end_datetime timestamptz,
  location_id uuid REFERENCES locations(id),
  cover_photo_id uuid REFERENCES group_photos(id),
  created_by uuid NOT NULL REFERENCES users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Custom enum type
CREATE TYPE event_state AS ENUM ('pending', 'planning', 'confirmed', 'live', 'ended', 'cancelled');
```

**Indexes:**
- `idx_events_state` on `status`
- `idx_events_cover_photo` on `cover_photo_id`

**Triggers:**
- `events_changed` — Refreshes `group_hub_events_cache` materialized view
- `on_event_created` — Sends notifications to group members
- `on_event_created_add_participants` — Auto-adds group members as participants
- `update_events_updated_at` — Auto-updates `updated_at`

**Relationships:**
- Belongs to `groups`
- Has many `event_participants`
- Has many `event_date_options` (for polling)
- Has many `chat_messages`
- Has many `group_photos`
- Has many `event_expenses`

**Event lifecycle:**
1. **planning** — Initial state; RSVP collection, date/location polls
2. **confirmed** — Date/location set; RSVP threshold met
3. **live** — Event started; photo uploads enabled
4. **ended** — Event finished; 24h upload window begins
5. **cancelled** — Event cancelled by host

**Query patterns:**
- Upcoming events: `SELECT * FROM events WHERE group_id = $1 AND status IN ('planning', 'confirmed') AND starts_at > now() ORDER BY starts_at LIMIT 10`
- Live events: `SELECT * FROM events WHERE group_id = $1 AND status = 'live' ORDER BY starts_at DESC LIMIT 1`
- Recent memories: `SELECT * FROM events WHERE group_id = $1 AND status = 'ended' ORDER BY ends_at DESC LIMIT 20`

**RLS:** Group members can read; creators and admins can update.

---

### locations

**Purpose:** Event locations with map integration.

**Schema:**
```sql
CREATE TABLE locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  address text,
  latitude double precision,
  longitude double precision,
  place_id text,
  created_by uuid REFERENCES users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);
```

**Relationships:**
- Referenced by `events.location_id`
- Has many `location_suggestion_votes`

**Query patterns:**
- Find by coordinates: `SELECT * FROM locations WHERE ST_DWithin(geography(ST_MakePoint(longitude, latitude)), geography(ST_MakePoint($1, $2)), $3)`
- Autocomplete: `SELECT * FROM locations WHERE name ILIKE $1 LIMIT 10`
- Event location: `SELECT l.* FROM locations l JOIN events e ON e.location_id = l.id WHERE e.id = $1`

**Notes:**
- Consider PostGIS extension for geospatial queries
- Cache popular locations client-side
- Store Google Maps Place ID for integration

---

### location_suggestions ⚠️ (Needs implementation)

**Purpose:** User-created location suggestions for events during planning phase.

**Status:** ⚠️ Schema exists but not yet integrated into UI. Related to event planning flows and "Decide later" location feature.

**Schema:**
```sql
CREATE TABLE location_suggestions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  location_name text NOT NULL,
  address text,
  latitude double precision,
  longitude double precision,
  created_at timestamptz NOT NULL DEFAULT now()
);
```

**Relationships:**
- Belongs to `events`
- Belongs to `users` (suggester)
- Has many `location_suggestion_votes`

**Query patterns:**
- Get suggestions for event: `SELECT * FROM location_suggestions WHERE event_id = $1 ORDER BY created_at`
- Get suggestion with vote count: `SELECT ls.*, COUNT(lsv.id) as vote_count FROM location_suggestions ls LEFT JOIN location_suggestion_votes lsv ON lsv.suggestion_id = ls.id WHERE ls.event_id = $1 GROUP BY ls.id`

**Notes:**
- Users can suggest multiple locations per event
- Similar to `event_date_options` but for locations
- Part of the "Decide later" location polling feature

---

### location_suggestion_votes ⚠️ (Needs implementation)

**Purpose:** User votes on location suggestions for events (similar to date polls).

**Status:** ⚠️ Schema exists but not yet integrated into UI. Related to event planning flows.

**Schema:**
```sql
CREATE TABLE location_suggestion_votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  suggestion_id uuid NOT NULL REFERENCES location_suggestions(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);
```

**Indexes:**
- `idx_location_suggestion_votes_suggestion` on `suggestion_id`
- `idx_location_suggestion_votes_user` on `user_id`

**Query patterns:**
- Get votes for suggestion: `SELECT COUNT(*) FROM location_suggestion_votes WHERE suggestion_id = $1`
- User's vote: `SELECT * FROM location_suggestion_votes WHERE suggestion_id = $1 AND user_id = $2`
- Tally votes for event: `SELECT suggestion_id, COUNT(*) as votes FROM location_suggestion_votes WHERE suggestion_id IN (SELECT id FROM location_suggestions WHERE event_id = $1) GROUP BY suggestion_id ORDER BY votes DESC`

**Notes:**
- Similar pattern to `event_date_votes` but for locations
- Part of the "Decide later" location polling feature
- One vote per user per suggestion

---

### event_participants

**Purpose:** Many-to-many relationship between users and events with RSVP status.

**Schema:**
```sql
CREATE TABLE event_participants (
  pevent_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rsvp text DEFAULT 'pending' CHECK (rsvp IN ('going', 'cant', 'pending')),
  joined_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (pevent_id, user_id)
);
```

**Indexes:**
- `idx_ep_event_user` on `(pevent_id, user_id)`
- `idx_ep_event` on `pevent_id`
- `idx_ep_user` on `user_id`
- `idx_ep_event_rsvp` on `(pevent_id, rsvp)`

**Triggers:**
- `participants_changed` — Refreshes `group_hub_events_cache`

**Query patterns:**
- Get user RSVP: `SELECT rsvp FROM event_participants WHERE pevent_id = $1 AND user_id = $2`
- Count RSVPs: `SELECT rsvp, COUNT(*) FROM event_participants WHERE pevent_id = $1 GROUP BY rsvp`

**RLS:** Participants can read; users can update their own RSVP.

---

### event_date_options

**Purpose:** Date/time options for event scheduling polls.

**Schema:**
```sql
CREATE TABLE event_date_options (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT edo_time_check CHECK (ends_at > starts_at),
  UNIQUE (event_id, id)
);
```

**Indexes:**
- `uq_event_date_options_event_id_id` on `(event_id, id)`
- `idx_event_date_options_created_at` on `created_at`

**Relationships:**
- Belongs to `events`
- Has many `event_date_votes`

**Query patterns:**
- List options: `SELECT * FROM event_date_options WHERE event_id = $1 ORDER BY starts_at`

---

### event_date_votes

**Purpose:** User votes on event date options.

**Schema:**
```sql
CREATE TABLE event_date_votes (
  option_id uuid NOT NULL REFERENCES event_date_options(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  vote_status text NOT NULL CHECK (vote_status IN ('yes', 'no', 'maybe')),
  voted_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (option_id, user_id)
);
```

**Query patterns:**
- Get user vote: `SELECT vote_status FROM event_date_votes WHERE option_id = $1 AND user_id = $2`
- Tally votes: `SELECT option_id, vote_status, COUNT(*) FROM event_date_votes WHERE option_id IN ($1, $2, ...) GROUP BY option_id, vote_status`

---

### chat_messages

**Purpose:** Event-scoped chat messages (planning + live + 24h post-event).

**Schema:**
```sql
CREATE TABLE chat_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  message text NOT NULL,
  reply_to_id uuid REFERENCES chat_messages(id),
  is_pinned boolean DEFAULT false,
  is_deleted boolean DEFAULT false,
  read boolean DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

**Indexes:**
- `idx_chat_messages_event_created` on `(event_id, created_at DESC)`
- `idx_chat_messages_event_pinned` on `(event_id, is_pinned, created_at DESC)` WHERE `is_pinned = true`
- `idx_chat_messages_event_not_deleted` on `(event_id, is_deleted, created_at DESC)` WHERE `is_deleted = false`
- `idx_chat_messages_event_read` on `(event_id, read)` WHERE `read = false`
- `idx_chat_messages_reply_to` on `reply_to_id` WHERE `reply_to_id IS NOT NULL`
- `idx_chat_messages_user` on `user_id`

**Triggers:**
- `chat_messages_updated_at_trigger` — Auto-updates `updated_at`

**Query patterns:**
- Recent messages: `SELECT * FROM chat_messages WHERE event_id = $1 AND is_deleted = false ORDER BY created_at DESC LIMIT 50`
- Pinned messages: `SELECT * FROM chat_messages WHERE event_id = $1 AND is_pinned = true ORDER BY created_at DESC`
- Unread count: `SELECT COUNT(*) FROM chat_messages WHERE event_id = $1 AND user_id != $2 AND read = false`

**Notes:**
- Soft delete (`is_deleted`) for message removal
- Pin feature for important info (location changes, etc.)
- Consider pagination with cursor-based approach for large threads

---

### group_messages ⚠️ (Pending implementation)

**Purpose:** Group-scoped messages (separate from event chat).

**Status:** ⚠️ Schema exists but not yet integrated into UI. Related to `GROUP_HUB_P1_P2_HANDOFF.md`.

**Schema:**
```sql
CREATE TABLE group_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  message text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
```

**Notes:**
- Similar indexing strategy to `chat_messages`
- May replace or complement event chat in future iterations

---

### message_reads ⚠️ (Pending implementation)

**Purpose:** Track read status of messages (group or event chat).

**Status:** ⚠️ Schema exists but not yet integrated. May be used for read receipts feature.

**Schema:**
```sql
CREATE TABLE message_reads (
  message_id uuid NOT NULL REFERENCES group_messages(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  read_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (message_id, user_id)
);
```

**Query patterns:**
- Check if user read message: `SELECT EXISTS(SELECT 1 FROM message_reads WHERE message_id = $1 AND user_id = $2)`
- Get read count: `SELECT COUNT(*) FROM message_reads WHERE message_id = $1`

**Notes:**
- Tracks read receipts for `group_messages` (not event chat)
- Alternative to boolean flag for more granular tracking
- Consider for future read receipts feature in group chat

---

### group_photos

**Purpose:** Photos uploaded during events (live + 24h window).

**Schema:**
```sql
CREATE TABLE group_photos (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  url text NOT NULL,
  storage_path text NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now(),
  uploader_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  is_portrait boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

**Indexes:**
- `idx_group_photos_event_captured` on `(event_id, captured_at DESC)`
- `idx_group_photos_uploader` on `uploader_id`
- `idx_group_photos_created` on `created_at DESC`

**Triggers:**
- `update_group_photos_updated_at` — Auto-updates `updated_at`

**Relationships:**
- Belongs to `groups`
- Belongs to `events` (nullable for group-level photos)
- Belongs to `users` (uploader)

**Query patterns:**
- Event photos: `SELECT * FROM group_photos WHERE event_id = $1 ORDER BY captured_at DESC LIMIT 100`
- Cover photos: `SELECT * FROM group_photos WHERE event_id = $1 AND is_cover = true`
- User contributions: `SELECT * FROM group_photos WHERE event_id = $1 AND uploader_id = $2`

**Storage convention:**
- Path: `/{group_id}/{event_id}/{user_id}/{uuid}.jpg`
- Metadata: uploader_id, event_id, upload timestamp
- Compression: client-side (see `image_compression_service.dart`)

**Notes:**
- Each user can mark **one cover** at upload time
- Host can remove cover designation if needed
- Use Supabase Storage CDN for serving images
- Consider lazy loading and thumbnail generation for performance

---

### event_expenses ⚠️ (Pending full implementation)

**Purpose:** Track event-related expenses and splits.

**Status:** ⚠️ Basic structure exists but needs refinement for payment flows (see `INBOX_PAYMENTS_P1_P2_HANDOFF.md`).

**Schema:**
```sql
CREATE TABLE event_expenses (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  title text NOT NULL,
  total_amount numeric(10, 2) NOT NULL,
  created_by uuid REFERENCES users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);
```

**Relationships:**
- Belongs to `events`
- Has many `expense_splits`

**Query patterns:**
- Event expenses: `SELECT * FROM event_expenses WHERE event_id = $1 ORDER BY created_at DESC`
- User expenses view: Use `user_event_expenses` view (see Views section)

**Notes:**
- `title` describes the expense (e.g., "Dinner", "Uber")
- `total_amount` is split among participants via `expense_splits` table

---

### expense_splits ⚠️ (Pending full implementation)

**Purpose:** Per-user split of an expense.

**Status:** ⚠️ Basic structure; needs payment settlement logic.

**Schema:**
```sql
CREATE TABLE expense_splits (
  expense_id uuid NOT NULL REFERENCES event_expenses(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount numeric NOT NULL,
  has_paid boolean DEFAULT false,
  PRIMARY KEY (expense_id, user_id)
);
```

**Query patterns:**
- User debts: `SELECT expense_id, amount FROM expense_splits WHERE user_id = $1 AND is_paid = false`
- Net balance: Aggregate across all events in a group

**Notes:**
- Future: integrate with payment APIs (Venmo, Cash App) via phone number
- MVP: manual "mark as paid" flow

---

### photos ⚠️ (Might be duplicate of group_photos)

**Purpose:** Alternative photo storage table (may be legacy or duplicate).

**Status:** ⚠️ Exists in schema but appears to overlap with `group_photos`. Needs clarification with P2 team.

**Schema:**
```sql
CREATE TABLE photos (
  photo_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  uploaded_by uuid NOT NULL REFERENCES users(id),
  storage_path text NOT NULL,
  is_cover boolean DEFAULT false,
  caption text,
  uploaded_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (event_id, photo_id)
);
```

**Indexes:**
- `uq_photos_event_id_id` on `(event_id, photo_id)`
- `uq_photos_event_and_pk` on `(event_id, photo_id)`

**Notes:**
- May be replaced by `group_photos` table
- Check with P2 team if this table is still in use or can be deprecated
- Both tables serve similar purposes; consolidation recommended

---

### memories ⚠️ (Pending implementation)

**Purpose:** Post-event memory compilation metadata.

**Status:** ⚠️ Schema exists but not yet integrated. Related to `MEMORY_MANAGEMENT_P1_P2_HANDOFF.md`, `MEMORY_P1_P2_HANDOFF.md`, `MEMORY_VIEWER_P1_P2_HANDOFF.md`.

**Schema:**
```sql
CREATE TABLE memories (
  mem_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id),
  status text CHECK (status IN ('open', 'closing', 'ready')),
  cover_photo_id uuid REFERENCES group_photos(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  closed_at timestamptz
);
```

**Relationships:**
- Belongs to `events`
- Belongs to `users` (memory owner/curator)
- References `group_photos` for cover

**Query patterns:**
- User's memories: `SELECT * FROM memories WHERE user_id = $1 AND status = 'ready' ORDER BY created_at DESC`
- Event memory: `SELECT * FROM memories WHERE event_id = $1`

**Memory lifecycle:**
- **open** — Upload window active (during event + 24h after)
- **closing** — Upload window ended, finalizing
- **ready** — Memory complete and shareable

**Notes:**
- Each event can have one memory per user or one shared memory (TBD)
- Cover photo selected from user-uploaded covers
- Ready memories can generate share cards (IG Story, Post)

---

### notifications ⚠️ (Pending implementation)

**Purpose:** User notifications for events, actions, and updates.

**Status:** ⚠️ Schema exists but not yet integrated. Related to `INBOX_NOTIFICATIONS_P1_P2_HANDOFF.md`.

**Schema:**
```sql
CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type text NOT NULL,
  title text NOT NULL,
  message text,
  payload jsonb CHECK (jsonb_typeof(payload) = 'object'),
  is_read boolean DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);
```

**Notification types:**
- `event_created` — New event in your group
- `event_updated` — Event details changed (time, location)
- `rsvp_reminder` — Reminder to confirm RSVP
- `event_starting` — Event starting soon
- `upload_window_opened` — Can now upload photos
- `upload_window_closing` — 2h left to upload photos
- `memory_ready` — Memory is ready to view/share
- `payment_reminder` — Settle expense with user
- `mention` — Mentioned in chat

**Query patterns:**
- Unread notifications: `SELECT * FROM notifications WHERE user_id = $1 AND is_read = false ORDER BY created_at DESC LIMIT 20`
- Mark as read: `UPDATE notifications SET is_read = true WHERE id = $1`

**Payload structure:**
```json
{
  "event_id": "uuid",
  "group_id": "uuid",
  "action_url": "/events/uuid"
}
```

**Notes:**
- `payload` contains context for deep linking
- Consider batching notifications (e.g., "3 new events this week")
- Integration with push notifications service

---

## Views & Materialized Views

### event_participants_summary_view

**Purpose:** Aggregate RSVP counts per event.

**Schema:**
```sql
CREATE VIEW event_participants_summary_view AS
SELECT
  e.id AS event_id,
  COUNT(ep.user_id) AS total_participants,
  COUNT(CASE WHEN ep.rsvp = 'going' THEN 1 END) AS going_count,
  COUNT(CASE WHEN ep.rsvp = 'cant' THEN 1 END) AS cant_count,
  COUNT(CASE WHEN ep.rsvp = 'pending' THEN 1 END) AS pending_count,
  jsonb_build_object(
    'going', COUNT(CASE WHEN ep.rsvp = 'going' THEN 1 END),
    'cant', COUNT(CASE WHEN ep.rsvp = 'cant' THEN 1 END),
    'pending', COUNT(CASE WHEN ep.rsvp = 'pending' THEN 1 END)
  ) AS rsvp_breakdown
FROM events e
LEFT JOIN event_participants ep ON ep.pevent_id = e.id
GROUP BY e.id;
```

**Usage:**
```sql
SELECT * FROM event_participants_summary_view WHERE event_id = $1;
```

---

### user_event_expenses

**Purpose:** Simplified view for user expense breakdown per event.

**Schema:**
```sql
CREATE VIEW user_event_expenses AS
SELECT
  ee.id AS expense_id,
  ee.event_id,
  ee.title AS expense_title,
  ee.total_amount,
  ee.created_by AS payer_id,
  es.user_id,
  es.amount AS user_share,
  es.is_paid,
  COUNT(*) OVER (PARTITION BY ee.id) AS total_participants
FROM event_expenses ee
JOIN expense_splits es ON es.expense_id = ee.id
ORDER BY ee.created_at DESC;
```

**Usage:**
```sql
-- Get user's expenses for an event
SELECT * FROM user_event_expenses WHERE event_id = $1 AND user_id = $2;

-- Get net balance for user in event
SELECT 
  SUM(CASE WHEN payer_id = $2 THEN total_amount - user_share ELSE -user_share END) AS net_balance
FROM user_event_expenses
WHERE event_id = $1 AND user_id = $2;
```

**Notes:**
- Simplifies expense calculations for UI
- Shows both what user owes and what user is owed
- `total_participants` helps calculate equal splits

---

### home_events_view ⚠️ (Needs optimization)

**Purpose:** Unified view for Home screen showing planning, live, and recap events.

**Status:** ⚠️ Complex view; may need denormalization or materialized view for performance (see `HOME_P1_P2_HANDOFF.md`).

**Schema:** (Simplified excerpt)
```sql
CREATE VIEW home_events_view AS
SELECT
  ep.user_id,
  e.id AS event_id,
  e.name,
  e.emoji,
  e.status,
  e.starts_at,
  e.ends_at,
  g.id AS group_id,
  g.name AS group_name,
  -- ... RSVP counts, photo counts, etc.
FROM event_participants ep
JOIN events e ON e.id = ep.pevent_id
JOIN groups g ON g.id = e.group_id
WHERE e.status != 'ended' -- Adjust filter as needed
ORDER BY
  CASE e.status
    WHEN 'live' THEN 1
    WHEN 'confirmed' THEN 2
    WHEN 'planning' THEN 3
  END,
  e.starts_at;
```

**Performance considerations:**
- High read frequency (Home screen loads)
- Consider materialized view with periodic refresh
- Add composite index on `(user_id, status, starts_at)` if keeping as standard view

---

### group_hub_events_view & group_hub_events_cache ⚠️

**Purpose:** Aggregate events, photos, and actions for Group Board screen.

**Status:** ⚠️ Pending `GROUP_HUB_P1_P2_HANDOFF.md` and `GROUP_DETAILS_PHOTOS_P1_P2_HANDOFF.md`.

**Schema:** (Materialized view)
```sql
CREATE MATERIALIZED VIEW group_hub_events_cache AS
SELECT
  event_id,
  group_id,
  event_name,
  status,
  starts_at,
  participant_count,
  going_count,
  photo_count
FROM group_hub_events_view;
```

**Refresh trigger:**
- `auto_refresh_group_cache()` function triggered on `events`, `event_participants`, `group_photos` changes

**Query patterns:**
- Group board: `SELECT * FROM group_hub_events_cache WHERE group_id = $1 ORDER BY starts_at DESC LIMIT 20`

**Notes:**
- Materialized view trades freshness for performance
- Refresh strategy: on-demand or periodic (e.g., every 5 minutes)
- Consider incremental refresh for large groups

---

## Triggers & Functions

### update_updated_at_column()
Auto-updates `updated_at` timestamp on row modification.

**Applied to:** `events`, `groups`, `group_photos`, `chat_messages`

### auto_refresh_group_cache()
Refreshes `group_hub_events_cache` materialized view.

**Triggered by:** Changes to `events`, `event_participants`

### handle_new_event()
Sends notifications to group members when an event is created.

**Triggered by:** `INSERT` on `events`

### add_group_members_to_event()
Auto-adds all group members as event participants with `rsvp = 'pending'`.

**Triggered by:** `INSERT` on `events`

### handle_new_group()
Adds the group creator as the first member with `role = 'admin'`.

**Triggered by:** `INSERT` on `groups`

---

## Row-Level Security (RLS) Policies

**General principle:** Users can only access data for groups they are members of.

### groups
- **SELECT:** `user_id IN (SELECT user_id FROM group_members WHERE group_id = groups.id)`
- **INSERT:** Authenticated users can create groups
- **UPDATE:** Only admins can update group metadata
- **DELETE:** Only admins can delete groups

### events
- **SELECT:** User is a group member
- **INSERT:** User is a group member
- **UPDATE:** User is event creator or group admin
- **DELETE:** User is event creator or group admin

### chat_messages
- **SELECT:** User is event participant
- **INSERT:** User is event participant
- **UPDATE:** User is message author (for edits/deletes)
- **DELETE:** User is message author or event creator

### group_photos
- **SELECT:** User is group member
- **INSERT:** User is event participant (during upload window)
- **UPDATE:** User is uploader or event creator (for cover designation)
- **DELETE:** User is uploader or event creator

**Critical:** Test RLS policies in integration tests; never bypass with service role keys in client app.

---

## Pending Features & Schema Changes

The following features are in `HANDOFFS_TODO` and will require schema updates:

### ⚠️ Home Screen Optimizations
**Handoff:** `HOME_P1_P2_HANDOFF.md`
- Optimize `home_events_view` for performance
- Add indexes for mode-specific queries (Planning, Living, Recap)
- Consider materialized view for "Next Events" section

### ⚠️ Event Living (Live Event Experience)
**Handoff:** `EVENT_LIVING_P1_P2_HANDOFF.md`
- Live event banner and timer
- Real-time photo uploads and visibility
- "Extend 30m" and "End now" actions
- 24h upload window management

### ⚠️ Memory Management
**Handoff:** `MEMORY_MANAGEMENT_P1_P2_HANDOFF.md`, `MEMORY_P1_P2_HANDOFF.md`, `MEMORY_VIEWER_P1_P2_HANDOFF.md`
- Memory lifecycle (open → closing → ready)
- Cover photo selection and management
- Share card generation (IG Story 9:16, Post 1:1)
- Memory viewer with gallery layout

### ⚠️ Group Board & Photos
**Handoff:** `GROUP_HUB_P1_P2_HANDOFF.md`, `GROUP_DETAILS_PHOTOS_P1_P2_HANDOFF.md`
- Group Board actions, events, memories, expenses
- Photo gallery with filtering (by event, by user, by date)
- Photo metadata and search

### ⚠️ Inbox & Notifications
**Handoff:** `INBOX_ACTIONS_P1_P2_HANDOFF.md`, `INBOX_NOTIFICATIONS_P1_P2_HANDOFF.md`, `INBOX_PAYMENTS_P1_P2_HANDOFF.md`
- New tables: `notifications`, `action_items`, `payment_requests`
- Notification types: event changes, RSVP reminders, memory ready, payment reminders
- Action items: confirm RSVP, add photos, settle payment
- Read/unread status tracking

### ⚠️ Edit Group
**Handoff:** `EDIT_GROUP_P1_P2_HANDOFF.md`
- Group metadata updates (name, description, cover photo)
- Member management (add, remove, change role)
- Invite link regeneration

---

## Migration & Version Control

**Current status:** Beta database; schema subject to change.

**Migration strategy:**
- Use Supabase Migration tool for schema changes
- Test migrations in staging environment first
- Coordinate schema changes with app releases (backend compatibility)
- Document breaking changes in changelog

**Backward compatibility:**
- Add new columns as nullable; populate defaults in migration
- Deprecate columns before removing (add `is_deprecated` flag)
- Version API responses if schema changes affect client contracts

---

## Testing & Validation

### RLS Testing
- Write integration tests for each RLS policy
- Test unauthorized access attempts (should fail gracefully)
- Verify cascade deletes and orphan prevention

### Performance Testing
- Benchmark common queries (Home, Group Board, Event Detail)
- Monitor slow query log in Supabase dashboard
- Simulate load with concurrent users (10, 100, 1000)

### Data Integrity
- Validate foreign key constraints
- Test trigger execution (e.g., auto-add participants)
- Verify check constraints (e.g., `ends_at > starts_at`)

---

## Monitoring & Observability

**Supabase Dashboard:**
- Monitor query performance (slow queries, cache hit rate)
- Track storage usage (photos)
- Review RLS policy usage

**Application-level:**
- Log Supabase errors (network, RLS, constraint violations)
- Track query latency (P50, P95, P99)
- Monitor cache hit rates (Riverpod providers, local DB)

**Alerts:**
- Slow queries (> 1s)
- High error rate (> 5%)
- Storage nearing quota

---

## Future Optimizations

### Phase 2 (Post-MVP)
- **Partitioning:** Partition `chat_messages` and `group_photos` by date for archival
- **Read replicas:** Offload read-heavy queries to replicas
- **CDN caching:** Serve static data (group list, user profiles) via CDN
- **GraphQL:** Consider PostgREST GraphQL layer for flexible querying

### Phase 3 (Scale)
- **Sharding:** Shard by `group_id` for horizontal scaling
- **Event sourcing:** For audit logs and undo/redo functionality
- **Real-time subscriptions:** Use Supabase Realtime for live updates (chat, photos)

---

## Quick Reference

### Common Query Patterns

**User's groups:**
```sql
SELECT g.* FROM groups g
JOIN group_members gm ON gm.group_id = g.id
WHERE gm.user_id = $1
ORDER BY g.updated_at DESC;
```

**Upcoming events for user:**
```sql
SELECT e.* FROM events e
JOIN event_participants ep ON ep.pevent_id = e.id
WHERE ep.user_id = $1 AND e.status IN ('planning', 'confirmed') AND e.starts_at > now()
ORDER BY e.starts_at LIMIT 10;
```

**Event photos (covers first):**
```sql
SELECT * FROM group_photos
WHERE event_id = $1
ORDER BY is_cover DESC, captured_at DESC
LIMIT 100;
```

**RSVP summary:**
```sql
SELECT rsvp, COUNT(*) FROM event_participants
WHERE pevent_id = $1
GROUP BY rsvp;
```

### Performance Checklist

- [ ] Query uses indexed columns for filtering/sorting
- [ ] `LIMIT` applied to all list queries
- [ ] Only required columns selected (no `SELECT *`)
- [ ] Materialized views used for expensive aggregations
- [ ] RLS policies tested and performant
- [ ] Storage paths follow convention (`/{group_id}/{event_id}/{user_id}/{uuid}`)
- [ ] Images compressed client-side before upload
- [ ] Pagination implemented (cursor-based preferred)

---

## Changelog

**2025-11-29** — Complete database structure documentation (synced with `supabase_structure.sql`)
- Documented all 21 tables with full schema details
- Added `location_suggestions` table (was missing in initial version)
- Corrected schemas to match `supabase_structure.sql`: custom enums (`rsvp_status`, `event_state`), field names, constraints
- Fixed `group_photos` schema (added `url`, `is_portrait` fields)
- Fixed `group_user_settings` schema (`is_pinned`, `is_muted`, `group_state`)
- Fixed `expense_splits` field name (`has_paid` not `is_paid`)
- Clarified `message_reads` references `group_messages` not `chat_messages`
- Added 4 views (1 materialized): `event_participants_summary_view`, `user_event_expenses`, `home_events_view`, `group_hub_events_cache`
- Documented all triggers, indexes, constraints, and RLS policies
- Marked 11 tables/features with ⚠️ pending implementation from `HANDOFFS_TODO`
- Added comprehensive performance and optimization guidelines
- Included query patterns and usage examples for each table
- Cross-referenced with P2 handoff documents for pending work

**Source of truth:** This document is manually maintained and must be updated whenever `supabase_structure.sql` changes. The SQL file reflects the live database schema exported by Supabase.

---

## Related Documentation

- `README.md` — Architecture overview and development workflow
- `AGENTS.md` — Agent-specific guidelines and best practices
- `PRODUCT_CONCEPT.md` — Product vision and MVP scope
- `HANDOFFS_DONE/` — Completed P2 backend implementations
- `HANDOFFS_TODO/` — Pending backend work

---

**For questions or schema change requests, coordinate with P2 backend team.**
