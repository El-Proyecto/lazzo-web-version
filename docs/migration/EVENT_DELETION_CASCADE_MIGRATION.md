# Event Deletion CASCADE Migration

## Context
When attempting to delete an event from the Edit Event page, users encounter a PostgreSQL foreign key constraint violation error. The error occurs because related records in child tables (e.g., `event_date_options`, `chat_messages`, `location_suggestions`) still reference the event being deleted.

**Current Error:**
```
PostgrestException(message: update or delete on table "events" violates foreign key constraint
"event_date_options_event_id_key" on table "event_date_options", code: 23503, 
details: Key is still referenced from table "event_date_options"., hint: null)
```

## Problem Analysis
The Supabase schema has **9 tables** with foreign keys referencing `events(id)`, but **NONE** have `ON DELETE CASCADE`:

1. `chat_messages.event_id` → Event chat messages
2. `event_date_options.event_id` → Date/time suggestions (CAUSING THE ERROR)
3. `event_date_votes.event_id` → Votes on date suggestions
4. `event_expenses.event_id` → Event expenses
5. `event_participants.pevent_id` → RSVP participants
6. `group_photos.event_id` → Event photos
7. `location_suggestions.event_id` → Location suggestions
8. `message_reads.event_id` → Chat read receipts
9. `photos.event_id` → Memory photos

Additionally:
- `groups.event_id` → Groups can reference an event (should be `SET NULL` not `CASCADE`)

## Solution
Add `ON DELETE CASCADE` to all foreign keys referencing `events(id)`. This is **standard practice** for events where complete deletion is expected.

### Why CASCADE is Safe Here
- **Events are self-contained units**: When an event is deleted, all related data (suggestions, votes, messages, photos) should also be deleted
- **No data orphaning**: Child records without their parent event are meaningless
- **Matches user expectations**: Deleting an event should remove everything associated with it
- **Simplifies client code**: No need for manual cleanup of related records

### Special Case: Groups
`groups.event_id` should use `ON DELETE SET NULL` instead of `CASCADE` because:
- Groups can exist independently of events
- When an event is deleted, the group should persist with `event_id = NULL`
- Group members and history remain intact

## Migration Steps

### Phase 1: Preparation (DO FIRST)
- [x] Identify all affected foreign keys
- [x] Create migration SQL script
- [ ] **Test in Supabase staging environment** (if available)
- [ ] Backup production database before applying

### Phase 2: Database Migration
- [ ] Open Supabase SQL Editor
- [ ] Copy contents of `MIGRATIONS/ADD_CASCADE_DELETE_EVENTS.sql`
- [ ] Execute migration script
- [ ] Run verification query (included in script)
- [ ] Confirm all foreign keys show `delete_rule = 'CASCADE'` (except `groups.event_id` = 'SET NULL')

### Phase 3: Validation
- [ ] Test event deletion in app:
  - Create test event with date suggestions
  - Add location suggestions
  - Send chat messages
  - Add RSVP participants
  - Delete event via Edit Event page
  - Verify no error occurs
  - Verify all related records deleted automatically
- [ ] Verify group behavior:
  - Create test group with event
  - Delete event
  - Verify group still exists with `event_id = NULL`
- [ ] Check RLS policies still work correctly
- [ ] Monitor Supabase logs for any unexpected behavior

### Phase 4: Verification in Production
- [ ] Delete test event in production
- [ ] Verify success banner appears
- [ ] Query database to confirm related records deleted:
  ```sql
  SELECT COUNT(*) FROM event_date_options WHERE event_id = '<deleted_event_id>'; -- Should be 0
  SELECT COUNT(*) FROM location_suggestions WHERE event_id = '<deleted_event_id>'; -- Should be 0
  SELECT COUNT(*) FROM chat_messages WHERE event_id = '<deleted_event_id>'; -- Should be 0
  ```

## Rollback Plan
If issues arise after migration:

1. **Immediate rollback** (within 5 minutes):
   - Run Step 1 of migration script (DROP constraints)
   - Re-add constraints WITHOUT `ON DELETE CASCADE` (original behavior)

2. **If data integrity issues detected**:
   - Restore from pre-migration backup
   - Investigate specific failures
   - Modify migration script to address issues
   - Re-test in staging

