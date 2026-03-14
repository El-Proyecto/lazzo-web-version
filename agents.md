# Lazzo — Agent Guide

**Repository:** lazzo-web-version (Flutter app).

**Audience:** engineering agents & copilots. **Goal:** ship features fast without breaking architecture. This repo follows **Clean Architecture (Presentation / Domain / Data)** + **Supabase** + **Riverpod**. It is focused on UI and widgets; maintaining, fixing bugs, and improving or adding features are equally important.

| Task type | Load first |
|-----------|-------------|
| Fix a bug | [.agents/debugging.md](.agents/debugging.md), [.agents/coding_rules.md](.agents/coding_rules.md) |
| Small improvement | [.agents/coding_rules.md](.agents/coding_rules.md), [.agents/workflows.md](.agents/workflows.md) |
| New feature | [.agents/workflows.md](.agents/workflows.md), [.agents/architecture.md](.agents/architecture.md), [.agents/coding_rules.md](.agents/coding_rules.md) |
| Database change | [.agents/database.md](.agents/database.md), [.agents/migrations.md](.agents/migrations.md), [.agents/workflows.md](.agents/workflows.md) |
| Refactoring | [.agents/architecture.md](.agents/architecture.md), [.agents/migrations.md](.agents/migrations.md), [.agents/coding_rules.md](.agents/coding_rules.md) |

## Non-negotiable rules

Always read and follow these, regardless of task:

- **Domain layer purity** — No Flutter or Supabase imports in `domain/`.
- **No direct Supabase in widgets** — Use providers/use cases and repositories only.
- **Tokens-only UI** — Use `shared/themes` and `shared/constants`; no hardcoded hex or magic numbers in components.
- **Reusable widgets in shared** — Put shared UI in `shared/components/`; feature-specific UI stays in `features/<f>/presentation/widgets/`.
- **Fake-first** — Default DI uses fake repositories; one override switches to real Supabase.
- **Move-don't-delete** — When relocating widgets or code, move or replace; do not delete without a replacement.

## Repository structure

```
lib/
├─ features/<feature>/   presentation | domain | data
├─ shared/               components | constants | themes
├─ services/
├─ routes/
└─ resources/
```

Schema source of truth: `supabase_structure.sql` and `supabase_schema.sql` at repo root (see [.agents/database.md](.agents/database.md)).

Full rules, playbooks, and technical details live in `.agents/`. Use the index below to load the relevant doc.

## Documentation index

- [.agents/architecture.md](.agents/architecture.md) — Repository layout, folder responsibilities, navigation, widget migration.
- [.agents/coding_rules.md](.agents/coding_rules.md) — Golden rules, tokens, quality gates, naming, what to avoid, bootstrapping.
- [.agents/workflows.md](.agents/workflows.md) — Feature playbook and common playbooks.
- [.agents/database.md](.agents/database.md) — Schema docs and Supabase guidelines.
- [.agents/debugging.md](.agents/debugging.md) — Emergency debugging and logging.
- [.agents/migrations.md](.agents/migrations.md) — IMPLEMENTATION / MIGRATION / HANDOFF docs.

---

When in doubt—whether fixing, improving, or adding—apply: **tokenize, separate layers, fake-first, DI override, move-don't-delete**.
