# Anchor — Project Memory

Single-user, cross-device habit tracker. Philosophy: **never miss twice** — one
missed day never breaks a streak; two consecutive missed days do. Deliberately
quiet: one tap is enough, history is honest, no gamification or guilt.

Flutter **Web** (PWA) + Firebase (Auth, Firestore, Hosting) + Bloc + go_router.

**The spec is law:** [anchor-final-spec.md](anchor-final-spec.md). Every design
question is answered there first. If the spec and this file ever disagree, the
spec wins; fix this file.

## Rules (all mandatory reading before writing code)

- @.claude/rules/architecture.md — layers, dependency direction, repositories, DI
- @.claude/rules/engineering-principles.md — SOLID/DRY/YAGNI etc. + comment style, every rule testable
- @.claude/rules/coding-standards.md — naming, blocs, comments, copy, lints
- @.claude/rules/time-and-streaks.md — 3 AM boundary, injected clock, streak math
- @.claude/rules/firestore-and-security.md — data model, rules, secrets, public-repo hygiene
- @.claude/rules/testing.md — what gets tested where, and how deeply
- @.claude/rules/workflow.md — phase discipline, verification-first, git/CI

## Non-negotiable invariants (short form)

1. **Domain layer is pure Dart** — zero Flutter/Firebase imports in `lib/domain/`.
2. **Nothing derived is ever persisted** — streaks, totals, heatmaps are computed
   at read time. About to store one? Stop, compute it.
3. **All time flows through the injected `clock` + `DayBoundary`** — a direct
   `DateTime.now()` outside `core/time/` is a review-blocker.
4. **Every user-facing string lives in `lib/core/copy.dart`** — no inline literals
   in widgets.
5. **No confirmation dialogs anywhere** — reversibility (undo, edit) instead.
6. **Entry doc ID is the effective date** (`yyyy-MM-dd`) — writes are idempotent
   `set(merge: true)`; never introduce read-before-write or transactions for
   check-ins.
7. **Don't assume — verify.** Read the actual file, run the actual command, check
   the actual spec section before acting on a belief about the codebase.

## Project status

- Phase 0 (repo & skeleton) complete — commit `5bda241`.
- Next: Phase 1 (Auth + foundation) per spec §11. Do not start a phase before
  the previous phase's acceptance criteria pass.
- Placeholder files marked `// Placeholder. Implemented in a later phase` are
  intentional; fill them only in their designated phase.

## Commands

```bash
# Dev loop (emulators = the only local environment; prod is deploy-only)
firebase emulators:start                               # Auth :9099, Firestore :8080, UI enabled
flutter run -d chrome --dart-define=USE_EMULATORS=true

# Verification (CI runs exactly these)
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test

# Deploy (Phase 5+; rules whenever they change)
flutter build web --release
firebase deploy --only hosting
firebase deploy --only firestore:rules
```

Firebase project: `anchor-51808323232`, Firestore region `asia-south1`.
Lints: `very_good_analysis` (see `analysis_options.yaml` for the two documented opt-outs).
