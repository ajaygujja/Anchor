---
name: check
description: Run Anchor's full local verification gate — format, analyze, tests, architecture greps. Use before any commit, after completing any task, when the user says "check", "verify", "is it green", or before claiming work is done.
---

# Anchor verification gate

Run every step from the repo root (`/Users/ajay/Development/projects/anchor`).
Report each step's actual result — never claim a step passed without running it.

## 1. Format

```bash
dart format --output=none --set-exit-if-changed .
```

Fails → run `dart format .`, re-run the check.

## 2. Analyze

```bash
flutter analyze
```

Zero issues required. Fix code rather than adding `// ignore:`.

## 3. Tests

```bash
flutter test
```

All green required. If a change touched `streak_calculator.dart` or
`day_boundary.dart`, confirm the §3 edge-case table tests all executed
(see `.claude/rules/time-and-streaks.md`).

## 4. Architecture greps (each must print nothing)

```bash
# Domain purity — no Flutter/Firebase in lib/domain/
grep -rEn "package:(flutter|firebase|cloud_firestore)" lib/domain/

# No direct Firestore access from presentation
grep -rEn "package:cloud_firestore" lib/features/

# All time via injected clock — no wall-clock reads outside core/time/
grep -rn "DateTime.now()" lib/ --include="*.dart" | grep -v "lib/core/time/"

# No dart:io in a web app
grep -rn "dart:io" lib/ --include="*.dart"
```

Any hit is a review-blocker: fix it, don't suppress it.

## 5. Copy audit (only when the change touched widgets)

Scan the diff for quoted string literals inside `lib/features/` widgets that a
user would read (labels, messages, nudges). Each belongs in
`lib/core/copy.dart` as a `Copy` constant.

## 6. Rules tests (only when `firestore.rules` or the data model changed)

```bash
cd firestore-tests && npm test   # requires firebase emulators (see package.json once Phase 1 lands)
```

## Report format

One line per step: step name, command, pass/fail. On any failure: the exact
error output, the fix applied, and the re-run result. End with an overall
verdict; "green" only if every applicable step actually passed in this run.
