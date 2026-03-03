# Lazzo — PostHog Setup & Integration Guide

**Guião completo para setup do PostHog Cloud EU.**
Segue os passos por ordem. Cada secção tem o que fazer, como verificar, e links relevantes.

**Pré-requisitos:** Acesso ao repo da app (Flutter/iOS) e ao repo da web (Vercel).

**Referências:**
- [METRICS.md](METRICS.md) — taxonomia de eventos, dashboards, flags, cost optimization
- [ROADMAP_BETA_DEPLOY.md](ROADMAP_BETA_DEPLOY.md) — roadmap com Epic A1 (PostHog Integration)

---

## Parte 1 — Criar Conta & Projeto PostHog

### 1.1 Criar conta PostHog Cloud EU

1. Vai a **https://eu.posthog.com/signup**
2. Cria conta com email (ou Google/GitHub SSO)
3. **Confirma que estás no EU cloud** — o URL deve ser `eu.posthog.com`, não `app.posthog.com` (US)
4. Cria um projeto chamado **"Lazzo"**

### 1.2 Anotar credenciais

Depois de criar o projeto:

1. Vai a **Project Settings → Project API Key**
2. Anota:
   - **API Key** (algo como `phc_xxxxxxxxxxxx`) — usado nos SDKs
   - **Project ID** — visível no URL do projeto
   - **Host:** `https://eu.i.posthog.com` (EU instance)

> Guarda estes valores — vais precisar para a app e para a web.

### 1.3 Configurar Project Settings (cost-safe)

Vai a **Project Settings** e garante:

| Setting | Valor | Motivo |
|---------|-------|--------|
| **Session Replay** | **OFF** | Custa dinheiro, não é necessário na beta |
| **Autocapture** | **OFF** | Vamos usar só eventos explícitos |
| **Heatmaps** | **OFF** | Não necessário |
| **Web Analytics** | **OFF** | Temos eventos custom |
| **Exception Autocapture** | **ON** | Gratuito, apanha erros unhandled |
| **Surveys** | **OFF** | Não vamos usar |
| **Data Pipelines** | **OFF** | Não necessário |

> ⚠️ Isto é **crítico** para manter $0 de custos. O free tier do PostHog dá 1M events/month e 1M flag requests/month. Com ~50 beta users, vamos usar ~1,500 events/month.

---

## Parte 2 — Integração na App (Flutter/iOS)

### 2.1 Adicionar dependência

No `pubspec.yaml`:

```yaml
dependencies:
  posthog_flutter: ^4.0.0  # Verifica a versão mais recente em pub.dev
```

Depois corre:
```bash
flutter pub get
```

### 2.2 Configuração iOS (Info.plist)

No ficheiro `ios/Runner/Info.plist`, adiciona:

```xml
<dict>
    <!-- ... existing entries ... -->
    <key>com.posthog.posthog</key>
    <dict>
        <key>apiKey</key>
        <string>phc_YOUR_API_KEY</string>
        <key>host</key>
        <string>https://eu.i.posthog.com</string>
        <key>captureScreenViews</key>
        <false/>
        <key>captureApplicationLifecycleEvents</key>
        <false/>
        <key>debug</key>
        <true/>
    </dict>
</dict>
```

> `captureScreenViews: false` e `captureApplicationLifecycleEvents: false` porque vamos controlar manualmente quais ecrãs rastrear. `debug: true` para ver logs durante desenvolvimento — muda para `false` antes de submeter para TestFlight.

### 2.3 Criar `AnalyticsService`

Cria o ficheiro `lib/services/analytics_service.dart`:

