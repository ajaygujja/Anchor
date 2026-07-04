# Anchor — Final Specification & Implementation Plan (v2 / Final)

> **Status:** Approved for implementation. This document supersedes V1 entirely.
> **Audience:** Claude (Opus / Claude Code) executing the build, and Ajay reviewing it.
> **Prerequisite already done:** Firebase project is created.

---

## 0. What Anchor Is (One Paragraph)

Anchor is a single-user, cross-device habit tracker built around one philosophy: **never miss twice**. It is deliberately quiet — one tap is always enough, history is honest, and the only encouragement is identity-level micro-copy, never guilt or gamification. It is a Flutter **Web** app (PWA-installable) backed by Firebase (Auth + Firestore + Hosting), designed so the repo can safely go public later, and structured so a native mobile app can be added later without a rewrite.

---

## 1. Locked Decisions (Changelog from V1)

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | **Streak rule = "never miss twice", literally.** One missed day does NOT break a streak; two consecutive missed days do. | Encodes the actual philosophy into the math. No tokens, no settings, nothing to manage. |
| 2 | **Writing = expandable per-entry reflection.** The note field grows into a proper multi-line reflection attached to a habit's daily entry. No separate journal in v1. | "Bit more, not too much." One collection, one screen, easy to extend later. |
| 3 | **State management = Bloc** (`flutter_bloc`). | Matches Ajay's work stack; consistency beats novelty. |
| 4 | **Auth = Google Sign-In only. No account linking, no export.** Recovery = documented runbook (Section 8), leveraging the fact that Ajay owns the Firebase project. | Simplicity. Google handles day-to-day recovery better than anything custom. |
| 5 | **Day boundary = 3:00 AM local.** A check-in between midnight and 3am counts toward the *previous* calendar day. | Matches how humans think about "today" after a late night. |
| 6 | **Web-first, PWA-installable.** Native app deferred until the web version has been used daily for a while. Architecture keeps platform code isolated so mobile is additive later. | |
| 7 | **Environments = Firebase Emulator Suite for local dev + one real project for prod.** No second Firebase project. | Industry-standard solo setup: full offline dev loop, zero risk of polluting real data, no double project maintenance. |
| 8 | **Everything derived is computed at read time** (streaks, totals, heatmap). Nothing derived is ever persisted. | One source of truth. Editing history always self-heals. |

---

## 2. UX Specification

### 2.1 The Effective Day (3 AM Rule)

All "today" logic uses `effectiveDate`:

```
effectiveDate = (localNow - 3 hours).calendarDate
```

- Applies everywhere: check-in target, "done today" counts, streak math, heatmap bucketing, quote-of-the-day selection.
- Implemented in ONE place (`DayBoundary` service in `core/time/`) and injected everywhere. Never inline `DateTime.now()` in features — always go through the injected clock + boundary (this also makes streak logic fully unit-testable).

### 2.2 Screens

There is no bottom nav. Dashboard is home; everything else is one tap deeper.

**A. Sign-In screen**
- Single centered "Continue with Google" button, app name, one line of the philosophy ("Never miss twice.").
- On web: `FirebaseAuth.signInWithPopup(GoogleAuthProvider())`. No `google_sign_in` plugin needed for web (that plugin becomes relevant only when the mobile app is built — the `AuthRepository` abstraction hides this).
- Auth state persists (Firebase default `LOCAL` persistence); returning users skip this screen entirely.

