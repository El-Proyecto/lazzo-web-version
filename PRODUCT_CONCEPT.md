# Lazzo — Product Concept (MVP → Closed Beta)

**Tagline:** *Plan fast, remember forever.*

**Audience:** Private groups of friends (18–35) who want to plan quickly, enjoy the moment, and keep a focused, private memory — without social “noise”.

---

## 1) Product North Star
- **One place** to go from **plan → live → remember**.
- **Fast planning** (<30s), **private by default**, **low‑friction memories** (uploads during the event and within 24h), and **light payments** for transparency.
- **Closed iOS/Android beta (TestFlight)** ready experience: stable, delightful, minimal but complete.

**Differentiation:** Speed + privacy + complete flow. No global feed. Share only what you choose via an auto‑generated Memory Card.

---

## 2) MVP Scope (Included in Beta)
### Core pillars & features
1) **Planning**
   - Create event in <30s: title + emoji, date/time (or “Decide later”), location (or “Decide later”).
   - Quick polls (date/location if needed), RSVP (Going / Can’t).
   - Event chat (per‑event thread) open during planning, live, and 24h after.

2) **Live & Uploads (24h window)**
   - Take photos in‑app and/or import from camera roll.
   - Each uploader can mark **one Cover** at upload time (host can remove covers if needed).
   - Live banner/timer for the active event; host can **Extend 30m** or **End now**.

3) **Memory (Post‑event)**
   - During the 24h window: “Add photos · Xh left”.
   - At close: **Memory Ready** (final set includes user‑selected Covers).
   - **Share Card** generator: IG Story (9:16) / Post (1:1) with a subtle watermark.

4) **Home (3 modes)**
   - **Planning**: upcoming events first, central action to create event.
   - **Living**: current event first; quick access to camera; Add Event CTA appears (since FAB is camera).
   - **Recap**: memory‑to‑end cards and share surfaces.

5) **Groups**
   - Group list with status chips (Actions/Photos/Unread). Group Board shows: actions, next/current events, memories, expenses.

6) **Payments (light)**
   - Track items per event, net totals per person.
   - “Mark as paid/received” with transparent breakdown.

7) **Profiles & Privacy**
   - Profiles: own memories, others’ profiles show only shared context.

8) **Auth & Invites**
   - Sign‑in: email passwordless, Apple/Google.
   - Group invites: deep link + QR (expires in 48h).

9) **Notifications & Inbox**
   - Actions: confirm RSVP, add photos, finish memory, payments reminders.
   - Notifications: event changes, window start/end, memory ready, mentions.

### Out of Scope for MVP (explicitly)
- Complex camera modes; advanced ML; public/global feed; web app.

---

## 3) Future Features (Not in MVP)
- **Event recommendations (AI) for the group.**
- **Annual Recap** (Spotify‑style) with highlights.
- **Phone‑number login** (to enable possible payment integrations with cash apps).
- **Group streaks** (consistency/reward loop).
- **Short videos** (likely paid tier).
- **One‑time invites** for non‑members.

**If traction skews to nightlife:**
- Camera/Event modes (Disposable Camera, Random Reveal, etc.).
- Photo **voting** to select what goes into the memory.

---

## 4) Personas & Jobs‑to‑be‑Done
**Primary:** group organizers (hosts) and casual participants.
- *Host JTBD:* “Quickly coordinate date/place, keep people engaged, and produce a good memory without micro‑managing.”
- *Participant JTBD:* “Know where/when, contribute photos easily, and keep memories private unless I choose to share.”

**Context of use:** mobile, on‑the‑go, spotty connectivity; social coordination pressure (speed and clarity matter).

---

## 5) UX Principles
- **Speed > features:** minimal taps, clear states (loading/empty/error), progressive disclosure.
- **Privacy by default:** no global feed; opt‑in sharing only; per‑profile controls.
- **Temporal clarity:** event phases (**Planning → Live → Recap**) drive surfaces and CTAs.
- **Consistency:** one visual language; predictable section headers/cards; touch targets ≥44px.
- **“Don’t block the moment”**: capture first; organize/curate shortly after.

---

## 6) Information Architecture & Navigation (Conceptual)
- **Home** (mode‑aware): first card and center action vary by phase; shared sections (Next, Pending, Memory to end).
- **Group Board**: actions, events (next/current), memories, expenses.
- **Event**: header, RSVP/polls, chat, location/date/time, uploads; live banner during event.
- **Memory**: gallery (covers + rest), close/ready states, share card.
- **Inbox**: notifications, actions, payments.
- **Profile**: edit profile; user’s memories.

