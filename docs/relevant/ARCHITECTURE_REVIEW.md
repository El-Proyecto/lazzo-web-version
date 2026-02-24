# ARCHITECTURE_REVIEW.md

**Lazzo Flutter + Supabase App Architecture Review**  
*Generated on: September 24, 2025*

## Executive Summary

• **Strengths**: Clean Architecture foundations are solid with proper domain/data/presentation separation, good use of entities and repositories, well-structured feature folders, comprehensive fake repositories for development.

• **Critical Issues**: Multiple Supabase calls directly in presentation layer (auth pages/providers), duplicate token systems causing inconsistency, missing DI overrides for most features leading to incomplete fake-to-real transitions.

• **High Priority**: Presentation layer boundary violations in auth feature, inconsistent tokenization with both `shared/themes/colors.dart` and `styles/app_styles.dart`, hardcoded dimensions in shared components.

• **Medium Priority**: Incomplete test coverage (empty test files), missing provider overrides in main.dart for all features, no RLS auditing framework, Navigator 1.0 limitations for complex flows.

• **Architectural Debt**: Domain layer purity is excellent (✅), but inconsistent token usage and direct Supabase imports in presentation create maintainability risks.

• **Security Concerns**: Some auth pages bypass repository pattern, potential RLS coverage gaps, no systematic security audit framework.

• **Performance**: Some components use fixed dimensions instead of responsive design, no systematic const usage audit, state granularity appears appropriate with Riverpod.

---

## Repository Map & Layering

### Current Structure (Observed)
```
lib/
├─ shared/
│  ├─ constants/        ✅ Good: spacing, text_styles, assets
│  ├─ themes/           ✅ Good: colors, app_theme (dark-only)
│  └─ components/       ⚠️  Mixed: well-structured but some hardcoded values
├─ styles/              ❌ DUPLICATE: conflicts with shared/themes/
├─ features/
│  ├─ auth/             ❌ Boundary violations in presentation/
│  ├─ create_event/     ✅ Clean architecture exemplar
│  ├─ home/             ✅ Good structure, DI properly configured
│  ├─ groups/           ⚠️  Missing DI override in main.dart
│  ├─ profile/          ⚠️  Missing DI override in main.dart
│  └─ activities/       ⚠️  Missing DI override in main.dart
├─ services/            ✅ Well-structured cross-cutting concerns
├─ routes/              ✅ Clean Navigator 1.0 implementation
└─ core/                ✅ Good utilities and error handling
```

### Proposed Structure (Post-Refactor)
```
lib/
├─ shared/
│  ├─ constants/        ← Keep: spacing, text_styles, assets
│  ├─ themes/           ← Keep: single source for colors/theme
│  └─ components/       ← Refactor: remove hardcoded values
├─ features/            ← Fix: complete DI setup for all features
│  └─ <feature>/
│     ├─ domain/        ← Keep: pure Dart
│     ├─ data/          ← Keep: Supabase + fakes
│     └─ presentation/  ← Fix: no direct Supabase imports
├─ services/            ← Keep: app-wide services
├─ routes/              ← Enhance: prepare for go_router migration
└─ core/                ← Keep: errors, env, utils
```

**Key Improvements:**
- Remove `styles/` duplicate → consolidate into `shared/themes/`
- Complete DI coverage → all features have fake→real switching
- Clean presentation boundaries → no Supabase in presentation/
- Systematic tokenization → eliminate hardcoded values in components

---

## Guideline Compliance Audit

| Severity | Location | Rule Violated | Why It Matters | Suggested Fix |
|----------|----------|---------------|----------------|---------------|
| **Blocker** | `lib/features/auth/presentation/pages/auth_page.dart:41` | Direct Supabase in presentation | Breaks Clean Architecture, tight coupling | Move to repository pattern via providers |
| **Blocker** | `lib/features/auth/presentation/pages/finish_setup.dart:49` | Direct Supabase in presentation | Bypasses domain layer, testing impossible | Create repository + provider injection |
| **Blocker** | `lib/features/auth/presentation/widgets/finish_auth/profile_avatar.dart:81` | Direct Supabase storage | Presentation calling data directly | Move to repository method |
| **High** | `lib/styles/app_styles.dart:1-74` | Duplicate token system | Inconsistent theming, maintenance burden | Migrate to shared/themes/ and delete |
| **High** | `lib/shared/components/cards/pending_event_expanded_card.dart:103-104` | Hardcoded dimensions `width: 32, height: 32` | Not tokenized, accessibility issues | Use tokens: `Gaps.xl` or responsive sizing |
| **High** | `lib/shared/components/inputs/inputBox.dart:33` | Hardcoded height `height: 48` | Fixed sizing, not responsive | Use tokens and intrinsic sizing |
| **High** | `lib/main.dart:38-47` | Incomplete DI coverage | Only 2/6 features have overrides | Add overrides for groups, profile, activities, auth |
| **Med** | `test/features/profile/photo_removal_test.dart:1` | Empty test file | No test coverage | Implement or remove empty file |
| **Med** | `lib/shared/components/widgets/grabber_bar.dart:12-13` | Hardcoded dimensions | Not tokenized | Use `Gaps.xs` for consistency |
| **Low** | `lib/features/auth/presentation/providers/auth_provider.dart:2` | Supabase import in provider | Should inject via constructor | Accept repository in constructor |

