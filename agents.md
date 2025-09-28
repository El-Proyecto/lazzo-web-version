# Lazzo — Agent Guide

**Audience:** engineering agents & copilots. **Goal:** ship features fast without breaking architecture. This repo follows **Clean Architecture (Presentation / Domain / Data)** + **Supabase** + **Riverpod**.

> **Key rule:** We do **not** keep `figma_raw/`. Copy UI from Figma and **immediately tokenize** into `shared/components/`. If a piece is **not reusable**, place it under the feature’s `presentation/widgets/`.

---

## 1) Golden Rules
- **Tokenize first**: replace all colors/sizes/fonts/radii with tokens from `shared/constants` & `shared/themes`.
- **Single source rule**: Only use `shared/themes/colors.dart` and `shared/constants/`. Never create `styles/`, `theme/`, or other token files.
- **No infra in Domain**: Domain must have **no** imports from Flutter/Supabase.
- **Presentation ≠ Data**: Widgets do not call Supabase; they consume **providers/use cases**.
- **Complete DI coverage**: Every feature must have provider overrides in `main.dart`. No partial implementations.
- **Fake-first**: default DI wires **fake repositories**. A single override flips to Supabase.
- **Stateless Shared**: All `shared/components/*` must be stateless and reusable.
- **Minimal queries**: Data layer selects only columns needed by **entities**.

---

## 2) Repository Layout (for Agents)
```
lib/
├─ shared/
│  ├─ constants/        # spacing, text styles, assets
│  ├─ themes/           # colors, app_theme (dark-only MVP)
│  └─ components/       # reusable, tokenized UI (cards, sections, nav, ctas, forms)
├─ features/
│  └─ <feature>/
│     ├─ domain/        # entities/, repositories/ (interfaces), usecases/
│     ├─ data/          # data_sources/ (Supabase), models/ (DTO), repositories/ (impl), fakes/
│     └─ presentation/  # pages/, providers/ (Riverpod), widgets/ (feature-specific UI)
├─ services/            # supabase_client, storage, notifications, location
├─ routes/              # AppRouter (Navigator 1.0)
└─ resources/           # i18n
```

**Where to put things**
- Reusable card/section/navbar → `shared/components/...`
- Feature-only widget → `features/<f>/presentation/widgets/...`
- State/DI → `features/<f>/presentation/providers/...`
- Entity/Use case/repo interface → `features/<f>/domain/...`
- Supabase queries & DTOs → `features/<f>/data/...`

---

## 3) Tokens & Theme (Source of Truth)
- Colors: `shared/themes/colors.dart` (e.g., `BrandColors.bg2`, `colorScheme.primary`).
- Spacing: `shared/constants/spacing.dart` (`Insets`, `Gaps`, `Radii`, `Pads`).
- Typography: `shared/constants/text_styles.dart` (`labelLarge`, `titleMediumEmph`, etc.).
- Theme: `shared/themes/app_theme.dart` (Material 3, dark-only). **Never hardcode hex** in components.

**Tokenization checklist**
- Replace all `Color(0xFF...)` → tokens.
- Replace `EdgeInsets.all/only` values → `Insets`, `Pads`, `Gaps`.
- Replace `BorderRadius.circular(...)` → `Radii`.
- Replace `TextStyle(...)` → `AppText.*`.
- Remove fixed widths; prefer `Expanded`, constraints, or natural sizing.

---

## 4) End‑to‑End Feature Flow (Playbook)
**Goal:** new feature visible with fake data, then switch to Supabase by DI override.

1. **Scope UI**: list screens/sections; identify reusable vs feature-specific.
2. **Domain contracts**
   - Create **Entity** with minimal fields UI needs.
   - Define **Repository interface** (methods used by use cases/UI).
   - Add **Use case** (one action per class).
3. **UI**
   - Copy from Figma → create tokenized component(s) in `shared/components/`.
   - Compose screen in `features/<f>/presentation/pages/` (use shared components).
4. **State**
   - Create **providers** (Riverpod) exposing `AsyncValue` states; inject **FakeRepo** by default.
5. **Data**
   - Add **Supabase data source** in `data/data_sources/` (read/write/RPC/storage calls).
   - Add **DTO model** in `data/models/` (parse row ↔ entity).
   - Implement **Repository** in `data/repositories/` (use data source + DTO; return **entities**).
6. **DI Override**
   - In `main.dart`’s `ProviderScope(overrides: [...])`, swap `FakeRepo` → `RepoImpl(SupabaseClient)`.

