# Lazzo — Agent Guide

**Audience:** engineering agents & copilots. **Goal:** ship features fast without breaking architecture. This repo follows **Clean Architecture (Presentation / Domain / Data)** + **Supabase** + **Riverpod**.

> **Key rule:** Create UI designs and **immediately tokenize** into the feature's `presentation/widgets`. If a piece is **reusable**, place it under `shared/components/`.

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

**Database documentation**
- **Source of truth (raw schema):** `supabase_structure.sql` — auto-exported from Supabase, updated by P2 team
- **Human-readable docs:** `SUPABASE_DATABASE_STRUCTURE.md` — comprehensive guide with 21 tables, relationships, indexes, triggers, views, RLS policies, performance guidelines, and pending features
- **When to use which:**
  - Use `supabase_structure.sql` for quick schema lookups and precise field definitions
  - Use `SUPABASE_DATABASE_STRUCTURE.md` for understanding relationships, query patterns, optimization strategies, and pending work
- **Critical:** When `supabase_structure.sql` changes, `SUPABASE_DATABASE_STRUCTURE.md` must be updated to match

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
- **Database reference**: See `supabase_structure.sql` for current schema (source of truth) and `SUPABASE_DATABASE_STRUCTURE.md` for comprehensive documentation with relationships, query patterns, indexes, triggers, and RLS policies.

**Performance & Optimization (Always Recommend When Possible):**
- **Query optimization**: Select only required columns; use indexed columns for filtering/sorting; always add `LIMIT`; leverage materialized views for complex aggregations; batch operations to reduce round trips.
- **Schema design**: Denormalize strategically with materialized views; use foreign keys with CASCADE; validate data with DB constraints; use UUIDs for primary keys.
- **Caching strategies**: Use materialized views for expensive queries; client-side caching with Riverpod; consider local database (SQLite/Isar) for offline-first features; stale-while-revalidate pattern for non-critical data.
- **Efficient indexing**: Composite indexes for common query patterns; partial indexes for filtered queries; monitor index usage and drop unused ones; B-tree indexes for equality/range queries.
- **Local database usage**: Cache frequently accessed data; optimistic updates (local first, sync async); conflict resolution with `updated_at` timestamps; selective sync for active groups/events only.
- **Payload size minimization**: Paginate all lists with `limit + offset` or cursor-based; compress images before upload; JSON field pruning (only non-null fields); use storage CDN for images (never fetch full blobs via API).

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
- **All `print()` debug statements removed** - run `./scripts/remove_debug_prints.sh` before merge.

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

## 16) Logging & Debugging Guidelines

**CRITICAL: Never merge `print()` statements to main branch.**

**Purpose:** Rapid debugging during feature development without infrastructure overhead.

**Allowed in feature branches:**
```dart
// ✅ OK - Prefixed with feature name
print('[EventChat] Sending message: ${message.content}');
print('[Profile] Loading user $userId');
print('[SupabaseClient] Query took ${duration}ms');

// ✅ OK - Important state transitions
print('[EventProvider] State: loading → loaded (${events.length} events)');

// ❌ NEVER - No prefix, unclear context
print('Debug: $someVar');
print(response);
print('here');
```

**Naming Convention:**
- Format: `print('[FeatureName] description')`
- Feature names: `EventChat`, `Profile`, `Groups`, `CreateEvent`, `SupabaseClient`, `Repository`
- Include relevant IDs: `userId`, `eventId`, `groupId`
- Keep messages concise and actionable

**Before PR/Merge to Main:**
1. Run cleanup script: `./scripts/remove_debug_prints.sh`
2. Manually review any remaining prints that should stay (rare edge cases)
3. Verify with: `git grep -n "print(" lib/`
4. Zero prints in `lib/` folder = ready to merge

**Sensitive Data - NEVER LOG:**
- ❌ Passwords, tokens, API keys
- ❌ Full email addresses (use `email.substring(0, 3)...`)
- ❌ Phone numbers
- ❌ Complete user profiles
- ❌ Payment information

**Production Logging:** See `FUTURE_IMPROVEMENTS.md` for structured logging strategy (Logger package, Firebase Crashlytics).

---

## 17) Critical Changes Documentation

**When to create IMPLEMENTATION or MIGRATION markdown files:**

### IMPLEMENTATION Files

Use for **new features** or **major architecture changes** that require coordination between Supabase (P2 team) and codebase (agents/P1).