```dart
import 'package:posthog_flutter/posthog_flutter.dart';

/// Serviço de analytics — wrapper sobre PostHog SDK.
/// Chamado APENAS da presentation layer (pages/providers).
/// NUNCA importar no domain layer.
///
/// Identity flow:
/// 1. App abre → PostHog gera distinct_id anónimo automaticamente
/// 2. Auth completa → chamar identify(supabaseUserId) → merge anónimo → user
/// 3. Logout → chamar reset() → novo distinct_id anónimo
class AnalyticsService {
  static Posthog get _posthog => Posthog();

  // --------------- Cache de feature flags ---------------
  static final Map<String, dynamic> _flagCache = {};
  static DateTime? _lastFlagReload;
  static const _flagReloadInterval = Duration(minutes: 30);

  // --------------- Inicialização ---------------

  /// Chamar uma vez no main.dart, DEPOIS do Supabase.initialize()
  static Future<void> initialize() async {
    // PostHog inicializa automaticamente via Info.plist (iOS)
    // Aqui apenas fazemos o primeiro reload de flags
    await reloadFeatureFlags();
  }

  // --------------- Core Tracking ---------------

  /// Envia um evento para PostHog.
  /// [properties] são mescladas com global properties automaticamente.
  static Future<void> track(
    String event, {
    Map<String, dynamic>? properties,
  }) async {
    await _posthog.capture(
      eventName: event,
      properties: properties,
    );
  }

  // --------------- Identity ---------------

  /// Chamar quando auth completa (host ou guest).
  /// PostHog faz alias automático: anonymous distinct_id → userId.
  /// Todas as sessões anteriores são unificadas.
  static Future<void> identify(
    String userId, {
    Map<String, dynamic>? properties,
  }) async {
    await _posthog.identify(
      userId: userId,
      userProperties: properties,
    );
    // Reload flags para o utilizador agora identificado
    await reloadFeatureFlags();
  }

  /// Chamar no logout.
  /// Limpa distinct_id + gera novo anónimo.
  static Future<void> reset() async {
    await _posthog.reset();
    _flagCache.clear();
    _lastFlagReload = null;
  }

  // --------------- Screen Tracking ---------------

  /// Enviar APENAS para ecrãs críticos (ver lista em METRICS.md).
  /// NÃO chamar em cada navegação/animação/bottom sheet.
  ///
  /// Ecrãs críticos: home, event_detail, event_living, event_recap,
  /// create_event, memory_viewer, memory_ready, invite_landing,
  /// profile, inbox
  static Future<void> screenViewed(
    String screenName, {
    String? eventId,
  }) async {
    await _posthog.screen(
      screenName: screenName,
      properties: {
        if (eventId != null) 'event_id': eventId,
      },
    );
  }

  // --------------- Feature Flags ---------------

  /// Lê flag do CACHE LOCAL — síncrono, sem network call.
  /// Chamar dentro de build() é seguro (não faz request).
  static bool isFeatureEnabled(String flagKey) {
    final value = _flagCache[flagKey];
    if (value is bool) return value;
    if (value is String) return value.isNotEmpty;
    return false;
  }

  /// Lê valor da flag do CACHE LOCAL — para flags multivariate.
  static String? getFeatureFlagValue(String flagKey) {
    final value = _flagCache[flagKey];
    if (value is String) return value;
    if (value is bool) return value.toString();
    return null;
  }

  /// Recarrega flags do servidor PostHog.
  /// Chamar APENAS em:
  /// - App open (initialize)
  /// - Auth complete (identify)
  /// - Timer de 30 min (se app estiver ativa)
  /// NÃO chamar em cada screen transition ou build().
  static Future<void> reloadFeatureFlags() async {
    try {
      await _posthog.reloadFeatureFlags();

      // Lê os valores atualizados para o cache local
      // Nota: posthog_flutter não expõe getAllFlags(), então
      // precisamos ler cada flag individualmente
      for (final flagKey in _knownFlags) {
        final value = await _posthog.getFeatureFlag(flagKey);
        if (value != null) {
          _flagCache[flagKey] = value;
        }
      }

      _lastFlagReload = DateTime.now();
    } catch (e) {
      // Silently fail — flags mantêm valores do cache anterior
      // Em caso de erro de rede, melhor usar valores antigos que crashar
    }
  }

  /// Verifica se é hora de recarregar flags (30 min interval).
  /// Chamar num timer periódico ou no app lifecycle.
  static Future<void> reloadFlagsIfNeeded() async {
    if (_lastFlagReload == null) {
      await reloadFeatureFlags();
      return;
    }
    final elapsed = DateTime.now().difference(_lastFlagReload!);
    if (elapsed >= _flagReloadInterval) {
      await reloadFeatureFlags();
    }
  }

  // Lista de flags conhecidas — atualizar quando adicionares novas flags
  static const _knownFlags = [
    'auth_wall_placement',
    'upload_nudge_variant',
    'recap_cta_variant',
    'rsvp_ui_variant',
    'memories_first_flow',
  ];
}
```

### 2.4 Integrar no `main.dart`

No `main.dart`, **depois** do `Supabase.initialize()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Supabase (já existente)
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // 2. PostHog Analytics (NOVO)
  await AnalyticsService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        // ... existing overrides ...
      ],
      child: const LazzoApp(),
    ),
  );
}
```

### 2.5 Instrumentar Identity (auth flow)

No provider/page onde o auth completa, adicionar:

```dart
// Depois de auth bem-sucedido (email OTP verificado)
await AnalyticsService.identify(
  supabaseUser.id,  // O UUID do Supabase user
  properties: {
    'email': supabaseUser.email,  // PostHog aceita email para user display
    'role': 'host',  // ou 'guest'
    'created_at': supabaseUser.createdAt.toIso8601String(),
  },
);

// Track o evento de auth
await AnalyticsService.track('auth_completed', properties: {
  'auth_type': 'email_passwordless',
  'is_new_user': isNewUser,
  'platform': 'ios',
});
```

No logout:

```dart
await AnalyticsService.reset();
```

