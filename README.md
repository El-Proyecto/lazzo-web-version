# Lazzo — Project Guide (Clean Architecture + Supabase + Flutter)

This README explains **how the project is organized**, **how features are built end‑to‑end**, and **how humans & AI agents** should collaborate safely. Keep this at the repo root.

---

## High‑level Architecture
- **Presentation** (Flutter UI): pages, widgets, state (Riverpod), navigation.
- **Domain** (pure Dart): entities, repository **interfaces**, use cases. No Flutter/Supabase imports.
- **Data** (infra): data sources (Supabase), DTO/models, repository **implementations**.
- **Shared**: design system (tokens), reusable UI components.
- **Core/Services**: cross‑cutting utilities (errors, env), Supabase client service, storage, notifications.
- **Routes/Resources**: router config (Navigator 1.0 named routes), i18n.

```
lib/
├─ core/               # env, errors, utils
├─ services/           # supabase_service, storage, notifications
├─ shared/             # design tokens + reusable UI
│  ├─ constants/       # spacing, text_styles, assets
│  ├─ themes/          # colors, app_theme
│  └─ components/      # cards, sections, nav, ctas, forms
├─ features/
│  └─ <feature>/
│     ├─ domain/       # entities/, repositories/, usecases/
│     ├─ data/         # data_sources/, models/, repositories/, fakes/
│     └─ presentation/ # pages/, widgets/, providers/, (views/ optional)
├─ routes/             # AppRouter (Navigator 1.0 named routes)
└─ resources/          # translations
```

---

## Design System (tokens)
**Single source of truth** for colors/spacing/typography. All UI must use tokens (no hex/inline sizes except micro 1–2px optical fixes).
- `shared/themes/colors.dart` → Brand colors & dark colorScheme
- `shared/constants/spacing.dart` → Insets, Gaps, Radii, Pads
- `shared/constants/text_styles.dart` → labelLarge, titleMediumEmph, bodyMedium, etc.
- `shared/themes/app_theme.dart` → ThemeData (Material 3, dark‑only MVP)
- **Critical:** Never create duplicate token systems (e.g., `styles/app_styles.dart`). Use only `shared/themes/` and `shared/constants/`.
- Reusable UI goes in `shared/components/` (cards/, sections/, nav/, ctas/, forms/)

**Figma → Flutter rule**: export **Widget** from plugin → copy **directly** to `shared/components/...` and **tokenize immediately** (substituir cores/tamanhos/raios/fonte por tokens; remover larguras fixas).
We **do not** keep any `figma_raw/` dumps in this repo. If a piece is **not reusable**, place it under `features/<feature>/presentation/widgets/` instead of `shared/components/`.

---

## Feature Development Flow (2 roles)
**Goal:** UI works with fake data first, then flips to Supabase without touching widgets.

### Role P1 — UI + State + Contracts
1) Define **Domain contracts**
   - `features/<f>/domain/entities/…` → minimal fields UI needs.
   - `features/<f>/domain/repositories/…` → interface methods (no implementations).
   - `features/<f>/domain/usecases/…` → one action per class.
2) Build **UI components** in `shared/components/…` (tokenized, stateless, reusable).
3) Compose screens in `features/<f>/presentation/pages/…` using shared components.
4) Create **providers** in `features/<f>/presentation/providers/…`
   - Default DI points to **fakes** (see below).
   - Expose `AsyncValue` for loading/error/success.
   - **Never import Supabase directly** in presentation layer.
5) Put **fakes** in `features/<f>/data/fakes/…` implementing repo interfaces (return mock data).

### Role P2 — Data + Supabase
1) Implement **data source** in `features/<f>/data/data_sources/…` (Supabase queries only; respect RLS; select minimal columns; indexes friendly `order + limit`).
2) Map rows to **models/DTO** in `features/<f>/data/models/…` (parse, defaults, toEntity()).
3) Implement **repository** in `features/<f>/data/repositories/…` (bridge model → entity, normalize errors).
4) **Dependency Injection** override
   - In `main.dart` (ProviderScope overrides), swap `FakeRepository → RepositoryImpl(Supabase…)`.
   - **All features must have DI overrides**, not just some.
   - No UI changes needed.

**Handoff contract:** P1 publishes entity fields + repo method signatures before P2 starts. P2 must not change contracts without sync.

---

## Adding a New Feature (Checklist)
1) **Scoping**: list the UI sections/cards; identify shared vs feature‑specific.
2) **Domain**: add entity → repository interface → use case(s).
3) **UI**: export Figma Widget(s) → `shared/components/…` tokenized. Compose Page in `presentation/pages`.
4) **State**: create providers. Default repo provider → **fake** (under `data/fakes`).
5) **Data**: implement Supabase data source + model + repo impl.
6) **DI override**: switch provider to real impl in `main.dart`.
7) **States**: verify loading/empty/error visuals.
8) **QA**: RLS read/write paths, storage paths, performance (limit/order/index), navigation.

---

