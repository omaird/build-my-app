# Milestone 1 — Foundation: Design

**Date:** 2026-05-08
**Status:** Approved (brainstorming complete; ready for implementation plan)
**Owner:** Omair Dawood
**Roadmap context:** First of three milestones — Foundation (this), Persona Journeys (M2), Habit Formation (M3).

---

## 1. Goal

Eliminate the Neon ↔ Firestore data drift, retire the manual `seed-firestore.cjs` workflow, and remove the iOS Firestore cold-start band-aids. Leave the codebase with a single source of truth (Firestore + Firebase Auth) and a stabilized iOS data flow.

## 2. Outcomes

When the milestone is done:

1. The web app reads and writes Firestore directly. Neon is dead code (deleted from web; iOS legacy clients deleted).
2. Web auth is Firebase Auth (Google + GitHub providers), matching iOS.
3. The admin panel uses Firebase Auth custom claims (`request.auth.token.admin == true`) for write authorization.
4. iOS no longer refetches content on every tab switch. A single source-of-truth fetch lives in a new `ContentFeature` reducer; child features (Adkhar, Journeys, Library) consume from shared state via TCA scope. On Firestore failure or cold start, the user sees cached data — never `SampleData`.
5. Existing user accounts in Neon are abandoned (fresh-start migration). Users sign in again on first visit; profiles auto-created in Firestore on first sign-in.
6. The `SettingsPage` reset TODO is wired up.
7. Repo hygiene: `firebase-debug.log` gitignored, `autoforge/` (a separate project that landed here) removed.

## 3. Out of Scope

Deferred to later milestones, called out explicitly so they don't creep in:

- Audio recitation playback. The admin schema already has `audioUrl`; we leave it and don't build the player here.
- Push notifications and streak restoration → Milestone 3.
- Family Fortress and Inner Peace persona journeys → Milestone 2.
- Real-time content listeners on iOS. Today's pull model is fine; we keep it.
- Migration of existing Neon `user_activity` / `user_progress` history. Fresh start.
- Apple Watch, Android, premium tiers, social features.

## 4. Architecture

### 4.1 Web — Data Layer

Replace [src/lib/db.ts](../../../src/lib/db.ts) (Neon SQL client) with `src/lib/firebase.ts` initializing the Firebase Web SDK (Auth + Firestore) from `VITE_FIREBASE_*` env vars. Drop `@neondatabase/serverless` from `package.json`.

Hooks switch to Firestore queries while keeping React Query as the caching layer. Only the `queryFn` body changes:

| Hook | Before (Neon SQL) | After (Firestore) |
|------|-------------------|-------------------|
| `useDuas` | `SELECT * FROM duas` | `getDocs(collection(db, 'duas'))` |
| `useJourneys` | `SELECT … FROM journeys` | `query(collection(db, 'journeys'), orderBy('sortOrder'))` |
| `useJourneyDuas(id)` | join SQL | `query(collection(db, 'journey_duas'), where('journeyId', '==', id))` |
| `useCategories` | `SELECT * FROM categories` | `getDocs(collection(db, 'categories'))` |
| `useCollections` | `SELECT * FROM collections` | `getDocs(collection(db, 'collections'))` |
| `useActivity` | `SELECT … FROM user_activity WHERE user_id = ?::uuid` | `getDocs(collection(db, 'user_activity', uid, 'dates'))` |
| `useUserHabits` | localStorage + Neon | localStorage for subscriptions + Firestore for completions |
| `addXp` (in `AuthContext`) | UPSERT against `user_profiles` + `user_activity` | Firestore transaction mirroring iOS `recordPracticeCompletion` |
| `hooks/admin/*` | `INSERT/UPDATE/DELETE` SQL | `addDoc` / `updateDoc` / `deleteDoc` |

The `mapDbToFrontend` shim functions (~150 LoC) are deleted. Firestore docs are camelCase already.