### 2.6 Instrumentar Eventos Core

Exemplo para cada categoria (implementar nos respetivos providers/pages):

```dart
// --- Event Created (create_event provider) ---
await AnalyticsService.track('event_created', properties: {
  'event_id': event.id,
  'has_location': event.location != null,
  'has_datetime': event.startDatetime != null,
  'has_emoji': event.emoji != null,
  'creation_duration_seconds': stopwatch.elapsedSeconds,
  'platform': 'ios',
  'user_role': 'host',
});

// --- RSVP Submitted (rsvp provider) ---
await AnalyticsService.track('rsvp_submitted', properties: {
  'event_id': eventId,
  'vote': vote.name,  // 'going' or 'cant'
  'time_to_rsvp_seconds': timeToRsvp,
  'platform': 'ios',
  'user_role': 'guest',
});

// --- Photo Uploaded (memory/photo provider) ---
await AnalyticsService.track('photo_uploaded', properties: {
  'event_id': eventId,
  'platform': 'ios',
  'is_cover': isCover,
  'upload_duration_ms': uploadDuration.inMilliseconds,
  'file_size_kb': fileSizeBytes ~/ 1024,
});

// --- Invite Link Shared (share bottom sheet) ---
// On Copy Link button:
await AnalyticsService.track('invite_link_shared', properties: {
  'event_id': eventId,
  'share_method': 'copy_link',
  'platform': 'ios',
  'user_role': 'host',
});
// On Share (green) button:
await AnalyticsService.track('invite_link_shared', properties: {
  'event_id': eventId,
  'share_method': 'share',
  'share_content': 'card',  // ou 'qr_code'
  'platform': 'ios',
  'user_role': 'host',
});

// --- Recap Viewed (recap page) ---
await AnalyticsService.track('recap_viewed', properties: {
  'event_id': eventId,
  'viewer_role': isHost ? 'host' : 'guest',
  'photo_count': photoCount,
  'platform': 'ios',
});

// --- Memory Ready (memory provider) ---
await AnalyticsService.track('memory_ready', properties: {
  'event_id': eventId,
  'photo_count': photos.length,
  'contributor_count': uniqueUploaders.length,
  'hours_since_event_end': hoursSinceEnd,
});

// --- App Opened (app lifecycle) ---
await AnalyticsService.track('app_opened', properties: {
  'source': 'organic',  // ou 'push_notification', 'deep_link'
  'platform': 'ios',
  'app_version': packageInfo.version,
});
```

### 2.7 Instrumentar Screen Views (APENAS ecrãs críticos)

Adiciona `AnalyticsService.screenViewed()` **apenas** nestes 10 ecrãs, no `initState()` ou equivalente:

```dart
// HomePage
@override
void initState() {
  super.initState();
  AnalyticsService.screenViewed('home');
}

// EventPage
@override
void initState() {
  super.initState();
  AnalyticsService.screenViewed('event_detail', eventId: widget.eventId);
}

// EventLivingPage
AnalyticsService.screenViewed('event_living', eventId: widget.eventId);

// EventRecapPage
AnalyticsService.screenViewed('event_recap', eventId: widget.eventId);

// CreateEventPage
AnalyticsService.screenViewed('create_event');

// MemoryViewerPage
AnalyticsService.screenViewed('memory_viewer', eventId: widget.eventId);

// MemoryReadyPage
AnalyticsService.screenViewed('memory_ready', eventId: widget.eventId);

// ProfilePage
AnalyticsService.screenViewed('profile');

// InboxPage
AnalyticsService.screenViewed('inbox');
```

**NÃO** adicionar screen_viewed em: settings, edit profile, OTP, photo preview, share memory, bottom sheets, dialogs, etc.

### 2.8 Usar Feature Flags

```dart
// Ler flag (síncrono, do cache local — seguro no build)
final showMemoryFirst = AnalyticsService.isFeatureEnabled('memories_first_flow');
final nudgeVariant = AnalyticsService.getFeatureFlagValue('upload_nudge_variant');

// No widget:
if (showMemoryFirst) {
  // Mostrar "Add to memory" primeiro
} else {
  // Mostrar RSVP primeiro (default)
}

// Mostrar nudge variant:
switch (nudgeVariant) {
  case 'urgency':
    return 'Últimas horas para adicionar fotos!';
  case 'social_proof':
    return '${uploadCount} amigos já adicionaram fotos';
  default:
    return 'Adiciona as tuas fotos ao memory';
}
```

### 2.9 Timer de Reload de Flags (30 min)

No `LazzoApp` ou `MainLayout`, adiciona um timer periódico:

