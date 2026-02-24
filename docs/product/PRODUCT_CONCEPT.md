# Lazzo — Product Concept (MVP → Closed Beta)

**Tagline:** *Plan fast, remember forever.*

**Audience:** Friends (18–35) who want to quickly plan informal events, enjoy the moment, and keep a private memory — without social “noise” or the friction of yet another app install.

---

## 1) Product North Star
- **One place** to go from **plan → live → remember**.
- **Fast planning** (<30s), **private by default**, **low‑friction memories** (uploads during the event and within 24h).
- **Zero‑friction participation:** members who aren’t the host can RSVP, view event details, and add photos entirely via the **web** — no app install required.
- **App‑powered creation & sharing:** creating events and generating Share Cards requires the native app (iOS/Android).
- **Closed beta (TestFlight + Web)** ready experience: stable, delightful, minimal but complete.

**Differentiation:** Speed + privacy + complete flow + web accessibility. No global feed. No group overhead. Share only what you choose via an auto‑generated Memory Card.

---

## 2) MVP Scope (Included in Beta)
### Core pillars & features

1) **Planning**
   - Host creates event in <30s (app only): title + emoji, date/time, location.
   - Host shares the **event link** (deep link + QR code) to WhatsApp/iMessage/any messaging app.
   - Members open the link on **app or web**; they enter lightweight credentials (name + email/phone) for identity verification and RSVP (Going / Can’t).

2) **Live & Uploads (24h window)**
   - Take photos in‑app and/or import from camera roll (app); upload from device on web.
   - Each uploader can mark **one Cover** at upload time (host can remove covers if needed).
   - Live banner/timer for the active event; host can **Extend 30m** or **End now**.

3) **Memory (Post‑event)**
   - During the 24h window: “Add photos · Xh left”.
   - At close: **Memory Ready** (final set includes user‑selected Covers).
   - **Share Card** generator (app only): IG Story (9:16) / Post (1:1) with a subtle watermark.

4) **Home (3 modes) — App only**
   - **Planning**: upcoming events first, central action to create event.
   - **Living**: current event first; quick access to camera.
   - **Recap**: memory cards and share surfaces.

5) **Web Experience (Companion)**
   - **Same event link** used for sharing works on the web — phases transition automatically (Planning → Live → Recap).
   - Web supports: viewing event details, RSVP voting, uploading photos, viewing memory.
   - Web does **not** support: creating events, generating Share Cards.
   - Lightweight auth: members identify themselves via name + email or phone (no full account required to participate).

6) **Profiles & Privacy**
   - Profiles (app): own memories, past events.
   - Others’ profiles show only shared event context.

7) **Auth & Invites**
   - **Host (app):** sign‑in via email passwordless.
   - **Members (web or app):** lightweight credential entry (name + email) when accessing an event link — enough to verify identity without forcing a full sign‑up.
   - Event invites: single shareable link + QR code per event (expires with configurable TTL).

8) **Notifications & Inbox**
   - Actions: confirm RSVP, add photos, finish memory.
   - Notifications (app push + web if applicable): event updates, live started, upload window opened/closing, memory ready.

### Out of Scope for MVP (explicitly)
- Groups / group management; expenses / payments. *(Removed in v2 pivot — previously explored, now permanently deferred.)*
- Complex camera modes; advanced ML; public/global feed.
- Web-based event creation (host is app-only).
- Android release (iOS-first for beta).

---

## 3) Future Features (Not in MVP)
- **Annual Recap** (Spotify‑style) with highlights.
- **Phone‑number login** (to streamline identity).
- **Short videos** (likely paid tier).
- **Web‑based event creation** (extend hosting beyond app).
- **Multi‑day events** (trips, festivals).
- **Collaborative captions/notes** on photos.
- **Automatic best‑of selection** (heuristics → ML).
- **Android release** (Google Play, post-beta).

**If traction skews to nightlife:**
- Camera/Event modes (Disposable Camera, Random Reveal, etc.).
- Photo **voting** to select what goes into the memory.

*Note: Groups, recurring events, and expense splitting were explored in v1 and removed in the v2 pivot. Re-evaluation deferred to post-public launch.*

---

## 4) Personas & Jobs‑to‑be‑Done
**Primary:** event hosts and casual participants.
- *Host JTBD:* “Quickly set up an event, share a link, see who’s in, and produce a memory — without chasing people to install an app.”
- *Participant JTBD:* “Open a link, say I’m going, upload photos, and see the memory — without downloading anything.”

**Context of use:** mobile, on‑the‑go, spotty connectivity; social coordination pressure (speed and clarity matter). Participants may be on any device/browser.

---

## 5) UX Principles
- **Speed > features:** minimal taps, clear states (loading/empty/error), progressive disclosure.
- **Zero‑friction participation:** web‑first for non‑hosts; no app install barrier.
- **Privacy by default:** no global feed; opt‑in sharing only.
- **Temporal clarity:** event phases (**Planning → Live → Recap**, or **Expired** if the host missed the start date) drive surfaces and CTAs — consistent across app and web.
- **Consistency:** one visual language across app and web; predictable section headers/cards; touch targets ≥44px.
- **“Don’t block the moment”**: capture first; organize/curate shortly after.

---

## 6) Information Architecture & Navigation (Conceptual)

### App (iOS/Android)
- **Home** (mode‑aware): first card and center action vary by phase; sections: upcoming events, current event, past memories.
- **Calendar**: calendar and list view to track events and past memories.
- **Event Page**: header, RSVP status, location/date/time, uploaded photos;
- **Memory**: gallery (covers + rest), close/ready states, Share Card generator.
- **Inbox**: notifications, actions.
- **Profile**: edit profile; user’s memories and past events.

