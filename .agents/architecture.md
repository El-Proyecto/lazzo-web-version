# Architecture

**Repository:** lazzo-web-version.

*Quick reference: repo layout, folder roles, navigation, lint enforcement, widget migration (move/replace, import paths, checklist).*

## Repository layout

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

For database schema and Supabase documentation, see [database.md](database.md).

## Responsibilities by folder

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

## Navigation

- Router: `routes/AppRouter` (Navigator 1.0 named routes).
- For previews, set `initialRoute` to target page.
- If nested tabs/guards become complex, consider `go_router` migration later.

## Architecture enforcement

**Automated checks**

Lint rules are configured in `analysis_options.yaml` to enforce:

- Architecture violations prevention (`depend_on_referenced_packages`, `avoid_relative_lib_imports`)
- Performance best practices (`prefer_const_constructors`, `prefer_const_literals_to_create_immutables`)
- Code quality standards (`prefer_single_quotes`, `avoid_unnecessary_containers`)

**Manual review checklist**

- [ ] `git grep "Supabase.instance" -- lib/features/*/presentation/` returns empty
- [ ] `git grep "Color(0x" -- lib/shared/components/` returns empty
- [ ] `git grep "styles/app_styles" -- lib/` returns empty
- [ ] All features have entries in `main.dart` ProviderScope overrides

## Widget migration & management

**CRITICAL RULE: Never delete widgets during migration - always move or replace them.**

### Widget organization principles

- **Shared components** (`shared/components/`): Only truly reusable UI that's used across 3+ features
- **Feature widgets** (`features/*/presentation/widgets/`): Components specific to one feature
- **Generic replacements**: Create unified components to replace multiple similar widgets

### Safe widget migration process

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

### Import path patterns

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

### Component movement checklist

Before moving any widget file:

- [ ] Search all imports: `git grep "filename.dart"`
- [ ] List all consuming files
- [ ] Plan import path updates
- [ ] Move file to new location
- [ ] Update ALL import paths immediately
- [ ] Run `flutter analyze` to verify no broken imports
- [ ] Update export files (`components.dart`, feature exports)
- [ ] Test app compilation and basic functionality

### Forbidden operations

- **NEVER** delete widgets without ensuring they're replaced or moved
- **NEVER** move widgets without updating import paths immediately
- **NEVER** leave broken import paths "to fix later"
- **NEVER** create duplicate widgets in different locations
- **NEVER** move shared design tokens (colors, spacing, text_styles)

### Recovery from broken migration

If widgets are missing or imports broken:

1. Check git history: `git log --oneline --name-only`
2. Find moved files: `find lib/ -name "*widget_name*"`
3. Search for broken imports: `flutter analyze | grep "Target of URI doesn't exist"`
4. Fix import paths systematically, feature by feature
5. Verify each fix with `flutter analyze`

### Widget architecture rules

- **Generic widgets** (3+ usages): `shared/components/category/generic_name.dart`
- **Feature widgets** (1-2 usages): `features/feature_name/presentation/widgets/specific_name.dart`
- **Replacement strategy**: Create generic first, migrate consumers, remove specifics
- **Import consistency**: Use absolute paths from lib/ root for clarity
- **Export management**: Keep `shared/components/components.dart` updated with only shared exports