```dart
class _MainLayoutState extends State<MainLayout> with WidgetsBindingObserver {
  Timer? _flagReloadTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _flagReloadTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => AnalyticsService.reloadFlagsIfNeeded(),
    );
  }

  @override
  void dispose() {
    _flagReloadTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App voltou ao foreground — reload flags
      AnalyticsService.reloadFlagsIfNeeded();
      AnalyticsService.track('app_opened', properties: {
        'source': 'organic',
        'platform': 'ios',
      });
    }
  }
}
```

### 2.10 Verificar integração

1. Corre a app em debug
2. Vai ao PostHog → **Live Events** (no dashboard)
3. Abre a app, navega para Home → deve aparecer `screen_viewed` com `screen_name: home`
4. Cria um evento → deve aparecer `event_created`
5. Abre um evento → deve aparecer `screen_viewed` com `screen_name: event_detail`
6. Verifica que **NÃO** aparecem eventos ao navegar para settings, edit profile, etc.

---

## Parte 3 — Integração Web (Vercel)

### 3.1 Adicionar PostHog JS SDK

No projeto web (Vercel), adiciona o snippet PostHog. Dependendo do framework:

**Se Next.js / React:**

```bash
npm install posthog-js
```

Cria um ficheiro de inicialização:

```typescript
// lib/posthog.ts
import posthog from 'posthog-js';

export function initPostHog() {
  if (typeof window === 'undefined') return;
  
  posthog.init('phc_YOUR_API_KEY', {
    api_host: 'https://eu.i.posthog.com',
    
    // COST OPTIMIZATION — crítico
    autocapture: false,            // Não queremos autocapture
    disable_session_recording: true, // Session replay OFF
    capture_pageview: false,        // Vamos controlar manualmente
    capture_pageleave: false,       // Não necessário
    
    // Feature flags — bootstrap para instant load
    bootstrap: {
      featureFlags: {},  // Pode ser populado via server-side para instant flags
    },
    
    // Privacy
    respect_dnt: true,             // Respeitar Do Not Track
    persistence: 'localStorage',   // Para manter distinct_id entre sessões
  });
}

export { posthog };
```

**Se HTML puro / outro framework:**

```html
<script>
  !function(t,e){var o,n,p,r;e.__SV||(window.posthog=e,e._i=[],e.init=function(i,s,a){function g(t,e){var o=e.split(".");2==o.length&&(t=t[o[0]],e=o[1]),t[e]=function(){t.push([e].concat(Array.prototype.slice.call(arguments,0)))}}(p=t.createElement("script")).type="text/javascript",p.async=!0,p.src=s.api_host+"/static/array.js",(r=t.getElementsByTagName("script")[0]).parentNode.insertBefore(p,r);var u=e;for(void 0!==a?u=e[a]=[]:a="posthog",u.people=u.people||[],u.toString=function(t){var e="posthog";return"posthog"!==a&&(e+="."+a),t||(e+=" (stub)"),e},u.people.toString=function(){return u.toString(1)+".people (stub)"},o="capture identify alias people.set people.set_once set_config register register_once unregister opt_out_capturing has_opted_out_capturing opt_in_capturing reset isFeatureEnabled getFeatureFlag getFeatureFlagPayload reloadFeatureFlags group updateEarlyAccessFeatureEnrollment getEarlyAccessFeatures getActiveMatchingSurveys getSurveys onFeatureFlags".split(" "),n=0;n<o.length;n++)g(u,o[n]);e._i.push([i,s,a])},e.__SV=1)}(document,window.posthog||[]);
  
  posthog.init('phc_YOUR_API_KEY', {
    api_host: 'https://eu.i.posthog.com',
    autocapture: false,
    disable_session_recording: true,
    capture_pageview: false,
    capture_pageleave: false,
  });
</script>
```

### 3.2 Identity Unification (Web)

O fluxo de identity na web é igual ao da app:

```typescript
// 1. Guest abre link do evento — PostHog gera distinct_id anónimo
// (automático, nada a fazer)

// 2. Guest faz auth (name + email) → Supabase retorna user_id
function onGuestAuthCompleted(userId: string, eventId: string) {
  // Merge anónimo → user_id
  posthog.identify(userId, {
    role: 'guest',
  });
  
  // Track o evento
  posthog.capture('guest_auth_completed', {
    event_id: eventId,
    auth_method: 'email',
    platform: 'web',
  });
}

// 3. Logout (se aplicável)
function onLogout() {
  posthog.reset();
}
```

### 3.3 Instrumentar Guest Funnel (Web)

