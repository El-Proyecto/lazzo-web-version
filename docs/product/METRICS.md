# Lazzo — Metrics Plan (Post-Beta)

**Tool:** PostHog Cloud EU
**Platforms:** iOS app (via `posthog_flutter`) + Web (via PostHog JS SDK)
**Last updated:** Feb 27, 2026

---

## 1) Event Taxonomy

All events use a shared taxonomy across app and web. PostHog unifies sessions via `distinct_id`.

### Identity Unification (alias/identify)

PostHog generates an anonymous `distinct_id` on first load (app or web). When the user authenticates, we call `identify()` to merge the anonymous session with the real `user_id`.

**Flow:**
1. **First touch (anonymous):** PostHog auto-assigns a random `distinct_id`. All pre-auth events (`invite_link_opened`, `app_opened`) are tracked under this anonymous ID.
2. **Auth completes:** Call `posthog.identify(supabase_user_id)` — PostHog creates an alias from anonymous → `user_id` and merges all prior events.
3. **Subsequent sessions:** `distinct_id` is already the `user_id`, no further aliasing needed.

**Cross-platform:** If a guest uses web first (anonymous → auth → `user_id`) and later installs the app, both platforms call `identify()` with the same Supabase `user_id`. PostHog merges automatically.

**Critical rules:**
- Never manually set `distinct_id` before auth — let PostHog generate it
- Always call `identify(supabase_user_id)` on `auth_completed` / `guest_auth_completed`
- On logout, call `posthog.reset()` to clear the `distinct_id` (generates a new anonymous one)

### Global Properties (on every event)

| Property | Type | Description |
|----------|------|-------------|
| `event_id` | string (UUID) | The Lazzo event being interacted with (null for app-level events) |
| `user_id` | string (UUID) | Authenticated user ID |
| `platform` | string | `ios` or `web` |
| `user_role` | string | `host` or `guest` |
| `event_phase` | string | `pending`, `confirmed`, `living`, `recap`, `ended`, `expired` (null for non-event screens) |
| `app_version` | string | App build version (e.g., `1.0.1+2`) |

---

### Core Events

#### App Lifecycle

| Event | When | Extra Properties |
|-------|------|-----------------|
| `app_opened` | App launch or web page load | `source`: organic / push_notification / deep_link |

> **Removed:** `session_started` — PostHog tracks sessions natively. No need for a custom event.

> **Removed:** generic `screen_viewed` on every navigation — fires too often, inflates event volume and costs (especially with feature flag evaluations per event). Use only the critical screen events below.

#### Critical Screen Views (selective, not on every navigation)

Only fire `screen_viewed` for screens that represent **meaningful funnel steps or decision points**. Do NOT fire on transient screens, modals, bottom sheets, or animation transitions.

| `screen_name` value | When | Why it matters | Checked |
|---------------------|------|----------------|--|
| `event_detail` | User opens an event | Event interest signal | X |
| `event_living` | User enters live event view | Live participation | X |
| `event_recap` | User views recap page | Memory engagement | X |
| `create_event` | User opens event creation | Host intent | X |
| `memory_viewer` | User opens full memory | Memory depth | X |
| `memory_ready` | User sees Memory Ready page | Completion signal |  |
| `invite_landing` | Guest lands on invite page (web) | Top of guest funnel |  |
| `calendar` | User interacts with calendar (selects day, changes view mode) | Calendar engagement — tracked on interaction only, NOT on navigation | X |
| `actions` | User opens Actions tab in Inbox | Host action engagement | X |
| `manage_guests` | User views the guests list / manage guests screen | Guest management engagement — track `event_phase` and `user_role` (host/guest) | X

Properties: `screen_name`, `platform`, `event_id` (if applicable)

#### Authentication

| Event | When | Extra Properties | Checked |
|-------|------|-----------------|--|
| `auth_started` | User taps Continue after filling create account / login fields (arrives at OTP verification page) | `auth_type`: email_passwordless / guest_lightweight |
| `auth_completed` | Successfully authenticated | `auth_type`, `is_new_user`: bool | X |
| `guest_auth_completed` | Web guest completes lightweight auth | `event_id`, `auth_method`: email |
| `profile_details_changed` | User edits profile details (name, avatar, etc.) after account creation | `fields_changed`: string[] |

