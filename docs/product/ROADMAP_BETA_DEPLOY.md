# Lazzo — Product Roadmap (Post-Beta → Deploy)

**Context (v2):** Hosts create events in the **native app** (iOS via TestFlight); guests participate on the **web** (Vercel, separate codebase). Each event completes the cycle **Planning → Live → Recap**, with a **memories-first** differentiator.

**Start date:** Feb 23, 2026
**Team:** 2 engineers (each with AI copilot)
**Infra:** Supabase (backend) · TestFlight (iOS) · Vercel (web) · PostHog Cloud EU (analytics + flags + errors)

---

## 1) Current State — What's Built

The app is a **feature-complete MVP** with 10 features, 62+ shared components, 13 services, and 28+ routes — all wired to real Supabase backends.

| Area | Status |
|------|--------|
| Auth (passwordless email + OTP) | ✅ Shipped |
| Event lifecycle (create → live → recap) | ✅ Shipped |
| RSVP | ✅ Shipped |
| Photo upload + cover selection | ✅ Shipped |
| Memory (ready + viewer + share card) | ✅ Shipped |
| Home (3 modes: planning/living/recap) | ✅ Shipped |
| Calendar view | ✅ Shipped |
| Inbox (notifications + actions) | ✅ Shipped |
| Profiles (own + other) | ✅ Shipped |
| Settings + report + suggestion | ✅ Shipped |
| Push notifications (APNS) | ✅ Shipped |
| Web guest experience | ✅ Shipped (Vercel) |
| **Analytics / crash reporting** | ❌ Not instrumented |
| **Feature flags** | ❌ Not available |
| **CI/CD pipeline** | ❌ Manual builds |
| **Landing page** | ❌ Not built |

**Legacy cleanup needed:** `group_invites` feature directory still in codebase (non-functional, DI removed). Groups & expenses were removed in v2 pivot.

---

## 2) Product Strategy

**Job-to-be-done:** "I want to invite people with minimal friction and end up with a beautiful shared memory of the moment."

**Positioning:** Not competing on invite-card personalization; we win on **capturing and curating memories** (fast participation → strong recap).

---

## 3) Outcomes, Metrics & Decision Gates

### North Star

**Events with a completed memory.**

> An event is "completed" when it reaches **Memory Ready** and is viewed by at least one guest.

### Core Funnel Metrics (must be instrumented — PostHog)

**Guest funnel (web):**

1. Invite link open → `invite_link_opened`
2. Lightweight auth → `guest_auth_completed`
3. RSVP → `rsvp_submitted`
4. Upload → `photo_uploaded`
5. Recap view → `recap_viewed`

**Host loop (app):**

1. Event created → `event_created`
2. Shares invite link → `invite_link_shared`
3. Shares recap → `recap_shared`
4. Creates another event → `event_created` (repeat)

### Activation & Retention Targets (beta-level)

| Metric | Target | How to measure |
|--------|--------|----------------|
| Guest activation | ≥ 50% of invite opens → RSVP | `rsvp_submitted / invite_link_opened` |
| Memory creation rate | ≥ 60–70% of events → Memory Ready with ≥1 upload | `memory_ready / event_created` |
| Host repeat | ≥ 25–30% create 2nd event within 14 days | PostHog cohort |
| Time to RSVP | Median < 60 seconds | `rsvp_submitted.ts - invite_link_opened.ts` |

### Beta → Semi-public Gate

Proceed to larger cohorts when:

* Crash-free sessions ≥ 99% (app + web)
* Median time to RSVP < 60 seconds
* ≥ 60% events reach Memory Ready

### Semi-public → Public Gate (App Store)

* Support load manageable (≤ 1 critical issue / 10 events)
* Strong onboarding comprehension (qualitative)
* Conversion stable across "outside the bubble" cohorts

---

## 4) Roadmap Structure

Two tracks running in parallel:

