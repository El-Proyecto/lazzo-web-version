# Lazzo — Metrics Plan (Post-Beta)

**Tool:** PostHog Cloud EU
**Platforms:** iOS app (via `posthog_flutter`) + Web (via PostHog JS SDK)
**Last updated:** Feb 23, 2026

---

## 1) Event Taxonomy

All events use a shared taxonomy across app and web. PostHog unifies sessions via `distinct_id` (mapped to Lazzo `user_id`).

### Global Properties (on every event)

| Property | Type | Description |
|----------|------|-------------|
| `event_id` | string (UUID) | The Lazzo event being interacted with (null for app-level events) |
| `user_id` | string (UUID) | Authenticated user ID |
| `platform` | string | `ios` or `web` |
| `user_role` | string | `host` or `guest` |
| `event_phase` | string | `planning`, `live`, `recap`, `expired` (null for non-event screens) |
| `app_version` | string | App build version (e.g., `1.0.1+2`) |

---

### Core Events

#### App Lifecycle

| Event | When | Extra Properties |
|-------|------|-----------------|
| `app_opened` | App launch or web page load | `source`: organic / push_notification / deep_link |
| `session_started` | New session detected | `is_first_session`: bool |
| `screen_viewed` | Navigation to a new screen | `screen_name`: route name |

#### Authentication

| Event | When | Extra Properties |
|-------|------|-----------------|
| `auth_started` | User taps sign in / lands on auth page | `auth_type`: email_passwordless / guest_lightweight |
| `auth_completed` | Successfully authenticated | `auth_type`, `is_new_user`: bool |
| `guest_auth_completed` | Web guest completes lightweight auth | `event_id`, `auth_method`: email |
| `profile_setup_completed` | User finishes profile creation | `has_avatar`: bool |

#### Event Creation (Host — app only)

| Event | When | Extra Properties |
|-------|------|-----------------|
| `event_created` | Host submits new event | `has_location`: bool, `has_datetime`: bool, `has_emoji`: bool, `creation_duration_seconds`: int |
| `event_edited` | Host edits existing event | `fields_changed`: string[] |
| `event_phase_changed` | Event transitions phase | `from_phase`, `to_phase`, `trigger`: auto / host_action |

#### Invite & Share

| Event | When | Extra Properties |
|-------|------|-----------------|
| `invite_link_shared` | Host shares invite link | `share_channel`: whatsapp / imessage / copy / qr / other |
| `invite_link_opened` | Someone opens an invite link | `referrer`: string (if available), `is_new_visitor`: bool |
| `qr_code_scanned` | QR code used to access event | `event_id` |

#### RSVP

| Event | When | Extra Properties |
|-------|------|-----------------|
| `rsvp_submitted` | Guest submits RSVP | `vote`: going / cant, `time_to_rsvp_seconds`: int (from invite open) |
| `rsvp_changed` | Guest changes RSVP | `from_vote`, `to_vote` |

#### Photo Upload

| Event | When | Extra Properties |
|-------|------|-----------------|
| `photo_upload_started` | User initiates upload | `source`: camera / gallery, `photo_count`: int |
| `photo_uploaded` | Photo successfully uploaded | `upload_duration_ms`: int, `file_size_kb`: int, `is_cover`: bool |
| `photo_upload_failed` | Upload fails | `error_type`: string, `retry_count`: int |
| `photo_cover_selected` | User marks a photo as cover | — |

#### Memory & Recap

| Event | When | Extra Properties |
|-------|------|-----------------|
| `memory_ready` | Memory compilation complete | `photo_count`: int, `contributor_count`: int, `hours_since_event_end`: float |
| `recap_viewed` | User views the recap/memory | `viewer_role`: host / guest, `photo_count`: int |
| `recap_shared` | User shares recap externally | `share_channel`: string |
| `share_card_generated` | Share card created | `format`: story_9_16 / post_1_1 |
| `memory_viewer_opened` | Full-screen memory viewer | `photo_index`: int |

#### Host Actions

| Event | When | Extra Properties |
|-------|------|-----------------|
| `host_nudge_sent` | Host nudges guests | `nudge_type`: upload / rsvp, `guest_count`: int |
| `event_participation_viewed` | Host views participation summary | `rsvp_count`: int, `upload_count`: int |
| `event_ended_manually` | Host ends event early | `hours_before_auto_end`: float |
| `event_extended` | Host extends event time | `extension_minutes`: int |

#### Engagement

| Event | When | Extra Properties |
|-------|------|-----------------|
| `poll_created` | Poll created in event | `option_count`: int |
| `poll_voted` | User votes on poll | `poll_id`: string |
| `suggestion_submitted` | User submits suggestion | `suggestion_type`: string |
| `notification_received` | Push notification received | `notification_type`: string |
| `notification_tapped` | User taps notification | `notification_type`: string, `time_to_tap_seconds`: int |

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

**Evaluation:** flags evaluated on `distinct_id` (user-level) for consistency.

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
event_created → invite_link_shared → event_participation_viewed → recap_shared → event_created (repeat)
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
- Crash-free session rate
- `photo_upload_failed` rate and error types
- Slowest screen loads (from `screen_viewed` timing)

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
| **Upload failure rate** | `photo_upload_failed` / `photo_upload_started` | < 5% | P1 |

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
- [ ] Set `distinct_id` to Supabase `user_id` on auth
- [ ] Implement `identify()` with user properties (role, created_at)
- [ ] Instrument all core events listed above
- [ ] Implement feature flag evaluation wrapper
- [ ] Test in debug mode (verify events in PostHog live view)

### Web Integration
- [ ] Add PostHog JS snippet to Vercel project
- [ ] Configure same project/API key
- [ ] Set `distinct_id` to match app user IDs (Supabase `user_id`)
- [ ] Instrument guest funnel events
- [ ] Implement feature flag evaluation
- [ ] Test cross-platform user tracking (same user on app + web)

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
  // Core tracking
  static Future<void> track(String event, {Map<String, dynamic>? properties});
  
  // User identification
  static Future<void> identify(String userId, {Map<String, dynamic>? properties});
  
  // Screen tracking
  static Future<void> screenViewed(String screenName);
  
  // Feature flags
  static Future<bool> isFeatureEnabled(String flagKey);
  static Future<String?> getFeatureFlagValue(String flagKey);
  
  // Reset on logout
  static Future<void> reset();
}
```

### Cross-platform User Tracking

Critical: when a guest uses the web first and later installs the app, PostHog must unify their identity.

1. Web: set `distinct_id` to Supabase `user_id` after auth
2. App: set `distinct_id` to same Supabase `user_id` after auth
3. PostHog automatically merges sessions under the same `distinct_id`

### Privacy & GDPR (EU)

- PostHog Cloud EU stores data in EU (Frankfurt)
- Respect user consent: implement opt-out toggle in Settings
- Do NOT track: passwords, full email addresses, sensitive PII
- Track: hashed/anonymized user IDs, behavioral events, aggregate properties
- Cookie banner for web (PostHog respects `posthog.opt_out_capturing()`)

---

## 8) Alerts & Automation (Future)

Once baseline is established (end of Phase 2):

| Alert | Condition | Action |
|-------|-----------|--------|
| Upload failure spike | `photo_upload_failed` rate > 10% in 1h | Investigate immediately |
| Guest dropout | Guest activation < 30% for 3 consecutive days | Review auth/RSVP flow |
| Zero memories | No `memory_ready` events in 48h during cohort | Check event lifecycle |
| Error spike | Error rate > 5% on any platform in 1h | Check PostHog errors + deploy |
