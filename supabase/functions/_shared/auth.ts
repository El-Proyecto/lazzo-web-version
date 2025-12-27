// Shared authentication utilities for Edge Functions
// Protects scheduled functions from unauthorized access

/**
 * Verifies the secret header for scheduled Edge Functions
 * Use this to prevent unauthorized invocations
 */
export function verifySchedulerSecret(req: Request): boolean {
  const authHeader = req.headers.get('authorization')
  const secretHeader = req.headers.get('x-scheduler-secret')
  
  // Allow service role key OR scheduler secret
  const expectedSecret = Deno.env.get('SCHEDULER_SECRET')
  
  if (!expectedSecret) {
    console.warn('[Auth] SCHEDULER_SECRET not set - allowing all requests (DEV ONLY)')
    return true // In dev, allow if not configured
  }
  
  // Check scheduler secret header
  if (secretHeader === expectedSecret) {
    return true
  }
  
  // Check if it's a service role request
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (authHeader?.includes(serviceRoleKey || '')) {
    return true
  }
  
  return false
}

/**
 * Returns 401 Unauthorized response
 */
export function unauthorizedResponse(corsHeaders: Record<string, string>) {
  return new Response(
    JSON.stringify({ 
      success: false, 
      error: 'Unauthorized: Invalid scheduler secret',
      timestamp: new Date().toISOString()
    }),
    { 
      status: 401, 
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    }
  )
}
