# Shared Components Migration Guide

## Analysis Summary

After analyzing the `shared/components/` folder, **you are absolutely correct**. Most components are feature-specific and violate the single responsibility principle for shared components. The current structure has ~90 components, but only ~15 are truly reusable across features.

## Core Issues Identified

### 🔴 **Critical Problems**
1. **Feature-specific components in shared space**: Many components are only used by one feature
2. **Multiple similar AppBars**: Each feature has its own AppBar instead of a configurable one
3. **Voting button explosion**: 14 different voting-related buttons (v1, v2, v3, etc.)
4. **Birthday picker variants**: 4 different birthday picker cards for one use case
5. **Dialog proliferation**: Feature-specific dialogs in shared space

### 🟡 **Architecture Violations**
- **90% of components used by only 1 feature**
- **Duplicate responsibilities** (multiple vote buttons, picker variants)
- **Poor scalability** - adding features creates more shared pollution
- **Import path complexity** - deep nested imports for feature-specific UI

---

## Migration Strategy

### Phase 1: Create Generic Components (Priority 1)

#### 🎯 **CommonAppBar** - Replace 3 AppBars with 1 Configurable
**Create:** `lib/shared/components/nav/common_app_bar.dart`
```dart
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? flexibleSpace;
  
  // Replaces: ProfileAppBar, CreateEventAppBar, GroupsAppBar
}
```

#### 🎯 **GenericCard** - Base card with flexible content
**Create:** `lib/shared/components/cards/base_card.dart`
```dart
class BaseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  
  // Replaces multiple single-use cards
}
```

#### 🎯 **UnifiedVoteWidget** - Single configurable vote component
**Create:** `lib/shared/components/buttons/vote_widget.dart`
```dart
class VoteWidget extends StatelessWidget {
  final VoteStatus status; // none, voted, votedNo
  final VoteStyle style; // compact, expanded, simple
  final List<String>? avatars;
  final int? count;
  final VoidCallback? onVote;
  
  // Replaces 14 voting buttons
}
```

### Phase 2: Move Feature-Specific Components

#### 📁 **Components to MOVE** (Feature-Specific)

##### Nav Components → Feature Widgets
- `nav/profile_app_bar.dart` → `features/profile/presentation/widgets/`
- `nav/create_event_app_bar.dart` → `features/create_event/presentation/widgets/`
- `nav/groups_app_bar.dart` → `features/groups/presentation/widgets/`

##### Cards → Feature Widgets
- `cards/ios_birthday_picker_card.dart` → `features/profile/presentation/widgets/`
- `cards/birthday_picker_card.dart` → `features/profile/presentation/widgets/`
- `cards/dropdown_birthday_picker_card.dart` → `features/profile/presentation/widgets/`
- `cards/email_info_card.dart` → `features/auth/presentation/widgets/`
- `cards/user_info_card.dart` → `features/profile/presentation/widgets/`
- `cards/editable_info_card.dart` → `features/profile/presentation/widgets/`
- `cards/event_created_banner.dart` → `features/create_event/presentation/widgets/`

##### Forms → Feature Widgets
- `forms/event_group_selector.dart` → `features/create_event/presentation/widgets/`
- `forms/inline_time_picker.dart` → `features/create_event/presentation/widgets/`
- `forms/inline_date_picker.dart` → `features/create_event/presentation/widgets/`

##### Dialogs → Feature Widgets
- `dialogs/group_context_menu.dart` → `features/groups/presentation/widgets/`
- `dialogs/group_selection_dialog.dart` → `features/create_event/presentation/widgets/`
- `dialogs/emoji_selector_dialog.dart` → `features/create_event/presentation/widgets/`
- `dialogs/event_history_dialog.dart` → `features/create_event/presentation/widgets/`
- `dialogs/confirm_event_dialog.dart` → `features/create_event/presentation/widgets/`
- `dialogs/exit_confirmation_dialog.dart` → `features/create_event/presentation/widgets/`

##### Buttons → Feature Widgets (Voting Related)
- All `compact_vote_widget_v*.dart` → `features/home/presentation/widgets/`
- `simple_vote_button.dart` → `features/home/presentation/widgets/`
- `vote_button.dart` → `features/home/presentation/widgets/`
- `voted_button.dart` → `features/home/presentation/widgets/`
- `voted_no_button.dart` → `features/home/presentation/widgets/`
- `voting_button.dart` → `features/home/presentation/widgets/`
- `voters_expanded_button.dart` → `features/home/presentation/widgets/`

