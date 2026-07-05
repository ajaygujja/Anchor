---
name: streak-touch
description: Safety procedure for any change to streak math or day-boundary logic (streak_calculator.dart, day_boundary.dart, or anything consuming their results). Use whenever streak, grace, heatmap, or 3AM-boundary behavior is created, changed, or debugged.
---

# Touching streak / boundary code

This is the soul of the app (spec §3). A silent off-by-one here is worse than
a crash — it lies to the user about their own history.

## Before writing code

1. Re-read spec §3 (algorithm) and §2.1 (3 AM rule) — the actual text, not
   memory. Also `.claude/rules/time-and-streaks.md`.
2. State the intended behavior change as new/changed rows in the edge-case
   table BEFORE implementation. If the change can't be expressed as table
   rows, it isn't understood yet.

## Non-negotiables to re-verify in the diff

- `streak_calculator.dart` stays a pure function
  `(Set<LocalDate> doneDates, LocalDate today) → StreakResult` — no clock
  access, no I/O, no Flutter/Firebase imports.
- `today` is always an **effective date** produced by `DayBoundary`; the
  calculator itself knows nothing about 3 AM.
- Grace semantics: grace days never increment the count; they only prevent
  reset. Pending ≠ missed (done yesterday, not yet today → no nudge, streak
  unchanged).
- All bucketing local-time; any `toUtc()` in the diff is a bug.
- Nothing derived gets persisted as a side effect of the change.

## Test procedure (TDD, genuinely)

1. Write/extend the table-driven tests first; run them; watch the new rows fail.
2. Implement; run the FULL table (all 9 mandatory rows from
   `.claude/rules/time-and-streaks.md` plus additions) — not just the new rows.
3. Boundary cases every change must keep green:
   - 01:30 local check-in → previous calendar date.
   - 02:59 vs 03:00 → different effective dates.
   - Streak evaluated at 02:00 uses yesterday as "today".
4. Cross-check one nontrivial scenario by hand: write out the date set on
   paper (or in the test comment), compute the expected streak manually,
   confirm the code agrees. Do not trust the implementation to define its own
   expectation.

## After

- Run the `check` skill.
- If consumer behavior changed (nudge visibility, heatmap cells, milestone
  timing), verify in the running app across a simulated boundary: freeze the
  clock in a widget test or run the app and confirm the dashboard rollover
  timer refreshes state.
- Update the table in `.claude/rules/time-and-streaks.md` if the mandatory
  row set grew.
