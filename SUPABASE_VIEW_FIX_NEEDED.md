# 🐛 Supabase View Fix Required

## Problem
Events without dates (`start_datetime = NULL` and `end_datetime = NULL`) are **not appearing** in the `home_events_view` because the WHERE clause excludes them.

## Current WHERE Clause (Broken)
```sql
where
  (
    e.start_datetime >= now()
    or e.end_datetime >= now()
    or e.end_datetime >= (now() - '24:00:00'::interval)
  )
  and e.status::text <> 'ended'::text
```

**Issue**: When both `start_datetime` and `end_datetime` are NULL, all three conditions evaluate to NULL/FALSE, so the event is filtered out.

## Required Fix

Replace the WHERE clause with:

```sql
where
  (
    -- Include events with NULL dates (date to be decided)
    e.start_datetime IS NULL
    or e.end_datetime IS NULL
    -- Include future events
    or e.start_datetime >= now()
    or e.end_datetime >= now()
    -- Include recent recap events (ended < 24h ago)
    or e.end_datetime >= (now() - '24:00:00'::interval)
  )
  and e.status::text <> 'ended'::text
```

## Expected Behavior After Fix

Events with `start_datetime = NULL` (date to be decided) should:
- ✅ Appear in **Confirmed Events** section (if `status = 'confirmed'`)
- ✅ Appear in **Pending Events** section (if `status = 'pending'`)
- ✅ Display with text: "Date and Location to be decided"
- ✅ Sort **last** in their section (after dated events)

## Testing
After applying the fix, test with:
1. Create an event without selecting a date
2. Verify it appears in the home page
3. Verify it shows "Date and Location to be decided"
4. Verify it appears after all dated events

## Frontend Code Already Ready
The Flutter app already handles NULL dates correctly:
- `home_event_remote_data_source.dart`: Filters and sorts NULL dates
- `home.dart`: Displays "Date and Location to be decided"
- Sorting logic: dated events first (ascending), NULL dates last

**Action Required**: Update `home_events_view` in Supabase with the fixed WHERE clause above.
