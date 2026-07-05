#!/usr/bin/env node
// One-time UID migration for the catastrophic recovery case (spec §7):
// copies users/{from}/** -> users/{to}/** with a temporarily-downloaded
// service-account key. Run per docs/RECOVERY.md, then delete the key.
//
// Usage:
//   node tool/migrate_uid.js --key ./service-account.json --from <oldUid> --to <newUid>
//
// Requires firebase-admin (installed on demand; not an app dependency):
//   npm install firebase-admin

const admin = require('firebase-admin');

function arg(name) {
  const i = process.argv.indexOf(`--${name}`);
  return i === -1 ? undefined : process.argv[i + 1];
}

async function copyCollection(db, srcRef, dstRef) {
  const snapshot = await srcRef.get();
  for (const docSnap of snapshot.docs) {
    const dstDoc = dstRef.doc(docSnap.id);
    await dstDoc.set(docSnap.data());
    for (const sub of await docSnap.ref.listCollections()) {
      await copyCollection(db, sub, dstDoc.collection(sub.id));
    }
  }
  return snapshot.size;
}

async function main() {
  const keyPath = arg('key');
  const fromUid = arg('from');
  const toUid = arg('to');

  if (!keyPath || !fromUid || !toUid) {
    console.error(
      'Usage: node tool/migrate_uid.js --key <key.json> --from <oldUid> --to <newUid>',
    );
    process.exit(1);
  }

  admin.initializeApp({
    // eslint-disable-next-line global-require, import/no-dynamic-require
    credential: admin.credential.cert(require(require('path').resolve(keyPath))),
  });
  const db = admin.firestore();

  const srcUser = db.collection('users').doc(fromUid);
  const dstUser = db.collection('users').doc(toUid);

  const srcSnap = await srcUser.get();
  if (srcSnap.exists) await dstUser.set(srcSnap.data());

  let habitCount = 0;
  for (const sub of await srcUser.listCollections()) {
    habitCount += await copyCollection(db, sub, dstUser.collection(sub.id));
  }

  console.log(`Copied users/${fromUid} -> users/${toUid} (${habitCount} habit docs).`);
  console.log('Verify in the app, delete the old tree, then delete and revoke this key.');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
