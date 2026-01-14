// Supabase Edge Function: send-push-notification-apns
// Sends push notifications via Apple Push Notification service (APNs)
// Replaces Firebase FCM implementation with direct APNs integration
//
// DEPLOYMENT:
// 1. Deploy: supabase functions deploy send-push-notification-apns
// 2. Set secrets:
//    supabase secrets set APNS_KEY_ID=ABC1234567
//    supabase secrets set APNS_TEAM_ID=XYZ9876543
//    supabase secrets set APNS_AUTH_KEY="$(cat AuthKey_ABC1234567.p8)"
//    supabase secrets set IOS_BUNDLE_ID=com.yourcompany.lazzo
//
// TESTING:
// curl -i --location --request POST 'https://[project-ref].supabase.co/functions/v1/send-push-notification-apns' \
//   --header 'Authorization: Bearer [service-role-key]' \
//   --header 'Content-Type: application/json' \
//   --data '{"notificationId":"123e4567-e89b-12d3-a456-426614174000"}'

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// APNs configuration
interface APNsConfig {
  keyId: string;
  teamId: string;
  authKey: string;
  bundleId: string;
}

// APNs endpoints
const APNS_ENDPOINTS = {
  production: "https://api.push.apple.com",
  sandbox: "https://api.sandbox.push.apple.com",
};

// Get APNs configuration from environment
const getAPNsConfig = (): APNsConfig => {
  const keyId = Deno.env.get("APNS_KEY_ID");
  const teamId = Deno.env.get("APNS_TEAM_ID");
  const authKey = Deno.env.get("APNS_AUTH_KEY");
  const bundleId = Deno.env.get("APNS_BUNDLE_ID");

  if (!keyId || !teamId || !authKey || !bundleId) {
    throw new Error("Missing APNs credentials in environment variables");
  }

  return { keyId, teamId, authKey, bundleId };
};

// Generate JWT for APNs authentication
const generateAPNsJWT = async (config: APNsConfig): Promise<string> => {
  const header = {
    alg: "ES256",
    kid: config.keyId,
  };

  const now = Math.floor(Date.now() / 1000);
  const claims = {
    iss: config.teamId,
    iat: now,
  };

  // Encode header and claims
  const encoder = new TextEncoder();
  const headerB64 = btoa(JSON.stringify(header))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
  const claimsB64 = btoa(JSON.stringify(claims))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
  const message = `${headerB64}.${claimsB64}`;

  // Import ECDSA P-256 private key
  const keyData = config.authKey
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\n/g, "")
    .trim();

  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  );

  // Sign with ECDSA SHA-256
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    cryptoKey,
    encoder.encode(message)
  );

  // Encode signature to base64url
  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");

  return `${message}.${signatureB64}`;
};

// Localized notification titles/bodies (fallback, client uses ARB files)
const getLocalizedMessage = (
  type: string,
  data: Record<string, string>
): { title: string; body: string } => {
  const { user_name, group_name, event_name, event_emoji, amount, mins, hours, date, time, place } = data;
  const emoji = event_emoji || "📅";

  const messages: Record<string, { title: string; body: string }> = {
    groupInviteReceived: {
      title: "Group Invite",
      body: `${user_name} invited you to join ${group_name}`,
    },
    paymentsAddedYouOwe: {
      title: "New Expense",
      body: `${user_name} added an expense: ${amount}`,
    },
    paymentsRequest: {
      title: "Payment Request",
      body: `${user_name} is requesting ${amount}`,
    },
    eventStartsSoon: {
      title: `${emoji} Event Starting Soon`,
      body: `${event_name} starts in ${mins} minutes`,
    },
    eventLive: {
      title: `${emoji} Event is Live!`,
      body: `${event_name} has started`,
    },
    chatMention: {
      title: `${emoji} Mentioned in Chat`,
      body: `${user_name} mentioned you in ${event_name}`,
    },
    securityNewLogin: {
      title: "New Login Detected",
      body: `Logged in from ${place || "unknown location"}`,
    },
    uploadsClosing: {
      title: `${emoji} Upload Window Closing`,
      body: `Upload photos for ${event_name} (${mins} min left)`,
    },
    memoryReady: {
      title: `${emoji} Memory Ready`,
      body: `Your memory for ${event_name} is ready to view`,
    },
    eventEndsSoon: {
      title: `${emoji} Event Ending Soon`,
      body: `${event_name} ends in ${mins} minutes`,
    },
    eventCreated: {
      title: "New Event",
      body: `${user_name} created ${emoji} ${event_name} in ${group_name}`,
    },
    eventDateSet: {
      title: `${emoji} Date Confirmed`,
      body: `${event_name} is on ${date} at ${time}`,
    },
    eventLocationSet: {
      title: `${emoji} Location Set`,
      body: `${event_name} will be at ${place}`,
    },
    eventExtended: {
      title: `${emoji} Event Extended`,
      body: `${event_name} extended by ${hours} hours`,
    },
    uploadsOpen: {
      title: `${emoji} Upload Photos`,
      body: `Upload photos for ${event_name} (${hours} hours left)`,
    },
    rsvpUpdated: {
      title: `${emoji} RSVP Updated`,
      body: `${user_name} is ${data.note} for ${event_name}`,
    },
    eventConfirmed: {
      title: `${emoji} Event Confirmed`,
      body: `${event_name} on ${date} at ${time}`,
    },
    eventDetailsUpdated: {
      title: `${emoji} Event Updated`,
      body: `${event_name} details changed`,
    },
    eventCanceled: {
      title: `${emoji} Event Canceled`,
      body: `${event_name} has been canceled`,
    },
  };

  return messages[type] || { title: "Notification", body: "You have a new notification" };
};

