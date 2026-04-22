# Testing — Agent Index

**Repository:** lazzo-web-version (Flutter · Dart 3 · Riverpod · Supabase).

This file is the entry point for any agent working on tests or coverage. Read it first, then open the specific guide for the priority you are implementing.

---

## Task routing

| Task | Load first |
|------|------------|
| Add tests (any layer) | This file → `test/guides/00_conventions.md` → guide for the target priority |
| P1 — Domain use cases | `test/guides/01_domain_usecases.md` |
| P2 — Domain entities | `test/guides/02_domain_entities.md` |
| P3 — Data DTOs / models | `test/guides/03_data_dtos_models.md` |
| P4 — Fake repository contracts | `test/guides/04_data_fakes_contract.md` |
| P5 — Supabase data sources | `test/guides/05_data_supabase_sources.md` |
| P6 — Riverpod providers | `test/guides/06_presentation_providers.md` |
| P7 — Widget / page tests | `test/guides/07_presentation_widgets.md` |
| P8 — Golden + integration | `test/guides/08_golden_and_integration.md` |
| Fix a failing test | `test/guides/00_conventions.md` + guide matching the layer |

---

## Priority order and rationale

```
P1 Domain use cases   → pure Dart, fastest ROI on coverage
P2 Domain entities    → equality, copyWith, edge cases
P3 Data DTOs          → round-trip JSON↔entity (where parse bugs hide)
P4 Fake contracts     → fakes used by default DI must honour interfaces
P5 Supabase sources   → mock SupabaseClient, test SQL paths
P6 Providers          → AsyncValue states via ProviderContainer
P7 Widget tests       → key pages with TestAppWrapper + overrides
P8 Golden + e2e       → visual regression + happy-path smoke tests
```

---

## Non-negotiable rules (aligned with AGENTS.md)

1. `flutter analyze` must pass with **zero violations** after every change.
2. No `print()` statements in test files.
3. Test files are named `*_test.dart` and mirror `lib/` structure under `test/`.
4. Every test imports from `lib/` — never redefine the SUT inside the test file.
5. Use `mocktail` (`Mock`, `when`, `verify`) — never `mockito` or hand-rolled mocks.
6. Use `faker` for realistic fake data; use `const` constructors where possible.
7. Domain (`lib/features/*/domain/`) must not import Flutter or Supabase — tests confirm this implicitly (Dart-only imports).
8. One `group()` per logical behaviour; test descriptions complete the sentence *"it should…"*.

---

## Canonical workflow (per agent session)

```
1. Read .agents/testing.md (this file)
2. Read test/guides/00_conventions.md
3. Open the guide for the current priority (01-08)
4. Implement ONE use case / entity / model at a time
5. flutter analyze          ← zero violations required
6. flutter test test/<path_to_new_test>.dart
7. flutter test --coverage
8. Inspect coverage/lcov.info for the touched file(s)
9. Review checklist in the guide → commit (single-feature scope)
10. Check off the item in the guide's progress tracker
```

---

## Coverage targets by layer

| Layer | Target |
|-------|--------|
| `**/domain/usecases/**` | ≥ 90 % lines |
| `**/domain/entities/**` | ≥ 85 % lines |
| `**/data/models/**` | ≥ 90 % lines |
| `**/data/fakes/**` | ≥ 80 % lines |
| `**/data/data_sources/**` | ≥ 70 % lines |
| `**/presentation/providers/**` | ≥ 75 % lines |
| `**/presentation/pages/**` | ≥ 60 % lines |

Note: thresholds are not yet enforced in CI — they are the working targets for this implementation round.

---

## Useful commands

```bash
# Run all tests with coverage
flutter test --coverage

# Run a single test file
flutter test test/features/event/domain/usecases/submit_rsvp_test.dart

# Run a folder
flutter test test/features/event/domain/

# View coverage summary (requires lcov)
genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html

# Analyzer (must pass before any commit)
flutter analyze
```

---

## Guides index

- [test/guides/00_conventions.md](../test/guides/00_conventions.md) — folder layout, naming, helpers, anti-patterns
- [test/guides/01_domain_usecases.md](../test/guides/01_domain_usecases.md) — P1
- [test/guides/02_domain_entities.md](../test/guides/02_domain_entities.md) — P2
- [test/guides/03_data_dtos_models.md](../test/guides/03_data_dtos_models.md) — P3
- [test/guides/04_data_fakes_contract.md](../test/guides/04_data_fakes_contract.md) — P4
- [test/guides/05_data_supabase_sources.md](../test/guides/05_data_supabase_sources.md) — P5
- [test/guides/06_presentation_providers.md](../test/guides/06_presentation_providers.md) — P6
- [test/guides/07_presentation_widgets.md](../test/guides/07_presentation_widgets.md) — P7
- [test/guides/08_golden_and_integration.md](../test/guides/08_golden_and_integration.md) — P8