```typescript
// --- Invite Landing (quando guest abre o link do evento) ---
posthog.capture('invite_link_opened', {
  event_id: eventId,
  platform: 'web',
  referrer: document.referrer || 'direct',
  is_new_visitor: !posthog.get_distinct_id().startsWith('user_'),
});

// Screen view para invite landing (crítico)
posthog.capture('screen_viewed', {
  screen_name: 'invite_landing',
  event_id: eventId,
  platform: 'web',
});

// --- RSVP Submitted ---
posthog.capture('rsvp_submitted', {
  event_id: eventId,
  vote: 'going',  // ou 'cant'
  time_to_rsvp_seconds: Math.round((Date.now() - pageLoadTime) / 1000),
  platform: 'web',
  user_role: 'guest',
});

// --- Photo Uploaded ---
posthog.capture('photo_uploaded', {
  event_id: eventId,
  platform: 'web',
  is_cover: isCover,
  upload_duration_ms: uploadDuration,
  file_size_kb: Math.round(file.size / 1024),
});

// --- Memory Viewed (replaces recap_viewed) ---
posthog.capture('memory_viewed', {
  event_id: eventId,
  view_source: 'recap',
  event_phase: 'recap',
  platform: 'web',
});
```

### 3.4 Feature Flags (Web)

```typescript
// Flags são carregadas automaticamente no init e cacheadas
// Ler de forma síncrona:
const authPlacement = posthog.getFeatureFlag('auth_wall_placement');

if (authPlacement === 'after_preview') {
  // Mostrar evento primeiro, depois pedir auth
} else {
  // Auth primeiro (default)
}

// Notificar PostHog quando uma flag é usada (para experiment tracking)
posthog.onFeatureFlags(() => {
  const variant = posthog.getFeatureFlag('upload_nudge_variant');
  // Aplicar variante
});
```

### 3.5 Bot Protection (Vercel)

No `vercel.json` ou na Vercel dashboard:

```json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Robots-Tag",
          "value": "noindex, nofollow"
        }
      ]
    }
  ]
}
```

**Vercel Firewall Rules** (dashboard → Settings → Firewall):

1. **Rate limit:** Max 60 requests/min por IP nas rotas de evento
2. **Block known bots:** Block requests com user agents de crawlers (Googlebot, Bingbot, etc.) nas rotas de evento — estas não devem ser indexadas
3. **Challenge suspicious traffic:** Ativa Managed Challenge para tráfego suspeito

**PostHog-side:** O autocapture está OFF e só disparamos eventos explícitos, portanto bots que não executam JavaScript não geram eventos. Para bots que executam JS, a rate limiting no Vercel é a primeira linha de defesa.

---

## Parte 4 — Criar Feature Flags no PostHog

### 4.1 Flags a criar (Phase 1)

Vai a **PostHog → Feature Flags → New Feature Flag** e cria:

#### Flag 1: `auth_wall_placement`

- **Key:** `auth_wall_placement`
- **Type:** Multivariate
- **Variants:**
  - `before_preview` (50%) — auth antes de ver o evento
  - `after_preview` (50%) — vê o evento, auth no RSVP
- **Rollout:** 100% of users
- **Match conditions:** `platform = web` (só aplica na web)

#### Flag 2: `upload_nudge_variant`

- **Key:** `upload_nudge_variant`
- **Type:** Multivariate
- **Variants:**
  - `standard` (34%) — "Adiciona as tuas fotos"
  - `urgency` (33%) — "Últimas horas! Adiciona fotos agora"
  - `social_proof` (33%) — "X amigos já adicionaram fotos"
- **Rollout:** 100% of users

#### Flag 3: `recap_cta_variant`

- **Key:** `recap_cta_variant`
- **Type:** Multivariate
- **Variants:**
  - `share_memory` (34%) — "Partilhar Memory"
  - `send_to_friends` (33%) — "Enviar aos amigos"
  - `save_photos` (33%) — "Guardar fotos"
- **Rollout:** 100% of users

#### Flags futuras (Phase 3)

- `rsvp_ui_variant` — criar quando estiver pronto para testar variantes de RSVP
- `memories_first_flow` — criar quando o A/B test de memories-first estiver implementado

### 4.2 Testar Flags

1. Guarda as flags
2. Na app (debug): chama `AnalyticsService.reloadFeatureFlags()`
3. Lê os valores: `AnalyticsService.getFeatureFlagValue('upload_nudge_variant')`
4. Verifica no PostHog → Feature Flags → flag → "Usage" que os requests estão a chegar
5. Na web: abre a consola do browser → `posthog.getFeatureFlag('auth_wall_placement')` deve retornar um valor

---

## Parte 5 — Criar Dashboards no PostHog

> **Nota:** Dashboards são combinados (app + web). Usa o filtro global `platform` quando quiseres ver dados de uma só plataforma. Cada dashboard tem insights independentes.

---

### 5.1 Dashboard: Guest Funnel

**Objetivo:** Medir conversão do guest desde que abre o link até ver o memory.

1. Vai a **PostHog → Dashboards → New Dashboard**
2. Nome: **"Guest Funnel"**
3. Descrição: *"Conversion from invite open to memory view (web + app)"*

#### Insight 1: Core Guest Funnel (Funnel)

