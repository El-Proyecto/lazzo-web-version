// Edge Function: Automatic Event Phase Transitions
// Schedule: Every 5 minutes (*/5 * * * *)
// Protected: Requires CRON_SECRET header
//
// Handles ALL automatic status transitions:
//   pending  → expired   (start_datetime passed without confirmation)
//   confirmed → living   (start_datetime reached)
//   living   → recap     (end_datetime reached)
//   recap    → ended     (24h after end_datetime)
//
// Tracks event_phase_changed to PostHog for each transition.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-cron-secret',
}

interface TransitionResult {
  event_id: string
  event_name: string
  from_phase: string
  to_phase: string
}

/**
 * Send event_phase_changed to PostHog via HTTP API (server-side capture).
 * Uses the PostHog /capture endpoint so we don't need the client SDK.
 */
async function trackPhaseChanges(transitions: TransitionResult[]): Promise<void> {
  const apiKey = Deno.env.get('POSTHOG_API_KEY')
  const host = Deno.env.get('POSTHOG_HOST') || 'https://eu.i.posthog.com'

  if (!apiKey || transitions.length === 0) return

  const batch = transitions.map((t) => ({
    event: 'event_phase_changed',
    // Use event_id as distinct_id so it groups per event, not per user
    // Server-side events don't have a user context
    distinct_id: `server_${t.event_id}`,
    properties: {
      event_id: t.event_id,
      event_name: t.event_name,
      from_phase: t.from_phase,
      to_phase: t.to_phase,
      trigger: 'auto_server',
      platform: 'server',
      $lib: 'supabase-edge-function',
    },
  }))

  try {
    const response = await fetch(`${host}/batch/`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ api_key: apiKey, batch }),
    })

    if (!response.ok) {
      console.error(`[transition-event-phases] PostHog batch failed: ${response.status}`)
    } else {
      console.log(`[transition-event-phases] Tracked ${transitions.length} phase changes to PostHog`)
    }
  } catch (err) {
    console.error('[transition-event-phases] PostHog tracking error:', err)
  }
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
    console.warn('[transition-event-phases] Unauthorized attempt')
    return new Response('Unauthorized', { status: 401 })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { autoRefreshToken: false, persistSession: false } }
    )

    const now = new Date().toISOString()
    const recapDeadline = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
    const transitions: TransitionResult[] = []

    console.log(`[transition-event-phases] Starting job at ${now}`)

    // ─── 1. pending → expired (start_datetime passed, never confirmed) ───
    const { data: pendingExpired, error: e1 } = await supabase
      .from('events')
      .select('id, name')
      .eq('status', 'pending')
      .not('start_datetime', 'is', null)
      .lte('start_datetime', now)

    if (e1) console.error('[transition-event-phases] pending→expired query error:', e1)

    if (pendingExpired && pendingExpired.length > 0) {
      for (const event of pendingExpired) {
        const { error } = await supabase
          .from('events')
          .update({ status: 'expired', updated_at: now })
          .eq('id', event.id)

        if (!error) {
          transitions.push({
            event_id: event.id,
            event_name: event.name,
            from_phase: 'pending',
            to_phase: 'expired',
          })
        }
      }
      console.log(`[transition-event-phases] pending→expired: ${pendingExpired.length}`)
    }

    // ─── 2. confirmed → living (start_datetime reached) ───
    const { data: confirmedLiving, error: e2 } = await supabase
      .from('events')
      .select('id, name')
      .eq('status', 'confirmed')
      .lte('start_datetime', now)

    if (e2) console.error('[transition-event-phases] confirmed→living query error:', e2)

    if (confirmedLiving && confirmedLiving.length > 0) {
      for (const event of confirmedLiving) {
        const { error } = await supabase
          .from('events')
          .update({ status: 'living', updated_at: now })
          .eq('id', event.id)

        if (!error) {
          transitions.push({
            event_id: event.id,
            event_name: event.name,
            from_phase: 'confirmed',
            to_phase: 'living',
          })
        }
      }
      console.log(`[transition-event-phases] confirmed→living: ${confirmedLiving.length}`)
    }

    // ─── 3. living → recap (end_datetime reached) ───
    const { data: livingRecap, error: e3 } = await supabase
      .from('events')
      .select('id, name')
      .eq('status', 'living')
      .lte('end_datetime', now)

    if (e3) console.error('[transition-event-phases] living→recap query error:', e3)

    if (livingRecap && livingRecap.length > 0) {
      for (const event of livingRecap) {
        const { error } = await supabase
          .from('events')
          .update({ status: 'recap', updated_at: now })
          .eq('id', event.id)

        if (!error) {
          transitions.push({
            event_id: event.id,
            event_name: event.name,
            from_phase: 'living',
            to_phase: 'recap',
          })
        }
      }
      console.log(`[transition-event-phases] living→recap: ${livingRecap.length}`)
    }

    // ─── 4. recap → ended (24h after end_datetime) ───
    const { data: recapEnded, error: e4 } = await supabase
      .from('events')
      .select('id, name')
      .eq('status', 'recap')
      .lte('end_datetime', recapDeadline)

    if (e4) console.error('[transition-event-phases] recap→ended query error:', e4)

    if (recapEnded && recapEnded.length > 0) {
      for (const event of recapEnded) {
        const { error } = await supabase
          .from('events')
          .update({ status: 'ended', updated_at: now })
          .eq('id', event.id)

        if (!error) {
          transitions.push({
            event_id: event.id,
            event_name: event.name,
            from_phase: 'recap',
            to_phase: 'ended',
          })
        }
      }
      console.log(`[transition-event-phases] recap→ended: ${recapEnded.length}`)
    }

    // ─── Track all transitions to PostHog ───
    await trackPhaseChanges(transitions)

    const summary = {
      success: true,
      total_transitions: transitions.length,
      pending_to_expired: transitions.filter(t => t.to_phase === 'expired').length,
      confirmed_to_living: transitions.filter(t => t.to_phase === 'living').length,
      living_to_recap: transitions.filter(t => t.to_phase === 'recap').length,
      recap_to_ended: transitions.filter(t => t.to_phase === 'ended').length,
      timestamp: now,
    }

    console.log('[transition-event-phases] Completed:', JSON.stringify(summary))

    return new Response(JSON.stringify(summary), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    console.error('[transition-event-phases] Fatal error:', error)
    const errorMessage = error instanceof Error ? error.message : 'Unknown error'
    return new Response(
      JSON.stringify({ success: false, error: errorMessage, timestamp: new Date().toISOString() }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