### Web
- **Event Page** (single‑page per event link): same phases as app — Planning (RSVP + details), Live (uploads), Recap (memory gallery).
- **Lightweight auth wall**: name + email before interacting.
- **No home/profile/inbox**: web is event‑scoped only.

---

## 7) Key User Flows (Outcome‑based)

1) **Create Event <30s (app)** → Title + emoji → date/time + location → share link/QR to WhatsApp/messaging.
2) **Join Event (web or app)** → Open link → enter name + email/phone → see event details → RSVP Going/Can’t.
3) **RSVP** → Vote quickly; counts update in real‑time; host sees who’s in — can manually confirm or auto‑confirm.
4) **Live Upload** → Take/import photos (app) or upload from device (web); each user marks one **Cover**; visible progress.
5) **Finish Memory** → Auto‑close at 24h or host closes now; memory becomes **Ready**; viewable on app and web.
6) **Share Card (app only)** → Select cover + highlights → generate IG/WA‑ready card with watermark.

---

## 8) Content & Copy Guidelines
- **Tone:** friendly, concise, playful; avoid jargon.
- **Clarity over cleverness:** action‑first labels (e.g., *Add Photos*, *Finish Memory*, *Create Event*).
- **Stateful messaging:** reflect phase/time (e.g., “12h left to add photos”).
- **Errors:** specific but safe; guide recovery (e.g., “Couldn’t upload. Try again when online.”).
- **i18n:** English/Portuguese for MVP; all strings sourced from translations.
- **Web copy:** guide users naturally — “Open the link your friend shared” / “No app needed”.

---

## 9) Privacy & Trust (Product Policy)
- **Private by default;** user opt‑in to share to IG/WhatsApp.
- **Uploads window**: during event + 24h after; host can close early.
- **Invite integrity:** event links are scoped to a single event; configurable expiry.
- **Lightweight identity:** web participants provide name + email/phone for verification — minimal data collection.
- **Share safety:** generated cards include only chosen content and a subtle watermark.

---

## 10) Notifications Strategy
- **Timely, helpful, minimal.**
- Triggers: event created/updated, RSVP prompts, live started, upload window opened/closing, memory ready.
- **App:** push notifications.
- **Web participants:** potential email/SMS reminders (future iteration).
- Respect user preferences and quiet hours where applicable.

---

## 11) Metrics & Success Criteria (MVP → Beta)

**North Star:** Events with a completed memory (Memory Ready + viewed by ≥1 guest).

**Core metrics (instrumented via PostHog Cloud EU):**

| Category | Metric | Target (Beta) |
|----------|--------|----------------|
| Speed | Median time to create event | < 30s |
| Guest activation | % invite opens → RSVP | ≥ 50% |
| Memory creation | % events reaching Memory Ready with ≥1 upload | ≥ 60–70% |
| Contribution | Uploads per event (participants contributing) | ≥ 2 contributors/event |
| Recap engagement | % events with ≥1 guest recap view | ≥ 40% |
| Sharing | Share Card generation rate from ready memories | Track baseline |
| Host retention | % hosts creating 2nd event within 14 days | ≥ 25–30% |
| Time to RSVP | Median invite open → RSVP | < 60 seconds |
| Web vs App | % of guest participation via web | Track baseline |
| Stability | Crash-free sessions (app + web) | ≥ 99% |

See [METRICS.md](METRICS.md) for full PostHog event taxonomy and dashboard specifications.

---

## 12) Beta Program (Closed — iOS/Android + Web)
- **Recruitment:** existing friend circles; 5–10 hosts per cohort; their friends participate via web.
- **Onboarding (app):** short “first run” hints; start at Home.
- **Onboarding (web):** event link landing page; guided credential entry; clear phase indicator.
- **Feedback loops:** in‑app feedback entry, post‑memory prompts, periodic check‑ins.
- **Success for beta:** stable sessions; core flows completed without guidance; >70% of events produce at least one ready memory; >50% of non‑host participants use web successfully.

---

## 13) Risks & Guardrails (Product)
- **Scope creep:** stick to MVP list; defer AI/camera modes/monetization to future. Groups & expenses already removed in v2.
- **Web parity expectations:** clearly communicate what web can and cannot do (no event creation, no Share Card).
- **Privacy leaks:** no unintended sharing; explicit confirmation for public profile display.
- **Friction at peak moments:** prioritize speed in Live flows; capture never blocked by optional fields.
- **Over‑notification:** batch where possible; clear settings.
- **Identity abuse (web):** lightweight verification (email) prevents impersonation without adding friction.
- **Instrumentation blind spots:** ensure PostHog covers both app + web with shared event taxonomy before cohort testing.

---

## 14) Glossary
- **Event phases:** Planning → Live → Recap (or Expired if the start date passes without confirmation).
- **Expired event:** An event reaches *expired* state when its `start_datetime` passes while it was never confirmed by the host. The event never transitioned to Live — the moment was missed. The host can reschedule (set new dates) to reactivate it. Expiry is based purely on `start_datetime`, not `end_datetime`.
- **Host:** the user who creates the event (requires app).
- **Member/Participant:** anyone invited to the event (can use app or web).
- **Cover:** one photo selected by an uploader to represent their contribution.
- **Memory Ready:** final post‑event compilation ready to view/share.
- **Share Card:** auto‑generated visual for IG/Stories or messaging (app only).
- **Event Link:** unique shareable URL (+ QR code) for a single event; works on app and web.

---


> This document defines *product intent* for MVP and near‑term roadmap. For implementation rules (architecture, tokens, layering, DI, security), see `README.md` and `AGENTS.md`.