1. Clica **"+ New insight"** → tipo **Funnel**
2. Steps:
   - Step 1: `invite_link_opened`
   - Step 2: `rsvp_submitted`
   - Step 3: `photo_uploaded`
   - Step 4: `memory_viewed`
3. **Conversion window:** 7 days
4. **Breakdown:** `event_id` (para comparar eventos entre si)
5. **Chart type:** Steps (bar chart)
6. Guarda com nome: *"Core Guest Funnel"*

> **Pergunta-chave:** Onde é que os guests estão a desistir? Se o drop-off maior é entre step 1 e 2, o problema é o flow de RSVP/auth. Se é entre 2 e 3, precisamos de melhor nudging para uploads.

#### Insight 2: Auth Drop-off Sub-Funnel (Funnel)

1. Novo insight → **Funnel**
2. Steps:
   - Step 1: `rsvp_intent_started`
   - Step 2: `auth_started`
   - Step 3: `guest_auth_completed`
   - Step 4: `rsvp_submitted`
3. **Conversion window:** 30 minutes (auth flow deve ser rápido)
4. **Filter:** `platform = web` (estes eventos são web-only)
5. **Chart type:** Steps (bar chart)
6. Guarda com nome: *"Auth Drop-off (Web)"*

> **Pergunta-chave:** Quantos guests carregam no botão de voto mas NÃO completam o OTP? Se `rsvp_intent_started` → `auth_started` tem grande drop, o formulário de credentials é o problema. Se `auth_started` → `guest_auth_completed` é a queda, o OTP é a fricção.

#### Insight 3: Time to RSVP (Trends)

1. Novo insight → **Trends**
2. Evento: `rsvp_submitted`
3. **Aggregation:** Property average → `time_to_rsvp_seconds`
4. **Display:** Line chart, por dia
5. Guarda com nome: *"Time to RSVP (avg seconds)"*

> **Target:** < 60 segundos. Se sobe, algo no flow está a atrasar.

#### Insight 4: Guest Activation Rate (Trends — Formula)

1. Novo insight → **Trends**
2. Série A: `rsvp_submitted` — count unique users
3. Série B: `invite_link_opened` — count unique users
4. **Formula:** `A / B` (ativa formulas no canto superior)
5. **Display:** Line chart, por semana
6. Guarda com nome: *"Guest Activation Rate"*

> **Target:** ≥ 50%. Se descer, o funnel está a perder guests antes do RSVP.

---

### 5.2 Dashboard: Host Loop

**Objetivo:** Medir engagement dos hosts e repeat behavior.

1. **PostHog → Dashboards → New Dashboard**
2. Nome: **"Host Loop"**
3. Descrição: *"Host engagement: create → share → repeat"*

#### Insight 1: Host Loop Funnel (Funnel)

1. Novo insight → **Funnel**
2. Steps:
   - Step 1: `event_created`
   - Step 2: `invite_link_shared`
   - Step 3: `memory_viewed` (host a ver o memory do seu evento)
3. **Conversion window:** 14 days
4. **Filter:** `platform = ios` (hosts usam a app)
5. **Chart type:** Steps
6. Guarda com nome: *"Host Loop"*

> **Pergunta-chave:** Os hosts estão a partilhar o invite depois de criar? Se drop entre step 1→2 é alto, o share UX precisa de trabalho.

#### Insight 2: Repeat Hosts (Trends)

1. Novo insight → **Trends**
2. Evento: `event_created`
3. **Aggregation:** Unique users
4. **Display:** Line chart, por semana
5. Guarda com nome: *"Weekly Active Hosts (unique)"*

> Compara com total de hosts para inferir repeat rate.

#### Insight 3: Host Retention (Retention)

1. Novo insight → **Retention**
2. **Cohort event (start):** `event_created`
3. **Return event:** `event_created`
4. **Period:** Week
5. Guarda com nome: *"Host Retention (create → create)"*

> **Pergunta-chave:** Os hosts voltam para criar mais eventos? Este é o **PMF signal** mais forte.

---

### 5.3 Dashboard: Memory Health

**Objetivo:** Monitorar a qualidade e engagement com memories.

1. **PostHog → Dashboards → New Dashboard**
2. Nome: **"Memory Health"**
3. Descrição: *"Memory creation, engagement, and sharing metrics"*

#### Insight 1: Memory Creation (Trends)

1. Novo insight → **Trends**
2. Série A: `memory_ready` — count
3. Série B: `photo_uploaded` — count
4. **Display:** Line chart, por semana
5. Guarda com nome: *"Memories Created & Photos Uploaded"*

#### Insight 2: Photos per Memory (Trends)

1. Novo insight → **Trends**
2. Evento: `memory_ready`
3. **Aggregation:** Property average → `photo_count`
4. Segundo: `memory_ready` → Property average → `contributor_count`
5. **Display:** Line chart
6. Guarda com nome: *"Avg Photos & Contributors per Memory"*