**B. Dashboard (the daily screen)**
- Header: date ("Saturday, 5 July"), quiet "X of Y done today".
- **Quote card** (see 2.5).
- One card per active habit:
  - Habit name (tap → Habit Detail).
  - Current streak, shown quietly (e.g., "12 days") — no flame icons.
  - **One-tap check-in control** — a single large tap target on the card. Tap → done for `effectiveDate`. Instant optimistic UI, subtle scale/checkmark animation (≤300 ms).
  - **Undo:** after check-in, a snackbar for 5 seconds: "Done — Undo". Undo removes the entry. No confirmation dialogs anywhere in the app.
  - **Grace-state nudge:** if the habit was done the day before yesterday but NOT yesterday (i.e., streak is alive but one more miss kills it), the card shows the app's only nudge: a small line like *"Yesterday was a rest. Today keeps it alive."* Invitation tone, never alarm styling.
  - Optional reflection affordance: after checking in, a subtle "add a note" text button appears on the card (never required, never blocking). Opens a bottom sheet with one multi-line field.
- **Midnight/3am rollover:** if the app stays open across the boundary, a timer keyed to the next boundary triggers a state refresh — "today" updates without a manual reload.
- **Empty state (first run):** friendly, intentional: "One habit is enough to start." + a single "Add your first habit" button.

**C. Habit Detail** (tap habit name)
- Current streak + longest streak (computed).
- **Calendar heatmap** — month grid, color deepens with consistency; a single missed day inside a live streak renders as a *neutral* (not red) cell; only a broken chain reads as plain empty. Honest, not punitive.
- Chronological entry list (most recent first): date, done state, reflection preview. Tap an entry → edit sheet: toggle done, edit reflection, delete entry. Editing any past day recomputes everything instantly (because nothing is stored).
- Milestone micro-copy appears here and on the dashboard card at thresholds (see 2.4).

**D. Manage Habits** (behind an icon in the dashboard app bar)
- Add (name + optional color), rename, archive (never hard-delete a habit with history; archive hides it from the dashboard but keeps entries).
- Reordering habits: simple drag handle, persisted as `sortOrder` int.

### 2.3 Reflections (the "write something down" feature)

- Stored as `reflection` (string, nullable) on the daily Entry document.
- UI: a plain multi-line field in a bottom sheet. Auto-detect URLs on render and make them tappable; input stays a single plain field.
- Never blocks check-in. Can be added/edited any time, including on past entries.
- Soft cap 2,000 characters (validated in security rules too).

### 2.4 Encouragement (identity, not celebration)

- **Milestones** (7, 21, 30, 60, 100, 180, 365 days): one line of micro-copy on the habit card that day, e.g. Day 30 → *"This is who you are now."* No confetti, no badges, no sounds.
- **Recovery framing** on the grace-state nudge (see 2.2B).
- **Weekly recap card** on the dashboard (Monday): *"Last week: 5 of 7 days — steady."* One line, dismissible, computed on the fly.
- Copy lives in one constants file (`core/copy.dart`) so the voice is auditable and consistent.

### 2.5 Quote Card (designed component, not a text line)

- A typography-led card: large serif/display quote text, small attribution line, generous padding, subtle background tint that adapts to light/dark theme. Feels like a pull-quote in a magazine, not a `Text()` widget.
- **Quote of the day is deterministic:** `quotes[dayOfYear(effectiveDate) % quotes.length]` — same quote all day, changes at the 3am boundary, no randomness.
- Quotes are a local asset (`assets/quotes.json`, list of `{text, author}`). Ajay will populate the content with Claude Code during the build; the spec covers only the component and mechanism.

### 2.6 Theming & Polish

- **Dark mode is first-class** (night check-ins are the norm). `ThemeMode.system` default + manual toggle in Manage screen.
- Material 3, one seed color, restrained motion (standard easing, ≤300 ms), no celebratory animation beyond the check-in micro-acknowledgment.
- Responsive: single-column layout, max content width ~600 px centered on desktop, full-width on phone browsers. One layout, no breakpoint forks in v1.

---

## 3. Streak Algorithm (Precise Definition)

**Definitions**
- `D` = set of calendar dates (effective dates) where the entry exists and `done == true`, for one habit.
- `today` = `effectiveDate(now)`.
- A **chain** is a run of days where there are never 2+ consecutive dates missing from `D`.