**Location:** `IMPLEMENTATION/<FEATURE>_IMPLEMENTATION.md`
**Structure:**
```markdown
# Feature Name Implementation

## Overview
Brief description of what's being implemented

## Part 1: Supabase Changes (P2 Developer)
### Database Schema
- [ ] Create tables with exact DDL
- [ ] Add indexes
- [ ] Configure RLS policies
- [ ] Create triggers/functions if needed

### Storage Setup
- [ ] Create buckets
- [ ] Configure policies

### Testing
- [ ] Verify schema with test queries
- [ ] Test RLS with different user contexts
- [ ] Validate triggers/functions

## Part 2: Codebase Changes (Agent/P1)
### Domain Layer
- [ ] Create entities
- [ ] Define repository interfaces
- [ ] Add use cases

### Data Layer
- [ ] Implement data sources
- [ ] Create DTOs/models
- [ ] Implement repositories
- [ ] Add fake repositories

### Presentation Layer
- [ ] Create pages
- [ ] Add providers
- [ ] Build widgets

### Integration
- [ ] Wire DI in main.dart
- [ ] Add routes

### Testing
- [ ] Unit tests for use cases
- [ ] Widget tests for UI
- [ ] Integration test for full flow
- [ ] Manual testing checklist

## Acceptance Criteria
- [ ] All tests pass
- [ ] No prints in code
- [ ] Architecture rules followed
- [ ] Performance acceptable
```

**Example:** `CHAT_READ_RECEIPTS_IMPLEMENTATION.md` document the chat read receipts feature with Supabase `message_reads` table + Flutter optimistic UI.

### MIGRATION Files

Use for **breaking changes** or **refactoring** that affects multiple features and requires careful coordination.

**Location:** `MIGRATIONS/<CHANGE>_MIGRATION.md`

**Structure:**
```markdown
# Migration Name

## Context
Why this migration is needed

## Breaking Changes
List all breaking changes and their impact

## Migration Steps

### Phase 1: Preparation
- [ ] Identify all affected files
- [ ] Create feature flags if needed
- [ ] Backup critical data

### Phase 2: Database Migration (if applicable)
- [ ] Write migration script
- [ ] Test in staging
- [ ] Plan rollback strategy

### Phase 3: Code Migration
- [ ] Update domain layer
- [ ] Update data layer
- [ ] Update presentation layer
- [ ] Update tests

### Phase 4: Validation
- [ ] Run full test suite
- [ ] Manual testing
- [ ] Performance testing
- [ ] Rollback plan validated

## Rollback Plan
Exact steps to revert if issues arise

## Post-Migration Cleanup
- [ ] Remove deprecated code
- [ ] Update documentation
- [ ] Remove feature flags
```


### HANDOFF Files

Use for **role transitions** from P1 (planning/UI) to P2 (implementation/integration).

**Location:** `HANDOFFS_TODO/<FEATURE>_P1_P2_HANDOFF.md` (before) → `HANDOFFS_DONE/<FEATURE>_P1_P2_HANDOFF.md` (after)

**Structure:**
```markdown
# Feature Name - P1 to P2 Handoff

## P1 Deliverables (Planning & UI)
- [x] Feature specification
- [x] UI mockups/designs
- [x] User flows documented
- [x] Edge cases identified

## P2 Tasks (Implementation)
- [ ] Supabase schema design
- [ ] Backend logic implementation
- [ ] API integration
- [ ] Testing & validation

## Acceptance Criteria
How to verify feature is complete

## Notes & Considerations
Important context for P2 team
```

**Key Differences:**
| File Type | When to Use | Who Creates | Who Consumes |
|-----------|-------------|-------------|--------------|
| IMPLEMENTATION | New features with DB + code changes | P1/Agent (template) | P2 (DB) → Agent (code) |
| MIGRATION | Breaking changes, refactoring | Agent/P1 | All developers |
| HANDOFF | Role transition P1→P2 | P1 | P2 team |

**Benefits:**
- ✅ Single source of truth for complex changes
- ✅ Reduces back-and-forth in prompts
- ✅ Clear testing checkpoints
- ✅ Easier rollback if issues arise
- ✅ Knowledge preservation for team


---

Keep this guide up to date. When in doubt: **tokenize, separate layers, fake-first, DI override, move-don't-delete**.

