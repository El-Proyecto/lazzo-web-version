// Edge Function to notify participants 15 minutes before event ends
// Schedule: Every 5 minutes (*/5 * * * *)
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
    console.warn('[notify-events-ending] Unauthorized attempt')
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

    console.log('[notify-events-ending] Starting job...')

    // Call the optimized PostgreSQL function
    const { data, error } = await supabaseClient.rpc('notify_events_ending_soon')

    if (error) {
      console.error('[notify-events-ending] Error:', error)
      throw error
    }

    const result = data?.[0] || { notifications_created: 0, events_processed: 0 }
    console.log('[notify-events-ending] Job completed:', result)

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Event ending notifications sent',
        notifications_created: result.notifications_created,
        events_processed: result.events_processed,
        timestamp: new Date().toISOString()
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )
  } catch (error) {
    console.error('[notify-events-ending] Fatal error:', error)
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
