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
3. Run the one-time copy script (`tool/migrate_uid.js`, added in Phase 1) locally
   with a temporarily-downloaded service account key:
   copies `users/{oldUid}/**` → `users/{newUid}/**`.
   Delete the service account key immediately after.
4. Delete the old `users/{oldUid}` tree. Done.

The migration script is checked into the repo so future-you never has to figure
this out under stress.
