# Architecture Fixes - TODO List

**Status Legend:** 🔴 Blocker | 🟡 High Priority | 🟢 Medium Priority | ⚪ Low Priority  
**Progress:** ❌ Not Started | 🟦 In Progress | ✅ Complete

---

## Critical Path (Must Fix First)

### 🔴 PR 1: Eliminate Duplicate Token System
**Status:** ❌ Not Started  
**Effort:** 4 hours | **Risk:** Medium  
**Dependencies:** None

**Files to modify:**
- [ ] Delete `lib/styles/app_styles.dart`
- [ ] Find all imports: `git grep -l "styles/app_styles" lib/`
- [ ] Replace `AppColors.background1` → `BrandColors.bg1`
- [ ] Replace `AppColors.text1` → `BrandColors.text1`
- [ ] Replace `AppTextStyles.*` → `AppText.*`
- [ ] Verify no compilation errors

**Acceptance Criteria:**
- [ ] Single source of truth for colors in `shared/themes/colors.dart`
- [ ] All hardcoded `Color(0xFF...)` uses tokens
- [ ] No `styles/app_styles` imports remain
- [ ] App builds and runs without errors

**Commit:** `refactor: consolidate token system, remove duplicate styles/`

---

### 🔴 PR 2: Fix Auth Presentation Layer Violations
**Status:** ❌ Not Started  
**Effort:** 6 hours | **Risk:** High (auth is critical)  
**Dependencies:** PR 1 complete

**Files to modify:**
- [ ] `features/auth/presentation/pages/auth_page.dart:41`
  - Remove `Supabase.instance.client.auth.onAuthStateChange`
  - Use AuthProvider methods instead
- [ ] `features/auth/presentation/pages/finish_setup.dart:49`
  - Remove direct `Supabase.instance.client` usage
  - Inject repository via provider
- [ ] `features/auth/presentation/widgets/finish_auth/profile_avatar.dart:81`
  - Remove `Supabase.instance.client.storage.from()`
  - Move to storage service or repository method
- [ ] `features/auth/presentation/providers/auth_provider.dart:2`
  - Remove direct Supabase import
  - Accept repository in constructor
- [ ] `main.dart` - Add auth repository override

**Acceptance Criteria:**
- [ ] No `Supabase.instance.client` in presentation layer
- [ ] Auth flows work through providers/repositories only
- [ ] Can mock auth dependencies in tests
- [ ] User login/signup still works

**Commit:** `fix: enforce clean architecture in auth presentation layer`

---

### 🟡 PR 3: Complete DI Coverage for All Features
**Status:** ❌ Not Started  
**Effort:** 3 hours | **Risk:** Low  
**Dependencies:** PR 2 complete

**Missing DI overrides in main.dart:**
- [ ] Groups feature
  - Check for `groupsRepositoryProvider`
  - Add override in `ProviderScope(overrides: [])`
- [ ] Profile feature  
  - Check for `profileRepositoryProvider`
  - Add override in `ProviderScope(overrides: [])`
- [ ] Activities feature
  - Check for `activitiesRepositoryProvider`  
  - Add override in `ProviderScope(overrides: [])`
- [ ] Auth feature (from PR 2)
  - Check for `authRepositoryProvider`
  - Add override in `ProviderScope(overrides: [])`

**Acceptance Criteria:**
- [ ] All 6 features can switch fake→real via DI override
- [ ] Development still uses fakes by default  
- [ ] Production overrides to Supabase implementations
- [ ] No runtime errors when switching providers

**Commit:** `feat: complete dependency injection setup for all features`

---

## UI/UX Improvements

### 🟡 PR 4: Tokenize Shared Components  
**Status:** ❌ Not Started  
**Effort:** 4 hours | **Risk:** Low

**Components with hardcoded dimensions:**
- [ ] `shared/components/cards/pending_event_expanded_card.dart:103-104`
  - Replace `width: 32, height: 32` → `Size.square(Gaps.xl)`
- [ ] `shared/components/inputs/inputBox.dart:33`
  - Replace `height: 48` → use intrinsic sizing or token
- [ ] `shared/components/widgets/grabber_bar.dart:12-13`
  - Replace `width: 36, height: 4` → `Gaps.xl`, `Gaps.xxs`

