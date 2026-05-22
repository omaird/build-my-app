import { describe, it, beforeAll, afterAll, beforeEach, expect } from 'vitest';
import {
  assertFails,
  assertSucceeds,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import { getTestEnv } from './setup';

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await getTestEnv();
});

afterAll(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

describe('content collections', () => {
  it('allows anyone to read duas', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'duas/1'), { titleEn: 'Test' });
    });
    const unauth = env.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(unauth, 'duas/1')));
  });

  it('blocks non-admin from writing duas', async () => {
    const user = env.authenticatedContext('user-1').firestore();
    await assertFails(setDoc(doc(user, 'duas/1'), { titleEn: 'Test' }));
  });

  it('allows admin to write duas', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'user_profiles/admin-1'), {
        userId: 'admin-1', isAdmin: true, streak: 0, totalXp: 0, level: 1,
      });
    });
    const admin = env.authenticatedContext('admin-1').firestore();
    await assertSucceeds(setDoc(doc(admin, 'duas/1'), { titleEn: 'Test' }));
  });

  it('blocks non-admin write to journeys', async () => {
    const user = env.authenticatedContext('user-1').firestore();
    await assertFails(setDoc(doc(user, 'journeys/1'), { name: 'Test' }));
  });

  it('blocks non-admin write to categories', async () => {
    const user = env.authenticatedContext('user-1').firestore();
    await assertFails(setDoc(doc(user, 'categories/1'), { name: 'Test' }));
  });
});

describe('user_profiles self-promotion guard', () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'user_profiles/user-1'), {
        userId: 'user-1', isAdmin: false, streak: 0, totalXp: 0, level: 1,
      });
    });
  });

  it('user can update their own non-admin fields', async () => {
    const user = env.authenticatedContext('user-1').firestore();
    await assertSucceeds(updateDoc(doc(user, 'user_profiles/user-1'), { streak: 5 }));
  });

  it('user CANNOT set their own isAdmin to true', async () => {
    const user = env.authenticatedContext('user-1').firestore();
    await assertFails(updateDoc(doc(user, 'user_profiles/user-1'), { isAdmin: true }));
  });

  it('admin CAN set isAdmin on another user', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'user_profiles/admin-1'), {
        userId: 'admin-1', isAdmin: true, streak: 0, totalXp: 0, level: 1,
      });
    });
    const admin = env.authenticatedContext('admin-1').firestore();
    await assertSucceeds(updateDoc(doc(admin, 'user_profiles/user-1'), { isAdmin: true }));
  });
});

describe('user activity ownership', () => {
  it('user can write their own activity', async () => {
    const user = env.authenticatedContext('user-1').firestore();
    await assertSucceeds(setDoc(doc(user, 'user_activity/user-1/dates/2026-05-08'), {
      duasCompleted: [], xpEarned: 0,
    }));
  });

  it('user cannot write another user activity', async () => {
    const user = env.authenticatedContext('user-1').firestore();
    await assertFails(setDoc(doc(user, 'user_activity/user-2/dates/2026-05-08'), {
      duasCompleted: [], xpEarned: 0,
    }));
  });
});
