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

// --- Invite Link Shared (event page) ---
await AnalyticsService.track('invite_link_shared', properties: {
  'event_id': eventId,
  'share_channel': 'whatsapp',  // ou 'imessage', 'copy', 'qr'
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

**NÃO** adicionar screen_viewed em: settings, edit profile, OTP, photo preview, manage guests, share memory, bottom sheets, dialogs, etc.

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

// --- Recap Viewed ---
posthog.capture('recap_viewed', {
  event_id: eventId,
  viewer_role: 'guest',
  photo_count: photos.length,
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

### 5.1 Dashboard: Guest Funnel

1. Vai a **PostHog → Dashboards → New Dashboard**
2. Nome: **"Guest Funnel"**
3. Adiciona um **Funnel Insight**:
   - Step 1: `invite_link_opened`
   - Step 2: `guest_auth_completed`
   - Step 3: `rsvp_submitted`
   - Step 4: `photo_uploaded`
   - Step 5: `recap_viewed`
4. **Filters:** `platform = web`
5. **Breakdown:** by `event_id` (para ver por evento)
6. **Conversion window:** 7 days (eventos duram ~24h mas recap pode ser dias depois)

### 5.2 Dashboard: Host Loop

1. Novo dashboard: **"Host Loop"**
2. **Funnel Insight:**
   - Step 1: `event_created`
   - Step 2: `invite_link_shared`
   - Step 3: `event_participation_viewed`
   - Step 4: `recap_shared`
3. **Trends Insight:** `event_created` grouped by unique users (ver repeat hosts)
4. **Filters:** `user_role = host`

### 5.3 Dashboard: Memory Health

1. Novo dashboard: **"Memory Health"**
2. **Trends:**
   - `memory_ready` count over time
   - `photo_uploaded` count over time (avg per event usando breakdown by `event_id`)
3. **Table Insight:**
   - `memory_ready` com properties: `photo_count`, `contributor_count`, `hours_since_event_end`
4. **Ratio:**
   - `recap_viewed` (where `viewer_role = guest`) / `memory_ready` = recap view rate

### 5.4 Dashboard: Stability

1. Novo dashboard: **"Stability"**
2. **Trends:**
   - `$exception` count (PostHog automatic exception events) by `platform`
   - `photo_upload_failed` count and breakdown by `error_type`
3. **Retention:** users returning after first `app_opened`

### 5.5 Weekly Email Digest

1. Vai a **PostHog → Dashboards → Guest Funnel**
2. Clica **"Subscribe"** → email → Weekly (Monday)
3. Repete para os outros dashboards
4. Agora recebes um email de segunda-feira com os dados da semana anterior

---

## Parte 6 — Criar Cohorts

Vai a **PostHog → Persons & Groups → Cohorts → New Cohort**:

| Nome | Definição | Notas |
|------|-----------|-------|
| **Active Hosts** | Performed `event_created` in last 30 days | Retention |
| **Activated Guests** | Performed `rsvp_submitted` in last 30 days | Guest engagement |
| **Memory Contributors** | Performed `photo_uploaded` in last 30 days | Upload behavior |
| **Repeat Hosts** | Performed `event_created` ≥ 2 times ever | PMF signal |
| **Cohort #1 Hosts** | Manual list — add user emails/IDs | Phase 2 testers |
| **Cohort #2 Hosts** | Manual list — add user emails/IDs | Phase 3 testers |
| **Web-only Guests** | All events have `platform = web` | Web experience |

---

## Parte 7 — Verificação Final (Checklist)

### Pre-flight (antes do primeiro cohort)

**PostHog Account:**
- [ ] Conta Cloud EU criada (eu.posthog.com)
- [ ] Projeto "Lazzo" criado
- [ ] API key anotado
- [ ] Session Replay OFF
- [ ] Autocapture OFF
- [ ] Exception Autocapture ON

**App (Flutter/iOS):**
- [ ] `posthog_flutter` adicionado ao `pubspec.yaml`
- [ ] `Info.plist` configurado (API key + host + captureScreenViews: false)
- [ ] `AnalyticsService` criado e funcional
- [ ] `AnalyticsService.initialize()` no `main.dart` (após Supabase init)
- [ ] Identity: `identify()` chamado no auth complete
- [ ] Identity: `reset()` chamado no logout
- [ ] `app_opened` dispara na abertura
- [ ] `screen_viewed` dispara APENAS nos 10 ecrãs críticos
- [ ] Eventos de funnel instrumentados (event_created, rsvp_submitted, photo_uploaded, etc.)
- [ ] Feature flags: cache implementado, reload em app open + auth + 30 min
- [ ] Testado em debug: eventos visíveis no PostHog Live Events
- [ ] `debug: false` no Info.plist antes de build para TestFlight

**Web (Vercel):**
- [ ] PostHog JS SDK adicionado
- [ ] Config: `autocapture: false`, `disable_session_recording: true`
- [ ] Identity: `posthog.identify(userId)` no guest auth
- [ ] Identity: anonymous distinct_id gerado automaticamente (não setado manualmente)
- [ ] Guest funnel events instrumentados (invite_link_opened → guest_auth_completed → rsvp_submitted → photo_uploaded → recap_viewed)
- [ ] Vercel WAF / rate limiting ativo
- [ ] `X-Robots-Tag: noindex` nas páginas de evento
- [ ] Testado: eventos visíveis no PostHog Live Events

**Dashboards:**
- [ ] Guest Funnel dashboard criado
- [ ] Host Loop dashboard criado
- [ ] Memory Health dashboard criado
- [ ] Stability dashboard criado
- [ ] Weekly email digest configurado

**Feature Flags:**
- [ ] `auth_wall_placement` criada
- [ ] `upload_nudge_variant` criada
- [ ] `recap_cta_variant` criada
- [ ] Flags testadas em ambas as plataformas
- [ ] Valores default definidos (fallback se flag não resolve)

**Cross-Platform:**
- [ ] Mesmo `user_id` usado em app + web
- [ ] Mesmo nome de eventos em app + web
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
