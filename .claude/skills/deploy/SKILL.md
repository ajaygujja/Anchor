---
name: deploy
description: Deploy Anchor to Firebase Hosting and/or deploy Firestore rules, with the pre-flight checks that keep prod trustworthy. Use when the user asks to deploy, ship, release, or push rules to production.
---

# Deploying Anchor

Prod = Firebase project `anchor-51808323232` (Firestore `asia-south1`,
hosting at `https://anchor-51808323232.web.app`). Emulators are dev; prod is
deploy-only — never seed or test-write against prod data.

## Pre-flight (all must pass before any deploy)

1. Working tree clean on `main`, local `main` == `origin/main`
   (`git status`, `git log origin/main..main`). Deploying unpushed code breaks
   the "main is always deployable" contract.
2. Run the `check` skill — format, analyze, tests, greps all green.
3. If `firestore.rules` changed since the last deploy: rules tests in
   `firestore-tests/` pass against the emulator first.
4. Confirm with the user before the FIRST production deploy of a session —
   deploys are outward-facing.

## Hosting deploy

```bash
flutter build web --release
firebase deploy --only hosting
```

- Always `--release` — debug builds are not representative on web.
- Note: once CI deploy-on-merge is wired (spec §10), manual hosting deploys
  become the exception; prefer merging to `main` and letting CI ship. Check
  `.github/workflows/ci-cd.yml` to see whether that wiring exists yet before
  choosing the manual path.

## Rules deploy

```bash
firebase deploy --only firestore:rules
```

Deploy rules whenever `firestore.rules` changes — the committed file being
"correct" does nothing until deployed. Rules and the code depending on them
ship together.

## Post-deploy verification (not optional)

1. Open the live URL; confirm the new build actually loaded (hard-refresh —
   the service worker serves the old build until it updates; a stale page is
   expected once, not twice).
2. Sign in and perform one real end-to-end action (e.g. a check-in) against
   prod.
3. Check the browser console for errors.
4. If rules changed: confirm a normal in-app write still succeeds (an
   over-tightened validator that blocks the owner is the classic failure).

Report what was deployed (hosting, rules, or both), the verification results,
and the live URL.