---

## Refactor Plan (Incremental PRs)

### PR 1: Eliminate Duplicate Token System
**Scope:** Remove `styles/app_styles.dart`, migrate all references to `shared/themes/colors.dart`  
**Files to touch:**
- Delete: `lib/styles/app_styles.dart`
- Update: All files importing `app_styles.dart` → use `BrandColors` and `AppText`
- Verify: No `AppColors.background1` references remain

**Acceptance Criteria:**
- Single source of truth for colors in `shared/themes/colors.dart`
- All hardcoded `Color(0xFF...)` uses tokens
- No compilation errors after migration

**Estimated Effort:** 4 hours  
**Risk:** Medium (widespread changes)  
**Commit:** `refactor: consolidate token system, remove duplicate styles/`

### PR 2: Fix Auth Presentation Layer Violations
**Scope:** Remove direct Supabase calls from auth presentation layer  
**Files to touch:**
- `features/auth/presentation/pages/auth_page.dart` → use AuthProvider
- `features/auth/presentation/pages/finish_setup.dart` → inject repository
- `features/auth/presentation/widgets/finish_auth/profile_avatar.dart` → use storage service
- `features/auth/presentation/providers/auth_provider.dart` → constructor injection
- `main.dart` → add auth repository override

**Acceptance Criteria:**
- No `Supabase.instance.client` in presentation/
- Auth flows work through providers/repositories only
- Unit tests can mock dependencies

**Estimated Effort:** 6 hours  
**Risk:** High (auth is critical path)  
**Commit:** `fix: enforce clean architecture in auth presentation layer`

### PR 3: Complete DI Coverage for All Features
**Scope:** Add missing provider overrides in main.dart  
**Files to touch:**
- `main.dart` → add overrides for groups, profile, activities, auth
- Verify each feature has: fake repo, real repo impl, provider definition

**Acceptance Criteria:**
- All 6 features can switch fake→real via DI override
- Development still uses fakes by default
- Production overrides to Supabase implementations

**Estimated Effort:** 3 hours  
**Risk:** Low (additive changes)  
**Commit:** `feat: complete dependency injection setup for all features`

### PR 4: Tokenize Shared Components
**Scope:** Remove hardcoded dimensions from shared components  
**Files to touch:**
- `shared/components/cards/pending_event_expanded_card.dart`
- `shared/components/inputs/inputBox.dart` 
- `shared/components/widgets/grabber_bar.dart`
- Add responsive sizing constants to `shared/constants/spacing.dart` if needed

**Acceptance Criteria:**
- No hardcoded `width:`, `height:` in shared components
- Components use tokens from `Gaps`, `Insets`, or responsive sizing
- Accessibility touch targets maintained (min 44x44)

**Estimated Effort:** 4 hours  
**Risk:** Low (isolated changes)  
**Commit:** `refactor: tokenize dimensions in shared components`

### PR 5: Clean Up Test Structure
**Scope:** Remove empty test files, organize test structure  
**Files to touch:**
- Delete: `test/features/profile/photo_removal_test.dart` (empty)
- Create: Consistent test coverage plan
- Update: Test bootstrap to support all feature mocking

**Acceptance Criteria:**
- No empty test files
- Clear test organization (unit/ widget/ integration/)
- Test helper utilities for common mocking patterns

**Estimated Effort:** 2 hours  
**Risk:** Low (test infrastructure)  
**Commit:** `test: clean up test structure and remove empty files`

---

## Security & Privacy Audit

### RLS Coverage Assessment
**Priority: HIGH**

Current state: Unknown RLS coverage across all tables
- ✅ Auth flow uses proper Supabase auth context
- ⚠️  No systematic RLS verification in repositories
- ❌ No audit framework for RLS compliance

**Recommendations:**
1. Create RLS audit checklist for each repository method
2. Add RLS verification tests in integration test suite
3. Document RLS policies for each feature's data access patterns
4. Add RLS violation detection in CI/CD pipeline