## Post-Migration Cleanup
- [x] Document migration in `MIGRATIONS/` folder
- [ ] Update `supabase_structure.sql` to reflect new CASCADE constraints
- [ ] Re-export `supabase_schema.sql` after CASCADE changes
- [ ] Remove any manual cleanup code in Flutter app (if exists)
- [ ] Test event deletion across all user roles (host, admin, member)

## Performance Considerations
**CASCADE operations are efficient** in PostgreSQL:
- Single DELETE transaction removes event + all children
- No N+1 queries from client code
- Database handles referential integrity atomically
- Faster than manual cleanup loop

**Potential Impact:**
- Deleting an event with many related records (1000+ chat messages, 100+ photos) may take 1-2 seconds
- This is acceptable for event deletion (infrequent operation)
- No impact on read operations

## Security Considerations
**RLS Policies Still Apply:**
- `ON DELETE CASCADE` respects existing RLS DELETE policies
- Users can only delete events they have permission to delete
- Child records are deleted by the database (not by user), so no additional RLS checks needed on children
- This is PostgreSQL standard behavior and is secure

## Expected Behavior After Migration
✅ **Before:** DELETE event → Error (foreign key violation)  
✅ **After:** DELETE event → Success (event + all related records deleted automatically)

**What gets deleted CASCADE when event is deleted:**
- All date/time suggestions for the event
- All votes on those suggestions  
- All location suggestions for the event
- All votes on location suggestions
- All chat messages in the event
- All message read receipts
- All event photos and memories
- All RSVP participants
- All event expenses and splits

**What gets SET NULL when event is deleted:**
- `groups.event_id` → `NULL` (group persists without event reference)

## Related Issues & Fixes

### Issue #2: Materialized View Refresh Error (Discovered After CASCADE Migration)
**Error:**
```
PostgrestException(message: cannot refresh materialized view "public.group_photos_with_uploader" 
concurrently, code: 55000, details: Internal Server Error, 
hint: Create a unique index with no WHERE clause on one or more columns of the materialized view.)
```

**Root Cause:**
- After adding CASCADE DELETE, triggers attempt to refresh materialized views
- `group_photos_with_uploader` lacks required unique index for `REFRESH CONCURRENTLY`
- PostgreSQL requires unique index to support concurrent refresh (allows reads during refresh)

**Solution:**
Apply `MIGRATIONS/FIX_GROUP_PHOTOS_MATERIALIZED_VIEW.sql` which:
1. Adds unique index on `group_photos_with_uploader(id)`
2. Fixes `group_hub_events_cache` if it exists
3. Updates trigger functions to use `REFRESH CONCURRENTLY`
4. Tests all materialized views

**Why This Matters:**
- Without `CONCURRENTLY`, refresh locks the view (blocks queries)
- With `CONCURRENTLY`, users can query view during refresh (no downtime)
- Essential for production with active users

## Files Modified
- `MIGRATIONS/ADD_CASCADE_DELETE_EVENTS.sql` - CASCADE migration script
- `MIGRATIONS/FIX_GROUP_PHOTOS_MATERIALIZED_VIEW.sql` - Materialized view fix
- `MIGRATIONS/EVENT_DELETION_CASCADE_MIGRATION.md` - This document

## Migration Order (CRITICAL)
Execute in this exact order:
1. **First:** `ADD_CASCADE_DELETE_EVENTS.sql` (fixes foreign keys)
2. **Then:** `FIX_GROUP_PHOTOS_MATERIALIZED_VIEW.sql` (fixes materialized views)
3. **Finally:** Test event deletion

## Next Steps
1. **P2 Team:** 
   - Execute both SQL scripts in order
   - Run verification queries (included in scripts)
   - Test event deletion with old events (created before CASCADE)
2. **P1 Team:** 
   - Test event deletion in app after both migrations applied
   - Verify no errors when deleting events with photos
3. **Both:** 
   - Update `supabase_structure.sql` with CASCADE constraints
   - Re-export `supabase_schema.sql` and update `supabase_structure.sql` with materialized view notes

## Notes for P2 Team
- No code changes required in Flutter app
- Both migrations are pure SQL (Supabase side only)
- RLS policies on `events` table control who can delete
- CASCADE handles cleanup automatically and efficiently
- CONCURRENTLY allows queries during view refresh (no downtime)
- Verify with test data before production deployment
- If issues arise, rollback scripts available in migration files
