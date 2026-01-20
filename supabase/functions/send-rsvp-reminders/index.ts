import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (_req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    if (!supabaseUrl || !supabaseKey) {
      throw new Error('Missing required environment variables')
    }

    const supabase = createClient(supabaseUrl, supabaseKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })

    console.log('[send-rsvp-reminders] Starting RSVP reminder check...')

    // Chamar a função SQL que cria as notificações
    const { error } = await supabase.rpc('send_event_rsvp_reminders')

    if (error) {
      console.error('[send-rsvp-reminders] Error:', error)
      throw error
    }

    console.log('[send-rsvp-reminders] RSVP reminders sent successfully')

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'RSVP reminders sent',
        timestamp: new Date().toISOString()
      }),
      { 
        headers: { 'Content-Type': 'application/json' },
        status: 200
      }
    )
  } catch (error) {
    console.error('[send-rsvp-reminders] Fatal error:', error)
    return new Response(
      JSON.stringify({ 
        error: error.message,
        timestamp: new Date().toISOString()
      }),
      { 
        status: 500, 
        headers: { 'Content-Type': 'application/json' } 
      }
    )
  }
})