* **Track A — Reliability & Foundations** (instrumentation, stability, deploy pipeline)
* **Track B — Memories-first Experience** (participation, recap, sharing loops)

---

# 5) 8-Week Roadmap

## Phase 0 — Deploy Pipeline (Days 1–3)

**Goal:** repeatable, safe deploys before any cohort testing.

### Epic A0 — CI/CD & Deploy Pipeline (P0)

**Outcome:** ship with confidence, roll back in minutes.

**App (iOS):**
* TestFlight build pipeline (Xcode Cloud or GitHub Actions)
* Version bumping strategy (semver)
* Build number auto-increment

**Web (Vercel):**
* Verify production deploy pipeline
* Preview deploys for PRs (if applicable)
* Environment variable management

**Supabase:**
* Migration workflow documented
* Staging vs production strategy (at minimum: documented rollback)

**DoD:** both platforms can be deployed in < 15 min with a documented runbook.

---

## Phase 1 — Closed Beta Readiness (23 Feb - 8 Mar)

**Goal:** ship a measurable product, ready for cohort testing.

### Epic A1 — PostHog Integration (P0)

**Outcome:** identify drop-offs within 24h of cohort start.

**Scope — all via PostHog Cloud EU:**

**Analytics — instrument core events across app + web:**
* `event_created` — host creates event (props: `event_id`, `has_location`, `has_datetime`)
* `invite_link_opened` — guest opens invite (props: `event_id`, `platform`, `referrer`)
* `invite_link_shared` — host shares link (props: `event_id`, `share_method`: copy_link/share, `share_content`: card/qr_code)
* `guest_auth_completed` — guest completes lightweight auth (props: `event_id`, `auth_method`)
* `rsvp_submitted` — guest RSVPs (props: `event_id`, `vote`: going/cant, `time_to_rsvp_seconds`)
* `photo_uploaded` — photo uploaded (props: `event_id`, `platform`, `is_cover`, `upload_duration_ms`)
* `photo_cover_selected` — cover marked (props: `event_id`)
* `event_phase_changed` — phase transition (props: `event_id`, `from_phase`, `to_phase`)
* `memory_ready` — memory compilation complete (props: `event_id`, `photo_count`, `contributor_count`)
* `recap_viewed` — user views recap (props: `event_id`, `viewer_role`: host/guest, `platform`)
* `recap_shared` — recap shared externally (props: `event_id`, `share_channel`)
* `share_card_generated` — share card created (props: `event_id`, `format`: story/post)
* `app_opened` — app launch (props: `platform`, `app_version`)
* `screen_viewed` — **critical screens only** (10 screens: home, event_detail, event_living, event_recap, create_event, memory_viewer, memory_ready, invite_landing, profile, inbox). NOT on every navigation.

**Properties on all events:** `event_id`, `user_id`, `platform` (ios/web), `event_phase`, `user_role` (host/guest), `timestamp`

**Feature Flags — configure in PostHog (local cache, not per-render):**
* `auth_wall_placement` — before/after event preview on web
* `upload_nudge_variant` — copy A/B for upload prompts
* `recap_cta_variant` — different recap sharing CTAs
* `rsvp_ui_variant` — RSVP interface variations
* Cache flags locally; reload only on app open, auth complete, and every 30 min

**Identity Unification:**
* Let PostHog generate anonymous `distinct_id` on first launch/page load
* On auth complete: call `posthog.identify(supabase_user_id)` to merge anonymous → user
* Same `user_id` on both platforms → PostHog merges cross-platform automatically

**Cost Optimization:**
* Session Replay: **OFF** (do not enable until post-beta)
* Autocapture: **OFF** on web (explicit events only)
* Web bot protection: Vercel WAF + rate limiting on invite endpoints
* Event budget: ~1,500 events/month at beta scale (well under 1M free tier)

**Error Tracking:** PostHog exception autocapture on both platforms (free)

