import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, setDoc } from 'firebase/firestore';

const OWNER = 'owner-uid';
const ATTACKER = 'attacker-uid';

const validHabit = { name: 'Read', archived: false, color: null, sortOrder: 0 };
const validEntry = (id) => ({ date: id, done: true, reflection: null });

let testEnv;

function habitDoc(db, uid = OWNER, habitId = 'h1') {
  return doc(db, `users/${uid}/habits/${habitId}`);
}
function entryDoc(db, dateId, uid = OWNER, habitId = 'h1') {
  return doc(db, `users/${uid}/habits/${habitId}/entries/${dateId}`);
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'anchor-rules-test',
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: Number(process.env.FIRESTORE_PORT ?? 8080),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

describe('habits', () => {
  it('owner can create, read, update, and delete a valid habit', async () => {
    const db = testEnv.authenticatedContext(OWNER).firestore();
    await assertSucceeds(setDoc(habitDoc(db), validHabit));
    await assertSucceeds(getDoc(habitDoc(db)));
    await assertSucceeds(setDoc(habitDoc(db), { ...validHabit, name: 'Write' }));
    await assertSucceeds(deleteDoc(habitDoc(db)));
  });

  it('another uid cannot read or write the owner data', async () => {
    const attacker = testEnv.authenticatedContext(ATTACKER).firestore();
    await assertFails(setDoc(habitDoc(attacker, OWNER), validHabit));
    await assertFails(getDoc(habitDoc(attacker, OWNER)));
  });

  it('an unauthenticated client is denied', async () => {
    const anon = testEnv.unauthenticatedContext().firestore();
    await assertFails(setDoc(habitDoc(anon), validHabit));
    await assertFails(getDoc(habitDoc(anon)));
  });

  it('rejects invalid habit shapes', async () => {
    const db = testEnv.authenticatedContext(OWNER).firestore();
    await assertFails(setDoc(habitDoc(db), { ...validHabit, name: '' }));
    await assertFails(
      setDoc(habitDoc(db), { ...validHabit, name: 'x'.repeat(61) }),
    );
    await assertFails(setDoc(habitDoc(db), { ...validHabit, archived: 'no' }));
    await assertFails(setDoc(habitDoc(db), { ...validHabit, sortOrder: 1.5 }));
  });
});

describe('entries', () => {
  it('owner can create a valid date-keyed entry', async () => {
    const db = testEnv.authenticatedContext(OWNER).firestore();
    await assertSucceeds(setDoc(entryDoc(db, '2026-07-05'), validEntry('2026-07-05')));
  });

  it('rejects an entry whose date field disagrees with its doc id', async () => {
    const db = testEnv.authenticatedContext(OWNER).firestore();
    await assertFails(setDoc(entryDoc(db, '2026-07-05'), validEntry('2026-07-06')));
  });

  it('rejects a doc id that is not yyyy-MM-dd', async () => {
    const db = testEnv.authenticatedContext(OWNER).firestore();
    await assertFails(setDoc(entryDoc(db, '2026-7-5'), validEntry('2026-7-5')));
  });

  it('rejects a reflection over 2000 characters', async () => {
    const db = testEnv.authenticatedContext(OWNER).firestore();
    await assertFails(
      setDoc(entryDoc(db, '2026-07-05'), {
        date: '2026-07-05',
        done: true,
        reflection: 'x'.repeat(2001),
      }),
    );
  });

  it('another uid cannot write the owner entries', async () => {
    const attacker = testEnv.authenticatedContext(ATTACKER).firestore();
    await assertFails(
      setDoc(entryDoc(attacker, '2026-07-05', OWNER), validEntry('2026-07-05')),
    );
  });
});