User IDs become Firebase UID strings (no more `::uuid` casts). All hook signatures and component props that take a `userId` change type from `UUID` to `string`.

### 4.2 Web — Auth

[src/contexts/AuthContext.tsx](../../../src/contexts/AuthContext.tsx) is rewritten against the Firebase Auth Web SDK:

- `signInWithPopup(GoogleAuthProvider)` and `GithubAuthProvider`
- `onAuthStateChanged` drives the `user` state
- On first sign-in, a Firestore `user_profiles/{uid}` doc is auto-created mirroring iOS's `getOrCreateUserProfile` behavior in [FirebaseUserService.swift](../../../RIZQ-iOS/RIZQKit/Services/Firebase/FirebaseUserService.swift)
- `addXp`, `refreshProfile` rewritten as Firestore transactions matching iOS shape
- `lastUsedProvider` localStorage logic preserved (UX nicety)

Better Auth and `neon_auth` references are removed. `src/lib/auth-client.ts` is deleted.

### 4.3 Admin Authorization

The admin panel uses Firebase Auth custom claims for write authorization. A new CLI script `scripts/set-admin-claim.cjs` uses Firebase Admin SDK to toggle `admin: true` on a Firebase UID. This is run manually to bootstrap the first admin and to promote subsequent admins.

[firestore.rules](../../../firestore.rules) gains:

```javascript
match /duas/{id}        { allow read: if true; allow write: if request.auth.token.admin == true; }
match /journeys/{id}    { allow read: if true; allow write: if request.auth.token.admin == true; }
match /journey_duas/{id}{ allow read: if true; allow write: if request.auth.token.admin == true; }
match /categories/{id}  { allow read: if true; allow write: if request.auth.token.admin == true; }
match /collections/{id} { allow read: if true; allow write: if request.auth.token.admin == true; }
```

User data rules (owner-based) are unchanged.

**No Cloud Functions are deployed.** The CLI script is the only new infra. Admin user management UI in the existing admin panel stays read-only for the claim itself; promotions go through the CLI for now.

### 4.4 iOS — Content State

Today: each of `AdkharFeature`, `JourneysFeature`, `LibraryFeature`, `HomeFeature` fetches duas/journeys/categories independently on `becameActive`. Cold-start latency triggers a 10s/8s timeout that falls back to `SampleData` (fake content presented as real).

After: a new **`ContentFeature`** reducer (its own file, scoped under `AppFeature`) owns the canonical content state.

```
AppFeature.State
  ├── content: ContentFeature.State          ← NEW
  │     ├── duas: [Dua]
  │     ├── journeys: [Journey]
  │     ├── categories: [Category]
  │     ├── isLoaded: Bool
  │     └── error: ContentError?
  ├── home: HomeFeature.State
  ├── adkhar: AdkharFeature.State
  ├── journeys: JourneysFeature.State
  ├── library: LibraryFeature.State
  └── (other tabs)
```

Content is fetched once on app launch via `AppFeature`'s `.task`. Child features read content via TCA scope; they do **not** fetch on `becameActive`. The `becameActive` lifecycle on Adkhar/Journeys/Library is removed entirely. (HomeFeature keeps it for stats refresh, which is user-data, not content.)