**Dashboard:** build guest funnel + host loop + cohort view

**Implementation (app):**
* Add `posthog_flutter` to `pubspec.yaml`
* Create `lib/services/analytics_service.dart` (wraps PostHog SDK)
* Instrument events in providers/pages (not in domain layer)
* Feature flags: cache locally, read from `AnalyticsService.isFeatureEnabled()` (sync, no network)
* Identity: `identify()` on auth, `reset()` on logout

**Implementation (web):**
* Add PostHog JS SDK to Vercel project (same API key)
* Config: `autocapture: false`, `disable_session_recording: true`
* Identity: `posthog.identify(user_id)` on guest auth
* Share event taxonomy (same event names + properties as app)
* Enable Vercel WAF / rate limiting

**Non-goals:** session replay, autocapture, high-frequency screen tracking, group analytics.

**DoD:** dashboards live + QA verified end-to-end on both platforms + $0 PostHog bill.

### Epic A2 — Quality Bar v1 (P0)

**Outcome:** eliminate obvious blockers before real users.

* PostHog error capture active on both platforms
* Performance baseline: app startup time, web TTI
* Triage workflow: PostHog errors → GitHub Issues (label: `bug/beta`)
* **Note:** "Report a problem" already exists (route `/report-problem`, wired to Supabase `problem_reports` table)

**DoD:** errors captured + triage process documented.

### Epic B1 — Guest Onboarding Web Polish (P0)

**Outcome:** reduce confusion; faster RSVP.

* Review first screen: who/what/when + single CTA
* Loading/error states audit
* "What happens next" microcopy after RSVP
* Test on target mobile browsers (iOS Safari, Android Chrome)
* Track: `time_to_rsvp_seconds` property on `rsvp_submitted`

**DoD:** qualitative improvement confirmed; baseline metric captured for week-over-week comparison.

---

## Phase 2 — Cohort #1 (Friends) + Iteration (9 - 22 Mar)

**Goal:** validate funnel works end-to-end with real events; fix top frictions.

### Cohort plan

* Recruit: **5–7 hosts** (close friends) → each runs 1 real event
* Release cadence: **2 releases/week** (app via TestFlight, web via Vercel)
* Feedback: direct conversation + in-app report + PostHog session data

### Epic B2 — Memory Capture Flow v1 (P0)

**Outcome:** increase uploads per event.

* Upload UX audit: fewer steps, clear progress, retry on failure
* Gentle prompts: after RSVP, during live window, post-event
* "Upload later" intent tracking (`upload_intent_saved` event)
* Use PostHog flag `upload_nudge_variant` to test copy

**DoD:** ≥ 1 upload in ≥ 60% of cohort events.

### Epic B3 — Recap Experience v1 (P0)

**Outcome:** recap gets viewed and shared.

* Recap landing with clear "Memory Ready" moment
* Share recap link (OG image) + simple CTA on web
* Track: `recap_viewed`, `recap_shared`, `share_card_generated`

**DoD:** ≥ 40% of events have at least 1 recap view by a guest.

### Epic A3 — Permissions & Privacy Guardrails v1 (P1)

**Outcome:** reduce trust risk before expanding beyond friends.

* Event access rules: invite-only behavior, link expiry enforcement
* Basic abuse protections (rate limit uploads, signed URLs)
* Document privacy model for users

**DoD:** documented privacy behavior + basic protections active.

---

## Phase 3 — Cohort #2 ("Outside the bubble") + Differentiation (23 Mar - 5 Apr)

**Goal:** validate comprehension without founder explanation; emphasize memories-first.

### Cohort plan

* Recruit: **6–10 hosts** via friends-of-friends / communities
* Include event variety: dinner, party, trip, sports
* Use PostHog feature flags to A/B test key flows

### Epic B4 — Memories-first Differentiation (P0)

**Outcome:** guests understand why they should upload.

