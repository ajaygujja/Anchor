# Architecture Rules

Source of truth: spec §5. These rules make the future native mobile app cheap:
presentation and data may vary per platform; domain never changes.

## Layers and the dependency direction

```
presentation (lib/features/** — widgets + blocs/cubits)
      ↓ depends on
domain (lib/domain/** — entities, repository interfaces, pure logic)
      ↑ implemented by
data (lib/data/** — Firestore repositories, DTO mapping)
```

- **Domain is pure Dart.** No `package:flutter`, no `package:firebase_*`, no
  `package:cloud_firestore` imports anywhere under `lib/domain/`. `equatable`
  and `clock` are allowed (pure Dart).
- **Presentation never touches Firestore types.** Blocs depend only on the
  abstract repository interfaces in `lib/domain/repositories/`.
- **Data never imports presentation.** DTOs map Firestore documents to domain
  entities and back; entities never carry Firestore types (`Timestamp`,
  `DocumentSnapshot`) — convert at the DTO boundary.

Verify mechanically (run before any commit that touches these layers):

```bash
# Must print nothing:
grep -rEn "package:(flutter|firebase|cloud_firestore)" lib/domain/
# Must print nothing (blocs bypass repositories = violation):
grep -rEn "package:cloud_firestore" lib/features/
```

## Folder map (spec §5.2 — do not invent new top-level dirs)

| Path | Contents |
|---|---|
| `lib/app/` | `app.dart` (MaterialApp.router, themes), `router.dart` (go_router + auth redirect), `di.dart` (composition root) |
| `lib/core/time/` | `day_boundary.dart` — the ONLY place that knows the 3 AM rule |
| `lib/core/copy.dart` | every user-facing string |
| `lib/core/theme/` | light/dark themes, quote-card text styles |
| `lib/core/failures.dart` | sealed `Failure` hierarchy |
| `lib/domain/entities/` | `habit.dart`, `entry.dart`, `streak_result.dart` |
| `lib/domain/repositories/` | abstract interfaces only |
| `lib/domain/streaks/` | `streak_calculator.dart` — pure function, most-tested file in the repo |
| `lib/data/dtos/` | Firestore ↔ entity mapping |
| `lib/data/repositories/` | Firestore implementations of domain interfaces |
| `lib/features/<name>/` | `bloc/`, `view/`, and (where specced) `widgets/` |

Feature set is fixed for v1: `auth`, `dashboard`, `habit_detail`,
`manage_habits`. A new feature dir requires a spec change first.

## Repositories

- Interface lives in `lib/domain/repositories/`, named `XRepository`.
  Implementation lives in `lib/data/repositories/`, named `FirestoreXRepository`
  (or `FirebaseAuthRepository` for auth).
- The three v1 repositories: `AuthRepository`, `HabitRepository`,
  `EntryRepository`. Do not add more without a spec-backed reason.
- Streams for anything a screen watches (Firestore snapshots keep devices in
  sync live); one-shot futures for mutations.
- Repositories translate raw exceptions into the sealed `Failure` types in
  `lib/core/failures.dart` (`NetworkFailure`, `PermissionFailure`,
  `UnknownFailure`). A `FirebaseException` reaching a bloc or widget is a bug.

## Dependency injection

- **Constructor injection wired in `lib/app/di.dart`** (the composition root).
  No service locator (`get_it`), no `InheritedWidget` hand-rolling — the app is
  deliberately small enough for explicit wiring.
- Blocs receive repository interfaces (and `DayBoundary` where needed) through
  constructors. Widgets receive blocs via `BlocProvider`.
- Anything that reads time receives it injected (see time-and-streaks.md);
  this is what makes every date-dependent behavior unit-testable.

## Error surfaces

- UI shows quiet retry affordances — no scary red error walls, no raw exception
  text. Failures map to calm copy from `core/copy.dart`.
- Optimistic UI is the default for check-ins: local write first, UI updates
  instantly, sync happens when the network returns. Never block a tap on a
  network round-trip.

## Scalability posture (deliberate restraint)

- One year of daily use ≈ 365 tiny entry docs per habit — read the whole set
  with `orderBy(date)`; this is fine. The documented upgrade path (only when
  actually needed, never preemptively) is client-side caching + paginated
  windows. **Never stored aggregates** — they violate the one-source-of-truth
  rule and are explicitly out of scope (spec §12).
- Single-column responsive layout, max content width ~600 px. No breakpoint
  forks in v1.
