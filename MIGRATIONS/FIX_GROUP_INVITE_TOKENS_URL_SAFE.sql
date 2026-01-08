-- Migration: Fix Group Invite Tokens to be URL-safe and reusable
-- Date: 2026-01-07
-- Issue: Tokens with "/" causing 404, tokens not reused within 48h window

-- =====================================================
-- PART 1: Add indexes for fast lookups
-- =====================================================

-- Index for finding valid tokens by group
CREATE INDEX IF NOT EXISTS idx_group_invite_links_group_valid 
ON group_invite_links(group_id, expires_at, revoked_at) 
WHERE revoked_at IS NULL;

-- Index for token lookups (accepting invites)
CREATE INDEX IF NOT EXISTS idx_group_invite_links_token 
ON group_invite_links(token) 
WHERE revoked_at IS NULL;

-- =====================================================
-- PART 2: Function to generate URL-safe tokens
-- =====================================================

-- URL-safe Base64 variant: uses A-Z, a-z, 0-9, -, _ (no +, /, =)
-- Length: 24 characters = ~144 bits entropy (secure for 48h tokens)
CREATE OR REPLACE FUNCTION generate_url_safe_token()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..24 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN result;
END;
$$;

-- =====================================================
-- PART 3: Main RPC - Get or create invite link
-- =====================================================

CREATE OR REPLACE FUNCTION get_or_create_group_invite_link(
  p_group_id UUID,
  p_expires_in_hours INTEGER DEFAULT 48
)
RETURNS TABLE(
  id UUID,
  token TEXT,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_existing_link RECORD;
  v_new_token TEXT;
  v_new_id UUID;
  v_expires_at TIMESTAMPTZ;
BEGIN
  -- Get authenticated user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Verify user is member of group
  IF NOT EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = p_group_id 
    AND user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'User is not a member of this group';
  END IF;

  -- Try to find valid existing link (not expired, not revoked)
  SELECT 
    gil.id,
    gil.token,
    gil.expires_at,
    gil.created_at
  INTO v_existing_link
  FROM group_invite_links gil
  WHERE gil.group_id = p_group_id
    AND gil.expires_at > NOW()
    AND gil.revoked_at IS NULL
  ORDER BY gil.expires_at DESC
  LIMIT 1;

  -- If valid link exists, return it
  IF v_existing_link.id IS NOT NULL THEN
    RETURN QUERY SELECT 
      v_existing_link.id,
      v_existing_link.token,
      v_existing_link.expires_at,
      v_existing_link.created_at;
    RETURN;
  END IF;

  -- No valid link exists, create new one
  v_new_token := generate_url_safe_token();
  v_expires_at := NOW() + (p_expires_in_hours || ' hours')::INTERVAL;

  INSERT INTO group_invite_links (
    group_id,
    created_by,
    token,
    expires_at
  )
  VALUES (
    p_group_id,
    v_user_id,
    v_new_token,
    v_expires_at
  )
  RETURNING 
    group_invite_links.id,
    group_invite_links.token,
    group_invite_links.expires_at,
    group_invite_links.created_at
  INTO v_new_id, v_new_token, v_expires_at, v_existing_link.created_at;

  RETURN QUERY SELECT 
    v_new_id,
    v_new_token,
    v_expires_at,
    v_existing_link.created_at;
END;
$$;

-- =====================================================
-- PART 4: RPC to accept invite by token
-- =====================================================

CREATE OR REPLACE FUNCTION accept_group_invite_by_token(
  p_token TEXT
)
RETURNS TABLE(group_id UUID)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_invite RECORD;
BEGIN
  -- Get authenticated user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Find and validate invite link
  SELECT 
    gil.id,
    gil.group_id,
    gil.expires_at,
    gil.revoked_at
  INTO v_invite
  FROM group_invite_links gil
  WHERE gil.token = p_token;

  -- Token doesn't exist
  IF v_invite.id IS NULL THEN
    RAISE EXCEPTION 'Invalid invite token';
  END IF;

  -- Token expired
  IF v_invite.expires_at < NOW() THEN
    RAISE EXCEPTION 'Invite link has expired';
  END IF;

  -- Token revoked
  IF v_invite.revoked_at IS NOT NULL THEN
    RAISE EXCEPTION 'Invite link has been revoked';
  END IF;

  -- Check if user is already a member
  IF EXISTS (
    SELECT 1 FROM group_members
    WHERE group_members.group_id = v_invite.group_id
    AND group_members.user_id = v_user_id
  ) THEN
    -- Already member, just return group_id
    RETURN QUERY SELECT v_invite.group_id;
    RETURN;
  END IF;

  -- Add user to group
  INSERT INTO group_members (
    group_id,
    user_id,
    role
  )
  VALUES (
    v_invite.group_id,
    v_user_id,
    'member'
  )
  ON CONFLICT (group_id, user_id) DO NOTHING;

  RETURN QUERY SELECT v_invite.group_id;
END;
$$;

-- =====================================================
-- PART 5: Grant permissions
-- =====================================================

GRANT EXECUTE ON FUNCTION generate_url_safe_token() TO authenticated;
GRANT EXECUTE ON FUNCTION get_or_create_group_invite_link(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION accept_group_invite_by_token(TEXT) TO authenticated;

-- =====================================================
-- PART 6: Optional - Revoke old non-URL-safe tokens
-- =====================================================

-- Mark tokens with "/" or "+" as revoked (they cause 404)
UPDATE group_invite_links
SET revoked_at = NOW()
WHERE revoked_at IS NULL
  AND (token LIKE '%/%' OR token LIKE '%+%' OR token LIKE '%=%');

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Test token generation (should have no +, /, =)
-- SELECT generate_url_safe_token();

-- Count tokens with special chars (should be 0 after migration)
-- SELECT COUNT(*) FROM group_invite_links 
-- WHERE revoked_at IS NULL 
-- AND (token LIKE '%/%' OR token LIKE '%+%' OR token LIKE '%=%');

-- Test get_or_create (run twice, should return same token)
-- SELECT * FROM get_or_create_group_invite_link('YOUR_GROUP_ID_HERE');
-- SELECT * FROM get_or_create_group_invite_link('YOUR_GROUP_ID_HERE');
