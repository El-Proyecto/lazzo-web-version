-- ============================================================================
-- APPLE REVIEWER AUTHENTICATION SETUP
-- ============================================================================
-- Purpose: Create dedicated authentication path for Apple App Review team
-- Method: Password-based authentication (separate from normal OTP flow)
-- Date: 2026-01-24
-- ============================================================================

-- ============================================================================
-- PART 1: Reviewer Authentication Table (Audit & Tracking)
-- ============================================================================

-- Table to track reviewer login sessions and audit access
CREATE TABLE IF NOT EXISTS public.reviewer_auth_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reviewer_email TEXT NOT NULL,
    login_at TIMESTAMPTZ DEFAULT NOW(),
    ip_address TEXT,
    user_agent TEXT,
    session_id UUID,
    action TEXT DEFAULT 'login', -- 'login', 'logout', 'failed_attempt'
    notes TEXT
);

-- RLS: Only service role can insert/read
ALTER TABLE public.reviewer_auth_sessions ENABLE ROW LEVEL SECURITY;

-- No public access - only service role
CREATE POLICY "Service role only" ON public.reviewer_auth_sessions
    FOR ALL USING (false);

-- Index for quick lookups
CREATE INDEX IF NOT EXISTS idx_reviewer_sessions_email 
    ON public.reviewer_auth_sessions(reviewer_email);
CREATE INDEX IF NOT EXISTS idx_reviewer_sessions_login_at 
    ON public.reviewer_auth_sessions(login_at DESC);

-- ============================================================================
-- PART 2: Function to Log Reviewer Access
-- ============================================================================

CREATE OR REPLACE FUNCTION public.log_reviewer_access(
    p_email TEXT,
    p_action TEXT DEFAULT 'login',
    p_ip_address TEXT DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_session_id UUID;
BEGIN
    INSERT INTO public.reviewer_auth_sessions (
        reviewer_email,
        action,
        ip_address,
        user_agent,
        session_id,
        notes
    ) VALUES (
        p_email,
        p_action,
        p_ip_address,
        p_user_agent,
        auth.uid(),
        p_notes
    )
    RETURNING id INTO v_session_id;
    
    RETURN v_session_id;
END;
$$;

-- ============================================================================
-- PART 3: Create Reviewer User in public.users (if not exists)
-- ============================================================================
-- NOTE: The auth.users entry must be created via Supabase Dashboard or CLI
-- This only ensures the public.users row exists

CREATE OR REPLACE FUNCTION public.ensure_reviewer_user(
    p_reviewer_email TEXT,
    p_reviewer_name TEXT DEFAULT 'Apple Reviewer'
) RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Check if user already exists in public.users
    SELECT id INTO v_user_id
    FROM public.users
    WHERE email = lower(p_reviewer_email);
    
    IF v_user_id IS NOT NULL THEN
        RETURN v_user_id;
    END IF;
    
    -- Check if exists in auth.users
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE email = lower(p_reviewer_email);
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Reviewer must first be created in auth.users via Supabase Dashboard';
    END IF;
    
    -- Create public.users row
    INSERT INTO public.users (id, email, name)
    VALUES (v_user_id, lower(p_reviewer_email), p_reviewer_name)
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        updated_at = NOW();
    
    RETURN v_user_id;
END;
$$;

-- ============================================================================
-- PART 4: Cleanup Function (revoke reviewer access)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.revoke_reviewer_access(
    p_reviewer_email TEXT
) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
    -- Log revocation
    INSERT INTO public.reviewer_auth_sessions (
        reviewer_email,
        action,
        notes
    ) VALUES (
        p_reviewer_email,
        'access_revoked',
        'Manual revocation by admin'
    );
    
    -- Note: To fully revoke, you must also:
    -- 1. Delete from auth.users via Supabase Dashboard
    -- 2. Or change password via Dashboard
    
    RETURN TRUE;
END;
$$;

-- ============================================================================
-- USAGE INSTRUCTIONS (for P2/Admin)
-- ============================================================================
-- 
-- STEP 1: Create reviewer user in Supabase Dashboard
--   Go to: Authentication > Users > Add User
--   Email: reviewer@apple-testing.com (or any email you choose)
--   Password: [Generate secure password - minimum 12 chars]
--   Auto Confirm: YES (important!)
--
-- STEP 2: Run this to create public.users row:
--   SELECT ensure_reviewer_user('reviewer@apple-testing.com', 'Apple Reviewer');
--
-- STEP 3: For Apple App Store submission, provide:
--   Username: reviewer@apple-testing.com
--   Password: [the password you set]
--
-- STEP 4: After review, revoke access:
--   - Change password in Supabase Dashboard, OR
--   - Delete user from auth.users
--   - Run: SELECT revoke_reviewer_access('reviewer@apple-testing.com');
--
-- ============================================================================