**Add to spacing.dart if needed:**
- [ ] Icon sizes: `IconSizes.sm = 16, md = 24, lg = 32`
- [ ] Touch targets: `TouchTargets.min = 44`

**Acceptance Criteria:**
- [ ] No hardcoded `width:`, `height:` in shared components
- [ ] Components use tokens from `Gaps`, `Insets`, or responsive sizing
- [ ] Accessibility touch targets maintained (min 44x44)
- [ ] Visual appearance unchanged

**Commit:** `refactor: tokenize dimensions in shared components`

---

### 🟢 PR 5: Clean Up Test Structure
**Status:** ❌ Not Started  
**Effort:** 2 hours | **Risk:** Low

**Files to clean up:**
- [ ] Delete `test/features/profile/photo_removal_test.dart` (empty file)
- [ ] Audit for other empty test files: `find test/ -name "*.dart" -empty`
- [ ] Create test organization:
  - `test/unit_tests/<feature>/` for domain tests
  - `test/widget_tests/components/` for shared component tests
  - `test/integration_tests/` for end-to-end flows

**Test utilities to create:**
- [ ] `test/helpers/mock_repositories.dart` - Common mocks
- [ ] `test/helpers/test_app_wrapper.dart` - Wrapper with providers
- [ ] `test/helpers/golden_test_helper.dart` - Golden test utilities

**Acceptance Criteria:**
- [ ] No empty test files exist
- [ ] Clear test organization structure
- [ ] Test helper utilities for common patterns
- [ ] All tests still pass

**Commit:** `test: clean up test structure and remove empty files`

---

## Performance Optimizations

### 🟢 Add const Constructors
**Status:** ❌ Not Started  
**Effort:** 2 hours | **Risk:** Low

**Audit and fix:**
- [ ] All widgets in `shared/components/` have `const` constructors where possible
- [ ] Use `const` for all `TextStyle`, `EdgeInsets`, `Color` declarations
- [ ] Add `const` to widget instantiations in build methods

**Tools to use:**
- [ ] `flutter analyze` should show recommendations
- [ ] Add `prefer_const_constructors` lint rule
- [ ] Search: `git grep -n "new " lib/` (should return empty)

---

### 🟢 Optimize Riverpod Providers
**Status:** ❌ Not Started  
**Effort:** 3 hours | **Risk:** Low

**Review and optimize:**
- [ ] Use `select` for granular state subscriptions
- [ ] Add `autoDispose` where appropriate  
- [ ] Consider `family` providers for parameterized data
- [ ] Profile rebuild frequency in dev mode

---

## Security & Privacy

### 🟡 RLS Audit Framework
**Status:** ❌ Not Started  
**Effort:** 4 hours | **Risk:** Medium

**Create systematic RLS verification:**
- [ ] Document RLS policies for each feature
- [ ] Add integration tests that verify RLS enforcement
- [ ] Create checklist for each repository method
- [ ] Add RLS violation detection in CI/CD

**Files to create:**
- [ ] `docs/SECURITY_RLS_POLICIES.md`
- [ ] `test/integration_tests/rls_verification_test.dart`

---

### 🟢 Input Validation Audit
**Status:** ❌ Not Started  
**Effort:** 2 hours | **Risk:** Low

**Verify server-side validation:**
- [ ] All user inputs validated on Supabase side
- [ ] File upload size limits enforced
- [ ] XSS prevention in text inputs
- [ ] SQL injection prevention (using parameterized queries)

---

## Monitoring & Observability

### 🟢 Add Performance Monitoring
**Status:** ❌ Not Started  
**Effort:** 3 hours | **Risk:** Low

**Implement tracking:**
- [ ] Provider rebuild frequency
- [ ] Screen load times  
- [ ] Network request durations
- [ ] Error rates by feature

**Tools to integrate:**
- [ ] Firebase Performance (if using Firebase)
- [ ] Custom analytics for critical user flows

---

## Notes

**Priority Order:**
1. Complete PRs 1-3 (Critical Path) before other feature work
2. PRs 4-5 can be done in parallel with feature development
3. Performance and security items are ongoing improvements

**Testing Strategy:**
- Unit tests for each repository implementation
- Widget tests for shared components after tokenization  
- Integration tests for critical auth and event creation flows

**Risk Mitigation:**
- PR 2 (Auth changes) should be tested thoroughly on staging
- Have rollback plan for token system changes
- Consider feature flags for major provider changes