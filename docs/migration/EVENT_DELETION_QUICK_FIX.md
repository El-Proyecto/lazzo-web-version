# Event Deletion - Quick Fix Guide

## Problem Summary
Deleting old events fails with 2 sequential errors:

### Error #1: Foreign Key Constraint ❌
```
cannot delete event - violates foreign key constraint on "event_date_options"
```
**Cause:** No CASCADE on foreign keys  
**Fix:** `MIGRATIONS/ADD_CASCADE_DELETE_EVENTS.sql`

### Error #2: Materialized View Refresh ❌
```
cannot refresh materialized view "group_photos_with_uploader" concurrently
```
**Cause:** Missing unique index on materialized view  
**Fix:** `MIGRATIONS/FIX_GROUP_PHOTOS_MATERIALIZED_VIEW.sql`

---

## Quick Fix (Copy-Paste Ready)

### Step 1: Add CASCADE to Foreign Keys
Open Supabase SQL Editor and run:
```sql
-- File: MIGRATIONS/ADD_CASCADE_DELETE_EVENTS.sql
-- Copy entire file contents here
```

### Step 2: Fix Materialized Views
Then run:
```sql
-- File: MIGRATIONS/FIX_GROUP_PHOTOS_MATERIALIZED_VIEW.sql
-- Copy entire file contents here
```

### Step 3: Verify
```sql
-- Test event deletion (replace with actual event ID)
DELETE FROM events WHERE id = 'your-test-event-id';
-- Should succeed without errors
```

---

## What Gets Fixed

### CASCADE DELETE (Step 1)
When you delete an event, automatically deletes:
- ✅ All date/time suggestions (`event_date_options`)
- ✅ All votes on suggestions (`event_date_votes`)
- ✅ All location suggestions (`location_suggestions`)
- ✅ All location votes (`location_suggestion_votes`)
- ✅ All chat messages (`chat_messages`)
- ✅ All read receipts (`message_reads`)
- ✅ All event photos (`group_photos`)
- ✅ All RSVP participants (`event_participants`)
- ✅ All expenses and splits (`event_expenses`, `expense_splits`)

**Special case:** `groups.event_id` → SET NULL (group persists without event)

### MATERIALIZED VIEW FIX (Step 2)
- ✅ Adds unique index to `group_photos_with_uploader`
- ✅ Fixes `group_hub_events_cache` if exists
- ✅ Updates triggers to use `REFRESH CONCURRENTLY`
- ✅ Allows queries during refresh (no downtime)

---

## Why This Happens with Old Events

**Old events** (created before CASCADE migration) have:
1. Related records in multiple tables
2. Triggers that refresh materialized views on DELETE
3. Materialized views without unique indexes

**New events** won't have these issues once migration is applied.

---

## Safety Notes

✅ **Safe to run:** Both scripts use `IF EXISTS` checks  
✅ **Rollback available:** DROP and re-add constraints without CASCADE  
✅ **RLS protected:** Only authorized users can delete events  
✅ **Atomic operations:** Database handles everything in transactions  
✅ **Production ready:** CONCURRENTLY allows queries during refresh  

---

## Testing Checklist

After running both migrations:

- [ ] Delete test event with date suggestions → Success
- [ ] Delete test event with location suggestions → Success
- [ ] Delete test event with chat messages → Success
- [ ] Delete test event with photos → Success
- [ ] Verify related records deleted automatically
- [ ] Verify group still exists (event_id = NULL)
- [ ] No PostgrestException errors in app
- [ ] Success banner appears in app

---

## If You Still Get Errors

### Error: "relation does not exist"
- View doesn't exist yet → Skip that part, it's optional
- Continue with the rest of the migration

### Error: "permission denied"
- Run as database owner/admin
- Check RLS policies allow DELETE

### Error: "syntax error"
- Copy ENTIRE file contents
- Don't copy partial sections
- Run in Supabase SQL Editor (not psql)

---

## Files Reference

1. **`ADD_CASCADE_DELETE_EVENTS.sql`** - Main fix for foreign keys
2. **`FIX_GROUP_PHOTOS_MATERIALIZED_VIEW.sql`** - Fix for materialized views
3. **`EVENT_DELETION_CASCADE_MIGRATION.md`** - Full documentation
4. **`EVENT_DELETION_QUICK_FIX.md`** - This document

---

**Execute in order:** Step 1 → Step 2 → Test  
**Estimated time:** 30 seconds per migration  
**Downtime:** None (CONCURRENTLY ensures queries work during refresh)
