# Milestone 1 — Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. The execution model is **multi-agent + skill-driven** per § 10 of the spec — the main session dispatches each task to a specialized subagent that invokes its own domain skills before writing code.

**Goal:** Migrate the RIZQ web app from Neon + Better Auth to Firestore + Firebase Auth, eliminating the manual seed-script workflow and the iOS Firestore cold-start band-aids, leaving a single source of truth for both clients.

**Architecture:** Web reads/writes Firestore directly via `@firebase/firestore` Web SDK; auth via `firebase/auth`. Admin authorization via existing `user_profiles.isAdmin` rules helper (no custom claims, no CLI). iOS gets a new `ContentFeature` reducer scoped under `AppFeature` and a `CachedContentClient` wrapper around the existing `FirestoreContentClient`. Cutover is gated by a `VITE_FIRESTORE_CUTOVER` env flag for atomic deploy + env-flip rollback.

**Tech Stack:** Web — React 18, TypeScript 5, Vite, TanStack Query v5, Firebase Web SDK v10+, Tailwind, shadcn/ui. Tests — Playwright + `@firebase/rules-unit-testing` v3 + Firebase Emulator Suite. iOS — Swift 5.9, SwiftUI iOS 17+, TCA 1.17, Firebase iOS SDK 11+, XCTest, swift-snapshot-testing.

**Spec:** [docs/superpowers/specs/2026-05-08-foundation-milestone-design.md](../specs/2026-05-08-foundation-milestone-design.md). All decisions and rationale live there. This plan is the executable form.

---

## Execution Conventions (read before starting)

**Branching.** Milestone branch: `m1-foundation` (cut from `main` at start). Each parallel-stream task runs in its own worktree on a sub-branch named `m1-stepN-<stream>` (e.g., `m1-step3-read-hooks`). Sub-branches merge to `m1-foundation` after their verification passes; `m1-foundation` merges to `main` only after the full milestone completes and the final review passes.

**Per-subagent skill invocations.** Every dispatched subagent must invoke skills BEFORE writing code, in this order:
1. **Web TS/React subagents:** `superpowers:test-driven-development`, then `context7` (look up Firebase Web SDK v10+ APIs and React Query v5 patterns), then implement, then `vercel:react-best-practices` after editing TSX, then `superpowers:verification-before-completion` before marking done.
2. **iOS Swift subagents:** `superpowers:test-driven-development` (TestStore tests), `context7` (TCA 1.17 + Firebase iOS 11+), implement, run `xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build` per [RIZQ-iOS/CLAUDE.md](../../../RIZQ-iOS/CLAUDE.md), then `superpowers:verification-before-completion`.
3. **Firestore Rules subagents:** `context7` (Firestore Security Rules v2 + `@firebase/rules-unit-testing` v3), TDD with rules tests as the spec.
4. **All subagents:** `superpowers:using-git-worktrees` if running in parallel, `superpowers:verification-before-completion` before reporting done.

**Commit cadence.** One commit per task minimum. The "Commit" step at the end of each task is non-optional. Commit messages follow the existing convention (`feat(scope):`, `fix(scope):`, `chore:`, etc.).

**Parallel dispatch markers.** Tasks with `**Parallel with:** Tasks X, Y, Z` may be dispatched concurrently to separate subagents in separate worktrees. Tasks without that marker run sequentially.

**Definition of done per task.** All TDD steps pass + commit landed + (where applicable) `vercel:react-best-practices` or `xcodebuild` produced no warnings.

**Review checkpoints (mandatory):** at end of Step 2, Step 3 staging, Step 5, and milestone end (after Step 7). See § 10.5 of the spec.

---

## File Structure (decomposition lock-in)

### Web — files created
- `src/lib/firebase.ts` — Firebase Web SDK initialization (Auth + Firestore)
- `src/lib/firestore-mappers.ts` — Document ↔ frontend type mappers (camelCase passthrough; mostly type assertions)
- `src/hooks/useFirestoreUserProfile.ts` — Replacement for Neon-backed profile fetching
- `src/hooks/useFirestoreActivity.ts` — Replaces `useActivity`
- `tests/rules/firestore-rules.test.ts` — Firestore Security Rules unit tests
- `e2e/practice.spec.ts` — Practice golden path
- `e2e/journeys.spec.ts` — Journey subscription flow
- `e2e/admin-duas.spec.ts` — Admin CRUD flow
- `firebase.json` (modified) — Add emulator config

### Web — files modified
- `src/contexts/AuthContext.tsx` — Better Auth → Firebase Auth Web
- `src/hooks/useDuas.ts`, `src/hooks/useJourneys.ts`, `src/hooks/useUserHabits.ts` — Neon SQL → Firestore
- `src/hooks/admin/useAdminDuas.ts`, `useAdminJourneys.ts`, `useAdminCategories.ts`, `useAdminCollections.ts`, `useAdminUsers.ts` — SQL writes → Firestore writes
- `src/pages/SettingsPage.tsx` — Wire reset TODO
- `src/pages/SignInPage.tsx`, `SignUpPage.tsx` — Use Firebase Auth providers
- `firestore.rules` — Add admin-write gates to content collections + self-promotion block
- `package.json` — Add `firebase`, remove `@neondatabase/serverless`, `better-auth`
- `.env.example` — Remove `VITE_DATABASE_URL`/`VITE_AUTH_URL`, add `VITE_FIREBASE_*` and `VITE_FIRESTORE_CUTOVER`
- `.gitignore` — Add `firebase-debug.log`, `firebase-debug.*.log`

### Web — files deleted
- `src/lib/db.ts`
- `src/lib/auth-client.ts`

### iOS — files created
- `RIZQ-iOS/RIZQ/Features/Content/ContentFeature.swift` — New TCA reducer
- `RIZQ-iOS/RIZQ/Dependencies/CachedContentClient.swift` — Cache wrapper around `FirestoreContentClient`
- `RIZQ-iOS/RIZQTests/ContentFeatureTests.swift`
- `RIZQ-iOS/RIZQTests/CachedContentClientTests.swift`

### iOS — files modified
- `RIZQ-iOS/RIZQ/App/AppFeature.swift` — Add `content: ContentFeature.State`, scope into child reducers
- `RIZQ-iOS/RIZQ/App/AppView.swift` — Pass content scope to child views
- `RIZQ-iOS/RIZQ/App/RIZQApp.swift` — Enable Firestore `PersistentCacheSettings`
- `RIZQ-iOS/RIZQ/Features/Adkhar/AdkharFeature.swift` — Consume from shared content; remove fetch/timeout/SampleData fallback
- `RIZQ-iOS/RIZQ/Features/Journeys/JourneysFeature.swift` — Same pattern
- `RIZQ-iOS/RIZQ/Features/Library/LibraryFeature.swift` — Same pattern
- `RIZQ-iOS/RIZQ/Features/Home/HomeFeature.swift` — Consume content from shared state for journey lists
- `RIZQ-iOS/CLAUDE.md` — Remove the Neon rollback procedure section

### iOS — files deleted
- `RIZQ-iOS/RIZQKit/Services/API/NeonService.swift`
- `RIZQ-iOS/RIZQKit/Services/API/NeonClient.swift`
- `RIZQ-iOS/RIZQKit/Services/API/APIClient.swift`
- `RIZQ-iOS/RIZQKit/Services/API/FirebaseNeonService.swift`
- `RIZQ-iOS/RIZQTests/NeonServiceTests.swift`