---

## 7) Key User Flows (Outcome‑based)
1) **Create Event <30s** → Name+emoji → set/decide later date+location → event appears on Home & Group Board.
2) **RSVP** → Vote Yes/No quickly from a card; counts update; host sees who’s in - can mannualy confirm event or it auto confirms.
3) **Live Upload** → Take/import photos; each user marks one **Cover**; visible progress.
4) **Finish Memory** → Auto‑close at 24h or close now; memory becomes **Ready**.
5) **Share Card** → Select cover + highlights → generate IG/WA‑ready card.
6) **Settle Payments (light)** → See net per person; mark as paid/received; transparent breakdown.
7) **Invite** → Link or QR; 48h expiry; new user lands in the right group after sign‑in.

---

## 8) Content & Copy Guidelines
- **Tone:** friendly, concise, playful; avoid jargon.
- **Clarity over cleverness:** action‑first labels (e.g., *Add Photos*, *Finish Memory*, *Create Event*).
- **Stateful messaging:** reflect phase/time (e.g., “12h left to add photos”).
- **Errors:** specific but safe; guide recovery (e.g., “Couldn’t upload. Try again when online.”).
- **i18n:** English/Portuguese for MVP; all strings sourced from translations.

---

## 9) Privacy & Trust (Product Policy)
- **Private by default;** user opt‑in to share to IG/Whatsapp.
- **Ephemeral chat** scoped to the event (planning + live + 24h post).
- **Uploads window**: during event + 24h after; host can close early.
- **Invite integrity:** deep‑links and QR codes expire (48h) and are group‑scoped.
- **User control:** clear toggles to show/hide on profile; easy leave/group management.
- **Share safety:** generated cards include only chosen content and a subtle watermark.

---

## 10) Notifications Strategy
- **Timely, helpful, minimal.**
- Triggers: event created/updated, RSVP prompts, live started, upload window opened/closing, memory ready, payment reminders.
- Respect user preferences and quiet hours where applicable.

---

## 11) Metrics & Success Criteria (MVP)
- **Speed:** median time to create event < 30s.
- **Engagement:** % of events confirmed within 24h; % with memory closed within 24h.
- **Contribution:** uploads per participant; coverage of covers.
- **Sharing:** share card generation rate from ready memories.
- **Payments:** time to settle; % of debts resolved.
- **Retention:** D7/D30 group activity; events per group per month.

---

## 12) Beta Program (Closed iOS/Android)
- **Recruitment:** existing friend groups; 5–10 groups per cohort.
- **Onboarding:** invite deep‑link; short “first run” hints; start at Home.
- **Feedback loops:** in‑app feedback entry, post‑memory prompts, periodic check‑ins.
- **Success for beta:** stable sessions; core flows completed without guidance; >70% of groups produce at least one ready memory.

---

## 13) Risks & Guardrails (Product)
- **Scope creep:** stick to MVP list; defer camera modes/AI/voting to future.
- **Privacy leaks:** no unintended sharing; explicit confirmation for public profile display.
- **Friction at peak moments:** prioritize speed in Live flows; capture never blocked by optional fields.
- **Over‑notification:** batch where possible; clear settings.

---

## 14) Glossary
- **Event phases:** Planning → Live → Recap.
- **Cover:** one photo selected by an uploader to represent their contribution.
- **Memory Ready:** final post‑event compilation ready to view/share.
- **Share Card:** auto‑generated visual for IG/Stories or messaging.
- **Group Board:** per‑group hub for actions, events, memories, expenses.

---

## 15) Appendix — Feature Matrix (MVP vs Later)
| Area | MVP (Beta) | Later |
|---|---|---|
| Planning | Create <30s; RSVP; quick polls | AI recommendations |
| Live & Uploads | In‑app camera; import; covers; extend/end | Advanced camera modes |
| Memory | Close at 24h; Memory Ready; Share Card | Photo voting; annual recap |
| Payments | Light tracking; mark paid/received | Phone‑number login & cash‑app integrations |
| Social/Profiles | Private by default; optional profile display | Streaks; short videos; one‑time invites |
| Invites | Deep link + QR (48h) | One‑time invites for non‑members |

> This document defines *product intent* for MVP and near‑term roadmap. For implementation rules (architecture, tokens, layering, DI, security), see `README.md` and `AGENTS.md`. 

