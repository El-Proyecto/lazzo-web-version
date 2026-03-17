# Coding rules

**Repository:** lazzo-web-version.

*Quick reference: golden rules, tokens/theme, quality gates, naming, avoid list, bootstrapping.*

## Golden rules

- **Tokenize first**: replace all colors/sizes/fonts/radii with tokens from `shared/constants` & `shared/themes`.
- **Single source rule**: Only use `shared/themes/colors.dart` and `shared/constants/`. Never create `styles/`, `theme/`, or other token files.
- **No infra in Domain**: Domain must have **no** imports from Flutter/Supabase.
- **Presentation ≠ Data**: Widgets do not call Supabase; they consume **providers/use cases**.
- **Complete DI coverage**: Every feature must have provider overrides in `main.dart`. No partial implementations.
- **Fake-first**: default DI wires **fake repositories**. A single override flips to Supabase.
- **Stateless Shared**: All `shared/components/*` must be stateless and reusable.
- **Minimal queries**: Data layer selects only columns needed by **entities**.

## Tokens & theme (source of truth)

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

## Quality gates (PR checklist)

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
- **All `print()` debug statements removed** - run `./scripts/clean_prints.sh` before merge.

## Naming & conventions

- Components: `SomethingCard`, `SectionHeader`, `ModeNavBar`, `CreateEventCta`.
- Providers: `somethingControllerProvider`, `somethingRepositoryProvider`.
- Use cases: verb-first `GetLastMemory`, `CreateEvent`, `VoteOnPoll`.
- Files are **snake_case**; classes are **PascalCase**.

## What agents must avoid

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

## Bootstrapping & running

- Theme: dark-only via `shared/themes/app_theme.dart`.
- Router: named routes; set `initialRoute` to preview target page.
- Start: `flutter pub get && flutter run`.
- Supabase env: initialize in `main.dart`; DI override to use real repositories.

### Required analyzers (before opening a PR)

- **Always run** `flutter analyze` at the project root (`lazzo-web-version`) after any code change.
- Do not ignore any warnings or errors introduced by your changes; fix them before opening a PR.