### Auth Flow Security
**Priority: MEDIUM**

Current state: Mixed implementation quality
- ✅ PKCE flow properly configured in main.dart
- ⚠️  Some auth pages bypass repository pattern (security testing gaps)
- ✅ No admin keys in app code
- ✅ Secrets properly managed via env

**Recommendations:**
1. Complete auth repository pattern implementation (PR 2)
2. Add auth flow integration tests with security assertions
3. Implement session timeout handling
4. Add rate limiting awareness in auth error handling

### Data Protection & Privacy
**Priority: MEDIUM**

**Actionable Steps:**
1. **PII Handling:** Audit storage paths for PII leakage in file names
2. **GDPR Readiness:** Implement user data export/delete endpoints
3. **Logging:** Ensure no sensitive data in logs/telemetry
4. **Input Validation:** Server-side validation for all user inputs
5. **Storage Policies:** Review file upload policies and size limits

---

## Performance & Reliability

### State Management Optimization
**Current Assessment:** Good foundation with Riverpod

**Optimizations:**
- ✅ Appropriate state granularity observed
- ⚠️  Some widgets could benefit from `const` constructors
- ✅ AsyncValue pattern properly used for loading states
- ⚠️  No systematic rebuild analysis

**Action Items:**
1. Add `const` to all shared components where possible
2. Implement selective rebuilds with Riverpod selectors for complex states
3. Add performance monitoring for provider rebuilds

### Supabase Query Optimization
**Current Assessment:** Need systematic review

**Priority Actions:**
1. **Index Compliance:** Audit all queries for proper index usage
2. **Query Shape:** Ensure `select` only needed columns (domain entity fields)
3. **Pagination:** Implement consistent pagination patterns
4. **Connection Pooling:** Review connection management in data sources

### Image & Asset Management
**Action Items:**
1. Implement image compression for uploads
2. Add progressive loading for image components
3. Cache strategy for frequently accessed assets
4. Offline queue for failed uploads with retry logic

---

## Testing & CI/CD Strategy

### Targeted Testing Plan

**Unit Tests (Domain Layer)**
- Target: All use cases and entities
- Pattern: AAA (Arrange-Act-Assert) with fake repositories
- Coverage: Business logic validation, error cases
- Files: `test/unit_tests/<feature>_usecase_test.dart`

**Widget Tests (Shared Components)**
- Target: All components in `shared/components/`
- Pattern: Golden tests for visual regression
- Coverage: Props variation, state changes, accessibility
- Files: `test/widget_tests/components/<component>_test.dart`

**Integration Tests (Critical Flows)**
- Target: Auth flow, event creation, core user journeys
- Pattern: Full app context with mocked Supabase
- Coverage: End-to-end scenarios, error recovery
- Files: `test/integration_tests/<flow>_test.dart`

### CI/CD Enhancement
**Current:** Basic CI in `.github/workflows/ci-dev.yml`

**Additions Needed:**
```yaml
- name: Analyze
  run: flutter analyze
- name: Format Check
  run: dart format --set-exit-if-changed .
- name: Test
  run: flutter test --coverage
- name: Build
  run: flutter build apk --debug
```

### Lint Rules for Architecture Enforcement
**Add to `analysis_options.yaml`:**
```yaml
linter:
  rules:
    # Token enforcement
    avoid_hardcoded_color: true
    avoid_hardcoded_text_style: true
    
    # Architecture enforcement
    depend_on_referenced_packages: true
    avoid_relative_lib_imports: true
    
    # Performance
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
```

---

## Navigation Strategy

### Current State: Navigator 1.0
**Assessment:** Adequate for current complexity, but showing limitations

**Strengths:**
- Simple named route structure
- Clean route definitions in `AppRouter`
- Proper argument passing patterns

**Limitations:**
- No deep linking support
- Complex nested navigation difficult
- No route guards/middleware
- URL generation not supported

### Migration to go_router (Future)
**Recommended Timeline:** After core architecture issues resolved (PR 6+)

**Migration Plan:**
1. **Phase 1:** Add go_router alongside Navigator 1.0
2. **Phase 2:** Migrate simple routes (no arguments)  
3. **Phase 3:** Migrate complex routes with arguments
4. **Phase 4:** Remove Navigator 1.0 dependencies

**When it's worth it:**
- ✅ When implementing deep linking
- ✅ When adding web support  
- ✅ When auth guards become complex
- ✅ When nested tab navigation is needed

**Risk Assessment:** Low risk if done incrementally after architecture stabilization

---