> **Target:** ≥ 5 fotos, ≥ 2 contributors por memory.

#### Insight 3: Memory View Rate (Trends — Formula)

1. Novo insight → **Trends**
2. Série A: `memory_viewed` — count unique `event_id`
3. Série B: `memory_ready` — count
4. **Formula:** `A / B`
5. Guarda com nome: *"Memory View Rate"*

> **Target:** ≥ 40% dos memories com pelo menos 1 view.

#### Insight 4: Share Card Funnel (Funnel — app only)

1. Novo insight → **Funnel**
2. Steps:
   - Step 1: `share_card_viewed`
   - Step 2: `share_card_shared`
3. **Conversion window:** 24 hours
4. **Filter:** `platform = ios`
5. Guarda com nome: *"Share Card Conversion (App)"*

> **Pergunta-chave:** Dos que vêem o share card, quantos partilham? Se baixo, o design do card precisa de iteração.

---

### 5.4 Dashboard: Stability

**Objetivo:** Monitorar erros e reliability.

1. **PostHog → Dashboards → New Dashboard**
2. Nome: **"Stability"**
3. Descrição: *"Errors, failures, and app health"*

#### Insight 1: Exceptions by Platform (Trends)

1. Novo insight → **Trends**
2. Evento: `$exception`
3. **Breakdown:** `platform`
4. **Display:** Line chart, por dia
5. Guarda com nome: *"Exceptions by Platform"*

#### Insight 2: Photo Upload Failures (Trends) - To Implement

1. Novo insight → **Trends**
2. Evento: `photo_upload_failed`
3. **Breakdown:** `error_type`
4. **Display:** Stacked bar, por dia
5. Guarda com nome: *"Upload Failures by Error Type"*

#### Insight 3: Upload Failure Rate (Trends — Formula) - To Implement

1. Novo insight → **Trends**
2. Série A: `photo_upload_failed` — count
3. Série B: `photo_upload_started` — count
4. **Formula:** `A / B`
5. Guarda com nome: *"Upload Failure Rate"*

> **Target:** < 5%.

#### Insight 4: App Retention (Retention)

1. Novo insight → **Retention**
2. **Cohort event:** `app_opened`
3. **Return event:** `app_opened`
4. **Period:** Week
5. Guarda com nome: *"App Retention (open → open)"*

---

## Parte 6 — Criar Cohorts

Vai a **PostHog → Persons & Groups → Cohorts → New Cohort**:

| # | Nome | Definição | Para quê |
|---|------|-----------|----------|
| 1 | **Active Hosts** | Performed `event_created` in last 30 days | Retention — filtrar dashboards por hosts ativos |
| 2 | **Activated Guests** | Performed `rsvp_submitted` in last 30 days | Guest engagement — validar if guests are converting |
| 3 | **Memory Contributors** | Performed `photo_uploaded` in last 30 days | Upload behavior — quem contribui para memories |
| 4 | **Repeat Hosts** | Performed `event_created` ≥ 2 times ever | **PMF signal** — o indicador mais forte de product-market fit |
| 5 | **Web-only Guests** | All events have `platform = web` | Web experience health — comparar com app guests |
| 6 | **Auth Dropouts** | Performed `rsvp_intent_started` but NOT `rsvp_submitted` in last 30 days | Friction — guests que quiseram votar mas desistiram no auth |
| 7 | **Cohort #1 Hosts** | Manual list — add user emails/IDs | Phase 2 beta testers |
| 8 | **Cohort #2 Hosts** | Manual list — add user emails/IDs | Phase 3 beta testers |

**Criação passo-a-passo (exemplo para "Auth Dropouts"):**
1. PostHog → Persons & Groups → Cohorts → **New Cohort**
2. Nome: `Auth Dropouts`
3. Matching criteria:
   - **Include users who:** Performed `rsvp_intent_started` in the last 30 days
   - **Exclude users who:** Performed `rsvp_submitted` in the last 30 days
4. Guardar

> Usa estes cohorts como filtros nos dashboards para segmentar análises.

---

## Parte 7 — Verificação Final (Checklist)

### Pre-flight (antes do primeiro cohort)

**PostHog Account:**
- [X] Conta Cloud EU criada (eu.posthog.com)
- [X] Projeto "Lazzo" criado
- [X] API key anotado
- [X] Session Replay OFF
- [X] Autocapture OFF
- [X] Exception Autocapture ON