#### Event Creation (Host — app only)

| Event | When | Extra Properties | Checked |
|-------|------|-----------------|---|
| `event_created` | Host submits new event | `has_location`: bool, `has_datetime`: bool, `has_emoji`: bool, `creation_duration_seconds`: int | X |
| `event_edited` | Host edits existing event | `fields_changed`: string[] | X |
| `event_phase_changed` | Event transitions phase | `from_phase`, `to_phase`, `trigger`: `manual` / `auto` (client) / `auto_server` (edge fn) | X |

#### Invite & Share

| Event | When | Extra Properties | Checked
|-------|------|-----------------|--|
| `invite_link_shared` | User taps Share (green button) or Copy Link in the share bottom sheet | `share_method`: `copy_link` / `share`, `share_content`: `card` / `qr_code` (only when method=share) | X |
| `invite_link_opened` | Someone opens an invite link | `referrer`: string (if available), `is_new_visitor`: bool |

> **Removed:** `qr_code_scanned` — impossible to detect QR code scanning vs link opening on the receiver side. What matters is tracking *what the host shared* (card vs QR code), which is now captured in `invite_link_shared.share_content`.

#### RSVP

| Event | When | Extra Properties | Checked |
|-------|------|-----------------|--|
| `rsvp_submitted` | Guest submits RSVP | `vote`: going / cant, `time_to_rsvp_seconds`: int (from invite open) | X |
| `rsvp_changed` | Guest changes RSVP | `from_vote`, `to_vote` | X |

#### Photo Upload

| Event | When | Extra Properties | Checked |
|-------|------|-----------------|--|
| `photo_upload_started` | Camera or gallery picker opens (any entry point: bottom sheet add_photo, nav_bar button, etc.) | `source`: camera / gallery | X |
| `photo_uploaded` | Photo successfully uploaded | `upload_duration_ms`: int, `file_size_kb`: int, `is_cover`: bool | X |
| `photo_upload_failed` | Upload fails | `error_type`: string, `retry_count`: int | X |
| `photo_cover_selected` | User marks a photo as cover | - | X |

#### Memory & Recap

| Event | When | Extra Properties |
|-------|------|-----------------|
| `memory_ready` | Memory compilation complete | `photo_count`: int, `contributor_count`: int, `hours_since_event_end`: float |
| `recap_viewed` | User views the recap/memory | `viewer_role`: host / guest, `photo_count`: int |
| `recap_shared` | User shares recap externally | `share_channel`: string |
| `share_card_generated` | Share card created | `format`: story_9_16 / post_1_1 |
| `memory_viewer_opened` | Full-screen memory viewer | `photo_index`: int |

#### Host Actions

| Event | When | Extra Properties | Checked |
|-------|------|-----------------|--|
| `event_ended_manually` | Host ends event or recap early via Manage Event | `event_status`: `living` / `recap` (which phase was ended), `hours_before_auto_end`: float | X
| `event_extended` | Host extends event time via Manage Event Time (during living phase) | `extension_minutes`: int | X |

> **Deferred to post-beta:** `host_nudge_sent`, `event_participation_viewed` — not available in current beta build.

#### Engagement

| Event | When | Extra Properties |
|-------|------|-----------------|
| `notification_tapped` | User taps push notification to open app | `notification_type`: string, `time_to_tap_seconds`: int |

> **Removed:** `notification_received` — tracked server-side by push notification service (APNS delivery receipts). No need to fire a client-side PostHog event for every received push.

#### Referral (Phase 4+)

| Event | When | Extra Properties |
|-------|------|-----------------|
| `referral_link_created` | Host creates referral link | — |
| `referral_link_opened` | Someone opens referral link | `referrer_id`: string |
| `referral_converted` | Referred user creates first event | `referrer_id`: string |

#### Landing Page (Phase 4+)

| Event | When | Extra Properties |
|-------|------|-----------------|
| `landing_page_viewed` | Landing page loads | `utm_source`, `utm_medium`, `utm_campaign` |
| `testflight_cta_clicked` | User clicks TestFlight CTA | `cta_location`: hero / footer / faq |

---

## 2) Feature Flags