**Current streak**
1. Determine chain end: if `today ∈ D`, end = today. Else if `yesterday ∈ D`, end = yesterday (today is merely *pending*, not a miss). Else if `today-2 ∈ D`, end = today-2 and the streak is in **grace state** (one more miss breaks it → show nudge). Else current streak = 0.
2. Walk backward from the chain end: keep extending while each preceding gap of missed days is ≤ 1. Stop at the first gap of ≥ 2 consecutive missed days, or at the habit's first entry.
3. **Current streak value = count of DONE days in the chain** (grace days don't add to the number; they just don't reset it). Example: done Mon, miss Tue, done Wed → streak = 2, chain alive.

**Longest streak** — apply the same chain rule across the full history; longest = max done-day count over all chains.

**Edge cases (all must have unit tests)**
- Habit created today, no entries → streak 0, no nudge.
- Done today only → 1.
- Done yesterday, not today → streak unchanged, no nudge (pending, not missed).
- Done day-before-yesterday, missed yesterday, not today → streak alive in grace, nudge shown.
- Missed yesterday AND day before → streak 0.
- Entry edited in the past (done→not done creating a 2-gap) → chain splits correctly.
- Entries before habit's `createdAt` (possible via backfill edits) → allowed, computed normally.
- Check-in at 01:30 local → belongs to previous calendar date.
- All date math in **local time via injected clock**; never UTC for day bucketing.

Implementation lives in pure Dart (`domain/streaks/streak_calculator.dart`) with **zero Flutter/Firebase imports** — a function from `(Set<LocalDate> doneDates, LocalDate today) → StreakResult{current, longest, isInGrace}`. This is the most-tested file in the repo.

---

## 4. Data Model (Firestore)

Everything is scoped under the user's UID **by path** — this makes security rules trivial and correct.

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

**Why the entry doc ID is the date:**
- Guarantees exactly one entry per habit per day at the database level (idempotent writes — a double-tap or an offline retry can never create duplicates).
- Check-in is a single `set(merge: true)` — no read-before-write, no transactions needed.
- Undo is a single `delete()`.

**Reads at scale:** streaks/heatmaps read a habit's entries with `orderBy(date)`. One year of daily use ≈ 365 tiny docs per habit — trivial for Firestore and for a personal tool. If this ever grows (multi-year, many habits), the upgrade path is client-side caching of the entry set + paginated windows; **do not** build stored aggregates now (they would violate the one-source-of-truth rule).

**Real-time:** all lists use Firestore snapshots (streams), so laptop and phone stay in sync live.

**Offline:** enable Firestore persistence for web at startup:
```dart
FirebaseFirestore.instance.settings =
    const Settings(persistenceEnabled: true);
```
Check-ins tap-and-forget: optimistic UI from the local write; sync happens whenever the network returns. This is non-negotiable for daily trust.

---

## 5. Architecture

### 5.1 Layers (clean-ish, pragmatic)

```
presentation (Widgets + Blocs/Cubits)
      ↓ depends on
domain (entities, pure logic: streaks, day boundary, validation)
      ↑ implemented by
data (repositories: Firestore data sources, DTO mapping)
```

- **Domain is pure Dart.** No Flutter, no Firebase imports. This is what makes the future mobile app cheap: presentation and data can vary per platform; domain never changes.
- **Repositories are interfaces in domain, implemented in data.** Blocs depend only on the interfaces. (`AuthRepository`, `HabitRepository`, `EntryRepository`.)
- Failures surface as sealed `Failure` types (network / permission / unknown), never raw exceptions in the UI layer.

### 5.2 Folder Structure