**Result:** UI flips from fake to real with **no** widget changes.

---

## 5) Responsibilities by Folder (for Automation)
- `presentation/pages/` — screen composition only; no DB/network.
- `presentation/providers/` — call use cases, manage `AsyncValue`; **no** JSON parsing.
- `presentation/widgets/` — feature-specific visuals; compose shared components.
- `domain/entities/` — pure Dart models; stable contracts.
- `domain/repositories/` — interfaces; define app data API.
- `domain/usecases/` — orchestrate a single intent; may apply business rules.
- `data/data_sources/` — Supabase calls (select/insert/update/RPC/storage). Respect RLS.
- `data/models/` — DTO/serialization; isolate parsing & defaults.
- `data/repositories/` — bridges data sources ↔ domain; returns entities.
- `data/fakes/` — in-memory/dev repos.
- `shared/components/` — tokenized stateless building blocks.
- `services/` — app-wide clients/services (Supabase, storage, notifications).

---

## 6) Supabase Guidelines
- **RLS first**: queries must satisfy row-level policies. No admin keys in app.
- **Minimal select**: only fields required by the **entity**.
- **Indexes**: sort & filter by indexed columns; always `limit`.
- **Storage**: path convention `/groupId/eventId/userId/uuid.jpg` + metadata (uploader, type, ts).
- **RPC/Triggers**: live in DB; expose via repository method signatures.

---

## 7) Navigation
- Router: `routes/AppRouter` (Navigator 1.0 named routes).
- For previews, set `initialRoute` to target page.
- If nested tabs/guards become complex, consider `go_router` migration later.

---

## 8) Quality Gates (PR checklist)
- Uses tokens (no hex/magic numbers; micro 1–2px allowed if necessary).
- Stateless, reusable components in `shared/components/`.
- `AsyncValue` covers loading/empty/error in pages.
- Domain has no Flutter/Supabase imports.
- Data layer selects minimal columns and respects RLS.
- One responsibility per use case.
- Small PRs; clear filenames; feature‑scoped changes.

**New mandatory checks:**
- No direct Supabase calls in presentation layer (use repositories only).
- All shared components use tokens (zero hardcoded dimensions/colors).
- Feature has complete DI setup (fake repo, real repo, provider override).
- `const` constructors added where possible for performance.
- Empty or TODO-only files are removed or implemented.

---

## 9) Common Playbooks
- **Add a new card used in many screens** → implement in `shared/components/cards/`, then compose in pages.
- **Add a feature list (e.g., events)** → Entity + Repo interface + Use case + Provider; UI consumes provider; Data layer later wires Supabase.
- **Replace fake with real** → only DI override in `main.dart`.
- **Add write action (POST)** → Use case calling repository; repository calls data source `.insert()`/RPC; UI reads `AsyncValue` and shows success/error.

---

## 10) Naming & Conventions
- Components: `SomethingCard`, `SectionHeader`, `ModeNavBar`, `CreateEventCta`.
- Providers: `somethingControllerProvider`, `somethingRepositoryProvider`.
- Use cases: verb-first `GetLastMemory`, `CreateEvent`, `VoteOnPoll`.
- Files are **snake_case**; classes are **PascalCase**.

---

## 11) What Agents Must Avoid
- Editing UI with hardcoded hex/px not backed by tokens.
- Importing Supabase or Flutter into `domain/`.
- Calling Supabase directly from widgets/pages/providers.
- Duplicating shared components inside features.
- Modifying repository interfaces without syncing owners.

**Critical violations that break architecture:**
- Creating duplicate token systems (e.g., `styles/app_styles.dart` when `shared/themes/` exists).
- Skipping DI overrides in `main.dart` (leaving features stuck on fake data).
- Using `Supabase.instance.client` anywhere in presentation layer.
- Hardcoding dimensions in shared components (breaks responsive design).
- Leaving empty test files or unimplemented TODOs in production code.

---

## 12) Bootstrapping & Running
- Theme: dark-only via `shared/themes/app_theme.dart`.
- Router: named routes; set `initialRoute` to preview target page.
- Start: `flutter pub get && flutter run`.
- Supabase env: initialize in `main.dart`; DI override to use real repositories.

---

## 13) Emergency Debugging
**When things break during refactoring:**

**"Token not found" errors:**
- Check if you're importing from `shared/themes/colors.dart` not `styles/app_styles.dart`
- Verify token exists in `BrandColors` or `colorScheme`

