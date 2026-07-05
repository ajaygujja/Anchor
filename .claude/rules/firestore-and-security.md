# Firestore & Security Rules

Source of truth: spec §4, §6. The repo must stay public-ready at every commit.

## Data model (fixed for v1)

```
users/{uid}
  habits/{habitId}
    name:        string (1–60 chars)
    createdAt:   timestamp (server)
    archived:    bool
    color:       string|null   (hex, cosmetic only)
    sortOrder:   int
    entries/{yyyy-MM-dd}          ← doc ID IS the effective date
      date:        string "yyyy-MM-dd" (duplicated from ID for querying)
      done:        bool
      reflection:  string|null (≤ 2000 chars)
      updatedAt:   timestamp (server)
```

- Everything is scoped under the user's UID **by path** — this is what keeps
  security rules trivial and correct. Never store user data outside
  `users/{uid}/`.
- **Entry doc ID = effective date.** This guarantees one entry per habit per
  day at the database level. Check-in is a single `set(merge: true)` — no
  read-before-write, no transactions. Undo is a single `delete()`. Do not
  "improve" this with auto-IDs, batches, or transactions.
- Schema changes (new fields, new collections) require: spec update →
  `firestore.rules` validation update → rules tests → then code.

## Derived data

Streaks, totals, heatmap buckets, weekly recaps: **computed at read time,
never persisted** (spec locked decision #8). A stored counter or aggregate
document is a review-blocker regardless of how tempting the performance
argument looks — the documented upgrade path is client-side caching, not
server-side aggregates.

## Offline & real-time

- Firestore web persistence is enabled at startup (`main.dart`). Check-ins are
  tap-and-forget: optimistic local write, sync when the network returns. Never
  add UI that waits for server confirmation of a check-in.
- Screens watch Firestore snapshot streams so laptop and phone stay live-synced.

## Security rules (`firestore.rules`)

- Rules-as-code: the committed file is the deployed truth. Any rules change
  ships in the same PR as its rules tests and deploys via
  `firebase deploy --only firestore:rules`.
- Shape: owner-only access (`request.auth.uid == uid`), shape validation on
  create/update (`validHabit`, `validEntry`: date ID regex, done is bool,
  reflection ≤ 2000 chars), default-deny for everything else. Keep this
  structure; extend the validators, don't relax them.
- Rules tests live in `firestore-tests/` (Node,
  `@firebase/rules-unit-testing`, against the emulator) covering the four-way
  matrix: owner CRUD ✓, attacker UID ✗, unauthenticated ✗, invalid shapes ✗.

## Secrets & public-repo hygiene

- **Safe to commit:** `lib/firebase_options.dart` (client identifier, not a
  secret — the boundary is the rules), all app code, `firestore.rules`,
  `firebase.json`.
- **Never commit:** service-account JSON (CI's key lives only in GitHub
  Secrets), `.env*`, anything under `.firebase/`. `.gitignore` already covers
  `*service-account*.json`, `*-adminsdk-*.json`, `.env`, `.env.*`, `.firebase/`
  — keep those patterns intact.
- Before the repo flips public: run `gitleaks` over history and audit
  `git log` for accidental keys.
- Environments: **emulators are the only local environment** (Auth :9099,
  Firestore :8080); the real project (`anchor-51808323232`) is prod-only.
  Never run local dev against prod; never seed test data into prod.
- Defense in depth (console, not code): Web API key restricted to Identity
  Toolkit + Firestore, HTTP referrers limited to hosting domains + localhost.
  App Check is explicitly deferred — don't add it in v1.

## Account recovery

`docs/RECOVERY.md` + `tool/migrate_uid.js` (Phase 1) handle the catastrophic
lost-Google-account case by copying `users/{oldUid}/**` → `users/{newUid}/**`
with a temporarily-downloaded service-account key, deleted after use. Keep the
runbook current when the data model changes.