```
lib/
  main.dart                     # bootstrap: Firebase init, emulator wiring, DI, runApp
  app/
    app.dart                    # MaterialApp.router, themes
    router.dart                 # go_router config + auth redirect
    di.dart                     # composition root (constructor injection; no service locator needed at this size)
  core/
    time/day_boundary.dart      # effectiveDate logic (uses package:clock)
    copy.dart                   # all user-facing strings & milestone copy
    theme/                      # light/dark themes, quote-card text styles
    failures.dart
  domain/
    entities/habit.dart, entry.dart, streak_result.dart
    repositories/               # abstract interfaces
    streaks/streak_calculator.dart
  data/
    dtos/                       # Firestore <-> entity mapping
    repositories/               # Firestore implementations
  features/
    auth/     (bloc/, view/)
    dashboard/(bloc/, view/, widgets/: habit_card, quote_card, weekly_recap)
    habit_detail/(bloc/, view/, widgets/: heatmap, entry_list, entry_edit_sheet)
    manage_habits/(bloc/, view/)
assets/quotes.json
test/                           # mirrors lib/ structure
firestore.rules
firebase.json
.github/workflows/ci-cd.yml
```

### 5.3 Blocs

| Bloc/Cubit | Responsibility |
|---|---|
| `AuthBloc` | Streams `authStateChanges`; states: unknown / unauthenticated / authenticated(uid). Drives router redirect. |
| `DashboardBloc` | Combines habits stream + recent-entries streams → per-habit view models (streak, grace flag, doneToday, milestone copy). Handles boundary-rollover refresh. |
| `CheckInCubit` | Check-in / undo for one habit (optimistic). |
| `HabitDetailBloc` | Full entry history stream + computed streaks + heatmap data for one habit. |
| `EntryEditCubit` | Toggle done / edit reflection / delete for a past entry. |
| `ManageHabitsBloc` | CRUD + archive + reorder. |

Conventions: `Equatable` states, sealed events, `bloc_test` for every bloc, no business logic in widgets.

### 5.4 Key Packages

