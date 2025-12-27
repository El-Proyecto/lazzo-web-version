

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      "access-control-allow-origin": "*",
      "access-control-allow-headers": "authorization, x-client-info, apikey, content-type",
    },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") return json({}, 200);

  const url = new URL(req.url);
  const token = url.searchParams.get("token")?.trim();

  if (!token) return json({ valid: false, reason: "missing_token" }, 400);

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const supabase = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false },
  });

  // 1) fetch do invite link
  const { data: link, error: linkErr } = await supabase
    .from("group_invite_links")
    .select("group_id, expires_at, revoked_at")
    .eq("token", token)
    .maybeSingle();

  if (linkErr) return json({ valid: false, reason: "db_error" }, 500);
  if (!link) return json({ valid: false, reason: "not_found" }, 404);
  if (link.revoked_at) return json({ valid: false, reason: "revoked" }, 410);

  const expiresAt = new Date(link.expires_at);
  if (expiresAt.getTime() <= Date.now()) {
    return json({ valid: false, reason: "expired" }, 410);
  }

  // 2) fetch do grupo (somente info não sensível)
  const { data: group, error: groupErr } = await supabase
    .from("groups")
    .select("id, name") // ajusta fields conforme a tua tabela
    .eq("id", link.group_id)
    .maybeSingle();

  if (groupErr) return json({ valid: false, reason: "db_error" }, 500);
  if (!group) return json({ valid: false, reason: "group_not_found" }, 404);

  return json({
    valid: true,
    group: { id: group.id, name: group.name },
    expires_at: link.expires_at,
  });
});
