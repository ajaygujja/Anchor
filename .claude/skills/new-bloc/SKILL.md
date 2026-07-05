---
name: new-bloc
description: Scaffold a Bloc or Cubit for Anchor following the fixed spec conventions — Equatable states, sealed events, repository interfaces only, bloc_test coverage. Use when creating or substantially reworking any Bloc/Cubit.
---

# New Bloc/Cubit

## 0. Verify it should exist

The v1 bloc set is closed (spec §5.3): `AuthBloc`, `DashboardBloc`,
`CheckInCubit`, `HabitDetailBloc`, `EntryEditCubit`, `ManageHabitsBloc`.
A bloc outside this list needs a spec change first — stop and raise it.
The Bloc-vs-Cubit choice is also fixed by that table; don't convert.

## 1. Check for an established pattern

Before writing anything, look at the most recently implemented bloc under
`lib/features/*/bloc/` and copy its structure exactly: file layout
(part files vs separate files), state shape style, event naming. Consistency
beats local preference. If none exists yet (Phase 1), this bloc SETS the
pattern — choose deliberately, it will be copied.

## 2. Structure

```
lib/features/<feature>/bloc/
  <name>_bloc.dart      # or <name>_cubit.dart
  <name>_event.dart     # blocs only; sealed class hierarchy
  <name>_state.dart     # Equatable
```

Requirements:
- States extend `Equatable` with complete `props`.
- Events are a sealed class hierarchy (blocs only).
- Constructor takes **domain repository interfaces** (and `DayBoundary` where
  time matters) — never a Firestore type, never a concrete data-layer class.
- No `DateTime.now()` — time arrives via the injected clock/DayBoundary.
- Failures arrive as sealed `Failure` values; map them to states, never rethrow
  into widgets.
- Long-lived streams (Firestore snapshots): subscribe in the bloc, cancel in
  `close()`.
- Optimistic mutations (check-in pattern): emit the optimistic state
  immediately, reconcile on repository result, roll back with the undo path on
  failure — never a loading spinner between tap and checkmark.

## 3. Wire it

- Register construction in `lib/app/di.dart` (constructor injection at the
  composition root — no service locator).
- Provide via `BlocProvider` at the narrowest scope that works (page-level
  unless the spec's screen flow requires wider).

## 4. Test it (not optional)

`test/features/<feature>/bloc/<name>_bloc_test.dart` using `bloc_test` +
`mocktail` repositories:
- Initial state.
- Every event/method → expected state sequence.
- Failure paths for every repository call.
- Time-sensitive behavior under `withClock` with a frozen clock.
- For optimistic flows: the optimistic emission, the success reconciliation,
  and the failure rollback as three separate cases.

## 5. Gate

Run the `check` skill. All green before the bloc is called done.