`firebase_core`, `firebase_auth`, `cloud_firestore`, `flutter_bloc`, `equatable`, `go_router`, `intl`, `clock`, `url_launcher` (tappable links in reflections). Dev: `bloc_test`, `mocktail`, `flutter_lints` (or `very_good_analysis` for a stricter bar — Claude's pick during setup, then never argue with it).

---

## 6. Security (Public-Repo-Ready from Day One)

### 6.1 The Boundary: Firestore Rules

`firestore.rules` (committed to the repo — rules-as-code is good practice):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{uid}/habits/{habitId} {
      allow read, delete: if isOwner(uid);
      allow create, update: if isOwner(uid) && validHabit();

      match /entries/{dateId} {
        allow read, delete: if isOwner(uid);
        allow create, update: if isOwner(uid) && validEntry(dateId);
      }
    }

    match /{document=**} { allow read, write: if false; }  // default deny

    function isOwner(uid) {
      return request.auth != null && request.auth.uid == uid;
    }
    function validHabit() {
      let d = request.resource.data;
      return d.name is string && d.name.size() >= 1 && d.name.size() <= 60
          && d.archived is bool
          && d.sortOrder is int;
    }
    function validEntry(dateId) {
      let d = request.resource.data;
      return d.date == dateId
          && dateId.matches('^\\d{4}-\\d{2}-\\d{2}$')
          && d.done is bool
          && (!('reflection' in d) || d.reflection == null
              || (d.reflection is string && d.reflection.size() <= 2000));
    }
  }
}
```

Rules get **unit tests** via `@firebase/rules-unit-testing` against the emulator (a small Node test file in `firestore-tests/`): owner can CRUD own data; another UID cannot read/write; unauthenticated denied; invalid entry shapes rejected. CI runs these.

### 6.2 What's Public vs. Secret

- **Safe to commit:** Firebase web config (`firebase_options.dart`) — it's a client identifier, not a secret; the boundary is the rules above. All app code. `firestore.rules`, `firebase.json`.
- **Never commit:** any **service account JSON** (only CI needs one, and it lives in GitHub Secrets — see §10), any local `.env`. `.gitignore` from day one includes: `*.json` service-account patterns (`*service-account*.json`, `*-adminsdk-*.json`), `.env*`, `/build`, `.firebase/`.
- **Defense in depth:** in Google Cloud Console, restrict the Web API key to Identity Toolkit + Firestore APIs, and to HTTP referrers: your `*.web.app` / `*.firebaseapp.com` domains + `localhost`.
- **Optional later hardening (not v1):** Firebase App Check with reCAPTCHA v3 for web. Deferred — adds setup friction, and rules already enforce ownership.

### 6.3 Public-Repo Hygiene

- MIT license file, honest README (what it is, the philosophy, screenshots later).
- Before flipping public: `git log` audit for accidentally committed keys (or run `gitleaks` once).
- No personal data lives in the repo — quotes.json is the only content file, and it's intentional.

---

## 7. Account Recovery Runbook (docs/RECOVERY.md in repo)

Day-to-day recovery (forgotten device, new phone) is Google's problem — their account recovery is stronger than anything custom. The catastrophic case only:

1. **Lost the Google account permanently.** You own the Firebase project (ensure the project has a second Owner: add a backup Google identity as an IAM Owner in Firebase console — one console click, zero code).
2. Sign into Anchor with a new Google account → new UID with empty data.
3. In Firebase Console → Firestore, locate old `users/{oldUid}` tree; run the one-time copy script (`tool/migrate_uid.js`, checked into the repo, run locally with a temporarily-downloaded service account key, deleted after use) to copy `users/{oldUid}/**` → `users/{newUid}/**`.
4. Delete the old tree. Done.

The runbook + script exist in the repo from Phase 1 so future-you never has to figure this out under stress.

---

## 8. Flutter Web + Hosting, From Zero (You've Never Deployed Web — Full Instructions)

You know Flutter mobile; here's everything that's different about web, in order.

### 8.1 One-Time Machine Setup

```bash
flutter upgrade                      # ensure a recent stable
flutter devices                      # should list "Chrome" — web is enabled by default on current stable
npm install -g firebase-tools        # Firebase CLI (needs Node.js ≥ 18)
firebase login
dart pub global activate flutterfire_cli
```

### 8.2 Project Wiring (Firebase project already exists)

```bash
flutter create anchor --platforms web --org com.ajay   # or add web to a repo: flutter create . --platforms web
cd anchor
flutterfire configure                # pick your project, select Web → generates lib/firebase_options.dart
```

In Firebase Console: **Authentication → Sign-in method → enable Google.** Add authorized domains (localhost + the hosting domains appear automatically).

### 8.3 Local Development Loop (with Emulators — your "dev environment")

```bash
firebase init emulators              # choose: Auth, Firestore; accept default ports; enable emulator UI
firebase emulators:start
flutter run -d chrome --dart-define=USE_EMULATORS=true
```

In `main.dart`, when `USE_EMULATORS` is true:
```dart
await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
```
This is the whole dev/prod split: emulators locally (fake data, works offline, resets freely), the real project is prod only. Hot reload works on web exactly like mobile.

**Web gotchas coming from mobile (know these upfront):**
- No `dart:io`. Anything platform-ish goes through abstractions (you barely need any here).
- Sign-in uses `signInWithPopup` — must be triggered by a user gesture (button tap), or browsers block the popup.
- Cold start is Flutter Web's weak point: keep the default loading screen decent (simple splash in `web/index.html`), build with `--release` for real judgments, and don't add heavy packages casually.
- Browser back button: `go_router` handles URL/back correctly — use it from day one, don't retrofit.
- Test in Chrome AND one mobile browser (Android Chrome) regularly; that's your real usage.

### 8.4 PWA (Installable Like an App)

Flutter's web template already ships a `manifest.json` + service worker. To make it feel first-class:
- Edit `web/manifest.json`: name "Anchor", theme/background colors matching the app, proper 192/512 icons (maskable).
- `<meta name="theme-color">` in `web/index.html` matching the theme.
- After deploying: open the site in Android Chrome → "Add to Home screen" → it launches standalone, full-screen, with your icon. This is your "app" until the native one exists.
- The generated `flutter_service_worker.js` handles caching/updates automatically; don't hand-roll caching in v1.

### 8.5 Hosting Setup & First Deploy

```bash
firebase init hosting     # public directory: build/web ; single-page app: Yes ; GitHub deploys: Yes (see §10)
flutter build web --release
firebase deploy --only hosting
```
Your app is now live at `https://<project-id>.web.app`. That's the entire deployment. Custom domain is optional (Hosting → Add custom domain → two DNS records, free SSL automatic).

Add cache headers in `firebase.json` (industry-standard for Flutter Web):
```json
"headers": [
  { "source": "**/*.@(js|wasm)", "headers": [{ "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }] },
  { "source": "/index.html", "headers": [{ "key": "Cache-Control", "value": "no-cache" }] },
  { "source": "flutter_service_worker.js", "headers": [{ "key": "Cache-Control", "value": "no-cache" }] }
]
```

Deploy rules whenever they change: `firebase deploy --only firestore:rules`.

---

## 9. Testing Strategy (Where the Effort Goes)

| Layer | Tooling | Depth |
|---|---|---|
| `streak_calculator` + `day_boundary` | plain `test` | **Exhaustive** — every edge case in §3, table-driven. The soul of the app. |
| Blocs | `bloc_test` + `mocktail` repos | All states/transitions incl. optimistic check-in + undo, rollover refresh. |
| Repositories | `fake_cloud_firestore` or emulator integration | Mapping + idempotent date-keyed writes. |
| Security rules | `@firebase/rules-unit-testing` (Node, emulator) | Owner/attacker/unauthenticated/invalid-shape matrix. |
| Widgets | `flutter_test` | Light: habit card states (done / pending / grace nudge / milestone), quote card, empty state. |

`flutter analyze` + `dart format --set-exit-if-changed` gate everything in CI.

---

## 10. CI/CD (GitHub Actions → Firebase Hosting)

Saying **Yes** to "GitHub deploys" during `firebase init hosting` auto-creates a deploy service account and stores it as a **GitHub repo secret** (`FIREBASE_SERVICE_ACCOUNT_<PROJECT>`) — the key never touches the repo. It also scaffolds two workflows; consolidate into one `ci-cd.yml`:

- **On pull request:** checkout → Flutter setup → `flutter analyze` → `flutter test` → rules tests (start emulator, run Node tests) → `flutter build web --release` → deploy to a **Hosting preview channel** (temporary URL posted on the PR).
- **On push to `main`:** same checks → deploy to the **live channel** + `firebase deploy --only firestore:rules`.

This gives you review-with-a-real-URL and an always-deployable main — the industry-standard solo workflow, with zero servers.

---

## 11. Implementation Plan (For Claude Opus / Claude Code to Execute)

Ordered phases; each has acceptance criteria. Do not start a phase before the previous one's criteria pass. Firebase project exists; start at Phase 0.

### Phase 0 — Repo & Skeleton (½ day)
1. `flutter create` (web only), commit the default `.gitignore` + additions from §6.2, MIT license, README stub.
2. Lints (`flutter_lints` or `very_good_analysis`), `analysis_options.yaml`.
3. Folder structure from §5.2 with placeholder files; add all packages from §5.4.
4. `flutterfire configure`; `main.dart` bootstrap with `USE_EMULATORS` dart-define wiring.
5. `firebase init` (emulators + hosting, GitHub deploys = Yes); commit `firebase.json`, `firestore.rules` (from §6.1), cache headers.
6. CI workflow running analyze + (empty) tests on PR.
**Accept:** app runs in Chrome against emulators; CI green; rules file deployed.

### Phase 1 — Auth + Foundation (1 day)
1. `AuthRepository` (interface + Firebase impl: `signInWithPopup`, `signOut`, `authStateChanges`).
2. `AuthBloc`; `go_router` with redirect (unauthenticated → sign-in, authenticated → dashboard).
3. Sign-in screen per §2.2A. Light/dark themes scaffolded.
4. Firestore rules tests in `firestore-tests/`, wired into CI.
5. `docs/RECOVERY.md` + `tool/migrate_uid.js` (§7). Add backup IAM Owner (manual console step — note it in README).
**Accept:** Google sign-in works against emulator AND once against prod; refresh keeps session; rules tests pass; attacker-UID test fails writes.

### Phase 2 — Habits CRUD (1 day)
1. `Habit` entity, DTO, `HabitRepository` (streams, add, rename, archive, reorder).
2. `ManageHabitsBloc` + Manage screen (§2.2D). Dashboard shows a plain habit list (no streaks yet) + empty state.
**Accept:** create/rename/archive/reorder sync live across two browser windows; archived habits hidden but data intact.

### Phase 3 — Core Loop: Check-In + Entries (1–1.5 days)
1. `DayBoundary` service (+ exhaustive tests), `Entry` entity/DTO, `EntryRepository` with **date-keyed idempotent** `setEntry`, `deleteEntry`, `entriesStream(habitId)`.
2. `CheckInCubit`: optimistic check-in, 5-s undo snackbar.
3. Entry list + edit sheet on Habit Detail (toggle done, reflection ≤2000 chars with tappable links, delete).
4. Enable Firestore web persistence; verify offline check-in (DevTools → offline → tap → reload → online → synced).
**Accept:** double-tap creates one doc; 1:30 AM check-in lands on previous date (test via injected clock); offline flow works; editing past entries works.

### Phase 4 — Streaks, Dashboard, Heatmap (1.5 days)
1. `streak_calculator.dart` + the full §3 test table **first** (TDD here, genuinely).
2. `DashboardBloc` composing habits + entries → view models (streak, doneToday, grace flag, milestone copy); boundary-rollover timer refresh.
3. Habit card final form (§2.2B): check-in animation, grace nudge, milestone line.
4. Heatmap widget on Habit Detail (month grid, neutral grace cells), current/longest streaks.
5. Quote card component + deterministic quote-of-day + `assets/quotes.json` (content populated with Ajay during build).
**Accept:** all §3 edge cases green; nudge appears/disappears correctly across simulated days; heatmap matches hand-computed fixture; quote stable within a day, changes at 3 AM.

### Phase 5 — Polish + PWA + Ship (1 day)
1. Weekly recap card (Mondays). Empty states, loading states, error surfaces (quiet retry, no scary reds).
2. Dark-mode audit of every screen; motion audit (≤300 ms, standard easing).
3. PWA manifest/icons/theme-color (§8.4); test "Add to Home screen" on Android Chrome.
4. `flutter build web --release` performance pass: acceptable cold load on mobile network, decent splash in `index.html`.
5. README with screenshots; `gitleaks` scan; first production deploy via merge to `main`.
**Accept:** installed PWA on phone used for a real check-in end-to-end; CI deploys on merge; repo is public-ready.

### Standing Rules for the Implementing Agent
- Domain layer: zero Flutter/Firebase imports, ever.
- Every user-facing string goes through `core/copy.dart`.
- No stored derived data. If you're about to persist a streak/total — stop, compute it.
- No confirmation dialogs; reversibility (undo/edit) instead.
- All time via injected `clock` + `DayBoundary`; direct `DateTime.now()` in features is a review-blocker.
- Prefer the codebase's existing patterns over introducing new ones (match conventions already established in earlier phases).
- Keep PRs per phase; CI must be green before the next phase.

---

## 12. Explicitly Out of Scope for v1

Notifications/reminders, multi-user or sharing, native mobile apps, data export, account linking, App Check, stored aggregates, schedules/frequencies (everything is daily), separate journal, analytics/telemetry of any kind.

---

*End of specification. Total estimated build: ~6 focused days.*