Why a dedicated reducer vs. stuffing into `AppFeature`:
- `AppFeature` is already a router (6 tabs + admin + auth + presentation state). It must not become a god reducer.
- `ContentFeature` is independently testable with its own `TestStore`.
- Future real-time listeners (M3+) belong here, not in a router.
- The widget target (which can't import `AppFeature`) can import a self-contained `ContentFeature`.

### 4.5 iOS — Cache Layer

A new **`CachedContentClient`** wraps the existing `FirestoreContentClient`. The wrapper is the only thing exposed to features; its `liveValue` is `CachedContentClient(wrapping: FirestoreContentClient.live)`.

Fallback chain on every fetch:

1. Network (Firestore) succeeds → return + persist to cache
2. Network fails / times out → return cache if present
3. Cache empty → return empty array

`SampleData` is **only** for Xcode previews and tests. It never reaches end users.

The cache uses `UserDefaults` (or a small file-based store, judgment call during implementation) keyed by collection name. Why a wrapper rather than burying the cache rule inside `FirestoreContentService`:
- Keeps `FirestoreContentService` a thin Firestore-SDK adapter (one job).
- The cache rule is exactly the kind of logic that fails silently — isolating it in a tested wrapper is the right trade.
- Composes cleanly with TCA dependencies. Tests swap to the unwrapped client trivially.
- Matches the existing pattern under [RIZQKit/Services/Persistence/](../../../RIZQ-iOS/RIZQKit/Services/Persistence/) where caching is already a separate concern.

Firestore offline persistence is **also** enabled explicitly in [RIZQApp.swift](../../../RIZQ-iOS/RIZQ/App/RIZQApp.swift) via `Firestore.firestore().settings.cacheSettings = PersistentCacheSettings()`. This gives us two layers of caching: Firestore SDK (transparent, generally good) + our wrapper (explicit, controlled, testable). Belt and suspenders is correct here because the cost is one line and the wrapper gives us deterministic test behavior the SDK cache doesn't.

### 4.6 Files Not Forced to Split

[AdkharFeature.swift](../../../RIZQ-iOS/RIZQ/Features/Adkhar/AdkharFeature.swift) (767 lines), [HomeFeature.swift](../../../RIZQ-iOS/RIZQ/Features/Home/HomeFeature.swift) (530), [HomeView.swift](../../../RIZQ-iOS/RIZQ/Features/Home/HomeView.swift) (653) shrink naturally as fetch logic moves out. If `AdkharFeature` is still >500 lines after the refactor, habit-completion logic splits into a child feature. Otherwise it stays.

## 5. Migration Sequence

The hard rule throughout: **never have a state where the app is broken in production**. Each step deploys cleanly.

**Step 1 — Prep (no behavior change).**
Add `firebase` to `package.json`. Create `src/lib/firebase.ts`. Add `scripts/set-admin-claim.cjs`. Bootstrap the first admin's custom claim. Update `firestore.rules` for content collection writes; deploy rules. Web still runs entirely on Neon + Better Auth — none of this is wired in. Verifiable: app behaves identically; new env present.

**Step 2 — Auth cutover.**
Rewrite `AuthContext.tsx` for Firebase Auth Web. Existing users re-sign-in. On first sign-in, `user_profiles/{uid}` is auto-created in Firestore. Better Auth removed; `auth-client.ts` deleted. Content reads still come from Neon — there is **no read/write split** introduced by this step. App stays consistent.

User-visible disruption: the one-time re-sign-in moment. Communicated via a brief notice on the landing page.

**Step 3 — Atomic Firestore cutover.**
A single deploy switches the entire web data path simultaneously:
- All read hooks → Firestore
- All user-data hooks (`useActivity`, `useUserHabits`, `addXp`, `refreshProfile`) → Firestore subcollections
- All admin write hooks (`hooks/admin/*`) → Firestore via client SDK guarded by custom claim

After this deploy, the web app no longer touches Neon at all. The seed script is retired the moment this deploys. No manual sync windows. This is the highest-risk step and is exactly why it's atomic; gated behind a staging deploy + manual smoke test before production promotion.

**Step 4 — Decommission Neon (web).**
Drop `@neondatabase/serverless`. Delete `src/lib/db.ts`. Remove `VITE_DATABASE_URL` and `VITE_AUTH_URL` from `.env.example`. Delete `mapDbToFrontend` shims. The Neon database itself stays paused for 14 days as an emergency rollback safety net, then is deleted.

**Step 5 — iOS refactor (parallel track, can run alongside Steps 1–4).**
Introduce `ContentFeature`. Wrap `FirestoreContentClient` with `CachedContentClient`. Remove `becameActive` content fetches from Adkhar/Journeys/Library. Replace `SampleData` user-facing fallback with cached-or-empty. Enable Firestore offline persistence in `RIZQApp.swift`. Delete debug banners, timeout fallbacks, multi-`.onAppear` backups. Verify each sub-step with `xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build`.

**Step 6 — Dead code purge.**
iOS: delete `NeonService.swift`, `NeonClient.swift`, `APIClient.swift`, `FirebaseNeonService.swift`, `NeonServiceTests.swift`. Remove the rollback procedure section from [RIZQ-iOS/CLAUDE.md](../../../RIZQ-iOS/CLAUDE.md) — pretending rollback is real after this milestone is false safety.

**Step 7 — Housekeeping.**
- Wire up the [SettingsPage:192](../../../src/pages/SettingsPage.tsx#L192) reset TODO using the iOS `firestoreUserClient.resetUserProgress` pattern as reference.
- `.gitignore` `firebase-debug.log` and remove the file from the working tree.
- Remove `autoforge/` from this repo. It's a separate Leon van Zyl project that landed here by accident; it should live in its own repo.

## 6. Testing Strategy

### 6.1 Web — Playwright e2e
Currently only [e2e/auth.spec.ts](../../../e2e/auth.spec.ts) and [e2e/admin-journeys.spec.ts](../../../e2e/admin-journeys.spec.ts) exist; last run failed. We expand coverage targeted at the unified data path:

- **`auth.spec.ts`** — updated to test Firebase Auth flow (Google emulator). Verify `user_profiles/{uid}` doc is created on first sign-in.
- **`practice.spec.ts`** (NEW) — golden path: sign in → open a dua → tap counter → verify XP recorded in Firestore (via emulator query).
- **`journeys.spec.ts`** (NEW) — subscribe to a journey → verify habit appears on Daily Adkhar page.
- **`admin-duas.spec.ts`** (NEW) — admin user (custom claim set in test setup) creates/updates/deletes a dua → verify Firestore write succeeded → verify a non-admin user sees the read but cannot write.

All e2e tests run against the Firebase Local Emulator Suite (Auth + Firestore + Rules). No real Firebase project hit in CI.

### 6.2 Firestore Rules Tests (NEW)
Use `@firebase/rules-unit-testing`. Coverage:
- Anyone can read content collections; only `admin: true` can write.
- A user can read/write their own `user_profiles/{uid}` doc; cannot read another user's.
- A user can read/write their own `user_activity/{uid}/dates/*` subcollection; cannot read another user's.

This is non-negotiable. The cost of a security rule bug is catastrophic; the cost of these tests is small.

### 6.3 iOS — Reducer Tests (TestStore)
- **`ContentFeatureTests`** (NEW) — onAppear loads from client, error state on failure, refresh action re-fetches.
- **`AdkharFeatureTests`** (NEW) — given content from parent state, derives correct habits per time slot. No Firestore mocking required because it doesn't fetch.
- **`JourneysFeatureTests`** (NEW) — same shape: derives from shared content.
- Existing `SettingsFeatureTests` and `FirebaseAuthTests` stay; `NeonServiceTests.swift` is deleted.

### 6.4 iOS — Cache Wrapper Tests (NEW)
`CachedContentClientTests` covers exactly the fallback rule:
- Network success → returns network result + cache populated.
- Network failure with cache present → returns cache.
- Network failure with no cache → returns empty array (NOT `SampleData`).

### 6.5 iOS — Snapshot Tests
Existing `RIZQSnapshotTests.swift` is preserved. Add snapshots for:
- Adkhar empty state (cached-or-empty fallback).
- Journeys loading state.
- Settings page after the reset TODO is wired.

### 6.6 What we deliberately don't test
- React Query plumbing (framework code).
- Firestore SDK behavior (Google's tests).
- UI animations / Framer Motion behavior.
- iOS view layouts beyond the targeted snapshots above.

## 7. Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Firebase custom claim takes ~1 hour to propagate to existing tokens | Admin can't write immediately after promotion | After CLI sets claim, force token refresh via `auth.currentUser.getIdToken(true)` in admin onboarding; document this in `set-admin-claim.cjs`. |
| Firestore quota costs from direct browser queries | Bill spike at scale | Enable web Firestore IndexedDB persistence (`enableIndexedDbPersistence` or new `persistentLocalCache`); tune React Query staleness; monitor in Firebase console for first 30 days post-cutover. |
| Step 3 atomic deploy is large; if something breaks, every web user feels it | Production outage | (a) Full staging deploy first with manual smoke test against the real Firestore project (isolated test data). (b) Step 3 ships behind a `VITE_FIRESTORE_CUTOVER` env flag. The deploy contains both code paths; flipping the flag is the cutover, so rollback is one env change, not a redeploy. After 7 days stable, the flag and the dead-code path are removed in a follow-up. |
| iOS `ContentFeature` not loaded yet when a child feature renders | Brief empty state on cold launch | Child features show a loading view if `content.isLoaded == false`. Cache makes this near-instant on subsequent launches. Acceptable. |
| Existing users surprised by the re-sign-in | Confusion, abandonment | Brief notice on landing page; first-sign-in welcome message references continuity ("your progress starts fresh — here's why"). |
| `autoforge/` directory accidentally committed if not removed before Step 1 | Repo contamination | Step 7 includes its removal; double-check via `.gitignore` before any commit. |

## 8. Decisions Made

Captured for the implementation phase so they don't get re-litigated:

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Migration depth | C — full migration | Highest-leverage; eliminates two-source-of-truth permanently. |
| User data fate | Fresh start | Pre-launch / small alpha; lossless migration not worth the complexity. |
| Admin auth | Custom claims, client-side writes | Few admins; Firestore rules + custom claim is a clean and well-scaled gate without Cloud Functions. |
| iOS stability scope | B — targeted refactor | Removes the actual root cause (per-tab refetches + SampleData fallback) without overengineering. |
| iOS content state location | Dedicated `ContentFeature` reducer | `AppFeature` must not become a god router; `ContentFeature` is independently testable, widget-reusable, and where future real-time listeners belong. |
| iOS cache location | `CachedContentClient` wrapper | Cache rule is bug-prone; isolating it in a thin tested layer is correct. Keeps `FirestoreContentService` a thin SDK adapter. |
| Step 3 risk mitigation | Env-flag-gated atomic cutover | Rollback via env flag, not redeploy; dead-code path removed after 7 stable days. |
| Web user-data hook ergonomics | Mirror iOS `FirebaseUserService` shape exactly | Cross-platform consistency; iOS has the canonical implementation already. |

## 9. Success Criteria

The milestone is complete when:

1. `git grep "@neondatabase/serverless"` returns nothing in `src/`.
2. `git grep "Better Auth\|@better-auth"` returns nothing.
3. `find RIZQ-iOS \( -name "Neon*.swift" -o -name "FirebaseNeonService.swift" -o -name "APIClient.swift" \)` returns nothing.
4. The Playwright suite (auth + practice + journeys + admin-duas + rules) passes against the Firebase emulator.
5. `xcodebuild` succeeds for the iOS target with `BUILD SUCCEEDED`.
6. Manual QA on iOS: cold-launch the app with airplane mode on; Adkhar/Journeys/Library show cached content (after at least one prior session), never `SampleData`.
7. Manual QA on web: an admin can sign in, create a new dua, and see it appear on the user-facing Library page within seconds — without any seed-script run.
8. The `SettingsPage` reset button works and clears the user's Firestore activity + progress data.
9. `firebase-debug.log` is gitignored; `autoforge/` is no longer in the repo.

## 10. Next Steps

1. User reviews this spec.
2. On approval, hand off to `superpowers:writing-plans` skill to produce the implementation plan with concrete steps, file diffs, and ordering.
3. Implementation plan execution lives in a separate session per superpowers conventions.