## Folder Responsibilities (for humans & agents)
- `features/<f>/presentation/pages/` — Screens composing sections/components. No network/DB.
- `features/<f>/presentation/widgets/` — Small feature widgets that compose shared components.
- `features/<f>/presentation/providers/` — Riverpod providers, **no parsing** or Supabase calls; call use cases.
- `features/<f>/domain/entities/` — Business models (pure Dart).
- `features/<f>/domain/repositories/` — Abstract contracts.
- `features/<f>/domain/usecases/` — Orchestrate one action (call repo, apply rules).
- `features/<f>/data/data_sources/` — Supabase interactions only (select/insert/update/RPC/storage).
- `features/<f>/data/models/` — DTOs converting raw maps ↔ entities.
- `features/<f>/data/repositories/` — Implements domain repositories using data sources + models.
- `features/<f>/data/fakes/` — Fake repos for fast UI dev.
- `shared/components/` — Cross‑feature UI building blocks (cards, sections, nav, ctas, forms). Stateless, tokenized.
- `shared/constants/` & `shared/themes/` — Design tokens & ThemeData. Theming only here.
- `services/` — App‑wide services (Supabase client, storage, notifications, location). No UI.
- `routes/` — AppRouter (Navigator 1.0). Add routes here, switch `initialRoute` as needed.
- `core/` — Errors, exceptions, env, generic utils.
- `resources/translations/` — i18n JSONs.

---

## Navigation
- Current: **Navigator 1.0** named routes via `AppRouter.routes`.
- For previewing a page, set `initialRoute` accordingly.
- If nested tabs or guards become complex, consider migrating to `go_router` later.

---

## Data & Supabase Guidelines
- Respect **RLS** in queries; never bypass with admin keys in app.
- Audit **RLS coverage** systematically; use integration tests to verify policies.
- Never call Supabase directly from presentation layer; use repository pattern.
- Select **only** columns required by the entity/use case.
- Use indexes: e.g., `order('created_at', ascending: false).limit(1)` on indexed columns.
- Storage paths convention: `/eventId/userId/uuid.jpg` with metadata (uploader, type, ts).
- RPC/Triggers live in DB; expose as repository methods.

---

## CI/CD & PR Hygiene
- Small PRs (<400 reviewable lines) per widget/feature slice.
- Conventional Commits (optional) for changelog.
- Lints: forbid raw hex colors & magic numbers (except micro optical fixes), prefer tokens.
- Definition of Done: loading/empty/error states, a11y touch size, tokens applied, no logic in shared components, telemetry hooks (where applicable).

---

## Widget Management Guidelines

**Component Organization Rules:**
- **Shared components** (`shared/components/`): Only widgets used across 3+ features (cards, buttons, nav, sections)
- **Feature widgets** (`features/*/presentation/widgets/`): Components specific to one feature
- **Generic over specific**: Create unified components (e.g., `CommonAppBar`) to replace multiple similar widgets

**Critical Don'ts:**
- Never delete widgets without ensuring they're replaced or moved
- Never leave broken import paths "to fix later"
- Never move shared design tokens (colors, spacing, text_styles) out of `shared/`
- Never create duplicate widgets in different locations

---

## Quality Checklist (Before PR)
**Architecture Boundaries:**
- [ ] No Supabase imports in `features/*/presentation/` or `features/*/domain/`
- [ ] All hardcoded colors use tokens from `shared/themes/colors.dart`
- [ ] All hardcoded dimensions use tokens from `shared/constants/spacing.dart`
- [ ] Shared components are stateless and reusable
- [ ] Feature has both fake and real repository implementations
- [ ] DI override exists in `main.dart` for the feature

**Code Quality:**
- [ ] `const` constructors where possible
- [ ] Proper error handling with `AsyncValue`
- [ ] No TODO/FIXME comments without GitHub issues
- [ ] Tests cover new functionality (unit for domain, widget for UI)

**Widget Management:**
- [ ] No broken import paths: `flutter analyze` shows no "Target of URI doesn't exist" errors
- [ ] Shared components are truly reusable (used by 3+ features)
- [ ] Feature-specific widgets are in correct `features/*/presentation/widgets/` folders
- [ ] All moved widgets have updated import paths in consuming files
- [ ] `shared/components/components.dart` exports only truly shared components

---

## Glossary
- **Tokenization**: replacing raw styles with design tokens (colors/spacing/typography/radii).
- **Template/Component**: UI structure with props, no side effects.
- **View (optional)**: thin wrapper that injects controllers/handlers from providers into components.
- **Entity**: domain model used by the app logic/UI.
- **Repository (Domain)**: interface defining data operations.
- **Repository Impl (Data)**: concrete implementation using data sources.
- **Data Source**: low‑level access (Supabase queries, storage).
- **DTO/Model**: serialization layer mapping raw data ↔ entity.
- **Fake Repo**: in‑memory/dev implementation for fast UI.

---

## Agent Playbook (AI/Automation)
- Never edit `figma_raw/`. Always create or update tokenized components in `shared/components/`.
- When adding data access, respect **contracts** in `domain/repositories/` and implement under `data/repositories/`.
- For temporary data, implement under `data/fakes/` and keep DI switchable.
- Do not add Flutter/Supabase imports in `domain/`.
- Prefer composition: pages → (views) → feature widgets → shared components.
- Keep changes localized per feature; avoid cross‑feature imports from `presentation/`.

---

## Getting Started (local)
1) Set dark theme in `app.dart`, set `initialRoute` (e.g., Home for previews).
2) Run `flutter pub get && flutter run`.
3) For Supabase, initialize in `main.dart` and provide DI overrides for repositories.

---

Questions or inconsistencies? Open an issue and tag which layer (presentation/domain/data/shared/services) is impacted.

