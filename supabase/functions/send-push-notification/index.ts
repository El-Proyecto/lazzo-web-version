// Supabase Edge Function: send-push-notification
// Sends push notifications via Firebase Cloud Messaging (FCM) and APNs
//
// DEPLOYMENT:
// 1. Install Supabase CLI: npm install -g supabase
// 2. Deploy: supabase functions deploy send-push-notification
// 3. Set secrets:
//    supabase secrets set FIREBASE_PROJECT_ID=your-project-id
//    supabase secrets set FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
//    supabase secrets set FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
//
// TESTING:
// curl -i --location --request POST 'https://[project-ref].supabase.co/functions/v1/send-push-notification' \
//   --header 'Authorization: Bearer [anon-key]' \
//   --header 'Content-Type: application/json' \
//   --data '{"notificationId":"123e4567-e89b-12d3-a456-426614174000"}'

/*import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Firebase Admin SDK initialization
interface FirebaseConfig {
  projectId: string;
  privateKey: string;
  clientEmail: string;
}

// Get Firebase credentials from environment
const getFirebaseConfig = (): FirebaseConfig => {
  const projectId = Deno.env.get("FIREBASE_PROJECT_ID");
  const privateKey = Deno.env.get("FIREBASE_PRIVATE_KEY");
  const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL");

  if (!projectId || !privateKey || !clientEmail) {
    throw new Error("Missing Firebase credentials in environment variables");
  }

  return { projectId, privateKey, clientEmail };
};

// Get Firebase access token for sending messages
const getAccessToken = async (config: FirebaseConfig): Promise<string> => {
  // Create JWT for Google OAuth
  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const claim = {
    iss: config.clientEmail,
    sub: config.clientEmail,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  // Sign JWT (requires crypto)
  const encoder = new TextEncoder();
  const headerBase64 = btoa(JSON.stringify(header));
  const claimBase64 = btoa(JSON.stringify(claim));
  const message = `${headerBase64}.${claimBase64}`;

  // Import private key
  const keyData = config.privateKey
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\n/g, "");
  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    encoder.encode(message)
  );

  const signatureBase64 = btoa(
    String.fromCharCode(...new Uint8Array(signature))
  );
  const jwt = `${message}.${signatureBase64}`;

  // Exchange JWT for access token
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const data = await response.json();
  return data.access_token;
};

// Localization messages (client-side uses ARB files, this is fallback)
const getLocalizedMessage = (
  type: string,
  locale: string,
  notification: any
): { title: string; body: string } => {
  const messages: Record<string, Record<string, any>> = {
    en: {
      groupInviteReceived: {
        title: "Group Invite",
        body: `${notification.user_name} invited you to join ${notification.group_name}`,
      },
      eventStartsSoon: {
        title: "Event Starting Soon",
        body: `${notification.event_emoji || "📅"} ${
          notification.event_name
        } starts in ${notification.mins} min`,
      },
      eventLive: {
        title: "Event is Live!",
        body: `${notification.event_emoji || "🎉"} ${
          notification.event_name
        } is happening now`,
      },
      eventEndsSoon: {
        title: "Event Ending Soon",
        body: `${notification.event_emoji || "⏰"} ${
          notification.event_name
        } ends in ${notification.mins} min`,
      },
      chatMention: {
        title: "You were mentioned",
        body: `${notification.user_name} mentioned you in ${notification.event_name}`,
      },
      paymentsAddedYouOwe: {
        title: "New Expense",
        body: `${notification.user_name} added an expense: You owe ${notification.amount}`,
      },
      paymentsRequest: {
        title: "Payment Request",
        body: `${notification.user_name} requests ${notification.amount} for ${notification.note}`,
      },
      memoryReady: {
        title: "Memory Ready",
        body: `Your memory for ${notification.event_name} is ready to share!`,
      },
      uploadsClosing: {
        title: "Upload Deadline Soon",
        body: `Photo uploads for ${notification.event_name} close in ${notification.mins} min`,
      },
    },
    pt: {
      groupInviteReceived: {
        title: "Convite de Grupo",
        body: `${notification.user_name} convidou-te para ${notification.group_name}`,
      },
      eventStartsSoon: {
        title: "Evento a Começar",
        body: `${notification.event_emoji || "📅"} ${
          notification.event_name
        } começa em ${notification.mins} min`,
      },
      eventLive: {
        title: "Evento Ao Vivo!",
        body: `${notification.event_emoji || "🎉"} ${
          notification.event_name
        } está a acontecer agora`,
      },
      eventEndsSoon: {
        title: "Evento a Terminar",
        body: `${notification.event_emoji || "⏰"} ${
          notification.event_name
        } termina em ${notification.mins} min`,
      },
      chatMention: {
        title: "Foste mencionado",
        body: `${notification.user_name} mencionou-te em ${notification.event_name}`,
      },
      paymentsAddedYouOwe: {
        title: "Nova Despesa",
        body: `${notification.user_name} adicionou despesa: Deves ${notification.amount}`,
      },
      paymentsRequest: {
        title: "Pedido de Pagamento",
        body: `${notification.user_name} pede ${notification.amount} para ${notification.note}`,
      },
      memoryReady: {
        title: "Memória Pronta",
        body: `A tua memória de ${notification.event_name} está pronta para partilhar!`,
      },
      uploadsClosing: {
        title: "Prazo de Upload Próximo",
        body: `Upload de fotos para ${notification.event_name} fecha em ${notification.mins} min`,
      },
    },
  };

  const localeMessages = messages[locale] || messages.en;
  const template = localeMessages[type] || {
    title: "Lazzo",
    body: "You have a new notification",
  };

  return template;
};

// Send FCM notification
const sendFcmNotification = async (
  token: string,
  message: { title: string; body: string },
  notification: any,
  accessToken: string,
  projectId: string
) => {
  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  const payload = {
    message: {
      token,
      notification: {
        title: message.title,
        body: message.body,
      },
      data: {
        notification_id: notification.id,
        deeplink: notification.deeplink || "",
        type: notification.type,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channel_id: "lazzo_notifications",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    },
  };

  const response = await fetch(fcmUrl, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`FCM error: ${error}`);
  }

  return await response.json();
};

// Main handler
serve(async (req) => {
  try {
    const { notificationId } = await req.json();

    if (!notificationId) {
      return new Response(
        JSON.stringify({ error: "notificationId required" }),
        { status: 400 }
      );
    }

    // Initialize Supabase client with service role (bypasses RLS)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Get notification details
    const { data: notification, error: notifError } = await supabase
      .from("notifications")
      .select("*")
      .eq("id", notificationId)
      .single();

    if (notifError || !notification) {
      return new Response(
        JSON.stringify({ error: "Notification not found" }),
        { status: 404 }
      );
    }

    // Only send push for category='push'
    if (notification.category !== "push") {
      return new Response(
        JSON.stringify({ message: "Not a push notification" }),
        { status: 200 }
      );
    }

    // Get user's push tokens
    const { data: tokens, error: tokensError } = await supabase
      .from("push_tokens")
      .select("token, platform")
      .eq("user_id", notification.recipient_user_id)
      .eq("is_active", true);

    if (tokensError || !tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ message: "No push tokens found" }), {
        status: 200,
      });
    }

    // Get user's locale for localization
    const { data: settings } = await supabase
      .from("user_notification_settings")
      .select("locale")
      .eq("user_id", notification.recipient_user_id)
      .single();

    const locale = settings?.locale || "en";
    const message = getLocalizedMessage(
      notification.type,
      locale,
      notification
    );

    // Get Firebase config and access token
    const firebaseConfig = getFirebaseConfig();
    const accessToken = await getAccessToken(firebaseConfig);

    // Send to all tokens
    const results = await Promise.allSettled(
      tokens.map((t) =>
        sendFcmNotification(
          t.token,
          message,
          notification,
          accessToken,
          firebaseConfig.projectId
        )
      )
    );

    const successCount = results.filter((r) => r.status === "fulfilled").length;
    const failCount = results.filter((r) => r.status === "rejected").length;

    console.log(
      `[SendPush] ✅ Sent ${successCount}/${tokens.length} notifications (${failCount} failed)`
    );

    return new Response(
      JSON.stringify({
        success: true,
        sent: successCount,
        failed: failCount,
      }),
      { status: 200 }
    );
  } catch (error) {
    console.error("[SendPush] ❌ Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    });
  }
});
*/