All managed via PostHog Feature Flags.

| Flag Key | Type | Variants | Purpose | Phase |
|----------|------|----------|---------|-------|
| `auth_wall_placement` | multivariate | `before_preview`, `after_preview` | When to require auth on web | 1 |
| `upload_nudge_variant` | multivariate | `standard`, `urgency`, `social_proof` | Upload prompt copy | 1 |
| `recap_cta_variant` | multivariate | `share_memory`, `send_to_friends`, `save_photos` | Recap sharing CTA | 1 |
| `rsvp_ui_variant` | multivariate | `buttons`, `swipe`, `single_tap` | RSVP interaction style | 3 |
| `memories_first_flow` | multivariate | `rsvp_first`, `memory_first` | CTA hierarchy on web | 3 |

**Evaluation & Cost Optimization:**

- Flags are evaluated on `distinct_id` (user-level) for consistency
- **Local evaluation (cache):** use `posthog_flutter`'s `reloadFeatureFlags()` on app start and after auth — flags are cached locally and evaluated without network calls on each check
- **Web:** PostHog JS SDK caches flags after initial load by default (`bootstrap` option for instant flags on page load)
- **Never call `getFeatureFlag()` inside `build()` methods or on every render** — cache result in a provider/state and read from there
- **Reload schedule:** reload flags on: app open, auth complete, every 30 min in background (not on every screen transition)
- At beta scale (~50 users), flag evaluation costs are negligible, but building good habits now prevents surprises at scale

---

## 3) Dashboards

### Dashboard 1: Guest Funnel

**Purpose:** Track conversion from invite open to recap view.

```
invite_link_opened → guest_auth_completed → rsvp_submitted → photo_uploaded → recap_viewed
```

**Filters:** by `event_id`, by `platform`, by date range
**Key insight:** Where are guests dropping off?

### Dashboard 2: Host Loop

**Purpose:** Track host engagement and repeat behavior.

```
event_created → invite_link_shared → recap_shared → event_created (repeat)
```

**Filters:** by host, by cohort week
**Key insight:** Are hosts coming back to create more events?

### Dashboard 3: Memory Health

**Purpose:** Track memory completion rate.

**Metrics:**
- % events reaching `memory_ready`
- Avg photos per memory
- Avg contributors per memory
- Time from event end to `memory_ready`
- % memories with ≥1 `recap_viewed` by a guest

### Dashboard 4: Acquisition (Phase 4+)

**Landing page:**
- `landing_page_viewed` → `testflight_cta_clicked` (conversion rate)
- Traffic sources (UTM breakdown)

**Referral loop:**
- `referral_link_created` → `referral_link_opened` → `referral_converted` (funnel)

### Dashboard 5: Stability

**Metrics:**
- Error rate by platform
- Crash-free session rate (PostHog native)
- `photo_upload_failed` rate and error types
- App open → first interaction latency

---

## 4) Key Metrics — Weekly Review

During active cohort testing (Phases 2–4), review these weekly:

| Metric | Definition | Target | Priority |
|--------|-----------|--------|----------|
| **Completed memories** | Events with `memory_ready` + `recap_viewed` by ≥1 guest | North Star | P0 |
| **Guest activation rate** | `rsvp_submitted` / `invite_link_opened` | ≥ 50% | P0 |
| **Memory creation rate** | `memory_ready` / `event_created` | ≥ 60–70% | P0 |
| **Time to RSVP** | Median seconds from `invite_link_opened` to `rsvp_submitted` | < 60s | P0 |
| **Upload rate** | Events with ≥1 `photo_uploaded` / total events | ≥ 60% | P0 |
| **Recap view rate** | Events with ≥1 `recap_viewed` / `memory_ready` events | ≥ 40% | P1 |
| **Host repeat rate** | Hosts with ≥2 `event_created` within 14 days | ≥ 25–30% | P1 |
| **Share rate** | `recap_shared` or `share_card_generated` / `memory_ready` | Track baseline | P1 |
| **Crash-free sessions** | Sessions without unhandled exceptions | ≥ 99% | P0 |
| **Upload failure rate** | `photo_upload_failed` / `photo_upload_started` (camera/gallery opens) | < 5% | P1 |

---

