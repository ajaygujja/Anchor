---
name: new-repository
description: Implement an Anchor repository — domain interface, Firestore implementation, DTO mapping, Failure translation, tests. Use when implementing AuthRepository, HabitRepository, or EntryRepository, or changing any repository's contract.
---

# New repository

## 0. Verify it should exist

The v1 repository set is closed (spec §5.1): `AuthRepository`,
`HabitRepository`, `EntryRepository`. Anything else needs a spec change first.

## 1. Domain interface — `lib/domain/repositories/<name>_repository.dart`

- Abstract class, pure Dart. Allowed imports: domain entities, `core/failures.dart`,
  pure packages (`equatable`, `clock`). Forbidden: anything Flutter/Firebase.
- Speaks **domain language only**: entities in and out, `LocalDate`/date types
  from domain — never `Timestamp`, `DocumentSnapshot`, `User` (firebase_auth).
- Streams for anything a screen watches (live sync across devices is a spec
  requirement); `Future` for one-shot mutations.
- Contract facts that belong in dartdoc: idempotency guarantees, ordering,
  what a `null`/empty result means.

## 2. DTO — `lib/data/dtos/<entity>_dto.dart`

- Owns the full Firestore ↔ entity conversion; `Timestamp` ↔ `DateTime`
  happens here and nowhere else.
- Field names must match the spec §4 schema exactly (`name`, `createdAt`,
  `archived`, `color`, `sortOrder`; `date`, `done`, `reflection`, `updatedAt`).
  A new field means the spec + `firestore.rules` validators + rules tests
  change in the same PR.
- Tolerant reads: a missing optional field maps to a sane default; a corrupt
  doc surfaces as a `Failure`, not a crash.

## 3. Firestore implementation — `lib/data/repositories/firestore_<name>_repository.dart`

- Implements the domain interface. Paths always UID-scoped:
  `users/{uid}/habits/{habitId}/entries/{yyyy-MM-dd}`.
- **Entry writes are date-keyed and idempotent**: doc ID = effective date,
  written with `set(merge: true)`. No read-before-write, no transactions, no
  auto-IDs for entries. Undo = `delete()`.
- Server timestamps via `FieldValue.serverTimestamp()` for `createdAt`/`updatedAt`.
- Every raw exception is translated to the sealed `Failure` hierarchy
  (`NetworkFailure`, `PermissionFailure`, `UnknownFailure`) at this boundary.
  Map from `FirebaseException.code` (e.g. `permission-denied` →
  `PermissionFailure`, `unavailable` → `NetworkFailure`) — verify the actual
  code strings against the installed cloud_firestore version, don't guess.
- No derived data is written. Ever.

## 4. Wire it

Construct in `lib/app/di.dart`; blocs receive the interface type.

## 5. Tests

- `test/data/` mirrors the file. Use `fake_cloud_firestore` if adding it as a
  dev dependency is justified, otherwise emulator-backed integration tests.
- Must cover: DTO mapping both directions (including null `color`/`reflection`),
  idempotency (two `setEntry` calls for the same date → exactly one doc),
  Failure translation per error code, stream emission on data change.

## 6. Gate

Run the `check` skill. If the data model or rules changed, also run the rules
tests in `firestore-tests/`.
