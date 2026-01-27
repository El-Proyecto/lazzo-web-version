// Edge Function to notify participants 1 hour before upload window closes
// Schedule: Every 10 minutes (*/10 * * * *)
// Protected: Requires CRON_SECRET header

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-cron-secret',
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Security: Verify cron secret
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 })
  }

  const secret = req.headers.get('x-cron-secret')
  if (!secret || secret !== Deno.env.get('CRON_SECRET')) {
    console.warn('[notify-uploads-closing] Unauthorized attempt')
    return new Response('Unauthorized', { status: 401 })
  }

  try {
    // Create Supabase client with service role key
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    console.log('[notify-uploads-closing] Starting job...')

    // Task 1: Notify participants about uploads closing soon
    const { data, error } = await supabaseClient.rpc('notify_uploads_closing_soon')

    if (error) {
      console.error('[notify-uploads-closing] Error:', error)
      throw error
    }

    const result = data?.[0] || { notifications_created: 0, events_processed: 0 }
    console.log('[notify-uploads-closing] Notifications sent:', result)

    // Task 2: Check and end expired recaps (recap period > 24h)
    const { data: expiredRecaps, error: recapError } = await supabaseClient.rpc('check_and_end_expired_recaps')

    if (recapError) {
      console.error('[notify-uploads-closing] Error ending expired recaps:', recapError)
      // Don't throw - this is secondary task
    } else {
      const recapCount = expiredRecaps?.length || 0
      if (recapCount > 0) {
        console.log(`[notify-uploads-closing] Ended ${recapCount} expired recaps:`, expiredRecaps)
      }
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Upload closing notifications sent',
        notifications_created: result.notifications_created,
        events_processed: result.events_processed,
        expired_recaps_ended: expiredRecaps?.length || 0,
        timestamp: new Date().toISOString()
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )
  } catch (error) {
    console.error('[notify-uploads-closing] Fatal error:', error)
    const errorMessage = error instanceof Error ? error.message : 'Unknown error'
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: errorMessage,
        timestamp: new Date().toISOString()
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