## 5) Cohort Definitions (PostHog)

| Cohort | Definition | Purpose |
|--------|-----------|---------|
| **Active hosts** | Users with `event_created` in last 30 days | Retention tracking |
| **Activated guests** | Users with `rsvp_submitted` in last 30 days | Guest engagement |
| **Memory contributors** | Users with `photo_uploaded` in last 30 days | Upload behavior |
| **Repeat hosts** | Users with ≥2 `event_created` ever | Product-market fit signal |
| **Cohort #1 hosts** | Manual list (Phase 2 beta testers) | Cohort comparison |
| **Cohort #2 hosts** | Manual list (Phase 3 beta testers) | Cohort comparison |
| **Web-only guests** | Users where all sessions have `platform = web` | Web experience health |

---

## 6) PostHog Setup Checklist

### Account & Project
- [ ] Create PostHog Cloud EU account (eu.posthog.com)
- [ ] Create project: "Lazzo"
- [ ] Note API key + project ID
- [ ] Verify data residency is EU

### App Integration (iOS)
- [ ] Add `posthog_flutter` to `pubspec.yaml`
- [ ] Create `lib/services/analytics_service.dart`
- [ ] Initialize PostHog in `main.dart` (after Supabase init)
- [ ] Let PostHog generate anonymous `distinct_id` on first launch (do NOT set manually)
- [ ] On `auth_completed`: call `posthog.identify(supabase_user_id)` to merge anonymous → user
- [ ] Implement `identify()` with user properties (`role`, `created_at`)
- [ ] On logout: call `posthog.reset()` to clear identity
- [ ] Instrument core events (funnel + host actions only, NOT generic screen_viewed)
- [ ] Instrument selective `screen_viewed` for 10 critical screens only
- [ ] Implement feature flag cache: `reloadFeatureFlags()` on app open + auth + every 30 min
- [ ] Never call `getFeatureFlag()` in `build()` — cache in provider state
- [ ] Test in debug mode (verify events in PostHog live view)

### Web Integration
- [ ] Add PostHog JS snippet to Vercel project
- [ ] Configure same project/API key
- [ ] Set `autocapture: false`, `disable_session_recording: true` in PostHog config
- [ ] Let PostHog generate anonymous `distinct_id` (do NOT set manually)
- [ ] On `guest_auth_completed`: call `posthog.identify(supabase_user_id)` to merge
- [ ] Instrument guest funnel events (same names as app)
- [ ] Implement feature flag bootstrap (instant flags on page load from cache)
- [ ] Enable Vercel WAF / rate limiting for bot protection
- [ ] Test cross-platform identity merge (same user on app + web)

### Dashboards
- [ ] Create Guest Funnel dashboard
- [ ] Create Host Loop dashboard
- [ ] Create Memory Health dashboard
- [ ] Create Stability dashboard
- [ ] Set up weekly email digest (PostHog subscriptions)

### Feature Flags
- [ ] Create `auth_wall_placement` flag
- [ ] Create `upload_nudge_variant` flag
- [ ] Create `recap_cta_variant` flag
- [ ] Test flag evaluation on both platforms
- [ ] Document flag values and expected behavior

---

## 7) Implementation Notes

### `AnalyticsService` Architecture (app)

```dart
// lib/services/analytics_service.dart
// Follows the services/ pattern — no domain layer dependency.
// Called from presentation layer (pages/providers) only.

class AnalyticsService {
  // Cached flag values (reloaded on app start + auth + every 30 min)
  static final Map<String, dynamic> _flagCache = {};

  // Core tracking
  static Future<void> track(String event, {Map<String, dynamic>? properties});
  
  // Identity unification — call on auth_completed
  // PostHog merges anonymous distinct_id → user_id automatically
  static Future<void> identify(String userId, {Map<String, dynamic>? properties});
  
  // Screen tracking — ONLY for critical screens (see taxonomy)
  static Future<void> screenViewed(String screenName, {String? eventId});
  
  // Feature flags — reads from local cache, NOT network
  static bool isFeatureEnabled(String flagKey);
  static String? getFeatureFlagValue(String flagKey);
  
  // Reload flags from server (call sparingly: app open, auth, every 30 min)
  static Future<void> reloadFeatureFlags();
  
  // Reset on logout — clears distinct_id + flag cache
  static Future<void> reset();
}
```