// Send push notification to APNs
const sendToAPNs = async (
  deviceToken: string,
  environment: string,
  payload: any,
  jwt: string,
  bundleId: string
): Promise<{ success: boolean; status?: number; reason?: string }> => {
  const endpoint = environment === "production" ? APNS_ENDPOINTS.production : APNS_ENDPOINTS.sandbox;
  const url = `${endpoint}/3/device/${deviceToken}`;

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "authorization": `bearer ${jwt}`,
        "apns-topic": bundleId,
        "apns-push-type": "alert",
        "apns-priority": "10",
        "apns-expiration": "0",
      },
      body: JSON.stringify(payload),
    });

    if (response.status === 200) {
      return { success: true, status: 200 };
    }

    const errorBody = await response.json().catch(() => ({}));
    return {
      success: false,
      status: response.status,
      reason: errorBody.reason || "Unknown error",
    };
  } catch (error) {
    console.error(`[APNs] Network error:`, error);
    return { success: false, reason: "Network error" };
  }
};

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Parse request body
    const { notificationId } = await req.json();

    if (!notificationId) {
      return new Response(
        JSON.stringify({ error: "Missing notificationId" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`[APNs] Processing notification: ${notificationId}`);

    // Create Supabase client with service role key
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );

    // 1) Fetch notification details
    const { data: notification, error: notifError } = await supabaseClient
      .from("notifications")
      .select("*")
      .eq("id", notificationId)
      .single();

    if (notifError || !notification) {
      console.error(`[APNs] Notification not found:`, notifError);
      return new Response(
        JSON.stringify({ error: "Notification not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Only send push for 'push' category
    if (notification.category !== "push") {
      console.log(`[APNs] Skipping non-push notification (category: ${notification.category})`);
      return new Response(
        JSON.stringify({ message: "Not a push notification", skipped: true }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2) Fetch user's active device tokens
    const { data: tokens, error: tokensError } = await supabaseClient
      .from("user_push_tokens")
      .select("id, device_token, platform, environment")
      .eq("user_id", notification.recipient_user_id)
      .eq("platform", "ios")
      .eq("is_active", true);

    if (tokensError || !tokens || tokens.length === 0) {
      console.log(`[APNs] No active tokens for user ${notification.recipient_user_id}`);
      return new Response(
        JSON.stringify({ message: "No active tokens", sent: 0 }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`[APNs] Found ${tokens.length} active token(s)`);

    // 3) Get APNs config and generate JWT
    const config = getAPNsConfig();
    const jwt = await generateAPNsJWT(config);

    // 4) Build notification payload
    const { title, body } = getLocalizedMessage(notification.type, notification);
    const payload = {
      aps: {
        alert: {
          title,
          body,
        },
        badge: 1, // TODO: Calculate actual unread count
        sound: "default",
        "content-available": 1,
      },
      deeplink: notification.deeplink || "",
      type: notification.type,
      notificationId: notification.id,
      eventId: notification.event_id,
      groupId: notification.group_id,
    };

    // 5) Send to all user's devices
    const results = await Promise.all(
      tokens.map(async (token) => {
        console.log(`[APNs] Sending to ${token.environment} token: ${token.device_token.substring(0, 16)}...`);

        const result = await sendToAPNs(
          token.device_token,
          token.environment,
          payload,
          jwt,
          config.bundleId
        );

        // Handle result
        if (result.success) {
          // Update last_used_at on success
          await supabaseClient
            .from("user_push_tokens")
            .update({ last_used_at: new Date().toISOString() })
            .eq("id", token.id);

          console.log(`[APNs] ✅ Sent successfully to token ${token.id}`);
          return { tokenId: token.id, success: true };
        } else {
          console.error(`[APNs] ❌ Failed to send to token ${token.id}:`, result.reason);

          // Mark token inactive if invalid
          if (result.status === 410 || result.reason === "BadDeviceToken") {
            await supabaseClient
              .from("user_push_tokens")
              .update({ is_active: false, updated_at: new Date().toISOString() })
              .eq("id", token.id);

            console.log(`[APNs] Marked token ${token.id} as inactive`);
          }

          return { tokenId: token.id, success: false, error: result.reason };
        }
      })
    );

    // 6) Return summary
    const successCount = results.filter((r) => r.success).length;
    const failureCount = results.filter((r) => !r.success).length;

    console.log(`[APNs] Summary: ${successCount} sent, ${failureCount} failed`);

    return new Response(
      JSON.stringify({
        message: "Push notifications processed",
        notificationId,
        sent: successCount,
        failed: failureCount,
        results,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[APNs] Fatal error:", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    return new Response(
      JSON.stringify({ error: errorMessage }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