**App (Flutter/iOS):**
- [X] `posthog_flutter` adicionado ao `pubspec.yaml`
- [X] `Info.plist` configurado (API key + host + captureScreenViews: false)
- [X] `AnalyticsService` criado e funcional (`lib/services/analytics_service.dart`)
- [X] `AnalyticsService.initialize()` no `main.dart` (após Supabase init)
- [X] Identity: `identify()` chamado no auth complete (login + signup OTP)
- [X] Identity: `reset()` chamado no logout (`settings_providers.dart`)
- [X] `app_opened` dispara na abertura (cold start + resume em `app.dart`)
- [X] `screen_viewed` dispara APENAS nos ecrãs críticos (home, event_detail, event_living, event_recap, create_event, inbox, memory_ready, memory_viewer, profile, calendar via tab switch, manage_guests)
- [X] Eventos de funnel instrumentados (event_created, rsvp_submitted, photo_uploaded, invite_link_shared via share bottom sheet copy_link/share, memory_viewed + memory_ready)
- [X] Feature flags: cache implementado, reload em app open + auth + 30 min timer (`app.dart`)
- [X] Testado em debug: eventos visíveis no PostHog Live Events
- [ ] `debug: false` no Info.plist antes de build para TestFlight

**Web (Vercel):**
- [X] PostHog JS SDK adicionado (`posthog-js` via npm)
- [X] Config: `autocapture: false`, `disable_session_recording: true` (`lib/analytics.ts`)
- [X] Identity: `posthog.identify(userId)` no guest auth (RsvpSection, PhotoUploadSheet, RecapAuthGate)
- [X] Identity: anonymous distinct_id gerado automaticamente (não setado manualmente)
- [X] Guest funnel events instrumentados (invite_link_opened → auth_started → guest_auth_completed → rsvp_submitted → photo_uploaded → memory_viewed)
- [ ] Vercel WAF / rate limiting ativo
- [X] `X-Robots-Tag: noindex` nas páginas de evento (`vercel.json`)
- [ ] Testado: eventos visíveis no PostHog Live Events

**Dashboards:**
- [ ] Guest Funnel dashboard criado (4 insights: core funnel, auth sub-funnel, time to RSVP, activation rate)
- [ ] Host Loop dashboard criado (3 insights: host funnel, weekly active hosts, host retention)
- [ ] Memory Health dashboard criado (4 insights: creation trends, photos/contributors avg, view rate, share card funnel)
- [ ] Stability dashboard criado (4 insights: exceptions, upload failures, failure rate, app retention)

**Cohorts:**
- [ ] Active Hosts, Activated Guests, Memory Contributors, Repeat Hosts, Web-only Guests, Auth Dropouts criados
- [ ] Cohort #1/#2 Hosts com manual list

**Feature Flags:**
- [_] `auth_wall_placement` criada
- [X] `upload_nudge_variant` criada
- [-] `recap_cta_variant` criada
- [ ] Flags testadas em ambas as plataformas
- [ ] Valores default definidos (fallback se flag não resolve)

**Cross-Platform:**
- [X] Mesmo `user_id` usado em app + web (Supabase UUID via `identifyUser()`)
- [X] Mesmo nome de eventos em app + web (taxonomia partilhada)
- [ ] Identity merge testado: user visto como 1 pessoa no PostHog (não 2)

---

## Parte 8 — Troubleshooting

### "Não vejo eventos no PostHog"

1. Verifica se o API key está correto
2. Verifica se o host é `https://eu.i.posthog.com` (não `https://app.posthog.com`)
3. Na app: verifica `debug: true` no Info.plist e procura logs PostHog na consola Xcode
4. Na web: abre Dev Tools → Network → procura requests para `eu.i.posthog.com`
5. Espera 1-2 minutos — há um buffer de envio

### "Vejo 2 pessoas em vez de 1 para o mesmo user"

1. Confirma que `posthog.identify(supabase_user_id)` é chamado **depois** do auth
2. Confirma que o `user_id` é idêntico em app e web (mesmo UUID do Supabase)
3. Não chames `posthog.reset()` sem necessidade (só no logout)
4. Vai a PostHog → Persons → procura o user → verifica se tem aliases

### "Feature flags retornam undefined/null"

1. Verifica se as flags estão criadas no PostHog dashboard
2. Verifica se o rollout está a 100%
3. Chama `reloadFeatureFlags()` e espera que complete
4. Na web: `posthog.onFeatureFlags(() => { console.log(posthog.getFeatureFlag('key')); })`
5. Verifica match conditions (e.g., `platform = web` pode filtrar a app)

### "Custos estão a subir"

1. Verifica PostHog → Settings → Billing → Usage
2. Identifica qual evento tem mais volume
3. Suspeitas de bots: verifica se `autocapture` está realmente OFF
4. Procura user agents suspeitos nos Persons
5. Ativa rate limiting no Vercel se ainda não fizeste

### "Events duplicados"

1. Verifica se o `track()` não está a ser chamado no `build()` de um widget (que reconstrui em cada frame)
2. `screen_viewed` só deve ser chamado em `initState()`, não em `build()`
3. Na web: verifica se o PostHog init não está a correr duas vezes (e.g., em server + client no Next.js)