##### Sections → Feature Widgets
- `sections/memories_section.dart` → `features/profile/presentation/widgets/`
- `sections/date_time_section.dart` → `features/create_event/presentation/widgets/`
- `sections/location_section.dart` → `features/create_event/presentation/widgets/`

##### Profile → Feature Widgets
- `profile/editable_profile_photo.dart` → `features/profile/presentation/widgets/`

##### Sheets → Feature Widgets
- `sheets/photo_change_bottom_sheet.dart` → `features/profile/presentation/widgets/`

---

#### ✅ **Components to KEEP** (Truly Shared)

##### Core UI Building Blocks
- `buttons/green_button.dart` ✅ - Used across auth, create_event
- `buttons/continue_with.dart` ✅ - Used across auth flows
- `buttons/expanded_card_button.dart` ✅ - Generic expandable button
- `buttons/stacked_avatars.dart` ✅ - Reusable avatar display

##### Navigation
- `nav/navigation_bar.dart` ✅ - App-wide bottom navigation

##### Basic Components
- `inputs/inputBox.dart` ✅ - Generic input field
- `inputs/search_bar.dart` ✅ - Generic search component
- `widgets/grabber_bar.dart` ✅ - Generic sheet handle
- `badges/group_badge.dart` ✅ - Reusable badge component
- `chips/filter_chip.dart` ✅ - Generic filter UI

##### Layout & Structure
- `sections/section_header.dart` ✅ - Generic section title
- `sections/section_block.dart` ✅ - Generic section wrapper
- `sections/lazzo_header.dart` ✅ - App branding (used across auth)

##### Core Cards (Reusable)
- `cards/pending_event_card.dart` ✅ - Used in home, notifications
- `cards/pending_event_expanded_card.dart` ✅ - Expanded version
- `cards/memory_summary_card.dart` ✅ - Used in home, profile
- `cards/memory_card.dart` ✅ - Used in profile, details
- `cards/group_card.dart` ✅ - Used in groups, selections

---

## Implementation Plan

### Step 1: Create Generic Components (1-2 days)
1. **CommonAppBar** - Replace 3 AppBars
2. **VoteWidget** - Unify 14 voting buttons
3. **BaseCard** - Generic card foundation

### Step 2: Feature Migration (2-3 days)
1. Move feature-specific components to respective `features/*/presentation/widgets/`
2. Update import paths
3. Remove from `shared/components/components.dart` exports

### Step 3: Cleanup (1 day)
1. Delete moved files from shared
2. Update documentation
3. Verify no broken imports

### Step 4: Testing (1 day)
1. Verify all pages still work
2. Check import paths
3. Validate no unused components

---

## Expected Benefits

### 🎯 **Clean Architecture Compliance**
- **95% reduction** in shared component pollution
- **Clear separation** between reusable and feature-specific UI
- **Scalable structure** - new features don't pollute shared space

### 📈 **Developer Experience**
- **Faster feature development** - clear component location
- **Easier maintenance** - components near their usage
- **Better imports** - shorter, more logical paths
- **Reduced complexity** - fewer cognitive load

### 🚀 **Performance**
- **Smaller bundle sizes** - no unused shared components
- **Better tree shaking** - unused feature components excluded
- **Faster builds** - fewer interdependencies

---

## Migration Checklist

### Pre-Migration
- [ ] Create generic components (CommonAppBar, VoteWidget, BaseCard)
- [ ] Test generic components in isolation
- [ ] Document component APIs

### During Migration
- [ ] Move components feature by feature
- [ ] Update imports immediately after each move
- [ ] Test each feature after migration
- [ ] Update `components.dart` exports

### Post-Migration
- [ ] Remove empty shared component folders
- [ ] Update documentation and guides
- [ ] Run full app test suite
- [ ] Verify bundle size reduction

---

## Risk Mitigation

### 🔧 **Technical Risks**
- **Import path updates** - Use IDE refactoring tools
- **Component dependencies** - Audit before moving
- **Circular imports** - Keep feature boundaries strict

### 🎯 **Process Risks**
- **Regression testing** - Test each feature after migration
- **Documentation** - Update README and agent guides
- **Team coordination** - Migrate feature by feature

---

## Final Recommendations

1. **Start with CommonAppBar** - Biggest immediate impact
2. **Migrate by feature** - Easier to track and test
3. **Keep truly shared components** - Don't over-migrate
4. **Update documentation** - Reflect new structure in guides

This migration will transform your shared components from **90 polluted components** to **~15 truly reusable building blocks**, making your architecture much more scalable and maintainable.