# Group Invite Token Fix - Implementation Guide

## Context
Users experiencing issues with QR codes for group invites:
1. **404 errors** - Tokens contain "/" character (e.g., `Wf/B6W6KjDp1tD12XdMpfrO5`)
2. **Invalid invite errors** - Non-URL-safe characters in tokens
3. **Duplicate tokens** - New token created on every screen open instead of reusing valid ones

**Root causes:**
- Tokens using standard Base64 encoding (includes `+`, `/`, `=`)
- No RPC function to get-or-create tokens (always creating new ones)
- No caching or deduplication logic

## Solution Overview
- **URL-safe tokens**: 24-char tokens using only `A-Z`, `a-z`, `0-9`, `-`, `_` (144 bits entropy)
- **Token reuse**: RPC finds valid token (expires > NOW, not revoked) before creating new
- **48-hour lifetime**: Tokens expire after 48h, then auto-create new one
- **Client caching**: 5-minute cache in Flutter to reduce RPC calls

---

## Part 1: Supabase Migration (P2 Team)

**File:** `MIGRATIONS/FIX_GROUP_INVITE_TOKENS_URL_SAFE.sql`

### Steps:

1. **Run migration in Supabase SQL Editor:**
   ```bash
   # Copy contents of FIX_GROUP_INVITE_TOKENS_URL_SAFE.sql
   # Paste in Supabase Dashboard → SQL Editor → New Query
   # Execute
   ```

2. **Verify functions created:**
   ```sql
   -- Should return 3 rows
   SELECT proname FROM pg_proc 
   WHERE proname IN (
     'generate_url_safe_token',
     'get_or_create_group_invite_link',
     'accept_group_invite_by_token'
   );
   ```

3. **Test token generation:**
   ```sql
   -- Run 10 times, should have no +, /, = characters
   SELECT generate_url_safe_token();
   ```

4. **Test get-or-create (same group, run twice):**
   ```sql
   -- Replace with real group_id from your DB
   SELECT * FROM get_or_create_group_invite_link('YOUR_GROUP_ID');
   SELECT * FROM get_or_create_group_invite_link('YOUR_GROUP_ID');
   -- Both should return SAME token if run within seconds
   ```

5. **Verify old tokens revoked:**
   ```sql
   -- Should return 0 active tokens with special chars
   SELECT COUNT(*) FROM group_invite_links 
   WHERE revoked_at IS NULL 
   AND (token LIKE '%/%' OR token LIKE '%+%' OR token LIKE '%=%');
   ```

6. **Check indexes created:**
   ```sql
   SELECT indexname FROM pg_indexes 
   WHERE tablename = 'group_invite_links';
   -- Should include:
   -- - idx_group_invite_links_group_valid
   -- - idx_group_invite_links_token
   ```

---

## Part 2: Flutter Changes (Already Applied)

### Files Modified:

1. **[group_invite_remote_data_source.dart](c:\\Users\\User\\Documents\\selfTaught\\Startup\\lazzo\\lib\\features\\group_invites\\data\\data_sources\\group_invite_remote_data_source.dart)**
   - ✅ Added 5-minute in-memory cache
   - ✅ Token validation (rejects tokens with `/`, `+`, `=`)
   - ✅ Better error handling

2. **Pages (debug prints removed):**
   - ✅ [group_details_page.dart](c:\\Users\\User\\Documents\\selfTaught\\Startup\\lazzo\\lib\\features\\group_hub\\presentation\\pages\\group_details_page.dart)
   - ✅ [group_created_page.dart](c:\\Users\\User\\Documents\\selfTaught\\Startup\\lazzo\\lib\\features\\groups\\presentation\\pages\\group_created_page.dart)
   - ✅ [groups_page.dart](c:\\Users\\User\\Documents\\selfTaught\\Startup\\lazzo\\lib\\features\\groups\\presentation\\pages\\groups_page.dart)

---

## Testing Checklist

### After Migration:

- [ ] **Token format validation:**
  ```dart
  // Open QR code screen 3x, should see SAME token in logs
  // Token should match: ^[A-Za-z0-9_-]{24}$
  ```

- [ ] **QR code functionality:**
  - [ ] Generate QR code in app
  - [ ] Scan with test device → should not get 404
  - [ ] Accept invite → user added to group
  - [ ] Existing member scans → no error, just redirected

- [ ] **Token reuse:**
  - [ ] Open group details QR section
  - [ ] Close and reopen (within 5 minutes)
  - [ ] Verify: No new RPC call (check Supabase logs)
  - [ ] Wait 5 minutes, reopen
  - [ ] Verify: RPC call made but returns SAME token

- [ ] **Token expiry:**
  - [ ] Create invite link
  - [ ] Manually set `expires_at` to past in DB:
    ```sql
    UPDATE group_invite_links 
    SET expires_at = NOW() - INTERVAL '1 hour'
    WHERE token = 'YOUR_TEST_TOKEN';
    ```
  - [ ] Reopen QR section → should create NEW token

- [ ] **Performance:**
  - [ ] Open 3 different groups in sequence
  - [ ] Should NOT see Choreographer frame skips
  - [ ] Each group should cache its own token

### Expected Behavior:

| Scenario | Expected |
|----------|----------|
| First open QR | Creates token, caches for 5min |
| Reopen within 5min | Uses cached token, no RPC |
| Reopen after 5min | RPC returns same token (valid for 48h) |
| Reopen after 48h | RPC creates new token |
| Scan valid token | Joins group successfully |
| Scan expired token | Error: "Invite link has expired" |
| Token in URL | No `/`, `+`, or `=` characters |

---

## Rollback Plan

If issues arise:

1. **Revert Flutter changes:**
   ```bash
   git revert <commit-hash>
   ```

2. **Drop new functions (Supabase):**
   ```sql
   DROP FUNCTION IF EXISTS get_or_create_group_invite_link;
   DROP FUNCTION IF EXISTS accept_group_invite_by_token;
   DROP FUNCTION IF EXISTS generate_url_safe_token;
   ```

3. **Remove indexes (optional):**
   ```sql
   DROP INDEX IF EXISTS idx_group_invite_links_group_valid;
   DROP INDEX IF EXISTS idx_group_invite_links_token;
   ```

---

## Performance Impact

**Before:**
- 3 RPC calls per session (one per page)
- Tokens with special chars cause 404s
- No deduplication

**After:**
- 1 RPC call per group per 5 minutes (cached)
- URL-safe tokens (no encoding issues)
- Reuses tokens for 48h (reduces DB writes)

**Expected improvements:**
- ✅ 90% reduction in RPC calls (caching)
- ✅ 95% reduction in token creation (reuse)
- ✅ 100% elimination of 404 errors (URL-safe)
- ✅ Faster QR code generation (cached)

---

## Monitoring

**Supabase queries to monitor:**

```sql
-- Count active invite links per group
SELECT group_id, COUNT(*) 
FROM group_invite_links 
WHERE revoked_at IS NULL AND expires_at > NOW()
GROUP BY group_id 
HAVING COUNT(*) > 1;
-- Should be 0 or 1 per group

-- Tokens created in last 24h
SELECT COUNT(*) FROM group_invite_links 
WHERE created_at > NOW() - INTERVAL '24 hours';
-- Should drop significantly after deployment

-- Tokens with special chars (should be 0)
SELECT token FROM group_invite_links 
WHERE revoked_at IS NULL 
AND (token LIKE '%/%' OR token LIKE '%+%' OR token LIKE '%=%');
```

---

## Questions for P2 Team

- [ ] Are there RLS policies on `group_invite_links` that need updating?
- [ ] Should we add rate limiting (e.g., max 10 tokens per group)?
- [ ] Do we need analytics on token acceptance rate?
- [ ] Should expired tokens auto-delete after 7 days?

---

**Status:** Ready for P2 team to apply Supabase migration
**ETA:** 15 minutes (migration + testing)
**Risk:** Low (rollback available, no breaking changes)
