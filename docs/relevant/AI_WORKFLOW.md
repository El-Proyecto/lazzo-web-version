# Why I Built Lazzo and What I've Learned Building with AI

## What I Built

Flutter iOS app + Next.js web companion that takes a group event from plan → live → memory. Host creates an event in <30 seconds, shares a link; guests RSVP and upload photos on the web with no app install required. A 24-hour window closes into a curated Memory the group keeps. Closed beta on TestFlight and getlazzo.com.

Group events kept falling apart in WhatsApp — messages buried, RSVPs forgotten — and when the event happened, photos disappeared because the sharing moment passed within 24 hours. Sitting together and realising there was nothing to show for a night out was a pattern that repeated enough times to be worth fixing. 23 interviews confirmed this wasn't a niche complaint; it was an accepted norm. No tool covered the full cycle: coordinate → RSVP → shared memory.

V1 testing sharpened the scope: guests felt obligated to install the app and in the real world they wouldn't. We rebuilt the entire guest experience as a web companion and cut four features — groups, chat, expenses, availability polls — that had positive Figma scores but competed with habits people already had.

## How I Use AI Coding Tools

**Three-layer context loading (L0 → L1 → L2).** `agents.md` is L0: a routing index, always loaded, ~55 lines. It maps task type to the relevant L1 file ("fixing a bug → load `debugging.md` + `coding_rules.md`"). The seven `.agents/` files are L1: specialized context per domain, 50–200 lines each, loaded only for the matching task. Actual source files are L2: consulted only when L1 specifies or the agent needs to verify a concrete detail. A debugging session loads ~250 lines total. A naive approach loads 2000+. Same result; 85% fewer tokens.

**Hard constraints in every session prevent architectural drift.** `coding_rules.md` states "Domain must have no imports from Flutter/Supabase" in plain language, not just as a lint rule. Before this existed, AI-generated use cases silently imported `SupabaseClient`. After: zero domain-layer violations across 40+ commits touching that layer. Rules that live only in `analysis_options.yaml` don't survive the model's context; rules that are written out in natural language do.

**Two schema files, two purposes — the agent doesn't get to choose.** `supabase_structure.sql` is 203 lines of CREATE TABLE statements (9KB); `supabase_schema.sql` is 5,374 lines of every RLS policy, trigger, function, and view (174KB). `database.md` (L1) specifies which to load based on the task: structure file for table-shape questions and query writing, full schema only for diffs and migrations. The Supabase MCP connector pulls the full schema automatically — which sounds convenient until an agent drafting a simple SELECT burns its context budget on 170KB of unrelated triggers. Minimum context for the task is a constraint, not a preference.

**Handoff docs as bounded agent prompts.** Each feature has a `P1_P2_HANDOFF.md` that separates "Supabase Changes (P2)" from "Codebase Changes (Agent/P1)." Architecture decisions are made before generation, not negotiated during. The agent gets a finite, testable scope. Open-ended instructions produce open-ended (and often wrong) outputs.

**Fake-first DI lets agents complete whole features without backend access.** Default wiring uses in-memory fake repositories. An agent can implement a full feature — entity → use case → provider → UI — with no Supabase credentials, no live schema, no network. One override in `main.dart` switches to real data. AI-generated features are independently testable before the backend is ready, and the fake repo doubles as a test fixture.

**Priority-ordered test guides give agents a deterministic testing curriculum.** `testing.md` routes agents through 8 priority levels — P1 domain use cases → P2 entities → P3 DTOs → P4 fake contracts → P5 Supabase sources → P6 providers → P7 widgets → P8 golden/e2e — each with its own guide in `test/guides/0X_*.md` and per-layer coverage targets (≥90% for use cases, ≥60% for pages). An agent implementing tests never decides "what should I test next?" — the priority order is explicit, the success condition is per-guide, and the commit scope is one priority at a time. Without this, agents default to writing the easiest tests, not the highest-value ones.

**Typed analytics taxonomy enforced at compile time.** `METRICS.md` defines the shared event taxonomy across both platforms. Both `analytics_service.dart` (Flutter) and `lib/analytics.ts` (Next.js) implement typed helpers per event. TypeScript strict + `flutter analyze` catch deviations the moment they're generated — no manual review needed to spot a hallucinated event name.