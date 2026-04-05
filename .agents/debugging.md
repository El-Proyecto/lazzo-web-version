# Debugging

**Repository:** lazzo-web-version.

*Quick reference: emergency fixes (tokens, providers, Supabase in UI, tokenization), print/logging policy and cleanup.*

## Emergency debugging

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

## Logging & debugging guidelines

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

**Naming convention:**

- Format: `print('[FeatureName] description')`
- Feature names: `EventChat`, `Profile`, `CreateEvent`, `SupabaseClient`, `Repository`
- Include relevant IDs: `userId`, `eventId`
- Keep messages concise and actionable

**Before PR/Merge to Main:**

1. Run cleanup script: `./scripts/clean_prints.sh`
2. Manually review any remaining prints that should stay (rare edge cases)
3. Verify with: `git grep -n "print(" lib/`
4. Zero prints in `lib/` folder = ready to merge

**Sensitive data - NEVER LOG:**

- ❌ Passwords, tokens, API keys
- ❌ Full email addresses (use `email.substring(0, 3)...`)
- ❌ Phone numbers
- ❌ Complete user profiles
- ❌ Payment information

**Production logging:** See `FUTURE_IMPROVEMENTS.md` for structured logging strategy (Logger package, Firebase Crashlytics).