## Guidelines Delta (Patches)

### README.md Updates
```diff
## Feature Development Flow (2 roles)
**Goal:** UI works with fake data first, then flips to Supabase without touching widgets.

### Role P1 — UI + State + Contracts
1) Define **Domain contracts**
   - `features/<f>/domain/entities/…` → minimal fields UI needs.
+  - `features/<f>/domain/repositories/…` → interface methods (no implementations).
   - `features/<f>/domain/usecases/…` → one action per class.
2) Build **UI components** in `shared/components/…` (tokenized, stateless, reusable).
3) Compose screens in `features/<f>/presentation/pages/…` using shared components.
4) Create **providers** in `features/<f>/presentation/providers/…`
   - Default DI points to **fakes** (see below).
   - Expose `AsyncValue` for loading/error/success.
+  - **Never import Supabase directly** in presentation layer.
5) Put **fakes** in `features/<f>/data/fakes/…` implementing repo interfaces (return mock data).

### Role P2 — Data + Supabase
1) Implement **data source** in `features/<f>/data/data_sources/…` (Supabase queries only; respect RLS; select minimal columns; indexes friendly `order + limit`).
2) Map rows to **models/DTO** in `features/<f>/data/models/…` (parse, defaults, toEntity()).
3) Implement **repository** in `features/<f>/data/repositories/…` (bridge model → entity, normalize errors).
4) **Dependency Injection** override
   - In `main.dart` (ProviderScope overrides), swap `FakeRepository → RepositoryImpl(Supabase…)`.
+  - **All features must have DI overrides**, not just some.
   - No UI changes needed.
```

```diff
## Design System (tokens)
**Single source of truth** for colors/spacing/typography. All UI must use tokens (no hex/inline sizes except micro 1–2px optical fixes).
- `shared/themes/colors.dart` → Brand colors & dark colorScheme
- `shared/constants/spacing.dart` → Insets, Gaps, Radii, Pads
- `shared/constants/text_styles.dart` → labelLarge, titleMediumEmph, bodyMedium, etc.
- `shared/themes/app_theme.dart` → ThemeData (Material 3, dark‑only MVP)
+ **Critical:** Never create duplicate token systems (e.g., `styles/app_styles.dart`). Use only `shared/themes/` and `shared/constants/`.
- Reusable UI goes in `shared/components/` (cards/, sections/, nav/, ctas/, forms/)
```

```diff
## Data & Supabase Guidelines
- Respect **RLS** in queries; never bypass with admin keys in app.
+ Audit **RLS coverage** systematically; use integration tests to verify policies.
+ Never call Supabase directly from presentation layer; use repository pattern.
- Select **only** columns required by the entity/use case.
- Use indexes: e.g., `order('created_at', ascending: false).limit(1)` on indexed columns.
- Storage paths convention: `/groupId/eventId/userId/uuid.jpg` with metadata (uploader, type, ts).
```

```diff
## Quality Checklist (Before PR)
+ **Architecture Boundaries:**
+ - [ ] No Supabase imports in `features/*/presentation/` or `features/*/domain/`
+ - [ ] All hardcoded colors use tokens from `shared/themes/colors.dart`
+ - [ ] All hardcoded dimensions use tokens from `shared/constants/spacing.dart`
+ - [ ] Shared components are stateless and reusable
+ - [ ] Feature has both fake and real repository implementations
+ - [ ] DI override exists in `main.dart` for the feature
+ 
+ **Code Quality:**
+ - [ ] `const` constructors where possible
+ - [ ] Proper error handling with `AsyncValue`
+ - [ ] No TODO/FIXME comments without GitHub issues
+ - [ ] Tests cover new functionality (unit for domain, widget for UI)
```

