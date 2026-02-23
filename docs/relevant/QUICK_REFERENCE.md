# Quick Reference - Architecture Compliance

**Use this checklist before every PR submission**

---

## 🚨 Critical Architecture Rules

### ❌ NEVER DO:
- [ ] Import `supabase_flutter` in `lib/features/*/presentation/`
- [ ] Import `supabase_flutter` in `lib/features/*/domain/`
- [ ] Use `Supabase.instance.client` anywhere in presentation layer
- [ ] Create new files in `lib/styles/` (use `shared/themes/` only)
- [ ] Hardcode `Color(0xFF...)` in shared components
- [ ] Hardcode `width:` or `height:` in shared components
- [ ] Skip DI overrides in `main.dart` for new features

### ✅ ALWAYS DO:
- [ ] Use tokens from `shared/themes/colors.dart` and `shared/constants/spacing.dart`
- [ ] Make shared components stateless and reusable
- [ ] Implement both fake and real repositories for features
- [ ] Add provider overrides in `main.dart` ProviderScope
- [ ] Follow repository pattern: Widget → Provider → UseCase → Repository → DataSource

---

## 📋 Pre-PR Checklist

### Architecture Boundaries
- [ ] Run: `git grep "Supabase.instance" -- lib/features/*/presentation/` (should be empty)
- [ ] Run: `git grep "import.*supabase_flutter" -- lib/features/*/domain/` (should be empty)
- [ ] Run: `git grep "Color(0x" -- lib/shared/components/` (should be empty)
- [ ] Run: `git grep "styles/app_styles" -- lib/` (should be empty)

### Code Quality
- [ ] All new widgets have `const` constructors where possible
- [ ] Proper error handling with `AsyncValue` for async operations
- [ ] No TODO/FIXME without corresponding GitHub issues
- [ ] Tests cover new functionality (unit for domain, widget for UI)

### Token Usage
- [ ] Colors use `BrandColors.*` or `Theme.of(context).colorScheme.*`
- [ ] Spacing uses `Gaps.*`, `Insets.*`, `Pads.*`, `Radii.*`
- [ ] Text styles use `AppText.*`
- [ ] No magic numbers except micro optical adjustments (1-2px)

---

## 🔧 Quick Fixes

### "Token not found" errors:
```bash
# Check if importing from wrong location
git grep -n "styles/app_styles" lib/
# Should import from shared/themes/colors.dart instead
```

### "Provider not found" errors:
```bash
# Check main.dart has your feature's provider override
grep -A 20 "ProviderScope(overrides:" lib/main.dart
```

### "Supabase errors" in presentation:
```bash
# Find violations
git grep -n "Supabase.instance" lib/features/*/presentation/
# Move to repository pattern instead
```

---

## 🏗️ Current Architecture Status

### ✅ Compliant Features:
- `create_event/` - Clean architecture exemplar
- `home/` - Good structure, DI configured

### ⚠️ Needs Attention:
- `auth/` - Presentation layer violations (in progress)
- `groups/` - Missing DI override
- `profile/` - Missing DI override  
- `activities/` - Missing DI override

### ❌ Active Issues:
- `lib/styles/app_styles.dart` - Duplicate token system (remove)
- Hardcoded dimensions in shared components
- Empty test files

---

## 📞 Getting Help

### Architecture Questions:
1. Check `ARCHITECTURE_REVIEW.md` for detailed analysis
2. Review `README.md` for feature development flow
3. Check `agents.md` for agent-specific guidelines

### Emergency Debugging:
- **Token issues**: Import from `shared/themes/colors.dart` not `styles/`
- **Provider issues**: Check `main.dart` ProviderScope overrides
- **Supabase issues**: Use repository pattern, never direct calls in presentation
- **UI issues**: Use `Expanded`/`Flexible`, check touch targets (min 44x44)

### Code Review Focus:
- Domain layer purity (no Flutter/Supabase imports)
- Presentation boundaries (no direct Supabase calls)
- Token usage (no hardcoded values)
- DI completeness (fake + real implementations)

---

**Last Updated:** September 24, 2025  
**Review this file monthly** and update based on architecture evolution.