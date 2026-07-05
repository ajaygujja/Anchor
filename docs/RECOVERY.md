# Account Recovery Runbook

Day-to-day recovery (forgotten device, new phone) is Google's problem — their
account recovery is stronger than anything custom. This runbook covers only the
**catastrophic** case: permanently losing the Google account.

## Prerequisite (do once, now)

Add a **backup IAM Owner** to the Firebase project: Firebase console → Project
settings → Users and permissions → add a second Google identity as **Owner**.
One click, zero code. Without this, losing the primary account is unrecoverable.

## If the Google account is lost permanently

1. Sign into Anchor with a new Google account → this creates a new UID with
   empty data.
2. In Firebase Console → Firestore, locate the old `users/{oldUid}` tree.
3. Download a temporary service-account key (Project settings → Service accounts
   → Generate new private key). It is git-ignored (`*-adminsdk-*.json`); never
   commit it.
4. Run the one-time copy script from the repo root:
   ```bash
   node tool/migrate_uid.js --key ./<adminsdk-key>.json --from <oldUid> --to <newUid>
   ```
   It copies `users/{oldUid}/**` → `users/{newUid}/**` (habits + every entry).
   Delete the key from disk and revoke it immediately after.
5. Sign in as the new account and confirm data is present (streaks/heatmaps
   recompute from the copied entries — nothing derived is stored).
6. Delete the old `users/{oldUid}` tree. Done.

The migration script is checked into the repo so future-you never has to figure
this out under stress.
