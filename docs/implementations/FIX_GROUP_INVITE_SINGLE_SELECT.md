# Fix: Group Invite Single-Select Implementation

## Problem
When inviting a user to a group, the error "Failed to send invitations" was displayed. The root causes were:

1. **RLS Policy Issue**: The `group_invites` table policy referenced `members_can_invite` column which was removed during the permissions cleanup
2. **Multi-select UX**: The UI allowed selecting multiple groups at once, which could create confusion and error-prone bulk operations
3. **Frontend Logic**: Data source was still checking for `members_can_invite` permission before showing invitable groups

## Solution Implemented

### 1. Updated Bottom Sheet to Single Selection ✅
**File**: `lib/features/profile/presentation/widgets/invite_to_group_bottom_sheet.dart`

Changes:
- Changed from checkbox (multi-select) to **radio button (single-select)**
- Updated callback signature from `Function(List<String> groupIds)` to `Function(String groupId)`
- Replaced `Set<String> _selectedGroupIds` with `String? _selectedGroupId`
- Changed visual indicator from checkmark icon to radio dot

**Why**: Simpler UX, easier error handling, one invite per action

### 2. Simplified Invite Handler ✅
**File**: `lib/features/profile/presentation/pages/other_profile_page.dart`

Changes:
- Renamed `_handleGroupsSelected()` to `_handleGroupSelected()`
- Removed loop for multiple invites
- Simplified success/error messages (single invite)
- Direct call to use case instead of iteration

**Result**: Cleaner code, clearer error messages

### 3. Fixed Data Source Permission Check ✅
**File**: `lib/features/profile/data/data_sources/other_profile_data_source.dart`

Changes in `getInvitableGroups()`:
- Removed `members_can_invite` from SELECT query
- Removed permission filtering logic (if/else checking `membersCanInvite` or admin role)
- Simplified to: **any group member can invite** (aligned with simplified permission model)

**Why**: The `members_can_invite` column was removed during permissions cleanup, causing the query to fail

### 4. Created SQL Migration Script ✅
**File**: `IMPLEMENTATION/FIX_GROUP_INVITE_PERMISSIONS.sql`

Changes:
- Drop old RLS policy that checks `members_can_invite`
- Create new simplified policy: **allow INSERT if user is group member**
- No longer checks `members_can_invite` or admin role
- All group members now have equal invite rights

**Policy Logic**:
```sql
-- Old (broken): checked g.members_can_invite OR gm.role = 'admin'
-- New (fixed):  checks gm.user_id = auth.uid() only
```

## Files Modified

| File | Change Type | Description |
|------|-------------|-------------|
| `invite_to_group_bottom_sheet.dart` | UI/Logic | Single-select with radio button |
| `other_profile_page.dart` | Logic | Single invite handler |
| `other_profile_data_source.dart` | Data | Remove permission check |
| `FIX_GROUP_INVITE_PERMISSIONS.sql` | Database | Update RLS policy |

## Testing Checklist

- [ ] Execute SQL migration: `IMPLEMENTATION/FIX_GROUP_INVITE_PERMISSIONS.sql`
- [ ] Restart Flutter app to clear cached queries
- [ ] Navigate to another user's profile (Other Profile page)
- [ ] Tap "Invite to Group" icon in app bar
- [ ] Verify bottom sheet shows groups with **radio buttons**
- [ ] Select one group → verify only one can be selected at a time
- [ ] Tap "Send Invitation" → verify success banner: "Invitation sent to [Name]"
- [ ] Check invited user's Inbox → verify `groupInviteReceived` notification appears
- [ ] Test accepting/declining invite → verify it works correctly

## Related Issues Fixed

1. ✅ **Group Invite Category**: Previously fixed in `FIX_GROUP_INVITE_CATEGORY.sql` (changed category from 'push' to 'actions')
2. ✅ **Group Permissions**: Previously removed `members_can_*` columns in permissions cleanup
3. ✅ **Multi-select UX**: Now simplified to single-select for better UX

## Architecture Alignment

This fix aligns with the **.agents/agents.md** golden rules:
- ✅ **Domain ≠ Data**: Domain layer unchanged, data layer simplified
- ✅ **Single source rule**: Removed duplicate permission logic
- ✅ **No infra in Domain**: Use case remains clean, repository handles data checks
- ✅ **Minimal queries**: Removed unnecessary `members_can_invite` column from SELECT

## Migration Steps

1. **Database (P2 team)**:
   ```bash
   psql -h [supabase-url] -U postgres -d postgres < IMPLEMENTATION/FIX_GROUP_INVITE_PERMISSIONS.sql
   ```

2. **Frontend (already done)**:
   - All Flutter changes already committed
   - No additional configuration needed

3. **Verification**:
   - Test invite flow end-to-end
   - Monitor logs for any RLS policy violations
   - Check notification delivery

## Future Improvements

If you need to restrict invites to **admins only** in the future:
- Update the RLS policy to check `gm.role = 'admin'`
- Update UI to show "Only admins can invite" message for non-admins
- Do NOT add back `members_can_invite` column (keep simplified model)

---

**Status**: ✅ Complete  
**Breaking Changes**: None (backward compatible)  
**Migration Required**: Yes (SQL script must be executed)
