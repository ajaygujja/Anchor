# Time & Streak Rules

The soul of the app. Source of truth: spec §2.1 and §3. Errors here corrupt
trust in the product more than any crash would.

## The effective day (3 AM rule)

```
effectiveDate = (localNow - 3 hours).calendarDate
```

- A check-in between midnight and 3 AM belongs to the **previous** calendar day.
- The rule applies everywhere "today" appears: check-in target, done-today
  counts, streak math, heatmap bucketing, quote-of-the-day selection, weekly
  recap windows.
- Implemented in exactly one place: `lib/core/time/day_boundary.dart`, built on
  `package:clock` so tests can freeze time with `withClock`. Injected wherever
  needed.
- **All day bucketing is local time. Never UTC.** A `.toUtc()` in date-bucketing
  code is a bug.
- `DateTime.now()` outside `core/time/` is a review-blocker. Verify:

```bash
# Must print nothing outside lib/core/time/:
grep -rn "DateTime.now()" lib/ --include="*.dart" | grep -v "lib/core/time/"
```

- **Rollover while open:** the dashboard keys a timer to the next 3 AM boundary
  and refreshes state when it fires — "today" must update without a manual
  reload.

## Streak algorithm (never-miss-twice, literally)

Definitions, for one habit:
- `D` = set of effective dates where an entry exists with `done == true`.
- A **chain** = a run of days never containing 2+ consecutive dates missing
  from `D`.

Current streak:
1. Chain end: `today ∈ D` → end = today. Else `yesterday ∈ D` → end =
   yesterday (today is *pending*, not a miss). Else `today-2 ∈ D` → end =
   today-2 and the streak is in **grace state** (show the nudge). Else 0.
2. Walk backward from the chain end while every gap of missed days is ≤ 1;
   stop at the first gap ≥ 2 or at the first entry.
3. **Streak value = count of DONE days in the chain.** Grace days don't add;
   they just don't reset. (done Mon, miss Tue, done Wed → streak 2, alive.)

Longest streak: same chain rule over full history; max done-count per chain.

## Implementation constraints

- Lives in `lib/domain/streaks/streak_calculator.dart` as a **pure function**:
  `(Set<LocalDate> doneDates, LocalDate today) → StreakResult{current, longest, isInGrace}`.
  Zero Flutter/Firebase imports. No I/O, no clock access — `today` is a
  parameter, which is what makes it exhaustively testable.
- Derived values (current streak, longest streak, grace flag, heatmap buckets,
  weekly recap) are **computed on every read, never stored**. Editing any past
  entry must self-heal everything with no migration or recompute job.

## Mandatory edge-case test table (spec §3 — every row is a unit test)

| # | Scenario | Expected |
|---|---|---|
| 1 | Habit created today, no entries | streak 0, no nudge |
| 2 | Done today only | streak 1 |
| 3 | Done yesterday, not today | streak unchanged, **no** nudge (pending) |
| 4 | Done day-before-yesterday, missed yesterday, not today | streak alive, **grace + nudge** |
| 5 | Missed yesterday AND day before | streak 0 |
| 6 | Past edit done→not-done creating a 2-gap | chain splits correctly |
| 7 | Entries before habit `createdAt` (backfill) | allowed, computed normally |
| 8 | Check-in at 01:30 local | belongs to previous calendar date |
| 9 | Any date math | local time via injected clock, never UTC |

Any change to `streak_calculator.dart` or `day_boundary.dart` runs the full
table plus new table-driven cases for the changed behavior — tests first
(Phase 4 is explicitly TDD).

## Grace-state nudge (the app's only nudge)

Shown only in scenario 4 above. Invitation tone, never alarm styling:
*"Yesterday was a rest. Today keeps it alive."* Copy lives in `core/copy.dart`.