### Repo
- Remove `autoforge/` directory entirely (separate Leon van Zyl project; doesn't belong here)
- `firebase-debug.log` removed and gitignored

---

# STEP 1 — Prep (no behavior change)

**Goal:** Plumb in Firebase, update rules, set up emulator + rules tests. Web app behavior unchanged.

**Branch:** `m1-step1-prep` (worktree off `m1-foundation`)

---

### Task 1.1: Cut milestone branch and create worktree

**Agent type:** Single — orchestrator

- [ ] **Step 1: Cut the milestone branch from main**

```bash
cd "/Users/omairdawood/Projects/RIZQ App"
git checkout main
git pull
git checkout -b m1-foundation
git push -u origin m1-foundation
```

- [ ] **Step 2: Create the Step 1 worktree**

```bash
git worktree add ../rizq-m1-step1-prep -b m1-step1-prep m1-foundation
cd ../rizq-m1-step1-prep
```

- [ ] **Step 3: Verify clean state**

Run: `git status`
Expected: `nothing to commit, working tree clean` on branch `m1-step1-prep`.

---

### Task 1.2: Add Firebase Web SDK dependency

**Agent type:** Web TS subagent
**Skills:** `context7` (look up Firebase Web SDK v10+ install + init)
**Files:**
- Modify: `package.json`

- [ ] **Step 1: Install firebase**

Run: `npm install firebase@^10`
Expected: package.json updated with `"firebase": "^10.x.x"`; `package-lock.json` updated.

- [ ] **Step 2: Verify install**

Run: `npm ls firebase`
Expected: shows `firebase@10.x.x` (or higher, no errors).

- [ ] **Step 3: Commit**

```bash
git add package.json package-lock.json
git commit -m "chore(web): add firebase web sdk dependency"
```

---

### Task 1.3: Create `src/lib/firebase.ts`

**Agent type:** Web TS subagent
**Skills:** `context7` (Firebase Web SDK init pattern), TDD-light (initialization is config; no test required at this stage)
**Files:**
- Create: `src/lib/firebase.ts`
- Modify: `.env.example`

- [ ] **Step 1: Write `src/lib/firebase.ts`**

```typescript
import { initializeApp, type FirebaseApp } from 'firebase/app';
import { getAuth, type Auth } from 'firebase/auth';
import {
  initializeFirestore,
  persistentLocalCache,
  persistentMultipleTabManager,
  type Firestore,
} from 'firebase/firestore';

let _app: FirebaseApp | undefined;
let _auth: Auth | undefined;
let _db: Firestore | undefined;

function getApp(): FirebaseApp {
  if (_app) return _app;
  _app = initializeApp({
    apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
    storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
    appId: import.meta.env.VITE_FIREBASE_APP_ID,
  });
  return _app;
}

export function getFirebaseAuth(): Auth {
  if (_auth) return _auth;
  _auth = getAuth(getApp());
  return _auth;
}

export function getDb(): Firestore {
  if (_db) return _db;
  _db = initializeFirestore(getApp(), {
    localCache: persistentLocalCache({
      tabManager: persistentMultipleTabManager(),
    }),
  });
  return _db;
}

export function isFirestoreCutoverEnabled(): boolean {
  return import.meta.env.VITE_FIRESTORE_CUTOVER === 'true';
}
```

- [ ] **Step 2: Update `.env.example`**

Add these lines (keep existing Neon vars for now — they're removed in Step 4):

```
# Firebase Web (added in Milestone 1)
VITE_FIREBASE_API_KEY=
VITE_FIREBASE_AUTH_DOMAIN=
VITE_FIREBASE_PROJECT_ID=rizq-app-c6468
VITE_FIREBASE_STORAGE_BUCKET=
VITE_FIREBASE_MESSAGING_SENDER_ID=
VITE_FIREBASE_APP_ID=

# Atomic-cutover flag (Step 3) — set to "true" to switch web data path to Firestore
VITE_FIRESTORE_CUTOVER=false
```

- [ ] **Step 3: Verify build still succeeds**

Run: `npm run build`
Expected: Build succeeds. The new `firebase.ts` is unused so it won't appear in the bundle.

- [ ] **Step 4: Commit**

```bash
git add src/lib/firebase.ts .env.example
git commit -m "feat(web): add firebase web sdk init module with persistent cache"
```

---

### Task 1.4: Set up Firebase Local Emulator Suite

**Agent type:** Web TS subagent
**Skills:** `context7` (Firebase emulator + `@firebase/rules-unit-testing` v3 setup)
**Parallel with:** Task 1.5
**Files:**
- Modify: `firebase.json`
- Create: `firestore.indexes.json` already exists; ensure unchanged

- [ ] **Step 1: Add emulator config to `firebase.json`**

Read existing `firebase.json` first. Then update to:

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "emulators": {
    "auth": { "port": 9099 },
    "firestore": { "port": 8080 },
    "ui": { "enabled": true, "port": 4000 },
    "singleProjectMode": true
  }
}
```

- [ ] **Step 2: Install emulator dev dependencies**

Run: `npm install --save-dev firebase-tools @firebase/rules-unit-testing@^3`
Expected: both added under `devDependencies`.

- [ ] **Step 3: Verify emulator boots**

Run (in a separate terminal): `npx firebase emulators:start --only auth,firestore --project rizq-app-c6468`
Expected: emulator UI accessible at http://localhost:4000; Firestore on 8080; Auth on 9099.

Stop the emulator (Ctrl+C) after verifying.

- [ ] **Step 4: Commit**

```bash
git add firebase.json package.json package-lock.json
git commit -m "chore(web): configure firebase local emulator suite"
```

---

### Task 1.5: Update `firestore.rules` for admin-gated content writes

**Agent type:** Firestore Rules subagent
**Skills:** `context7` (Firestore Security Rules v2), TDD-first (rules tests in Task 1.6 written before this rule change is finalized — but for clarity in this plan, rule update and rule tests are co-located)
**Parallel with:** Task 1.4

**Files:**
- Modify: `firestore.rules`

- [ ] **Step 1: Update content collection rules to gate writes on `isAdmin()`**

In `firestore.rules`, replace each of these blocks:

```javascript
match /duas/{duaId} {
  allow read: if true;
  allow write: if false;
}
```

with:

```javascript
match /duas/{duaId} {
  allow read: if true;
  allow write: if isAdmin();
}
```

Repeat for `journeys`, `journey_duas`, `categories`, `collections`.

- [ ] **Step 2: Tighten `user_profiles` rules to block self-promotion**

Replace the existing `match /user_profiles/{userId}` block with:

```javascript
match /user_profiles/{userId} {
  allow read: if isOwner(userId) || isAdmin();
  allow create: if isOwner(userId);  // self-create on first sign-in
  allow update: if isAdmin()
                || (isOwner(userId)
                    && !('isAdmin' in request.resource.data.diff(resource.data).affectedKeys()));
  allow delete: if isAdmin();
}
```

- [ ] **Step 3: Verify rules syntax**

Run: `npx firebase deploy --only firestore:rules --project rizq-app-c6468 --dry-run`

If the CLI doesn't support dry-run, instead boot the emulator with these rules:
Run: `npx firebase emulators:start --only firestore --project rizq-app-c6468`
Expected: emulator starts without rules-parse errors; stop with Ctrl+C.

- [ ] **Step 4: Commit (rules update; tests follow in Task 1.6)**

```bash
git add firestore.rules
git commit -m "feat(rules): gate content writes on isAdmin() and block self-promotion"
```

---

### Task 1.6: Firestore rules tests

**Agent type:** Firestore Rules subagent
**Skills:** `context7` (`@firebase/rules-unit-testing` v3), `superpowers:test-driven-development`
**Files:**
- Create: `tests/rules/firestore-rules.test.ts`
- Create: `tests/rules/setup.ts`
- Modify: `package.json` (add test script)

- [ ] **Step 1: Write `tests/rules/setup.ts`**

```typescript
import {
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import * as fs from 'fs';
import * as path from 'path';

export async function getTestEnv(): Promise<RulesTestEnvironment> {
  return initializeTestEnvironment({
    projectId: 'rizq-app-c6468',
    firestore: {
      rules: fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
}
```

- [ ] **Step 2: Write the failing test file `tests/rules/firestore-rules.test.ts`**

```typescript
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

  // Repeat the above three for journeys, journey_duas, categories, collections.
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
```

- [ ] **Step 3: Add test script to `package.json`**

In the `"scripts"` block of `package.json`, add:

```json
"test:rules": "firebase emulators:exec --only firestore --project rizq-app-c6468 'vitest run tests/rules'",
```

If `vitest` is not yet installed, run: `npm install --save-dev vitest`.

- [ ] **Step 4: Run tests to confirm they fail without the new rules**

First confirm they fail BEFORE the rule change by stashing rules and re-running. Skip this if Task 1.5 is already merged on the same branch — in that case proceed to Step 5.

Run: `npm run test:rules`
Expected: all 9 tests pass against the rules from Task 1.5.

- [ ] **Step 5: Commit**

```bash
git add tests/rules/setup.ts tests/rules/firestore-rules.test.ts package.json package-lock.json
git commit -m "test(rules): add firestore security rules unit tests"
```

---

### Task 1.7: Bootstrap-admin script (judgment-call: skip if Firebase console suffices)

**Agent type:** Web TS subagent
**Skills:** `context7` (Firebase Admin SDK Node)
**Files:**
- Create (optional): `scripts/bootstrap-first-admin.cjs`

This task is **conditionally executed**. If you can promote the first admin via the Firebase console (Firestore → user_profiles → set `isAdmin: true`), skip this task entirely and continue.

- [ ] **Step 1: If proceeding, write the script**

```javascript
// scripts/bootstrap-first-admin.cjs
// One-off: promotes a user to admin by setting isAdmin: true on their profile.
// Usage: node scripts/bootstrap-first-admin.cjs <firebase-uid>
const admin = require('firebase-admin');
const serviceAccount = require('../firebase-service-account.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

async function main() {
  const uid = process.argv[2];
  if (!uid) {
    console.error('Usage: node scripts/bootstrap-first-admin.cjs <firebase-uid>');
    process.exit(1);
  }
  await admin.firestore().collection('user_profiles').doc(uid).set(
    { isAdmin: true },
    { merge: true }
  );
  console.log(`✓ Set isAdmin=true for user_profiles/${uid}`);
}

main().catch((e) => { console.error(e); process.exit(1); });
```

- [ ] **Step 2: Commit**

```bash
git add scripts/bootstrap-first-admin.cjs
git commit -m "chore(scripts): add one-off bootstrap-first-admin script"
```

---

### Task 1.8: Merge Step 1 to milestone branch

**Agent type:** Single — orchestrator

- [ ] **Step 1: Verify all Step 1 tests pass on the worktree**

Run: `npm run test:rules && npm run build`
Expected: rules tests all green; build succeeds.

- [ ] **Step 2: Merge to milestone branch**

```bash
cd "/Users/omairdawood/Projects/RIZQ App"
git checkout m1-foundation
git merge --no-ff m1-step1-prep -m "merge: m1 step 1 prep complete"
git push
```

- [ ] **Step 3: Remove Step 1 worktree**

```bash
git worktree remove ../rizq-m1-step1-prep
git branch -d m1-step1-prep
```

---

# STEP 2 — Auth cutover (web)

**Goal:** Switch web auth from Better Auth to Firebase Auth. Existing users re-sign-in. Content reads still come from Neon — no read/write split introduced.

**Branch:** `m1-step2-auth`
**Review checkpoint:** REQUIRED at end of step (`pr-review-toolkit:code-reviewer` + `pr-review-toolkit:silent-failure-hunter`).

---

### Task 2.1: Create Step 2 worktree

**Agent type:** Single — orchestrator

- [ ] **Step 1: Create worktree from milestone branch**

```bash
cd "/Users/omairdawood/Projects/RIZQ App"
git worktree add ../rizq-m1-step2-auth -b m1-step2-auth m1-foundation
cd ../rizq-m1-step2-auth
```

---

### Task 2.2: Configure Firebase Auth providers (Google, GitHub)

**Agent type:** Web TS subagent
**Skills:** `context7` (Firebase Auth Web — `signInWithPopup`, `GoogleAuthProvider`, `GithubAuthProvider`)

This is a **Firebase console task**, not a code task. Document the required state:

- [ ] **Step 1: In Firebase console for project `rizq-app-c6468`**

- Authentication → Sign-in method → enable Google (already enabled per CLAUDE.md).
- Enable GitHub. Provide GitHub OAuth app client ID + secret. Add the Firebase callback URL (`https://rizq-app-c6468.firebaseapp.com/__/auth/handler`) to the GitHub OAuth app.
- Authorized domains: ensure web hosting domain is listed.

- [ ] **Step 2: Document in `.env.example`**

Already done in Task 1.3 (no further change required).

- [ ] **Step 3: Commit (no-op marker)**

No file changes. Skip the commit; proceed to Task 2.3.

---

### Task 2.3: Write the failing e2e test for Firebase Auth flow

**Agent type:** Web TS subagent
**Skills:** `superpowers:test-driven-development`, `context7` (Playwright + Firebase Auth Emulator)
**Files:**
- Modify: `e2e/auth.spec.ts`

- [ ] **Step 1: Read existing `e2e/auth.spec.ts` to understand current structure**

- [ ] **Step 2: Replace its contents with a Firebase-Auth-emulator-targeted test**

```typescript
import { test, expect } from '@playwright/test';

const EMULATOR_AUTH_URL = 'http://127.0.0.1:9099';
const EMULATOR_FIRESTORE_URL = 'http://127.0.0.1:8080';

test.describe('Firebase Auth flow', () => {
  test.beforeEach(async ({ page }) => {
    // Reset emulator state
    await page.request.delete(
      `${EMULATOR_AUTH_URL}/emulator/v1/projects/rizq-app-c6468/accounts`
    );
    await page.request.delete(
      `${EMULATOR_FIRESTORE_URL}/emulator/v1/projects/rizq-app-c6468/databases/(default)/documents`
    );
  });

  test('signing in with Google creates a user_profiles doc', async ({ page }) => {
    // Set env to point web at emulators
    await page.goto('/');
    await page.click('text=Sign In');

    // Note: Google sign-in popup is mocked via emulator's mock provider flow.
    // The Firebase Auth emulator exposes a simulated provider page that
    // creates an account on click.
    const popupPromise = page.waitForEvent('popup');
    await page.click('button:has-text("Continue with Google")');
    const popup = await popupPromise;
    await popup.waitForLoadState();
    await popup.fill('input[type="email"]', 'newuser@example.com');
    await popup.fill('input[type="text"]', 'New User');
    await popup.click('button:has-text("Sign in with Google.com")');

    await page.waitForURL((url) => !url.pathname.includes('signin'), { timeout: 10000 });

    // Verify a user_profiles doc exists in Firestore emulator
    const dbResponse = await page.request.get(
      `${EMULATOR_FIRESTORE_URL}/emulator/v1/projects/rizq-app-c6468/databases/(default)/documents/user_profiles`
    );
    const docs = await dbResponse.json();
    expect(docs.documents).toBeDefined();
    expect(docs.documents.length).toBe(1);
  });
});
```

- [ ] **Step 3: Run the test (expecting failure — AuthContext still uses Better Auth)**

Run: `npx playwright test e2e/auth.spec.ts`
Expected: test FAILS (Better Auth still loaded, popup mismatch, or no user_profiles created in Firestore).

- [ ] **Step 4: Commit the failing test**

```bash
git add e2e/auth.spec.ts
git commit -m "test(auth): add failing e2e for firebase auth flow + profile creation"
```

---

### Task 2.4: Rewrite `AuthContext.tsx` for Firebase Auth

**Agent type:** Web TS subagent
**Skills:** `context7` (Firebase Auth Web SDK + Firestore profile creation), `vercel:react-best-practices` (post-edit)
**Files:**
- Modify: `src/contexts/AuthContext.tsx`
- Read for reference: `RIZQ-iOS/RIZQKit/Services/Firebase/FirebaseUserService.swift` (canonical profile shape)
- Read for reference: existing `src/contexts/AuthContext.tsx` (preserve `lastUsedProvider` UX nicety)

- [ ] **Step 1: Read both reference files first** (use Read tool — do not skip)

- [ ] **Step 2: Replace `src/contexts/AuthContext.tsx` with Firebase-backed implementation**

```typescript
import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import {
  GoogleAuthProvider,
  GithubAuthProvider,
  onAuthStateChanged,
  signInWithPopup,
  signOut,
  type User as FirebaseUser,
} from 'firebase/auth';
import {
  doc,
  getDoc,
  runTransaction,
  setDoc,
  serverTimestamp,
} from 'firebase/firestore';
import { getFirebaseAuth, getDb } from '@/lib/firebase';

interface UserProfile {
  userId: string;
  displayName: string | null;
  streak: number;
  totalXp: number;
  level: number;
  lastActiveDate: string | null;
  isAdmin: boolean;
}

interface AuthContextValue {
  user: FirebaseUser | null;
  profile: UserProfile | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  signInWithGoogle: () => Promise<void>;
  signInWithGithub: () => Promise<void>;
  signOutUser: () => Promise<void>;
  addXp: (amount: number) => Promise<void>;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

const LAST_PROVIDER_KEY = 'lastUsedProvider';

function calculateLevel(xp: number): number {
  let level = 1;
  while (50 * level * level + 50 * level <= xp) level++;
  return level;
}

async function getOrCreateProfile(uid: string, displayName: string | null): Promise<UserProfile> {
  const db = getDb();
  const ref = doc(db, 'user_profiles', uid);
  const snap = await getDoc(ref);
  if (snap.exists()) {
    return { userId: uid, ...(snap.data() as Omit<UserProfile, 'userId'>) };
  }
  const fresh: UserProfile = {
    userId: uid,
    displayName: displayName ?? null,
    streak: 0,
    totalXp: 0,
    level: 1,
    lastActiveDate: null,
    isAdmin: false,
  };
  await setDoc(ref, { ...fresh, createdAt: serverTimestamp() });
  return fresh;
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<FirebaseUser | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const auth = getFirebaseAuth();
    return onAuthStateChanged(auth, async (fbUser) => {
      setUser(fbUser);
      if (fbUser) {
        const p = await getOrCreateProfile(fbUser.uid, fbUser.displayName);
        setProfile(p);
      } else {
        setProfile(null);
      }
      setIsLoading(false);
    });
  }, []);

  const signInWithGoogle = async () => {
    await signInWithPopup(getFirebaseAuth(), new GoogleAuthProvider());
    localStorage.setItem(LAST_PROVIDER_KEY, 'google');
  };

  const signInWithGithub = async () => {
    await signInWithPopup(getFirebaseAuth(), new GithubAuthProvider());
    localStorage.setItem(LAST_PROVIDER_KEY, 'github');
  };

  const signOutUser = async () => {
    await signOut(getFirebaseAuth());
  };

  const refreshProfile = async () => {
    if (!user) return;
    const p = await getOrCreateProfile(user.uid, user.displayName);
    setProfile(p);
  };

  const addXp = async (amount: number) => {
    if (!user) return;
    const db = getDb();
    const ref = doc(db, 'user_profiles', user.uid);
    const today = new Date().toISOString().slice(0, 10);
    await runTransaction(db, async (tx) => {
      const snap = await tx.get(ref);
      const current = snap.data() as UserProfile;
      const newXp = current.totalXp + amount;
      const newLevel = calculateLevel(newXp);
      // Streak logic: if last_active was yesterday, +1; if today, unchanged; else reset to 1.
      const last = current.lastActiveDate;
      let newStreak = current.streak;
      if (!last) newStreak = 1;
      else if (last === today) newStreak = current.streak;
      else {
        const yesterday = new Date(Date.now() - 86400000).toISOString().slice(0, 10);
        newStreak = last === yesterday ? current.streak + 1 : 1;
      }
      tx.update(ref, {
        totalXp: newXp,
        level: newLevel,
        streak: newStreak,
        lastActiveDate: today,
      });
    });
    await refreshProfile();
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        profile,
        isLoading,
        isAuthenticated: !!user,
        signInWithGoogle,
        signInWithGithub,
        signOutUser,
        addXp,
        refreshProfile,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
```

- [ ] **Step 3: Update `src/pages/SignInPage.tsx` and `SignUpPage.tsx` to use new methods**

Replace any `auth-client.ts` imports / Better Auth method calls with `useAuth().signInWithGoogle()` / `signInWithGithub()`. Preserve UI; just swap behavior.

- [ ] **Step 4: Run typecheck**

Run: `npx tsc --noEmit`
Expected: no errors.

- [ ] **Step 5: Run the e2e test from Task 2.3**

Run (in one terminal): `npx firebase emulators:start --only auth,firestore --project rizq-app-c6468`
Run (in another terminal): `npx playwright test e2e/auth.spec.ts`
Expected: test PASSES.

- [ ] **Step 6: Run `vercel:react-best-practices` skill**

Invoke the skill against the modified TSX files; address any flagged issues inline.

- [ ] **Step 7: Commit**

```bash
git add src/contexts/AuthContext.tsx src/pages/SignInPage.tsx src/pages/SignUpPage.tsx
git commit -m "feat(auth): switch web auth from better-auth to firebase auth"
```

---

### Task 2.5: Remove Better Auth dependency

**Agent type:** Web TS subagent
**Skills:** `superpowers:verification-before-completion`
**Files:**
- Delete: `src/lib/auth-client.ts`
- Modify: `package.json`

- [ ] **Step 1: Verify no remaining imports**

Run: `git grep -l "auth-client\|better-auth"`
Expected: only matches in `package.json` and `package-lock.json`.

If other files still import these, fix them first.

- [ ] **Step 2: Delete the auth client file**

Run: `git rm src/lib/auth-client.ts`

- [ ] **Step 3: Remove Better Auth from package.json**

Run: `npm uninstall better-auth`

- [ ] **Step 4: Verify build still passes**

Run: `npm run build`
Expected: build succeeds.

- [ ] **Step 5: Commit**

```bash
git add src/lib/auth-client.ts package.json package-lock.json
git commit -m "chore(auth): remove better-auth dependency and client module"
```

---

### Task 2.6: Step 2 review checkpoint + merge

**Agent type:** Reviewer subagents → orchestrator merge

- [ ] **Step 1: Run `pr-review-toolkit:code-reviewer` against the diff**

Diff scope: `m1-foundation..m1-step2-auth`. Address any high-priority issues by re-opening the relevant task and amending.

- [ ] **Step 2: Run `pr-review-toolkit:silent-failure-hunter` against the diff**

Specifically watch for: `addXp` transaction failure swallowed; `getOrCreateProfile` errors swallowed; sign-in popup rejection unhandled.

- [ ] **Step 3: Merge to milestone branch**

```bash
cd "/Users/omairdawood/Projects/RIZQ App"
git checkout m1-foundation
git merge --no-ff m1-step2-auth -m "merge: m1 step 2 auth cutover complete"
git push
git worktree remove ../rizq-m1-step2-auth
git branch -d m1-step2-auth
```

---

# STEP 3 — Atomic Firestore cutover

**Goal:** Switch all web data hooks (read, user-data, admin write) to Firestore in a single deploy, gated by `VITE_FIRESTORE_CUTOVER` env flag for atomic rollback.

**Branch:** `m1-step3-cutover`. Inside this, three parallel sub-branches: `m1-step3-read-hooks`, `m1-step3-user-data-hooks`, `m1-step3-admin-write-hooks`. They merge to `m1-step3-cutover` first, then it merges to `m1-foundation`.

**Review checkpoint:** REQUIRED on staging before prod env-flip (`pr-review-toolkit:review-pr` full workflow).

---

### Task 3.1: Cut Step 3 base branch and three parallel worktrees

**Agent type:** Single — orchestrator

- [ ] **Step 1: Cut the Step 3 base branch**

```bash
cd "/Users/omairdawood/Projects/RIZQ App"
git checkout m1-foundation
git checkout -b m1-step3-cutover
git push -u origin m1-step3-cutover
```

- [ ] **Step 2: Create three parallel worktrees**

```bash
git worktree add ../rizq-m1-step3-read -b m1-step3-read-hooks m1-step3-cutover
git worktree add ../rizq-m1-step3-userdata -b m1-step3-user-data-hooks m1-step3-cutover
git worktree add ../rizq-m1-step3-admin -b m1-step3-admin-write-hooks m1-step3-cutover
```

---

### Task 3.2: Read hooks — `useDuas`, `useJourneys`, `useJourneyDuas`, `useCategories`, `useCollections`

**Agent type:** Web TS subagent
**Skills:** TDD, `context7` (Firestore Web SDK queries + React Query v5), `vercel:react-best-practices`, `pr-review-toolkit:silent-failure-hunter`
**Worktree:** `../rizq-m1-step3-read` on branch `m1-step3-read-hooks`
**Parallel with:** Tasks 3.3, 3.4

**Files:**
- Modify: `src/hooks/useDuas.ts`, `src/hooks/useJourneys.ts`
- Read for reference: `RIZQ-iOS/RIZQKit/Services/Firebase/FirestoreContentService.swift` (canonical query patterns)

- [ ] **Step 1: Write the failing e2e — `e2e/practice.spec.ts`**

```typescript
import { test, expect } from '@playwright/test';

test('user can browse duas in Library page (read from Firestore)', async ({ page }) => {
  // Seed: insert a dua via the emulator REST API
  await page.request.patch(
    'http://127.0.0.1:8080/emulator/v1/projects/rizq-app-c6468/databases/(default)/documents/duas/1',
    { data: { fields: { titleEn: { stringValue: 'Test Morning Dua' } } } }
  );

  await page.goto('/library');
  await expect(page.locator('text=Test Morning Dua')).toBeVisible({ timeout: 5000 });
});
```

- [ ] **Step 2: Run test, expect failure**

Run (with emulators running): `npx playwright test e2e/practice.spec.ts`
Expected: FAIL — current `useDuas` queries Neon, not Firestore.

- [ ] **Step 3: Rewrite `src/hooks/useDuas.ts`**

```typescript
import { useQuery } from '@tanstack/react-query';
import { collection, getDocs, query, orderBy } from 'firebase/firestore';
import { getDb, isFirestoreCutoverEnabled } from '@/lib/firebase';
import type { Dua } from '@/types/dua';
import { getSql } from '@/lib/db'; // legacy fallback when cutover off

async function fetchDuasFirestore(): Promise<Dua[]> {
  const db = getDb();
  const snap = await getDocs(query(collection(db, 'duas'), orderBy('id')));
  return snap.docs.map((d) => ({ id: Number(d.id), ...(d.data() as Omit<Dua, 'id'>) }));
}

async function fetchDuasNeon(): Promise<Dua[]> {
  const sql = getSql();
  const rows = await sql`SELECT * FROM duas ORDER BY id` as Array<Record<string, unknown>>;
  // existing snake_case → camelCase mapping retained from prior implementation
  return rows.map((r) => ({
    id: r.id as number,
    titleEn: r.title_en as string,
    arabicText: r.arabic_text as string,
    transliteration: r.transliteration as string,
    translationEn: r.translation_en as string,
    // ... keep existing mapper fields ...
  })) as Dua[];
}

export function useDuas() {
  return useQuery({
    queryKey: ['duas', isFirestoreCutoverEnabled()],
    queryFn: () => (isFirestoreCutoverEnabled() ? fetchDuasFirestore() : fetchDuasNeon()),
  });
}
```

- [ ] **Step 4: Repeat the dual-path pattern for the other read hooks**

Create or modify:
- `src/hooks/useJourneys.ts` — Firestore: `query(collection(db, 'journeys'), orderBy('sortOrder'))`. Neon: existing implementation.
- `src/hooks/useJourneyDuas.ts` — Firestore: `query(collection(db, 'journey_duas'), where('journeyId', '==', id), orderBy('sortOrder'))`. Neon: existing implementation.
- `useCategories`, `useCollections` — analogous.

For each, apply the same `isFirestoreCutoverEnabled()` branching pattern.

- [ ] **Step 5: With `VITE_FIRESTORE_CUTOVER=true`, run e2e**

Run: `VITE_FIRESTORE_CUTOVER=true npx playwright test e2e/practice.spec.ts`
Expected: PASS.

- [ ] **Step 6: With `VITE_FIRESTORE_CUTOVER=false`, run existing tests to confirm Neon path still works**

Run: `VITE_FIRESTORE_CUTOVER=false npx playwright test`
Expected: existing tests still pass (Neon path unchanged).

- [ ] **Step 7: Commit**

```bash
git add src/hooks/useDuas.ts src/hooks/useJourneys.ts src/hooks/useJourneyDuas.ts \
        src/hooks/useCategories.ts src/hooks/useCollections.ts e2e/practice.spec.ts
git commit -m "feat(web): dual-path read hooks (firestore behind VITE_FIRESTORE_CUTOVER flag)"
```

---

### Task 3.3: User-data hooks — `useActivity`, `useUserHabits`, `addXp`, `refreshProfile`

**Agent type:** Web TS subagent
**Skills:** TDD, `context7` (Firestore subcollections + transactions), `vercel:react-best-practices`
**Worktree:** `../rizq-m1-step3-userdata` on branch `m1-step3-user-data-hooks`
**Parallel with:** Tasks 3.2, 3.4

**Files:**
- Create: `src/hooks/useFirestoreActivity.ts`
- Modify: `src/hooks/useUserHabits.ts`
- Modify: `src/contexts/AuthContext.tsx` (`addXp` already Firestore in Task 2.4 but verify `lastActiveDate` and date subcollection write)

- [ ] **Step 1: Write the failing e2e `e2e/journeys.spec.ts`**

```typescript
import { test, expect } from '@playwright/test';

test('user subscribes to a journey, habit appears on Daily Adkhar page', async ({ page }) => {
  // (Sign in via emulator, seed journey + journey_duas, navigate, click subscribe.)
  await page.goto('/');
  // ... Auth setup via emulator REST ...
  await page.goto('/journeys');
  await page.click('button:has-text("Subscribe")');
  await page.goto('/daily-adkhar');
  await expect(page.locator('[data-testid="habit-item"]').first()).toBeVisible({ timeout: 5000 });
});
```

(Detailed auth-emulator setup boilerplate is shared with the auth.spec.ts test — extract into `e2e/helpers/auth.ts` if you want; small refactor.)

- [ ] **Step 2: Run, expect failure**

Run: `VITE_FIRESTORE_CUTOVER=true npx playwright test e2e/journeys.spec.ts`
Expected: FAIL.

- [ ] **Step 3: Rewrite `src/hooks/useUserHabits.ts` for Firestore**

The localStorage subscriptions logic stays. The completions are stored in Firestore at `user_activity/{uid}/dates/{YYYY-MM-DD}` per the iOS shape. Apply the dual-path `isFirestoreCutoverEnabled()` flag pattern.

Key change: `recordCompletion(habitId, xp)` writes to:
- Firestore (cutover on): `setDoc(doc(db, 'user_activity', uid, 'dates', today), { duasCompleted: arrayUnion(habitId), xpEarned: increment(xp) }, { merge: true })`
- Neon (cutover off): existing UPSERT against `user_activity` table.

- [ ] **Step 4: Create `src/hooks/useFirestoreActivity.ts`** (replaces `useActivity` for the Firestore path)

```typescript
import { useQuery } from '@tanstack/react-query';
import { collection, getDocs, orderBy, query, limit } from 'firebase/firestore';
import { getDb } from '@/lib/firebase';
import { useAuth } from '@/contexts/AuthContext';

export function useFirestoreWeekActivity() {
  const { user } = useAuth();
  return useQuery({
    queryKey: ['user_activity', user?.uid],
    enabled: !!user,
    queryFn: async () => {
      const db = getDb();
      const snap = await getDocs(
        query(
          collection(db, 'user_activity', user!.uid, 'dates'),
          orderBy('__name__', 'desc'),
          limit(7)
        )
      );
      return snap.docs.map((d) => ({ date: d.id, ...(d.data() as { duasCompleted: number[]; xpEarned: number }) }));
    },
  });
}
```

Modify the existing `src/hooks/useActivity.ts` to delegate to `useFirestoreWeekActivity` when `isFirestoreCutoverEnabled()` is true.

- [ ] **Step 5: Verify e2e passes with cutover on**

Run: `VITE_FIRESTORE_CUTOVER=true npx playwright test e2e/journeys.spec.ts`
Expected: PASS.

- [ ] **Step 6: Verify Neon path still works with cutover off**

Run: `VITE_FIRESTORE_CUTOVER=false npx playwright test`
Expected: existing tests pass.

- [ ] **Step 7: Commit**

```bash
git add src/hooks/useUserHabits.ts src/hooks/useFirestoreActivity.ts \
        src/hooks/useActivity.ts e2e/journeys.spec.ts e2e/helpers/auth.ts
git commit -m "feat(web): dual-path user-data hooks (firestore behind cutover flag)"
```

---

### Task 3.4: Admin write hooks — `useAdminDuas`, `useAdminJourneys`, `useAdminCategories`, `useAdminCollections`, `useAdminUsers`

**Agent type:** Web TS subagent
**Skills:** TDD, `context7` (Firestore `addDoc`/`updateDoc`/`deleteDoc` + auto-numeric IDs strategy), `vercel:react-best-practices`, `pr-review-toolkit:silent-failure-hunter`
**Worktree:** `../rizq-m1-step3-admin` on branch `m1-step3-admin-write-hooks`
**Parallel with:** Tasks 3.2, 3.3

**Files:**
- Modify all in `src/hooks/admin/`

- [ ] **Step 1: Write failing e2e `e2e/admin-duas.spec.ts`**

```typescript
import { test, expect } from '@playwright/test';

test('admin user can create a dua via admin panel; non-admin cannot', async ({ page }) => {
  // Seed: admin user_profile with isAdmin: true via emulator REST
  // Seed: regular user_profile with isAdmin: false
  // Sign in as admin → /admin/duas → click "New Dua" → fill form → save
  // Verify dua appears in /library
  // Sign out, sign in as regular user → /admin/duas → expect redirect or error
});
```

(Full test body should mirror existing `e2e/admin-journeys.spec.ts` structure.)

- [ ] **Step 2: Run, expect failure**

Run: `VITE_FIRESTORE_CUTOVER=true npx playwright test e2e/admin-duas.spec.ts`
Expected: FAIL.

- [ ] **Step 3: Rewrite each admin hook with dual-path pattern**

For each admin hook, the create/update/delete mutations branch on the cutover flag. Example for `useAdminDuas.ts`:

```typescript
import { addDoc, collection, deleteDoc, doc, getDocs, query, orderBy, updateDoc } from 'firebase/firestore';
import { getDb, isFirestoreCutoverEnabled } from '@/lib/firebase';

async function createDuaFirestore(input: CreateDuaInput): Promise<AdminDua> {
  const db = getDb();
  // Numeric IDs in Firestore: use the doc ID matching the next integer.
  // Fetch max existing id + 1.
  const all = await getDocs(query(collection(db, 'duas'), orderBy('id', 'desc')));
  const nextId = (all.docs[0]?.data().id as number ?? 0) + 1;
  await setDoc(doc(db, 'duas', String(nextId)), { ...input, id: nextId });
  return { ...input, id: nextId } as AdminDua;
}
```

(Note: the iOS app stores numeric IDs as document IDs already per `seed-firestore.cjs`. Match that convention.)

Apply the analogous pattern for update (`updateDoc`) and delete (`deleteDoc`). Wrap behind `isFirestoreCutoverEnabled()`.

Repeat for `useAdminJourneys`, `useAdminCategories`, `useAdminCollections`, `useAdminUsers` (the latter does not write content; it lists user_profiles for the admin UI — straightforward Firestore query).

- [ ] **Step 4: Verify e2e passes**

Run: `VITE_FIRESTORE_CUTOVER=true npx playwright test e2e/admin-duas.spec.ts`
Expected: PASS.

- [ ] **Step 5: Manually verify the seed script is no longer needed**

In the emulator, create a dua via the admin UI with cutover ON. Verify in another browser tab that the public Library page shows it (no seed script run).

- [ ] **Step 6: Commit**

```bash
git add src/hooks/admin/ e2e/admin-duas.spec.ts
git commit -m "feat(admin): dual-path admin write hooks (firestore behind cutover flag)"
```

---

### Task 3.5: Merge parallel worktrees back to `m1-step3-cutover`

**Agent type:** Single — orchestrator

- [ ] **Step 1: Merge each sub-branch in turn**

```bash
cd "/Users/omairdawood/Projects/RIZQ App"
git checkout m1-step3-cutover
git merge --no-ff m1-step3-read-hooks -m "merge: read hooks dual-path"
git merge --no-ff m1-step3-user-data-hooks -m "merge: user-data hooks dual-path"
git merge --no-ff m1-step3-admin-write-hooks -m "merge: admin write hooks dual-path"
```

Resolve any conflicts inline (rare given the parallel work touched different files).

- [ ] **Step 2: Run full test suite (cutover ON)**

Run: `VITE_FIRESTORE_CUTOVER=true npm run test:rules && VITE_FIRESTORE_CUTOVER=true npx playwright test`
Expected: all pass.

- [ ] **Step 3: Run full test suite (cutover OFF — Neon path)**

Run: `VITE_FIRESTORE_CUTOVER=false npx playwright test`
Expected: all pass.

- [ ] **Step 4: Remove the parallel worktrees**

```bash
git worktree remove ../rizq-m1-step3-read
git worktree remove ../rizq-m1-step3-userdata
git worktree remove ../rizq-m1-step3-admin
git branch -d m1-step3-read-hooks m1-step3-user-data-hooks m1-step3-admin-write-hooks
```

---

### Task 3.6: Staging deploy + manual smoke + production env flip

**Agent type:** Cutover subagent
**Skills:** `superpowers:verification-before-completion`, `pr-review-toolkit:review-pr` (full workflow)

- [ ] **Step 1: Deploy `m1-step3-cutover` to staging with `VITE_FIRESTORE_CUTOVER=true`**

(Hosting platform varies — Vercel/Netlify/etc. Use whatever deploy step the project already uses.)

- [ ] **Step 2: Manual smoke test on staging**

Confirm:
- Sign in via Google.
- Sign in via GitHub.
- View Library — duas load from Firestore (verify in Firebase console).
- Subscribe to a journey.
- Complete a dua practice — XP recorded; visible in `user_profiles/{uid}` and `user_activity/{uid}/dates/{today}`.
- Admin user creates a new dua — appears in Library page within seconds, no seed script run.
- Non-admin user redirected away from `/admin`.

- [ ] **Step 3: Run full `pr-review-toolkit:review-pr` workflow**

Diff scope: `m1-foundation..m1-step3-cutover`. Address findings.

- [ ] **Step 4: Merge to milestone branch**

```bash
git checkout m1-foundation
git merge --no-ff m1-step3-cutover -m "merge: m1 step 3 atomic cutover (behind flag)"
git push
```

- [ ] **Step 5: Production env flip**

In production hosting env vars: set `VITE_FIRESTORE_CUTOVER=true`. Redeploy (or trigger build with new env).
**This is the user-visible cutover moment.** Monitor error rates for 24 hours.

If anomalies, revert by setting `VITE_FIRESTORE_CUTOVER=false` and redeploying — no code rollback needed.

- [ ] **Step 6: After 7 days of stability, schedule the dead-code removal**

This belongs to Step 4. Continue.

---

# STEP 4 — Decommission Neon (web)

**Goal:** Remove the dual-path code, drop Neon dependencies, leave web pure-Firestore.

**Branch:** `m1-step4-decommission-neon`

---

### Task 4.1: Create Step 4 worktree

**Agent type:** Single — orchestrator

- [ ] **Step 1**

```bash
cd "/Users/omairdawood/Projects/RIZQ App"
git worktree add ../rizq-m1-step4-neon -b m1-step4-decommission-neon m1-foundation
cd ../rizq-m1-step4-neon
```

---

### Task 4.2: Remove dual-path branching from all hooks

**Agent type:** Web TS subagent
**Skills:** `vercel:react-best-practices`, `pr-review-toolkit:silent-failure-hunter`
**Files:**
- Modify: every hook touched in Step 3 (read, user-data, admin write)
- Delete: `src/lib/db.ts`

- [ ] **Step 1: Delete the Neon branches in each hook**

For each hook, remove the `isFirestoreCutoverEnabled()` ternary; keep only the Firestore path. Remove `getSql` imports. Remove the legacy `mapDbToFrontend` helpers.

- [ ] **Step 2: Delete `src/lib/db.ts`**

Run: `git rm src/lib/db.ts`

- [ ] **Step 3: Drop `@neondatabase/serverless` and remove env var references**

Run: `npm uninstall @neondatabase/serverless`
Edit `.env.example`: delete `VITE_DATABASE_URL`, `VITE_AUTH_URL`, and the `VITE_FIRESTORE_CUTOVER` flag (no longer needed).

Edit `src/lib/firebase.ts`: remove the `isFirestoreCutoverEnabled()` export (no longer used).

- [ ] **Step 4: Verify build + tests still green**

Run: `npm run build && npx playwright test && npm run test:rules`
Expected: all pass.

- [ ] **Step 5: Verify zero Neon references remain in `src/`**

Run: `git grep -E "@neondatabase/serverless|getSql|VITE_DATABASE_URL|VITE_AUTH_URL|isFirestoreCutoverEnabled" -- 'src/' '*.ts' '*.tsx'`
Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "refactor(web): remove neon dual-path code and decommission @neondatabase/serverless"
```

---

### Task 4.3: Merge Step 4 to milestone branch

**Agent type:** Single — orchestrator

- [ ] **Step 1**

```bash
cd "/Users/omairdawood/Projects/RIZQ App"
git checkout m1-foundation
git merge --no-ff m1-step4-decommission-neon -m "merge: m1 step 4 decommission neon"
git push
git worktree remove ../rizq-m1-step4-neon
git branch -d m1-step4-decommission-neon
```

- [ ] **Step 2: Production deploy**

Deploy `m1-foundation` to production. With Neon code gone, the cutover is final on the web side.

- [ ] **Step 3: After 14 days of stability, pause the Neon database**

(Manual operation in Neon console.) After another 14 days, delete it.

---

# STEP 5 — iOS refactor (parallel track)

**Goal:** Hoist content fetching to a new `ContentFeature`, wrap `FirestoreContentClient` with a `CachedContentClient`, remove `becameActive` content fetches and `SampleData` user-facing fallbacks, enable Firestore offline persistence explicitly.

**Branch:** `m1-step5-ios`. Parallel sub-streams within: `m1-step5-content-feature`, `m1-step5-cache-wrapper`, `m1-step5-feature-refactor`. The feature-refactor stream depends on content-feature merging first.

**Review checkpoint:** REQUIRED at end (`pr-review-toolkit:code-reviewer` + `pr-review-toolkit:pr-test-analyzer`).

---

### Task 5.1: Create Step 5 base + parallel worktrees

**Agent type:** Single — orchestrator

- [ ] **Step 1**

```bash
cd "/Users/omairdawood/Projects/RIZQ App"
git checkout m1-foundation
git checkout -b m1-step5-ios
git push -u origin m1-step5-ios

git worktree add ../rizq-m1-step5-cf -b m1-step5-content-feature m1-step5-ios
git worktree add ../rizq-m1-step5-cache -b m1-step5-cache-wrapper m1-step5-ios
```

(The feature-refactor worktree is created in Task 5.5 after the first two merge.)

---

### Task 5.2: Create `ContentFeature` reducer

**Agent type:** iOS Swift subagent
**Skills:** `superpowers:test-driven-development`, `context7` (TCA 1.17 — `@Reducer`, `@ObservableState`, `@Dependency`, `.run`)
**Worktree:** `../rizq-m1-step5-cf` on `m1-step5-content-feature`
**Parallel with:** Task 5.3

**Files:**
- Create: `RIZQ-iOS/RIZQ/Features/Content/ContentFeature.swift`
- Create: `RIZQ-iOS/RIZQTests/ContentFeatureTests.swift`
- Modify: `RIZQ-iOS/project.yml` (if needed to register new directory)

- [ ] **Step 1: Write the failing test `ContentFeatureTests.swift`**

```swift
import ComposableArchitecture
import XCTest
@testable import RIZQ
@testable import RIZQKit

@MainActor
final class ContentFeatureTests: XCTestCase {
  func testOnAppearLoadsContent() async {
    let mockDuas = [Dua(id: 1, titleEn: "Test", arabicText: "ar", translationEn: "tr",
                       categoryId: 1, source: "Quran", repetitions: 1, xpValue: 10,
                       transliteration: nil, bestTime: nil, difficulty: nil,
                       rizqBenefit: nil, propheticContext: nil)]
    let store = TestStore(initialState: ContentFeature.State()) {
      ContentFeature()
    } withDependencies: {
      $0.cachedContentClient.fetchAllDuas = { mockDuas }
      $0.cachedContentClient.fetchAllJourneys = { [] }
      $0.cachedContentClient.fetchAllCategories = { [] }
    }

    await store.send(.task) { $0.isLoading = true }
    await store.receive(\.duasLoaded) {
      $0.duas = mockDuas
    }
    await store.receive(\.journeysLoaded) { _ in }
    await store.receive(\.categoriesLoaded) {
      $0.isLoaded = true
      $0.isLoading = false
    }
  }

  func testFetchErrorSetsErrorState() async {
    struct TestError: Error {}
    let store = TestStore(initialState: ContentFeature.State()) {
      ContentFeature()
    } withDependencies: {
      $0.cachedContentClient.fetchAllDuas = { throw TestError() }
      $0.cachedContentClient.fetchAllJourneys = { [] }
      $0.cachedContentClient.fetchAllCategories = { [] }
    }
    await store.send(.task) { $0.isLoading = true }
    await store.receive(\.loadFailed) {
      $0.error = .duasFailed
      $0.isLoading = false
    }
  }
}
```

- [ ] **Step 2: Run test — expect failure (file doesn't exist yet)**

Run: `cd RIZQ-iOS && xcodebuild test -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RIZQTests/ContentFeatureTests 2>&1 | grep -E "(error:|FAIL|PASS)"`
Expected: errors about missing `ContentFeature` symbol.

- [ ] **Step 3: Create `ContentFeature.swift`**

```swift
import ComposableArchitecture
import Foundation
import RIZQKit

@Reducer
struct ContentFeature {
  @ObservableState
  struct State: Equatable {
    var duas: [Dua] = []
    var journeys: [Journey] = []
    var categories: [Category] = []
    var isLoaded: Bool = false
    var isLoading: Bool = false
    var error: ContentError?
  }

  enum ContentError: Equatable { case duasFailed, journeysFailed, categoriesFailed }

  enum Action {
    case task
    case duasLoaded([Dua])
    case journeysLoaded([Journey])
    case categoriesLoaded([Category])
    case loadFailed(ContentError)
    case refresh
  }

  @Dependency(\.cachedContentClient) var content

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task, .refresh:
        state.isLoading = true
        state.error = nil
        return .merge(
          .run { send in
            do { let d = try await content.fetchAllDuas(); await send(.duasLoaded(d)) }
            catch { await send(.loadFailed(.duasFailed)) }
          },
          .run { send in
            do { let j = try await content.fetchAllJourneys(); await send(.journeysLoaded(j)) }
            catch { await send(.loadFailed(.journeysFailed)) }
          },
          .run { send in
            do { let c = try await content.fetchAllCategories(); await send(.categoriesLoaded(c)) }
            catch { await send(.loadFailed(.categoriesFailed)) }
          }
        )

      case let .duasLoaded(duas):
        state.duas = duas
        return .none

      case let .journeysLoaded(j):
        state.journeys = j
        return .none

      case let .categoriesLoaded(c):
        state.categories = c
        state.isLoaded = true
        state.isLoading = false
        return .none

      case let .loadFailed(err):
        state.error = err
        state.isLoading = false
        return .none
      }
    }
  }
}
```

- [ ] **Step 4: Add `RIZQ/Features/Content` to `project.yml` if XcodeGen requires it**

Inspect `RIZQ-iOS/project.yml`. If sources are auto-discovered, no change needed. Otherwise add the path.

If modified: run `cd RIZQ-iOS && xcodegen generate`.

- [ ] **Step 5: Run test — expect failure on `cachedContentClient` not yet defined**

Run the test command. Expected: errors about `cachedContentClient` dependency missing. That's fine — it's defined in Task 5.3 (parallel stream). For now, temporarily wire `ContentFeature` against the existing `firestoreContentClient`. We rewire to `cachedContentClient` in the merge step (Task 5.4).

Adjust the dependency line in `ContentFeature.swift`:
```swift
@Dependency(\.firestoreContentClient) var content
```
And update the test setup to use `firestoreContentClient`. Re-run.

Expected: tests PASS.

- [ ] **Step 6: Build verification**

Run: `cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 7: Commit**

```bash
git add RIZQ-iOS/RIZQ/Features/Content/ContentFeature.swift \
        RIZQ-iOS/RIZQTests/ContentFeatureTests.swift \
        RIZQ-iOS/project.yml
git commit -m "feat(ios): add ContentFeature reducer for shared content state"
```

---

### Task 5.3: Create `CachedContentClient` wrapper

**Agent type:** iOS Swift subagent
**Skills:** TDD, `context7` (TCA Dependencies, UserDefaults patterns)
**Worktree:** `../rizq-m1-step5-cache` on `m1-step5-cache-wrapper`
**Parallel with:** Task 5.2

**Files:**
- Create: `RIZQ-iOS/RIZQ/Dependencies/CachedContentClient.swift`
- Create: `RIZQ-iOS/RIZQTests/CachedContentClientTests.swift`

- [ ] **Step 1: Write failing test `CachedContentClientTests.swift`**

```swift
import ComposableArchitecture
import XCTest
@testable import RIZQ
@testable import RIZQKit

@MainActor
final class CachedContentClientTests: XCTestCase {
  override func setUp() {
    super.setUp()
    // Clear UserDefaults cache keys
    let defaults = UserDefaults.standard
    ["cached_duas", "cached_journeys", "cached_categories"].forEach { defaults.removeObject(forKey: $0) }
  }

  func testNetworkSuccessReturnsAndCachesResult() async throws {
    let mockDuas = [Dua.preview]
    var underlying = FirestoreContentClient.testValue
    underlying.fetchAllDuas = { mockDuas }
    let cached = CachedContentClient(wrapping: underlying)

    let result = try await cached.fetchAllDuas()
    XCTAssertEqual(result, mockDuas)

    // Verify cache populated
    let raw = UserDefaults.standard.data(forKey: "cached_duas")
    XCTAssertNotNil(raw)
  }

  func testNetworkFailureReturnsCachedResult() async throws {
    let mockDuas = [Dua.preview]
    // Pre-populate cache
    let data = try JSONEncoder().encode(mockDuas)
    UserDefaults.standard.set(data, forKey: "cached_duas")

    struct NetErr: Error {}
    var underlying = FirestoreContentClient.testValue
    underlying.fetchAllDuas = { throw NetErr() }
    let cached = CachedContentClient(wrapping: underlying)

    let result = try await cached.fetchAllDuas()
    XCTAssertEqual(result, mockDuas)
  }

  func testNetworkFailureWithEmptyCacheReturnsEmptyArray() async throws {
    struct NetErr: Error {}
    var underlying = FirestoreContentClient.testValue
    underlying.fetchAllDuas = { throw NetErr() }
    let cached = CachedContentClient(wrapping: underlying)

    let result = try await cached.fetchAllDuas()
    XCTAssertEqual(result, [])
  }
}
```

- [ ] **Step 2: Run test, expect failure**

Expected: errors about missing `CachedContentClient` type.

- [ ] **Step 3: Create `CachedContentClient.swift`**

```swift
import ComposableArchitecture
import Foundation
import os
import RIZQKit

private let logger = Logger(subsystem: "com.rizq.app", category: "CachedContentClient")

struct CachedContentClient: Sendable {
  var fetchAllDuas: @Sendable () async throws -> [Dua]
  var fetchAllJourneys: @Sendable () async throws -> [Journey]
  var fetchAllCategories: @Sendable () async throws -> [Category]

  init(wrapping underlying: FirestoreContentClient) {
    self.fetchAllDuas = Self.cachedFetch(
      key: "cached_duas",
      fetch: underlying.fetchAllDuas
    )
    self.fetchAllJourneys = Self.cachedFetch(
      key: "cached_journeys",
      fetch: underlying.fetchAllJourneys
    )
    self.fetchAllCategories = Self.cachedFetch(
      key: "cached_categories",
      fetch: underlying.fetchAllCategories
    )
  }

  private static func cachedFetch<T: Codable & Sendable>(
    key: String,
    fetch: @escaping @Sendable () async throws -> [T]
  ) -> @Sendable () async throws -> [T] {
    return {
      do {
        let result = try await fetch()
        if let data = try? JSONEncoder().encode(result) {
          UserDefaults.standard.set(data, forKey: key)
        }
        return result
      } catch {
        logger.error("Network fetch failed for \(key, privacy: .public); falling back to cache")
        if let data = UserDefaults.standard.data(forKey: key),
           let cached = try? JSONDecoder().decode([T].self, from: data) {
          return cached
        }
        return []
      }
    }
  }
}

extension CachedContentClient: DependencyKey {
  static let liveValue = CachedContentClient(
    wrapping: FirestoreContentClient.liveValue
  )

  static let testValue = CachedContentClient(
    wrapping: FirestoreContentClient.testValue
  )
}

extension DependencyValues {
  var cachedContentClient: CachedContentClient {
    get { self[CachedContentClient.self] }
    set { self[CachedContentClient.self] = newValue }
  }
}
```

- [ ] **Step 4: Run tests, expect pass**

Run: `cd RIZQ-iOS && xcodebuild test -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RIZQTests/CachedContentClientTests 2>&1 | grep -E "(error:|FAIL|PASS|Test Suite)"`
Expected: tests pass.

- [ ] **Step 5: Build verification**

Run: `cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD SUCCEEDED)"`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 6: Commit**

```bash
git add RIZQ-iOS/RIZQ/Dependencies/CachedContentClient.swift \
        RIZQ-iOS/RIZQTests/CachedContentClientTests.swift
git commit -m "feat(ios): add CachedContentClient wrapper with last-known-good fallback"
```

---

### Task 5.4: Merge Tasks 5.2 and 5.3 to `m1-step5-ios`; rewire `ContentFeature` to `cachedContentClient`

**Agent type:** iOS Swift subagent (orchestrator + a small follow-up edit)

- [ ] **Step 1: Merge both branches**

```bash
cd "/Users/omairdawood/Projects/RIZQ App"
git checkout m1-step5-ios
git merge --no-ff m1-step5-content-feature -m "merge: ContentFeature reducer"
git merge --no-ff m1-step5-cache-wrapper -m "merge: CachedContentClient wrapper"
git worktree remove ../rizq-m1-step5-cf
git worktree remove ../rizq-m1-step5-cache
git branch -d m1-step5-content-feature m1-step5-cache-wrapper
```

- [ ] **Step 2: Now that both exist, rewire `ContentFeature`**

In `ContentFeature.swift`, change:
```swift
@Dependency(\.firestoreContentClient) var content
```
to:
```swift
@Dependency(\.cachedContentClient) var content
```

- [ ] **Step 3: Update `ContentFeatureTests.swift`** to set `$0.cachedContentClient` instead of `$0.firestoreContentClient`.

- [ ] **Step 4: Rebuild + test**

Run: `cd RIZQ-iOS && xcodebuild test -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep -E "(error:|FAIL|PASS|BUILD)"`
Expected: build succeeds; ContentFeature + CachedContentClient tests pass.

- [ ] **Step 5: Commit**

```bash
git add RIZQ-iOS/RIZQ/Features/Content/ContentFeature.swift \
        RIZQ-iOS/RIZQTests/ContentFeatureTests.swift
git commit -m "refactor(ios): wire ContentFeature to CachedContentClient"
```

---

### Task 5.5: Wire `ContentFeature` into `AppFeature`; refactor child features

**Agent type:** iOS Swift subagent
**Skills:** TDD, `context7` (TCA `Scope`, child reducer composition)
**Worktree:** `../rizq-m1-step5-refactor` on `m1-step5-feature-refactor` (cut now that Task 5.4 has merged)

- [ ] **Step 1: Cut the worktree**

```bash
git worktree add ../rizq-m1-step5-refactor -b m1-step5-feature-refactor m1-step5-ios
cd ../rizq-m1-step5-refactor
```

- [ ] **Step 2: Modify `AppFeature.swift`**

Add `content: ContentFeature.State()` to `AppFeature.State`. Add `content(ContentFeature.Action)` to `Action`. Compose with `Scope(state: \.content, action: \.content) { ContentFeature() }`. On app's root `task`, send `.content(.task)`.

- [ ] **Step 3: Update `AppView.swift`**

Pass `store.scope(state: \.content, action: \.content)` down to children that need content. Specifically, refactor:
- `AdkharView` to receive `store.scope(state: \.adkhar, action: \.adkhar)` AND access content via `store.content.duas` / `store.content.journeys`. Alternatively, pass content into Adkhar's state via parent action.

Choose the parent-action pattern: `AdkharFeature.Action` gains `case contentUpdated(ContentFeature.State)`, and `AppFeature` listens for content state changes and forwards. Keeps `AdkharFeature` independently testable.

- [ ] **Step 4: Refactor `AdkharFeature.swift`**

- Remove the `becameActive` case that fetches duas/journeys.
- Remove the timeout/SampleData fallback blocks (~25 lines).
- Add `case contentUpdated(duas: [Dua], journeys: [Journey], categories: [Category])`. When received, recompute the habit list.
- Remove all `firestoreContentClient` direct calls; the feature no longer fetches content itself (only user habit data).

- [ ] **Step 5: Same refactor for `JourneysFeature.swift`**

Remove fetch + timeout + SampleData fallback. Subscribe to content via parent.

- [ ] **Step 6: Same for `LibraryFeature.swift`**

- [ ] **Step 7: Same for `HomeFeature.swift`**

`HomeFeature` retains its `becameActive` for user-data refresh (streak, weekly activity), but stops fetching journeys/duas. It reads them from parent.

- [ ] **Step 8: Update existing reducer tests**

`AdkharFeatureTests`, `JourneysFeatureTests`, etc. — assert content-derived behavior assuming content is provided externally.

- [ ] **Step 9: Build + run all tests**

Run: `cd RIZQ-iOS && xcodebuild test -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep -E "(error:|FAIL|PASS|BUILD)"`
Expected: build succeeds; all tests pass.

- [ ] **Step 10: Commit**

```bash
git add RIZQ-iOS/RIZQ/App/ RIZQ-iOS/RIZQ/Features/
git commit -m "refactor(ios): consume shared ContentFeature; remove per-feature fetches and SampleData fallback"
```

---

### Task 5.6: Enable Firestore offline persistence in `RIZQApp.swift`

**Agent type:** iOS Swift subagent
**Skills:** `context7` (Firebase iOS 11 `PersistentCacheSettings`)
**Files:**
- Modify: `RIZQ-iOS/RIZQ/App/RIZQApp.swift`

- [ ] **Step 1: Read existing `RIZQApp.swift`**

- [ ] **Step 2: After `FirebaseApp.configure()`, add explicit persistence**

```swift
import FirebaseFirestore

// Inside the App init (or AppDelegate didFinishLaunching), AFTER FirebaseApp.configure():
let settings = FirestoreSettings()
settings.cacheSettings = PersistentCacheSettings()
Firestore.firestore().settings = settings
```

(Important: `Firestore.firestore().settings = settings` must happen before any other Firestore call. If existing code calls Firestore inside `FirebaseApp.configure`'s aftermath in any other place, ensure ordering.)

- [ ] **Step 3: Build verification**

Run: `cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD SUCCEEDED)"`
Expected: `BUILD SUCCEEDED`. (Note: Firestore prints a warning if settings are set after first use; if so, move the snippet earlier.)

- [ ] **Step 4: Manual smoke test (airplane mode)**

Launch app → use it normally for a session → kill app → enable airplane mode → relaunch.
Expected: Adkhar/Journeys/Library show last-session content (cached), not `SampleData`. Loading state appears briefly, then real data.

- [ ] **Step 5: Commit**

```bash
git add RIZQ-iOS/RIZQ/App/RIZQApp.swift
git commit -m "feat(ios): enable explicit Firestore persistent cache"
```

---

### Task 5.7: Strip iOS debug residue from recent commits

**Agent type:** iOS Swift subagent
**Skills:** `pr-review-toolkit:silent-failure-hunter`
**Files:**
- Multiple: search-and-cleanup

- [ ] **Step 1: Find debug residue**

Run: `cd RIZQ-iOS && grep -rn "DEBUG\|debug banner\|//.*debug" RIZQ/Features/ 2>/dev/null`

Cross-reference against commits `3d4ed3a`, `96788ff`, `9eafc8b`, `2f0a111`, `f78a641`, `8482e2e`, `1cb1fa9`, `04a4523`, `ed7b759`, `033e5f6`, `91563eb`. For each addition, verify it's no longer needed (the new ContentFeature architecture removes the underlying issue).

- [ ] **Step 2: Remove debug banners on Adkhar/Journeys views**

- [ ] **Step 3: Remove redundant `.onAppear` backup triggers**

- [ ] **Step 4: Remove tab-change logging in `AppView`**

- [ ] **Step 5: Build + test**

Run: `cd RIZQ-iOS && xcodebuild test -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep -E "(error:|FAIL|PASS|BUILD)"`
Expected: all green.

- [ ] **Step 6: Commit**

```bash
git add RIZQ-iOS/RIZQ/
git commit -m "chore(ios): remove debug banners and redundant onAppear triggers (now obsolete)"
```

---

### Task 5.8: Step 5 review checkpoint + merge

**Agent type:** Reviewer subagents → orchestrator merge

- [ ] **Step 1: Run `pr-review-toolkit:code-reviewer` against `m1-step5-ios..m1-step5-feature-refactor`**

- [ ] **Step 2: Run `pr-review-toolkit:pr-test-analyzer` to confirm test coverage of `ContentFeature` and `CachedContentClient`**

- [ ] **Step 3: Merge feature-refactor branch + iOS-step branch**

```bash
cd "/Users/omairdawood/Projects/RIZQ App"
git checkout m1-step5-ios
git merge --no-ff m1-step5-feature-refactor -m "merge: feature refactor consumes shared content"
git checkout m1-foundation
git merge --no-ff m1-step5-ios -m "merge: m1 step 5 ios refactor complete"
git push
git worktree remove ../rizq-m1-step5-refactor
git branch -d m1-step5-feature-refactor m1-step5-ios
```

---

# STEP 6 — Dead code purge (iOS)

**Goal:** Delete legacy iOS Neon clients and the rollback-procedure section in CLAUDE.md.

**Branch:** `m1-step6-dead-code-purge`

---

### Task 6.1: Worktree + delete files + remove rollback section

**Agent type:** iOS Swift subagent

- [ ] **Step 1: Worktree**

```bash
cd "/Users/omairdawood/Projects/RIZQ App"
git worktree add ../rizq-m1-step6-purge -b m1-step6-dead-code-purge m1-foundation
cd ../rizq-m1-step6-purge
```

- [ ] **Step 2: Delete legacy iOS files**

```bash
git rm RIZQ-iOS/RIZQKit/Services/API/NeonService.swift
git rm RIZQ-iOS/RIZQKit/Services/API/NeonClient.swift
git rm RIZQ-iOS/RIZQKit/Services/API/APIClient.swift
git rm RIZQ-iOS/RIZQKit/Services/API/FirebaseNeonService.swift
git rm RIZQ-iOS/RIZQTests/NeonServiceTests.swift
```

- [ ] **Step 3: Verify no remaining references**

Run: `grep -rn "NeonService\|NeonClient\|APIClient\|FirebaseNeonService" RIZQ-iOS/RIZQ/ RIZQ-iOS/RIZQKit/ 2>/dev/null`
Expected: no output (or only matches in comments to be removed manually).

- [ ] **Step 4: Remove "Rollback Procedure" section from `RIZQ-iOS/CLAUDE.md`**

Delete the section titled "Rollback Procedure (If Needed)" and its bullets. Replace with a one-liner: `> Migration to Firestore is final as of Milestone 1 (May 2026). No rollback path is supported.`

- [ ] **Step 5: Regenerate Xcode project (if needed)**

Run: `cd RIZQ-iOS && xcodegen generate`

- [ ] **Step 6: Build verification**

Run: `cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD SUCCEEDED)"`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "chore(ios): purge legacy Neon clients and rollback procedure"
```

- [ ] **Step 8: Merge**

```bash
cd "/Users/omairdawood/Projects/RIZQ App"
git checkout m1-foundation
git merge --no-ff m1-step6-dead-code-purge -m "merge: m1 step 6 dead code purge"
git push
git worktree remove ../rizq-m1-step6-purge
git branch -d m1-step6-dead-code-purge
```

---

# STEP 7 — Housekeeping

**Goal:** Wire the SettingsPage reset TODO, gitignore `firebase-debug.log`, remove the `autoforge/` directory.

**Branch:** `m1-step7-housekeeping`. Two parallel sub-streams: `settings-reset` (web) and `repo-cleanup`.

---

### Task 7.1: Create Step 7 base + parallel worktrees

```bash
cd "/Users/omairdawood/Projects/RIZQ App"
git checkout m1-foundation
git checkout -b m1-step7-housekeeping
git worktree add ../rizq-m1-step7-settings -b m1-step7-settings-reset m1-step7-housekeeping
git worktree add ../rizq-m1-step7-cleanup -b m1-step7-repo-cleanup m1-step7-housekeeping
```

---

### Task 7.2: Wire `SettingsPage` reset TODO

**Agent type:** Web TS subagent
**Skills:** TDD, `vercel:react-best-practices`, reference iOS `firestoreUserClient.resetUserProgress`
**Worktree:** `../rizq-m1-step7-settings` on `m1-step7-settings-reset`
**Parallel with:** Task 7.3

**Files:**
- Modify: `src/pages/SettingsPage.tsx`
- Reference: `RIZQ-iOS/RIZQKit/Services/Firebase/FirebaseUserService.swift` `resetUserProgress` impl

- [ ] **Step 1: Read both files first**

- [ ] **Step 2: Write failing e2e (extends `e2e/journeys.spec.ts` or new `e2e/settings.spec.ts`)**

```typescript
test('reset progress wipes streak, xp, level, and activity', async ({ page }) => {
  // Sign in, complete a dua, navigate to Settings, click "Reset progress", confirm.
  // Verify profile shows level 1, xp 0, streak 0.
  // Verify activity subcollection is empty.
});
```

- [ ] **Step 3: Implement the reset handler**

Replace the TODO in `SettingsPage.tsx:192` with a Firestore-backed reset. Use the iOS pattern as reference: a single transaction that resets `user_profiles` fields and deletes the `user_activity/{uid}/dates/*` subcollection (use a batch).

```typescript
async function handleResetProgress() {
  if (!user) return;
  setIsResetting(true);
  try {
    const db = getDb();
    // Reset profile
    await updateDoc(doc(db, 'user_profiles', user.uid), {
      streak: 0, totalXp: 0, level: 1, lastActiveDate: null,
    });
    // Delete activity subcollection in batches
    const datesRef = collection(db, 'user_activity', user.uid, 'dates');
    const snap = await getDocs(datesRef);
    if (!snap.empty) {
      const batch = writeBatch(db);
      snap.docs.forEach((d) => batch.delete(d.ref));
      await batch.commit();
    }
    // Delete progress subcollection
    const duaRef = collection(db, 'user_progress', user.uid, 'duas');
    const dsnap = await getDocs(duaRef);
    if (!dsnap.empty) {
      const batch = writeBatch(db);
      dsnap.docs.forEach((d) => batch.delete(d.ref));
      await batch.commit();
    }
    await refreshProfile();
    toast.success('Progress reset');
  } catch (e) {
    toast.error('Failed to reset progress');
  } finally {
    setIsResetting(false);
  }
}
```

- [ ] **Step 4: Run e2e, expect pass**

Run: `npx playwright test e2e/settings.spec.ts`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/pages/SettingsPage.tsx e2e/settings.spec.ts
git commit -m "feat(settings): wire reset progress to firestore"
```

---

### Task 7.3: Repo cleanup (gitignore + autoforge removal + firebase-debug.log)

**Agent type:** Single — orchestrator, no specialized agent needed
**Worktree:** `../rizq-m1-step7-cleanup` on `m1-step7-repo-cleanup`
**Parallel with:** Task 7.2

**Files:**
- Modify: `.gitignore`
- Delete (working tree): `autoforge/`, `firebase-debug.log`

- [ ] **Step 1: Add lines to `.gitignore`**

```
# Firebase debug logs
firebase-debug.log
firebase-debug.*.log
firestore-debug.log
ui-debug.log

# AutoForge (separate project — should not live in this repo)
autoforge/
```

- [ ] **Step 2: Remove `firebase-debug.log` from working tree**

Run: `rm -f firebase-debug.log`

(Note: `firebase-debug.log` is a 760KB working-tree file but not committed; just deletion is enough.)

- [ ] **Step 3: Move `autoforge/` outside the repo**

Run: `mv autoforge ~/Projects/autoforge-recovered` (or wherever the user prefers — confirm before executing if unsure).

If the user is uncertain, leave it in place and rely on `.gitignore` to keep it out of version control. The user can move it later.

- [ ] **Step 4: Verify**

Run: `git status` — expect only `.gitignore` modified; `autoforge/` and `firebase-debug.log` no longer reported.

- [ ] **Step 5: Commit**

```bash
git add .gitignore
git commit -m "chore(repo): gitignore firebase debug logs and autoforge directory"
```

---

### Task 7.4: Merge Step 7 sub-branches

**Agent type:** Single — orchestrator

```bash
cd "/Users/omairdawood/Projects/RIZQ App"
git checkout m1-step7-housekeeping
git merge --no-ff m1-step7-settings-reset -m "merge: settings reset progress wired"
git merge --no-ff m1-step7-repo-cleanup -m "merge: repo cleanup"
git checkout m1-foundation
git merge --no-ff m1-step7-housekeeping -m "merge: m1 step 7 housekeeping"
git push
git worktree remove ../rizq-m1-step7-settings
git worktree remove ../rizq-m1-step7-cleanup
git branch -d m1-step7-housekeeping m1-step7-settings-reset m1-step7-repo-cleanup
```

---

# MILESTONE COMPLETION

### Task M.1: End-of-milestone review + merge to main

**Agent type:** Reviewer subagents → orchestrator merge

- [ ] **Step 1: Verify all success criteria from spec § 9**

Run each:
```bash
git grep "@neondatabase/serverless" -- src/ ; echo "expected: empty"
git grep -E "Better Auth|@better-auth" ; echo "expected: empty"
find RIZQ-iOS \( -name "Neon*.swift" -o -name "FirebaseNeonService.swift" -o -name "APIClient.swift" \) ; echo "expected: empty"
npx playwright test ; echo "expected: all green"
cd RIZQ-iOS && xcodebuild build -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' ; echo "expected: BUILD SUCCEEDED"
cat .gitignore | grep firebase-debug ; echo "expected: matches"
ls autoforge 2>&1 ; echo "expected: not found (or moved)"
```

- [ ] **Step 2: Run `validation:code-review` skill** (project-specific)

Address any high-priority findings.

- [ ] **Step 3: Run `pr-review-toolkit:review-pr` full workflow** against `main..m1-foundation`

Address any high-priority findings.

- [ ] **Step 4: Manual smoke test on staging deploy of `m1-foundation`**

Re-verify the full success criteria list with eyes on the running app. Production data flow from Firestore (no flag), iOS cached fallback works under airplane mode, settings reset clears all data.

- [ ] **Step 5: Merge to main**

```bash
cd "/Users/omairdawood/Projects/RIZQ App"
git checkout main
git merge --no-ff m1-foundation -m "feat: Milestone 1 — Foundation (web → Firestore + Firebase Auth, iOS ContentFeature/CachedContentClient refactor)"
git push
```

- [ ] **Step 6: Tag the milestone**

```bash
git tag -a m1-foundation-complete -m "Milestone 1: Foundation complete"
git push --tags
```

- [ ] **Step 7: Pause Neon database in Neon console**

After 14 days of stability, delete it.

- [ ] **Step 8: Update CLAUDE.md (root) to reflect new web architecture**

Replace any "Neon PostgreSQL (web)" references with Firestore. Update the database strategy section.

```bash
git checkout -b post-m1-claude-md-update
# ... edit CLAUDE.md ...
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md to reflect post-M1 firestore-only architecture"
git checkout main
git merge --no-ff post-m1-claude-md-update
git push
```

---

## Self-Review (executed at plan-write time)

**Spec coverage check:**
- § 4.1 Web Data Layer → Tasks 1.3, 3.2, 3.3, 3.4, 4.2 ✓
- § 4.2 Web Auth → Tasks 2.2–2.5 ✓
- § 4.3 Admin Authorization → Tasks 1.5, 1.6, 3.4 ✓
- § 4.4 iOS Content State → Tasks 5.2, 5.5 ✓
- § 4.5 iOS Cache Layer → Tasks 5.3, 5.4, 5.6 ✓
- § 5 Migration Sequence → Steps 1–7 map 1:1 ✓
- § 6 Testing Strategy → Tasks 1.6, 2.3, 3.2, 3.3, 3.4, 5.2, 5.3, 7.2 ✓
- § 7 Risks → Mitigated by env-flag pattern (Step 3), staging deploy (Task 3.6), rules tests (Task 1.6) ✓
- § 9 Success Criteria → Task M.1 Step 1 ✓
- § 10 Multi-agent execution model → Each task lists agent type, skills, worktree, parallelization markers ✓

**Placeholder scan:** Searched for "TBD", "TODO", "fill in", "implement later". The only matches are legitimate references to the existing `SettingsPage` TODO that Task 7.2 wires up. ✓

**Type consistency:** `cachedContentClient` referenced in Tasks 5.2 (initially as `firestoreContentClient` for the parallel-merge ordering, switched in 5.4), 5.5. `ContentFeature.State` properties (`duas`, `journeys`, `categories`, `isLoaded`, `isLoading`, `error`) consistent across Tasks 5.2, 5.5. `isFirestoreCutoverEnabled()` is exposed in Task 1.3 and removed in Task 4.2. ✓

**One gap fixed inline:** initially missed adding the `cachedContentClient` `DependencyValues` extension; corrected in Task 5.3 Step 3.
