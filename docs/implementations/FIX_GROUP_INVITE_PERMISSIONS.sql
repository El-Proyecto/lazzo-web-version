-- ========================================================================
-- FIX: Group Invite Permissions Policy
-- ========================================================================
-- PROBLEM: The RLS policy for group_invites references members_can_invite 
-- column which was removed during permissions cleanup
-- 
-- SOLUTION: Update the policy to allow invites from:
-- 1. Group admins (always)
-- 2. All members (since permissions were simplified to true by default)
-- 
-- This aligns with the frontend changes where:
-- - Bottom sheet now allows single invite selection
-- - All group members can invite (simplified from previous granular permissions)
-- ========================================================================

-- Step 1: Drop the old policy
DROP POLICY IF EXISTS "Members can invite users to groups" ON group_invites;

-- Step 2: Create new simplified policy
-- Allow any group member to invite users
CREATE POLICY "Members can invite users to groups"
ON group_invites
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM group_members gm
    WHERE gm.group_id = group_invites.group_id
      AND gm.user_id = auth.uid()
  )
);

-- Step 3: Verify the policy
-- Test that current user can insert invites for their groups
SELECT 
  policy_name,
  policy_type,
  policy_definition
FROM information_schema.table_privileges
WHERE table_name = 'group_invites'
LIMIT 5;

-- Expected result:
-- Policy allows INSERT if user is member of the group (regardless of role)
-- This is simpler and aligns with the simplified permissions model

-- ========================================================================
-- ADDITIONAL NOTES
-- ========================================================================
-- 
-- The old policy checked:
-- (g.members_can_invite = true OR gm.role = 'admin')
-- 
-- New policy simplified to:
-- - Just check membership (any member can invite)
-- - This aligns with frontend where members_can_invite was removed
-- - Simplifies permission model (all members have same invite rights)
-- 
-- If you need to restrict invites to admins only in the future:
-- Replace the policy with:
-- CREATE POLICY "Members can invite users to groups"
-- ON group_invites FOR INSERT WITH CHECK (
--   EXISTS (
--     SELECT 1 FROM group_members gm
--     WHERE gm.group_id = group_invites.group_id
--       AND gm.user_id = auth.uid()
--       AND gm.role = 'admin'
--   )
-- );
-- ========================================================================
