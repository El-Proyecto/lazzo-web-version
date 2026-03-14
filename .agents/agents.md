# Lazzo — Agent Guide

**Repository:** lazzo-web-version (Flutter app).

**Audience:** engineering agents & copilots. **Goal:** ship features fast without breaking architecture. This repo follows **Clean Architecture (Presentation / Domain / Data)** + **Supabase** + **Riverpod**.

> **Key rule:** Create UI designs and **immediately tokenize** into the feature's `presentation/widgets`. If a piece is **reusable**, place it under `shared/components/`.

Full rules, playbooks, and technical details live in `.agents/`. Use the index below to load the relevant doc.

## Documentation index

- [architecture.md](architecture.md) — Repository layout, folder responsibilities, navigation, widget migration.
- [coding_rules.md](coding_rules.md) — Golden rules, tokens, quality gates, naming, what to avoid, bootstrapping.
- [workflows.md](workflows.md) — Feature playbook and common playbooks.
- [database.md](database.md) — Schema docs and Supabase guidelines.
- [debugging.md](debugging.md) — Emergency debugging and logging.
- [migrations.md](migrations.md) — IMPLEMENTATION / MIGRATION / HANDOFF docs.

---

Keep this guide up to date. When in doubt: **tokenize, separate layers, fake-first, DI override, move-don't-delete**.
