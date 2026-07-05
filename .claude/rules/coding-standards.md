# Coding Standards

## Lints and formatting

- `very_good_analysis` is active via `analysis_options.yaml`. Never argue with
  it, never sprinkle `// ignore:` — fix the code. The only sanctioned opt-outs
  are the two already documented in `analysis_options.yaml`
  (`public_member_api_docs`, `sort_pub_dependencies`).
- `dart format` is CI-gated (`--set-exit-if-changed`). Format before committing.
- `lib/firebase_options.dart` and generated `*.g.dart` are analyzer-excluded;
  never hand-edit them.

## Bloc conventions (spec §5.3)

- Use a **Cubit** for single-concern, direct-mutation state (`CheckInCubit`,
  `EntryEditCubit`); use a **Bloc** where multiple streams compose or events
  need explicit modeling (`AuthBloc`, `DashboardBloc`, `HabitDetailBloc`,
  `ManageHabitsBloc`). This split is fixed by the spec — don't convert one to
  the other without a spec change.
- States extend `Equatable`. Events are sealed classes.
- **No business logic in widgets.** A widget computes nothing date-, streak-,
  or persistence-related; it renders state and dispatches events.
- Every bloc gets `bloc_test` coverage for all states and transitions,
  including optimistic paths (check-in + undo) and the boundary-rollover
  refresh.
- File layout inside a feature: `bloc/<name>_bloc.dart` (+ `_event.dart`,
  `_state.dart` as `part` files or separate files — pick one style in Phase 1
  and keep it everywhere), `view/<name>_page.dart`, `widgets/<piece>.dart`.

## Naming

- Files: `snake_case.dart`. Types: `UpperCamelCase`. One primary type per file,
  file named after it.
- Repository interfaces: `XRepository`; implementations:
  `Firestore*`/`FirebaseAuth*` prefix, in `lib/data/repositories/`.
- Entities are nouns (`Habit`, `Entry`, `StreakResult`); DTOs are
  `XDto` in `lib/data/dtos/`.
- Blocs/Cubits named exactly as the spec table §5.3 names them.

## User-facing text

- Every string a user can read lives in `lib/core/copy.dart` as a `static const`
  on `Copy`. This includes button labels, snackbars, nudges, milestone lines,
  empty states, and error surfaces. Inline string literals in widgets are a
  review-blocker.
- The voice is quiet, invitational, identity-level. Never guilt, never alarm,
  never exclamation-marked celebration. Milestone thresholds: 7, 21, 30, 60,
  100, 180, 365 days.

## Comments and dartdoc

- Comments state **constraints and invariants the code cannot show** — never
  narration of what the next line does, never justification of a change, never
  references to how the code used to be. A comment that only makes sense during
  code review is noise; delete it.
- Dartdoc on a public symbol states what the symbol **is**, not its history or
  its relationship to other codebases.
- When a rule comes from the spec, cite the section (e.g. `(spec §3)`), so the
  constraint is traceable.

## Reversibility over confirmation

- No confirmation dialogs anywhere in the app. Destructive-feeling actions get
  an undo path instead (5-second snackbar for check-ins) or are inherently
  editable (past entries). Habits with history are archived, never hard-deleted.

## Motion and theming

- Material 3, one seed color (`0xFF3A5A78`), `ThemeMode.system` default with a
  manual toggle in Manage. Dark mode is first-class — every new screen is
  checked in both themes before its phase closes.
- Animations ≤ 300 ms, standard easing. The check-in micro-acknowledgment is
  the only celebratory motion in the app.

## Dependencies

- The v1 package set is closed (spec §5.4): `firebase_core`, `firebase_auth`,
  `cloud_firestore`, `flutter_bloc`, `equatable`, `go_router`, `intl`, `clock`,
  `url_launcher`; dev: `bloc_test`, `mocktail`, `very_good_analysis`.
- Adding any package requires a spec-level justification, and web cold-start
  weight is part of that decision. Don't add heavy packages casually.
- No `dart:io` — this is a web app; anything platform-ish goes through an
  abstraction.