**"Provider not found" errors:**
- Check `main.dart` ProviderScope overrides list
- Verify feature has both fake and real repository providers

**"Auth/Supabase errors" in presentation:**
- Never call `Supabase.instance.client` in presentation/
- Use repository pattern: widget → provider → use case → repository → data source

**"UI looks wrong" after tokenization:**
- Check responsive vs fixed sizing decisions
- Verify accessibility touch targets (min 44x44)
- Use `Expanded`/`Flexible` instead of fixed widths

---

## 14) Architecture Enforcement

**Automated Checks:**
Lint rules are configured in `analysis_options.yaml` to enforce:
- Architecture violations prevention (`depend_on_referenced_packages`, `avoid_relative_lib_imports`)
- Performance best practices (`prefer_const_constructors`, `prefer_const_literals_to_create_immutables`)
- Code quality standards (`prefer_single_quotes`, `avoid_unnecessary_containers`)

**Manual Review Checklist:**
- [ ] `git grep "Supabase.instance" -- lib/features/*/presentation/` returns empty
- [ ] `git grep "Color(0x" -- lib/shared/components/` returns empty  
- [ ] `git grep "styles/app_styles" -- lib/` returns empty
- [ ] All features have entries in `main.dart` ProviderScope overrides

---

## 15) Widget Migration & Management Guidelines

**CRITICAL RULE: Never delete widgets during migration - always move or replace them.**

### Widget Organization Principles
- **Shared components** (`shared/components/`): Only truly reusable UI that's used across 3+ features
- **Feature widgets** (`features/*/presentation/widgets/`): Components specific to one feature
- **Generic replacements**: Create unified components to replace multiple similar widgets

### Safe Widget Migration Process
1. **Before moving any widget:**
   - Search codebase for all imports: `git grep "widget_name.dart"`
   - Identify all usage locations
   - Plan replacement strategy (move vs replace vs create generic)

2. **When moving widgets:**
   - Update import paths in ALL consuming files immediately
   - Test compilation after each move: `flutter analyze`
   - Fix import paths using correct relative structure:
     - From feature to shared: `../../../../shared/constants/spacing.dart`
     - Between features: `../../../other_feature/presentation/widgets/`

3. **When creating generic replacements:**
   - Create new generic widget first (e.g., `CommonAppBar`, `VoteWidget`)
   - Update consumers to use new generic widget
   - Only then remove old specific widgets
   - Update `shared/components/components.dart` exports

### Import Path Patterns
```dart
// From feature widget to shared constants
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

// From feature widget to shared components
import '../../../../shared/components/cards/memory_card.dart';

// From feature widget to other feature
import '../../../create_event/presentation/widgets/event_form.dart';

// From feature widget to same feature
import '../other_widget.dart';
import '../../domain/entities/profile_entity.dart';
```

### Component Movement Checklist
Before moving any widget file:
- [ ] Search all imports: `git grep "filename.dart"`
- [ ] List all consuming files
- [ ] Plan import path updates
- [ ] Move file to new location
- [ ] Update ALL import paths immediately
- [ ] Run `flutter analyze` to verify no broken imports
- [ ] Update export files (`components.dart`, feature exports)
- [ ] Test app compilation and basic functionality

### Forbidden Operations
- **NEVER** delete widgets without ensuring they're replaced or moved
- **NEVER** move widgets without updating import paths immediately
- **NEVER** leave broken import paths "to fix later"
- **NEVER** create duplicate widgets in different locations
- **NEVER** move shared design tokens (colors, spacing, text_styles)

### Recovery from Broken Migration
If widgets are missing or imports broken:
1. Check git history: `git log --oneline --name-only`
2. Find moved files: `find lib/ -name "*widget_name*"`
3. Search for broken imports: `flutter analyze | grep "Target of URI doesn't exist"`
4. Fix import paths systematically, feature by feature
5. Verify each fix with `flutter analyze`

### Widget Architecture Rules
- **Generic widgets** (3+ usages): `shared/components/category/generic_name.dart`
- **Feature widgets** (1-2 usages): `features/feature_name/presentation/widgets/specific_name.dart`
- **Replacement strategy**: Create generic first, migrate consumers, remove specifics
- **Import consistency**: Use absolute paths from lib/ root for clarity
- **Export management**: Keep `shared/components/components.dart` updated with only shared exports

---

Keep this guide up to date. When in doubt: **tokenize, separate layers, fake-first, DI override, move-don't-delete**.

