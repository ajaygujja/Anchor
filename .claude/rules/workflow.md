# Workflow Rules

## Verification-first (don't assume — verify)

Before acting on any belief about the codebase, check it:

- "This file probably contains X" → **Read the file.**
- "This command probably passes" → **Run the command.**
- "The spec probably says X" → **Open anchor-final-spec.md and cite the section.**
- "This package probably supports X" → check `pubspec.lock` for the actual
  resolved version, then its docs for that version.
- "CI probably covers X" → read `.github/workflows/ci-cd.yml`.

A claim like "done", "works", or "passes" is only made after the relevant
command actually ran in this session. If something wasn't verified, say so
explicitly.

## Phase discipline (spec §11)

- Work proceeds in the spec's phase order: 0 ✅ → 1 (Auth) → 2 (Habits CRUD) →
  3 (Check-in + Entries) → 4 (Streaks/Dashboard/Heatmap) → 5 (Polish + Ship).
- **A phase starts only after the previous phase's acceptance criteria
  demonstrably pass.** Quote the criteria, show the evidence.
- One PR per phase. CI green before merge; merge before next phase.
- Placeholder files (`// Placeholder. Implemented in a later phase`) are filled
  only in their designated phase — no opportunistic early implementation.
- Scope discipline: spec §12 lists what v1 will NOT have (notifications,
  multi-user, export, App Check, stored aggregates, schedules, analytics).
  Suggesting one of these is a spec conversation, not a code change.

## Git

- Small, single-purpose commits with imperative subjects; the body says why
  when the why isn't obvious.
- Never commit: generated build output, service-account keys, `.env*`
  (see firestore-and-security.md). `lib/firebase_options.dart` IS committed.
- Push after each meaningful commit — an unpushed local `main` is a liability
  on a cross-device project.
- Before flipping the repo public: `gitleaks` scan + history audit.

## Definition of done (any task, any phase)

1. `dart format --output=none --set-exit-if-changed .` passes.
2. `flutter analyze` clean.
3. `flutter test` green, including new tests for the new behavior.
4. Architecture greps clean (domain purity, no `DateTime.now()`, no Firestore
   imports in features — commands in architecture.md / time-and-streaks.md).
5. New user-facing strings are in `core/copy.dart`.
6. Both themes checked for any UI change (dark mode is first-class).
7. Behavior exercised for real at least once: app run against emulators, the
   flow tapped through.

## Existing patterns win

Prefer the codebase's established conventions over introducing new ones. When
Phase 1 fixes a style (bloc file layout, DTO shape, test naming), later phases
copy it. Consistency beats local optimality.
