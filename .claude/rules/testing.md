# Testing Rules

Source of truth: spec §9. Effort is deliberately uneven — spend it where the
product's trust lives.

## Depth by layer

| Layer | Tooling | Depth |
|---|---|---|
| `streak_calculator`, `day_boundary` | plain `package:test` | **Exhaustive.** Table-driven; every §3 edge case (see time-and-streaks.md table). The most-tested code in the repo. |
| Blocs/Cubits | `bloc_test` + `mocktail` repositories | All states and transitions, including optimistic check-in + undo, failure paths, boundary-rollover refresh. |
| Repositories | `fake_cloud_firestore` or emulator integration | DTO mapping both directions; idempotent date-keyed writes (double-write → one doc). |
| Security rules | `@firebase/rules-unit-testing` in `firestore-tests/` (Node + emulator) | Owner / attacker / unauthenticated / invalid-shape matrix. |
| Widgets | `flutter_test` | Light, targeted: habit card states (done / pending / grace nudge / milestone), quote card, empty state. Not pixel tests. |

## Conventions

- `test/` mirrors `lib/` structure: `test/domain/streaks/streak_calculator_test.dart`
  tests `lib/domain/streaks/streak_calculator.dart`.
- Time-dependent tests freeze time with `package:clock`'s `withClock` — never
  rely on the wall clock, never `sleep` to cross a boundary.
- Streak/day-boundary tests are table-driven: a list of
  `(description, doneDates, today, expected)` records looped through one
  assertion block, so adding an edge case is one line.
- Mock repositories with `mocktail`; never mock what you own inside domain
  (pure functions are called directly).
- A bug fix lands with a regression test that fails before the fix. No
  exceptions for "trivial" fixes — trivial fixes are where streak math rots.

## TDD zones

Phase 4's `streak_calculator.dart` is written test-first, genuinely: the full
§3 table exists and fails before the implementation exists. The same posture
applies to any later change of streak or boundary semantics.

## Gates

CI (`.github/workflows/ci-cd.yml`) runs, in order:
`dart format --set-exit-if-changed` → `flutter analyze` → `flutter test`
(rules tests join the pipeline when `firestore-tests/` lands in Phase 1).
All must pass locally before pushing; CI green is a hard gate between phases.

## What NOT to test

- No tests asserting Flutter framework behavior (e.g. that `BlocProvider`
  provides).
- No golden/screenshot tests in v1.
- No emulator round-trips inside `flutter test` unit runs — emulator-dependent
  tests live in `firestore-tests/` or dedicated integration suites.
