// app/i/[token]/page.tsx
//import React from "react";

async function resolveInvite(token: string) {
  const base = process.env.NEXT_PUBLIC_SUPABASE_FUNCTIONS_URL!;
  const res = await fetch(`${base}/invite-resolve?token=${encodeURIComponent(token)}`, {
    cache: "no-store",
  });
  const data = await res.json().catch(() => null);
  return { ok: res.ok, status: res.status, data };
}

export default async function InvitePage({ params }: { params: { token: string } }) {
  const token = params.token;
  const { ok, data } = await resolveInvite(token);

  // deep link fallback (opcional)
  const appScheme = `lazzo://invite/${token}`; // se tiveres scheme definido na app
  const universalUrl = `https://lazzo.com/i/${token}`; // o próprio link

  if (!ok || !data?.valid) {
    const reason = data?.reason ?? "unknown";
    return (
      <main style={{ padding: 24, maxWidth: 520, margin: "0 auto", fontFamily: "system-ui" }}>
        <h1>Convite inválido</h1>
        <p>Este convite não é válido ({reason}).</p>
        <p>Se achares que é um erro, pede um novo QR ao admin do grupo.</p>
      </main>
    );
  }

  const groupName = data.group?.name ?? "grupo";
  const expiresAt = data.expires_at;

  return (
    <main style={{ padding: 24, maxWidth: 520, margin: "0 auto", fontFamily: "system-ui" }}>
      <h1>Entrar no {groupName}</h1>
      <p>Abre a app para aceitares o convite.</p>
      <p style={{ opacity: 0.7 }}>Expira em: {new Date(expiresAt).toLocaleString("pt-PT")}</p>

      <div style={{ display: "grid", gap: 12, marginTop: 18 }}>
        {/* Se Universal/App Links estiverem configurados, clicar aqui geralmente abre a app */}
        <a href={universalUrl} style={{ padding: 12, border: "1px solid #ddd", borderRadius: 10, textAlign: "center" }}>
          Abrir na app
        </a>

        {/* Fallback para scheme (se usares custom scheme) */}
        <a href={appScheme} style={{ padding: 12, border: "1px solid #ddd", borderRadius: 10, textAlign: "center" }}>
          Abrir na app (fallback)
        </a>

        {/* Store links */}
        <a href={process.env.NEXT_PUBLIC_APPSTORE_URL!} style={{ padding: 12, border: "1px solid #ddd", borderRadius: 10, textAlign: "center" }}>
          Descarregar na App Store
        </a>
        <a href={process.env.NEXT_PUBLIC_PLAYSTORE_URL!} style={{ padding: 12, border: "1px solid #ddd", borderRadius: 10, textAlign: "center" }}>
          Descarregar na Google Play
        </a>
      </div>

      <p style={{ marginTop: 20, opacity: 0.7 }}>
        Se instalaste agora, volta a abrir este link depois da instalação.
      </p>
    </main>
  );
}