### AGENTS.md Updates  
```diff
## 1) Golden Rules
- **Tokenize first**: replace all colors/sizes/fonts/radii with tokens from `shared/constants` & `shared/themes`.
+ **Single source rule**: Only use `shared/themes/colors.dart` and `shared/constants/`. Never create `styles/`, `theme/`, or other token files.
- **No infra in Domain**: Domain must have **no** imports from Flutter/Supabase.
- **Presentation ≠ Data**: Widgets do not call Supabase; they consume **providers/use cases**.
+ **Complete DI coverage**: Every feature must have provider overrides in `main.dart`. No partial implementations.
- **Fake-first**: default DI wires **fake repositories**. A single override flips to Supabase.
- **Stateless Shared**: All `shared/components/*` must be stateless and reusable.
- **Minimal queries**: Data layer selects only columns needed by **entities**.
```

```diff
## 8) Quality Gates (PR checklist)
- Uses tokens (no hex/magic numbers; micro 1–2px allowed if necessary).
- Stateless, reusable components in `shared/components/`.
- `AsyncValue` covers loading/empty/error in pages.
- Domain has no Flutter/Supabase imports.
- Data layer selects minimal columns and respects RLS.
- One responsibility per use case.
- Small PRs; clear filenames; feature‑scoped changes.
+ **New mandatory checks:**
+ - No direct Supabase calls in presentation layer (use repositories only).
+ - All shared components use tokens (zero hardcoded dimensions/colors).
+ - Feature has complete DI setup (fake repo, real repo, provider override).
+ - `const` constructors added where possible for performance.
+ - Empty or TODO-only files are removed or implemented.
```

```diff
## 11) What Agents Must Avoid
- Editing UI with hardcoded hex/px not backed by tokens.
- Importing Supabase or Flutter into `domain/`.
- Calling Supabase directly from widgets/pages/providers.
- Duplicating shared components inside features.
- Modifying repository interfaces without syncing owners.
+ **Critical violations that break architecture:**
+ - Creating duplicate token systems (e.g., `styles/app_styles.dart` when `shared/themes/` exists).
+ - Skipping DI overrides in `main.dart` (leaving features stuck on fake data).
+ - Using `Supabase.instance.client` anywhere in presentation layer.
+ - Hardcoding dimensions in shared components (breaks responsive design).
+ - Leaving empty test files or unimplemented TODOs in production code.
```

```diff
## 13) Emergency Debugging (New Section)
**When things break during refactoring:**

+ **"Token not found" errors:**
+ - Check if you're importing from `shared/themes/colors.dart` not `styles/app_styles.dart`
+ - Verify token exists in `BrandColors` or `colorScheme`
+ 
+ **"Provider not found" errors:**
+ - Check `main.dart` ProviderScope overrides list
+ - Verify feature has both fake and real repository providers
+ 
+ **"Auth/Supabase errors" in presentation:**
+ - Never call `Supabase.instance.client` in presentation/
+ - Use repository pattern: widget → provider → use case → repository → data source
+ 
+ **"UI looks wrong" after tokenization:**
+ - Check responsive vs fixed sizing decisions
+ - Verify accessibility touch targets (min 44x44)
+ - Use `Expanded`/`Flexible` instead of fixed widths
```

### Architecture Enforcement (New Section for Both Guides)

**Automated Checks:**
```yaml
# Add to analysis_options.yaml
linter:
  rules:
    # Prevent architectural violations
    depend_on_referenced_packages: true
    avoid_relative_lib_imports: true
    
    # Enforce performance
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    
    # Prevent hardcoding (if custom rules available)
    # avoid_hardcoded_color: true
    # avoid_hardcoded_text_style: true
```

**Manual Review Checklist:**
- [ ] `git grep "Supabase.instance" -- lib/features/*/presentation/` returns empty
- [ ] `git grep "Color(0x" -- lib/shared/components/` returns empty  
- [ ] `git grep "styles/app_styles" -- lib/` returns empty
- [ ] All features have entries in `main.dart` ProviderScope overrides

---

## Risks & Open Questions

### High-Risk Areas
1. **Auth Flow Changes:** Critical path modifications could break user onboarding
2. **Token Migration:** Widespread style changes could introduce visual regressions  
3. **DI Overrides:** Incorrect repository wiring could cause runtime failures

### Technical Decisions Requiring Input
1. **Token Values:** Should hardcoded dimensions be responsive (MediaQuery) or fixed tokens?
2. **Test Coverage:** What's the minimum acceptable coverage percentage for each layer?
3. **Migration Timeline:** Should auth fixes block other feature development?

### Architecture Decision Record (ADR) Template
```markdown
# ADR-XXX: [Decision Title]

## Status
[Proposed | Accepted | Rejected | Superseded]

## Context
[What forces are driving this decision?]

## Decision
[What is the change that we're making?]

## Consequences
[What becomes easier or more difficult?]

## Implementation Plan
[Concrete steps and timeline]
```

### Open Questions for Stakeholder Input
1. **Performance Budget:** What are acceptable load times for auth/home screens?
2. **Offline Support:** Should the app work without internet connectivity?
3. **Accessibility:** What WCAG level compliance is required?
4. **Internationalization:** Beyond EN/PT, what locales are planned?
5. **Platform Parity:** Should iOS/Android features be identical?

---

**Review Completion:** This audit covers all major architectural concerns. Implement PRs 1-2 as highest priority to establish clean boundaries, then proceed with remaining optimizations based on feature development velocity and stakeholder priorities.