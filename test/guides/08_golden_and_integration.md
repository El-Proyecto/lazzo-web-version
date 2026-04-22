# 08 — Golden Tests & Integration Tests (P8)

**Priority:** 8 — optional polish. Implement after P1–P7 are stable.

**Pre-requisites:** `test/guides/00_conventions.md`, P7 complete. `test/helpers/golden_test_helper.dart`.

---

## 1. Objective

### Golden tests

Capture pixel snapshots of shared components and key pages, then alert on unintended visual regressions. Golden tests are **not** a substitute for widget tests — they are a complement that catches UI drift after token changes or refactors.

### Integration tests

End-to-end smoke tests that run the full Flutter app (with fake DI) and walk through a critical happy path. They catch wiring bugs that unit and widget tests cannot — e.g., a broken route, a missing DI override, a `UnimplementedError` thrown because a provider was never configured.

---

## 2. Golden tests

### Setup

`test/helpers/golden_test_helper.dart` already provides:

```dart
pumpGoldenWidget(tester, widget, {overrides, screenSize})
testWidgetStatesGolden(tester, {states}, baseFileName)
TestScreenSizes.phone   // 375×667
TestScreenSizes.tablet  // 768×1024
```

### Initial golden file generation

```bash
# Generate/update golden files (run once after writing the test)
flutter test --update-goldens

# Verify against existing golden files (run in CI)
flutter test
```

Golden files are committed to version control. After intentional UI changes, re-run `--update-goldens` and review the diff before committing.

### Shared components to golden-test

Start with stateless shared widgets — they are the most stable and have the highest reuse:

| Component | Test file |
|-----------|-----------|
| Primary button (from `shared/components/buttons/`) | `test/shared/components/buttons/primary_button_golden_test.dart` |
| Event full card (from `shared/components/cards/`) | `test/shared/components/cards/event_full_card_golden_test.dart` |
| RSVP widget (from `shared/components/widgets/`) | `test/shared/components/widgets/rsvp_widget_golden_test.dart` |
| Section header | `test/shared/components/sections/section_header_golden_test.dart` |

For each component, test at least two states (default + one variant such as loading or empty).

### Canonical golden test pattern

```dart
// test/shared/components/buttons/primary_button_golden_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/shared/components/buttons/primary_button.dart'; // adjust import
import '../../../helpers/golden_test_helper.dart';

void main() {
  group('PrimaryButton — golden', () {
    testWidgets('default state', (tester) async {
      await pumpGoldenWidget(
        tester,
        const PrimaryButton(label: 'Continuar', onTap: null),
        screenSize: TestScreenSizes.phone,
      );
      await expectLater(
        find.byType(PrimaryButton),
        matchesGoldenFile('goldens/primary_button_default.png'),
      );
    });

    testWidgets('loading state', (tester) async {
      await pumpGoldenWidget(
        tester,
        const PrimaryButton(label: 'Continuar', onTap: null, isLoading: true),
        screenSize: TestScreenSizes.phone,
      );
      await expectLater(
        find.byType(PrimaryButton),
        matchesGoldenFile('goldens/primary_button_loading.png'),
      );
    });
  });
}
```

Golden files are stored relative to the test file. Create a `goldens/` subfolder next to each test file:

```
test/shared/components/buttons/
  primary_button_golden_test.dart
  goldens/
    primary_button_default.png
    primary_button_loading.png
```

---

## 3. Integration tests

### Setup

The `integration_test` package is already in `pubspec.yaml`. Create the directory:

```
integration_test/
  app_test.dart
  helpers/
    integration_helpers.dart
```

### Core principle — fake DI for integration tests

Integration tests run the real app but with fake repositories by default (same as development). **Never connect to a live Supabase instance in CI.**

The default DI in `main.dart` uses `FakeEventRepository`, `FakeRsvpRepository`, etc. As long as integration tests launch `main()` without overriding to Supabase, they are safe to run in CI.

### Flows to smoke-test

Implement in this order:

#### Flow 1 — Auth page renders and accepts email input

```dart
// integration_test/app_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lazzo/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Smoke — Auth', () {
    testWidgets('auth page is visible on app launch', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Auth page should be visible
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
```

#### Flow 2 — Event list page loads with fake data

After auth (can be bypassed by starting at a specific route with fake user data), verify the home page renders event cards.

#### Flow 3 — Create event happy path

1. Navigate to `CreateEventPage`.
2. Enter event name.
3. Tap continue.
4. Verify `ConfirmEventBottomSheet` opens.
5. Confirm creation.
6. Verify navigation to event page.

### Running integration tests

```bash
# On a connected device or simulator
flutter test integration_test/app_test.dart

# On iOS simulator (headless)
flutter test integration_test/ --device-id <simulator-id>
```

Integration tests are NOT run in the current CI pipeline. Add them only after the basic test suite is stable, to avoid flaky CI failures. Document the step to add them in `ci-dev.yml` when ready.

---

## 4. CI integration (when ready)

When P1–P7 are stable and golden files are committed, add to `.github/workflows/ci-dev.yml`:

```yaml
# After flutter test --coverage step:
- name: Run integration tests (simulator)
  if: runner.os == 'macOS'
  run: flutter test integration_test/
```

For golden tests, they will run as part of `flutter test --coverage` automatically since they live in `test/`.

---

## 5. Agent workflow

### Golden tests
```
1. Read 00_conventions.md + golden_test_helper.dart
2. Pick one shared component (start with the most reused)
3. Create test file + goldens/ directory
4. Write 2–3 state variants
5. flutter test --update-goldens   (generate files)
6. flutter test                    (verify pass)
7. Commit test + golden files
8. Check off in §6
```

### Integration tests
```
1. Create integration_test/ directory
2. Write app_test.dart with Flow 1
3. flutter test integration_test/ --device-id <device>
4. Add Flow 2, Flow 3 incrementally
5. Check off in §6
```

---

## 6. Progress tracker

### Golden tests — shared components
- [ ] Primary button
- [ ] Event full card
- [ ] RSVP widget
- [ ] Section header

### Golden tests — pages
- [ ] `CreateEventPage` (empty state)
- [ ] `EventPage` (loaded state with fake data)

### Integration tests
- [ ] Flow 1 — Auth page on launch
- [ ] Flow 2 — Home/event list with fake data
- [ ] Flow 3 — Create event happy path