### Identity Unification (cross-platform)

PostHog handles anonymous → authenticated merging via `identify()`:

1. **Anonymous phase:** user opens app/web → PostHog auto-generates a random `distinct_id` → all pre-auth events tracked under it
2. **Auth completes:** call `posthog.identify(supabase_user_id)` → PostHog aliases anonymous → `user_id`, merges history
3. **Cross-platform:** same `user_id` on both app + web → PostHog merges into one person automatically
4. **Logout:** call `posthog.reset()` → new anonymous `distinct_id` generated

**Never** set `distinct_id` manually before auth. Let PostHog manage the anonymous ID.

### Privacy & GDPR (EU)

- PostHog Cloud EU stores data in EU (Frankfurt)
- Respect user consent: implement opt-out toggle in Settings
- Do NOT track: passwords, full email addresses, sensitive PII
- Track: hashed/anonymized user IDs, behavioral events, aggregate properties
- Cookie banner for web (PostHog respects `posthog.opt_out_capturing()`)

---

## 8) Cost Optimization Strategy

**Goal:** $0 PostHog costs during beta (free tier: 1M events/month, 1M flag requests/month).

### Event Volume Budget (beta: ~50 users, ~20 events/month)

Estimated monthly volume at beta scale:

| Category | Events/month (est.) | Notes |
|----------|--------------------:|-------|
| `app_opened` | ~300 | 50 users × ~6 opens/month |
| Critical `screen_viewed` | ~600 | 50 users × ~12 critical screens/month |
| Funnel events (RSVP, upload, etc.) | ~400 | ~20 events × ~20 interactions |
| Auth events | ~100 | New users + re-auths |
| Host actions | ~100 | Event creation, sharing, nudges |
| Error events | ~50 | Target: very low |
| **Total** | **~1,550** | **Well under 1M free tier** |

### What Costs Money (avoid)

| Feature | Cost driver | Our approach |
|---------|-------------|-------------|
| **Session Replay** | Storage + processing per recording | ❌ **OFF** — don't enable until post-beta |
| **High-frequency events** | Per-event billing above free tier | ✅ Removed `session_started`, limited `screen_viewed` |
| **Feature flag requests** | Per-request above free tier | ✅ Local cache + reload only on app open / auth / 30 min |
| **Group analytics** | Per-group pricing | ❌ Not using group analytics |
| **Surveys** | Per-response | ❌ Not using PostHog surveys |

### Web Bot Protection

The web invite pages are publicly accessible — bots can inflate event volumes.

**Mitigations:**
- **Vercel WAF / Rate Limiting:** Enable Vercel's built-in firewall rules to block known bot user agents and rate limit requests (e.g., max 60 requests/min per IP)
- **PostHog JS config:** Set `disable_session_recording: true` (mandatory), and consider `opt_out_capturing_by_default: true` with explicit opt-in after human interaction (e.g., first click/tap)
- **Autocapture OFF:** Disable PostHog's default autocapture (`autocapture: false` in config) — we only fire explicit named events
- **Property filter:** Add `is_bot: true` server-side property for known bot user agents; filter out in dashboards
- **Vercel Edge Config:** Consider blocking paths like `/_posthog/` from being crawled (robots.txt)

### PostHog Project Settings (cost-safe defaults)

```
Session Replay:          OFF
Autocapture:             OFF
Heatmaps:                OFF
Web Analytics:           OFF  (we use custom events instead)
Exception Autocapture:   ON   (free, catches unhandled errors)
Surveys:                 OFF
Data Pipelines:          OFF
```

---

## 9) Alerts & Automation (Future)

Once baseline is established (end of Phase 2):

| Alert | Condition | Action |
|-------|-----------|--------|
| Upload failure spike | `photo_upload_failed` rate > 10% in 1h | Investigate immediately |
| Guest dropout | Guest activation < 30% for 3 consecutive days | Review auth/RSVP flow |
| Zero memories | No `memory_ready` events in 48h during cohort | Check event lifecycle |
| Error spike | Error rate > 5% on any platform in 1h | Check PostHog errors + deploy |