* A/B test via PostHog feature flags:
  * Variant A: RSVP-first (current)
  * Variant B: "Add to memory" + RSVP secondary
* Add "Why upload?" microcopy and small preview of recap
* Track: upload rate by variant, RSVP rate by variant

**DoD:** data shows upload rate improves without harming RSVP.

### Epic B5 — Host "Participation Insights" v1 (P1) — POST-BETA

**Outcome:** host feels momentum and engagement.

* Simple summary in app: RSVPs + uploads count + "nudge guests" action
* Track: `host_nudge_sent`, `event_participation_viewed` events
* **Deferred:** not available in current beta build

**DoD:** hosts use at least one nudge in ≥ 30% of events.

### Epic A4 — Deliverability & Share Reliability (P0)

**Outcome:** links always look good when shared.

* OG tags for event links (title, emoji, date) — Vercel web
* Fallback image generation for events without photos
* Test on WhatsApp, iMessage, Telegram, Instagram DMs

**DoD:** previews consistent across WhatsApp + iMessage.

---

## Phase 4 — Semi-public Beta Packaging (6 Apr - 19 Apr)

**Goal:** ready to scale invitations + early brand presence.

### Epic A5 — Landing Page v1 + Search Console (P0)

**Outcome:** brand legitimacy + conversion funnel entry point.

* Landing: value prop, screenshots, "Get TestFlight" CTA, FAQs
* SEO basics: sitemap, robots, canonical, meta
* Google Search Console verification
* PostHog on landing page: `landing_page_viewed`, `testflight_cta_clicked`

**DoD:** indexed pages + analytics on landing.

### Epic B6 — Referral Loop v1 (P1)

**Outcome:** organic growth from satisfied hosts.

* "Invite another host" prompt after successful recap share
* Simple referral link tracking: `referral_link_created`, `referral_link_opened`

**DoD:** ≥ 15–20% of hosts invite at least one new host.

### Epic A6 — Release & Ops v1 (P0)

**Outcome:** predictable shipping cadence.

* Weekly release notes template
* Bug triage SLA: P0 same-day, P1 48h, P2 weekly
* Rollback plan documented for both platforms

**DoD:** 2-week streak with stable releases.

### Codebase Cleanup (P2)

* Remove `group_invites` feature directory (legacy, non-functional)
* Remove commented-out groups/payments DI code from `main.dart`
* Audit `print()` statements: run `./scripts/clean_prints.sh`
* Run `flutter analyze` clean
* Remove any empty/TODO-only files

---

# 6) What We Will NOT Do in the Next 2 Months

* Deep invite-card customization (Partiful/Evite parity)
* Payments, groups, complex social graphs
* Heavy SEO content strategy (blog, keywords)
* Monetization experiments
* Android beta (focus on iOS + web)
* Web-based event creation (host stays app-only)
* AI features (auto-selection, smart albums)
* Multi-language beyond EN
* Session replay / advanced PostHog features
* PostHog autocapture / web analytics
* Generic screen_viewed on every navigation (cost risk)

---

# 7) Future Roadmap (Themes — 3–12 Months)

## 3–6 months (Post-beta → Public)

### Theme 1 — Memory Engine (Core moat)
* Better recap formats (timeline, highlights, auto-curated)
* Automatic best-of selection (simple heuristics first, ML later)
* Collaborative captions/notes
* Multi-day events (trips)

### Theme 2 — Participation Growth
* Smarter nudges (time-based + behavior-based via PostHog cohorts)
* "Upload from camera roll later" reminders (push notification)
* Web-to-app deep links for power users

### Theme 3 — Host Delight
* Host toolkit: agenda, pinned updates
* Notifications/actions tuning
* Anti-abuse and moderation basics

### Theme 4 — Public Launch Readiness
* Android release (Google Play)
* App Store listing preparation
* Onboarding polish
* Accessibility pass
* Localization (PT/EN)

## 6–12 months (Scale)

* Distribution loops (referrals, communities, student orgs)
* Partnerships (venues, creators)
* Optional monetization: premium recap exports, event packs
* Annual Recap (Spotify-style highlights)

---

# 8) Resourcing & Cadence

**Team:** 2 engineers + AI copilot each — no dedicated PM or designer (founders wear multiple hats).

**Normal weeks:**

| Day | Activity |
|-----|----------|
| Mon | Pick weekly goals + divide epics between devs |
| Tue–Thu | Build, ship, iterate |
| Fri | Release (TestFlight + Vercel) + notes + top learnings |

**Cohort weeks (Phases 2–3):**

| Day | Activity |
|-----|----------|
| Mon | Review PostHog data from weekend events |
| Tue–Thu | Fix top frictions + ship improvements |
| Fri | Release + collect qualitative feedback |

**Communication:** async-first. Sync on Mondays (30 min planning).

---

# 9) Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Guests don't upload → memory moat fails | High | CTA A/B tests, upload nudges, recap preview, frictionless UX |
| Web auth friction kills conversion | High | A/B test auth placement with PostHog flags; progressive gating |
| Share previews inconsistent | Medium | OG pipeline + fallback images; test on WhatsApp/iMessage/Telegram |
| 2-person team → scope creep / burnout | High | Strict P0-only during phases; defer P2; weekly priority review |
| PostHog instrumentation gaps → blind decisions | High | Define taxonomy first; QA every event before cohort launch |
| PostHog costs spike from bots/autocapture | Medium | Autocapture OFF; session replay OFF; Vercel WAF; selective screen_viewed |
| TestFlight review delays block iteration | Medium | Submit builds early; keep builds stable; have rollback ready |
| Cross-platform data gaps (app vs web) | Medium | Shared `user_id` + `event_id`; PostHog unifies with `distinct_id` |
| Not enough beta hosts recruited | Medium | Start reaching out week 1; have backup list; lower minimum to 3 hosts |

---

# 10) Appendix — Deliverables Checklist

## Phase 0: Pipeline
- [X] TestFlight build pipeline documented & working
- [X] Vercel deploy pipeline verified
- [X] Version strategy defined (semver + build number)

## Phase 1: Foundations
- [X] PostHog Cloud EU account created & configured
- [X] PostHog SDK integrated in app (`posthog_flutter`)
- [X] PostHog JS SDK integrated in web
- [X] Core event taxonomy implemented (funnel events firing correctly)
- [X] Identity unification verified (anonymous → auth merge works)
- [X] Selective screen_viewed on 10 critical screens only
- [X] Feature flags configured with local cache (≥ 3 flags ready)
- [X] Autocapture OFF, session replay OFF, bot protection ON
- [X] Guest funnel dashboard live in PostHog
- [X] Host loop dashboard live in PostHog
- [X] Feature flags configured (≥ 3 flags ready)
- [X] Error tracking active on both platforms
- [X] Guest web onboarding reviewed & polished

## Phase 2: Cohort #1
- [ ] 5–7 hosts recruited and briefed
- [ ] Upload flow bulletproof (progress, retry, error handling)
- [ ] Recap view polished + share working
- [ ] Privacy model documented
- [ ] First funnel data analyzed in PostHog
- [ ] Top 3 friction points identified & fixed

## Phase 3: Cohort #2
- [ ] 6–10 external hosts recruited
- [ ] A/B test running via PostHog flags (memories-first CTA)
- [ ] Host insights v1 shipped
- [ ] OG previews consistent across messaging platforms
- [ ] Upload rate improving vs Cohort #1

## Phase 4: Semi-public
- [ ] Landing page v1 live on Vercel
- [ ] Google Search Console verified
- [ ] Referral loop instrumented + tracked
- [ ] Release cadence proven (2+ weeks stable)
- [ ] Legacy code cleaned up (group_invites removed)
- [ ] Gate decision: proceed to public or iterate more
