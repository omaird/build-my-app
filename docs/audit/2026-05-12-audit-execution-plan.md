# Audit Execution Plan — RIZQ App

**Date:** 2026-05-12
**Owner:** Omair Dawood
**Status:** Drafted — **execution BLOCKED** until Milestone 1 fully merges to `main`.
**Source:** Three parallel deep-dive agents (web / iOS / repo-hygiene), synthesized + re-graded against domain knowledge and M1 boundary. Original audit findings live in the session transcript that produced this plan.

---

## 1. Strategy

| Decision | Choice | Trade-off accepted |
|----------|--------|--------------------|
| Tracking | Plan doc only (this file). No GitHub issues. | No public dashboard; loop has a single source of truth. |
| PR strategy | Single mega-PR off `main`, all 30 commits stacked. | Brutal to review; mitigated by per-commit verification gates and clean commit messages. |
| Branch base | `main`, **after** Milestone 1 fully merges. | Loses parallel-with-M1 momentum; gains zero merge-conflict risk. |
| Branch name | `audit/full-sweep` | — |
| Execution model | Parallel batches (default) + Ralph loop (overnight/unattended) | Choose per session. |

**Why this works:** the 30 items are mostly atomic, file-scoped commits. With `npx tsc --noEmit` + `npm run lint` + `npm run build` passing per commit, the mega-PR's review burden drops to "is each commit message accurate and is the diff sane" — which is fast on commits that all pass CI.

---

## 2. Execution Gates — DO NOT START UNTIL

All three must be true before the first batch dispatches:

- [ ] **G1.** Milestone 1 is fully merged. Verify: `git log main --oneline | head -5` shows the M1 merge commit; `git branch --merged main` includes `m1-foundation`.
- [ ] **G2.** `main` is green: `npx tsc --noEmit`, `npm run lint`, `npm run build`, `npm run test:rules`, and `npx playwright test` all pass on a clean clone of `main`.
- [ ] **G3.** GitHub Actions CI exists and is passing on `main` (item #03 below — if it's not in M1, it becomes the *first* commit of this audit instead of being gated by itself).

---

## 3. Status Legend

- `[ ]` — todo (not yet picked up)
- `[~]` — in-progress (filled in with agent + branch + start time)
- `[!]` — blocked (filled in with blocker)
- `[x]` — done (filled in with commit SHA)
- `[-]` — skipped (filled in with reason)

When an agent picks up an item, it **edits this file** to flip `[ ]` → `[~]` *before* starting work. On completion, it flips `[~]` → `[x]` and writes the commit SHA. This is how the Ralph loop and parallel batches avoid stomping on each other.

---

## 4. How to Run

### 4a. Parallel batch dispatch (default, fast)

The orchestrator (main agent) groups items with **non-overlapping file sets** and dispatches N agents in one message:

```
For each batch:
1. Read this file, find next N items where status=[ ] and files don't overlap.
2. Edit file: mark each as [~] with agent ID + branch + timestamp.
3. Send N parallel Agent() calls, each with one item's content from §6 below.
4. Each agent: implement, verify, commit, edit this file to mark [x] with SHA.
5. After all return, run aggregate verification (§5) and dispatch next batch.
```

Realistic throughput: 4–6 items per batch, 5–7 batches to drain.

### 4b. Ralph loop (overnight, unattended)

Invoke the `loop` skill with:

> `/loop` — Read `docs/audit/2026-05-12-audit-execution-plan.md`. Find the FIRST item in §6 where status is `[ ]`. Mark it `[~]` with your agent ID + branch + ISO timestamp. Implement per the item's spec. Run the verification command. If it passes, commit with the item's commit-message template, then mark the item `[x] <sha>`. If verification fails, mark `[!]` with the error summary and stop. If no `[ ]` items remain, stop. Pick a delay that gets you cache-warm next iteration.

### 4c. Manual pickup

A human (or you) opens this file, picks any `[ ]` item, follows the spec in §6.

### Pre-flight per agent (mandatory)

Each agent must:

1. `git fetch origin && git checkout audit/full-sweep && git pull --ff-only` (or create the branch from `main` if first item).
2. Edit this file: flip the item's `[ ]` to `[~] agent=<id> branch=audit/full-sweep started=<ISO ts>`.
3. Implement.
4. Run the item's **Verify** command.
5. Commit with message: `audit(#NN): <title>` plus a one-line summary of the change.
6. Edit this file: flip `[~]` to `[x] <commit-sha>`.
7. Push the commit (or leave for the orchestrator to push at batch end).

### Branch naming

Single branch: `audit/full-sweep`. All commits land here. Mega-PR opens at the end.

If a single item *needs* its own branch (e.g., #04 strictNullChecks fans out across many files), the agent may use `audit/full-sweep-NN-<slug>` as a feature branch, then squash-merge into `audit/full-sweep`.

---

## 5. Aggregate Verification (run between batches)

```bash
npx tsc --noEmit
npm run lint
npm run build
npm run test:rules
npx playwright test
cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Any failure → halt, do not start next batch, mark the failing item as `[!]`.

---

## 6. Items

> **Numbering:** items #01–#30 match the synthesis order in the audit findings session (P1 first, then P2, then P3).
> **`conflicts-m1`** says whether the item touches a file M1 will rewrite. Since execution is gated on M1 completion, this is informational only — useful if we ever decide to fast-path some items into M1 itself.

---

### #01 — Fix AdminRoute render-and-navigate React anti-pattern

- **sev:** P1 | **type:** commit | **status:** `[ ]`
- **files:** `src/components/AdminRoute.tsx` (lines 32–48)
- **dod:** Non-admin visiting `/admin/*` sees ONE outcome: either the Access Denied page OR a redirect to `/`, never both. No `<Navigate>` rendered inside an active JSX branch.
- **verify:** Add a Playwright test that signs in as a non-admin (test fixture sets `user_profiles/{uid}.isAdmin = false`), visits `/admin`, asserts URL is either `/admin` (denied page) or `/` (redirect) — but not flickering between them. Existing test: `e2e/admin-journeys.spec.ts` covers admin happy path; this adds the negative case.
- **hint:** Most likely fix: keep the Access Denied UI, **remove** the `<Navigate to="/" replace />` on line 45. The denied page already has a contact-admin message; users can navigate away themselves. If product intent is auto-redirect, replace the whole `if (!isAdmin)` block with `return <Navigate to="/" replace />` and drop the JSX.
- **commit-msg:** `audit(#01): remove render-phase Navigate in AdminRoute non-admin branch`
- **conflicts-m1:** no

### #02 — Align Vite + Firestore-emulator + Playwright ports

- **sev:** P1 | **type:** commit | **status:** `[ ]`
- **files:** `vite.config.ts`, `firebase.json`, `playwright.config.ts`
- **dod:** Running `npm run dev` + `firebase emulators:start` + `npx playwright test` simultaneously works with no manual `--port` flags. Documented in `README.md` (item #20 picks up the README sweep).
- **verify:** `npm run dev` + `firebase emulators:start --only firestore,auth` + `npx playwright test` all run concurrently in three terminals, all green.
- **hint:** Suggested: Vite → 5174, Firestore emulator stays at 8080, Playwright base URL → `http://localhost:5174`. Update all three configs in one commit so the change is atomic.
- **commit-msg:** `audit(#02): align dev/emulator/playwright ports to 5174/8080/5174`
- **conflicts-m1:** no

### #03 — Set up GitHub Actions CI

- **sev:** P1 | **type:** PR-sized commit | **status:** `[ ]`
- **files:** `.github/workflows/ci.yml` (new)
- **dod:** On every push to a PR branch and on push to `main`: tsc, eslint, vitest rules tests (emulator), Playwright (emulator), iOS xcodebuild all run. Required-status-check on `main` branch protection mentions `ci` job.
- **verify:** Open a throwaway PR; CI runs end-to-end; failing job correctly blocks merge.
- **hint:** Use `firebase-tools` action or `firebase emulators:exec` wrapped around `playwright test`. iOS step uses `macos-latest` runner. Cache `~/.npm` and `~/Library/Developer/Xcode/DerivedData`. Java 21 is required for emulator — note in memory.
- **commit-msg:** `audit(#03): add GitHub Actions CI workflow (lint, type, rules, e2e, ios)`
- **conflicts-m1:** no — but note: if M1 hasn't added CI by completion, this should become *the first* commit of the audit since later items rely on it.

### #04 — Enable TypeScript strict mode (start with strictNullChecks)

- **sev:** P1 | **type:** PR-scope commit | **status:** `[ ]`
- **files:** `tsconfig.app.json`, `tsconfig.json`, ripple across `src/**/*.{ts,tsx}` as needed
- **dod:** `"strictNullChecks": true` enabled in `tsconfig.app.json`; `npx tsc --noEmit` clean. (Defer full `"strict": true` to a follow-up; bite off null-safety first.)
- **verify:** `npx tsc --noEmit` exits 0; lint clean; `npm run build` clean.
- **hint:** Expect 30–80 errors initially. Common patterns to fix: nullable optional chaining (`x?.y` instead of `x.y`), `useState<T | null>(null)` typing, guard `||`/`??` for nullable env vars in `src/lib/firebase.ts`. Resist adding `!` non-null-assertion casts — they recreate the problem. Prefer explicit `if (!x) return` guards.
- **commit-msg:** `audit(#04): enable strictNullChecks and fix null-safety errors`
- **conflicts-m1:** moderate — M1 Step 3 rewrites the data hooks. Doing this AFTER M1 means we strict-check the new Firestore code, which is the right order.

### #05 — Re-enable `@typescript-eslint/no-unused-vars`

- **sev:** P1 | **type:** commit | **status:** `[ ]`
- **files:** `eslint.config.js` (line 23), incidental fixes across `src/**`
- **dod:** Remove the `"@typescript-eslint/no-unused-vars": "off"` line. `npm run lint` clean. Intentional unused params use `_` prefix.
- **verify:** `npm run lint` exits 0.
- **hint:** Fix any flagged unused imports/vars by deletion. For function parameters that are intentionally unused (e.g., `(req, res, next)` middleware shape), rename to `_req`, `_res`, `_next`. Don't suppress with `// eslint-disable-next-line`.
- **commit-msg:** `audit(#05): re-enable no-unused-vars and clean up dead identifiers`
- **conflicts-m1:** no

### #06 — Move iOS service clients into Dependencies/

- **sev:** P1 | **type:** PR-scope commit | **status:** `[ ]`
- **files:**
  - move: `RIZQ-iOS/RIZQ/Features/Adkhar/AdkharFeature.swift:492-767` → new `RIZQ-iOS/RIZQ/Dependencies/AdkharServiceClient.swift`
  - move: `RIZQ-iOS/RIZQ/Features/Journeys/JourneysFeature.swift:258-360` → new `RIZQ-iOS/RIZQ/Dependencies/JourneyServiceClient.swift`
- **dod:** Service-client structs + liveValue definitions live in `Dependencies/`. Feature files only contain reducer + state + actions. `project.yml` updated to include the new files. Build passes.
- **verify:** `xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build` succeeds. All existing TestStore tests still pass.
- **hint:** Pattern reference: `RIZQ-iOS/RIZQ/Dependencies/FirestoreContentClient.swift`. Use manual struct registration (per CLAUDE.md: no `@DependencyClient` macro).
- **commit-msg:** `audit(#06): relocate AdkharServiceClient and JourneyServiceClient to Dependencies/`
- **conflicts-m1:** **YES** — M1 Step 5 refactors AdkharFeature and JourneysFeature. Doing this AFTER M1 means the file sections have shifted; agent must re-locate the structs by name, not line number.

### #07 — Fix iOS widget hardcoded XP/level + Firebase singleton bypass

- **sev:** P1 | **type:** commit | **status:** `[ ]`
- **files:** `RIZQ-iOS/RIZQ/Features/Adkhar/AdkharFeature.swift` (around lines 308–315 and 699)
- **dod:** (a) `WidgetDataManager.shared.updateDailyProgress(...)` call uses real `currentXp` / `xpToNextLevel` / `level` captured from `state` before entering the `.run` block, not hardcoded `0/100/1`. (b) `currentUserId` closure in `AdkharServiceClient.liveValue` reads from the injected `authClient`, not `Auth.auth().currentUser?.uid` directly.
- **verify:** Build passes. Add a TestStore test that asserts the widget update closure receives the correct XP from state. Manual: install on simulator, complete a habit, confirm widget shows correct level after refresh.
- **hint:** For (a), capture values before `.run`: `let xp = state.profile?.totalXp ?? 0; let level = state.profile?.level ?? 1; let nextXp = state.profile?.xpToNextLevel ?? 100`. For (b), the `authClient` dependency already exposes the user — surface `currentUserId` via that client.
- **commit-msg:** `audit(#07): use real XP/level in widget update and route auth through authClient`
- **conflicts-m1:** partial — M1 may shift line numbers in AdkharFeature but the structural fix is independent.

### #08 — DRY `AdkharFeature.onAppear` and `refreshData`

- **sev:** P1 | **type:** commit | **status:** `[ ]`
- **files:** `RIZQ-iOS/RIZQ/Features/Adkhar/AdkharFeature.swift` (lines 173–258)
- **dod:** One private helper (e.g., `loadAllData(send:)`) replaces both duplicate blocks. Both case handlers call the helper. No behavior change (logging line currently missing from `refreshData` is restored).
- **verify:** Build passes; existing `AdkharFeatureTests` (or new ones) pass; manual app open + pull-to-refresh both show streak + habits correctly.
- **hint:** Helper signature: `private func loadAllData(send: Send<Action>, userId: String) async throws { … }`. Both call sites await this with the user's ID.
- **commit-msg:** `audit(#08): extract shared loadAllData helper from Adkhar onAppear/refresh`
- **conflicts-m1:** **YES** — M1 Step 5 refactors AdkharFeature. Doing this after M1 may make this commit unnecessary if M1 happens to DRY the same blocks; verify before starting.

### #09 — Remove HomeFeature's duplicate habit fetch

- **sev:** P1 | **type:** PR-scope commit | **status:** `[ ]`
- **files:** `RIZQ-iOS/RIZQ/Features/Home/HomeFeature.swift` (lines 250–256, 286–292), `RIZQ-iOS/RIZQ/App/AppFeature.swift` (to pipe count up), `RIZQ-iOS/RIZQ/Features/Adkhar/AdkharFeature.swift` (to expose count)
- **dod:** `HomeFeature.onAppear` / `refreshData` does NOT call `adkharService.fetchAllHabits()`. Today's habit count flows from `AdkharFeature.State.todaysHabits.count` via shared state through `AppFeature`. Home displays the same count without doing its own Firestore fetch.
- **verify:** Cold-launch app, observe Firestore reads in console — should see ONE habits fetch, not two. TestStore test asserts HomeFeature reads count from parent state.
- **hint:** Use TCA's `@Shared` for `todaysHabitsCount` if appropriate, or pipe through `AppFeature.State`. M1's `ContentFeature` already establishes the "fetch once, share via scope" pattern — this extends that pattern from content to user-data counts.
- **commit-msg:** `audit(#09): remove duplicate habit fetch in HomeFeature; share count via parent state`
- **conflicts-m1:** **YES** — M1 Step 5 reshapes content fetches in HomeFeature/AdkharFeature. After M1 lands, this becomes "extend the ContentFeature pattern to user-data".

### #10 — Fix iOS LibraryFeature hardcoded category IDs in fallback

- **sev:** P1 | **type:** commit | **status:** `[ ]`
- **files:** `RIZQ-iOS/RIZQ/Features/Library/LibraryFeature.swift` (lines 172–180)
- **dod:** Failure-path filter does NOT compare `dua.categoryId == 3` with hardcoded integers. Either filters by slug from the cached `categories` list, or returns `state.allDuas` (let the user filter manually).
- **verify:** Build passes; manual: force a Firestore error on category filter, confirm the fallback shows correct duas.
- **hint:** Simplest fix: in the `.failure` case, just `return .send(.duasReplaced(state.allDuas))` — no filtering needed since the user's chosen category is already preserved in state.
- **commit-msg:** `audit(#10): drop hardcoded category IDs in LibraryFeature failure fallback`
- **conflicts-m1:** **YES** — M1 Step 5 removes `SampleData` fallbacks generally; this block may evaporate. Verify before starting; if M1 already removed the failure-path code, mark this `[-] skipped — resolved by M1`.

### #11 — Raise `SWIFT_STRICT_CONCURRENCY` from `minimal` to `targeted`

- **sev:** P1 | **type:** issue → commit | **status:** `[ ]`
- **files:** `RIZQ-iOS/project.yml` (line 23), `RIZQ-iOS/RIZQKit/Services/Firebase/FirestoreContentService.swift` (line 19), ripple across affected files
- **dod:** `SWIFT_STRICT_CONCURRENCY: targeted` in `project.yml`. `@unchecked Sendable` on `FirestoreContentService` either removed (preferred) or replaced with proper `Sendable` conformance + actor isolation. Build passes with zero new warnings.
- **verify:** `xcodebuild` with `SWIFT_STRICT_CONCURRENCY=targeted` succeeds; no new warnings introduced.
- **hint:** Expect Sendable warnings on capture closures. Most fix with `@MainActor` annotation or marking value types `Sendable` (since most models are already `struct` + `Codable`). The Firestore service likely needs `actor` conversion or `@MainActor` rather than `@unchecked`.
- **commit-msg:** `audit(#11): raise strict concurrency to targeted and remove @unchecked Sendable`
- **conflicts-m1:** low — M1 changes content code but not Sendable boundaries.

### #12 — Expand iOS TCA TestStore coverage

- **sev:** P1 | **type:** PR-scope commit | **status:** `[ ]`
- **files:** new tests under `RIZQ-iOS/RIZQTests/` — `AdkharFeatureTests.swift`, `JourneysFeatureTests.swift`, `HomeFeatureTests.swift`, `PracticeFeatureTests.swift`
- **dod:** Each feature has at minimum: success-path test, failure-path test, timeout-fallback test (per CLAUDE.md mandatory pattern), and one binding/action test. Coverage of timeout fallback for at least Adkhar and Journeys.
- **verify:** `bundle exec fastlane test` passes; new tests appear in test report; `xcodebuild test` shows the new files included.
- **hint:** Pattern reference: existing `SettingsFeatureTests.swift`. Use `TestStore` with `withDependencies { $0.firestoreUserClient = .mock; $0.continuousClock = ImmediateClock() }`. For timeout paths, configure the mock to await indefinitely while the clock advances past the timeout — the fallback case fires.
- **commit-msg:** `audit(#12): add TestStore coverage for Adkhar/Journeys/Home/Practice features`
- **conflicts-m1:** partial — M1 Step 5 will add `ContentFeatureTests`. This adds coverage for the *other* features. No conflict.

### #13 — Remove dead web hooks + admin dashboard duplicate

- **sev:** P1 | **type:** commit | **status:** `[ ]`
- **files:** delete `src/hooks/useUserData.ts`, delete `src/data/duaLibrary.ts`, edit `src/hooks/useDuas.ts` (remove unused `useDua`/`useDuasByCategory` exports if confirmed unused), edit `src/pages/admin/AdminDashboardPage.tsx` (replace local stats with existing admin hooks)
- **dod:** Each file/export is confirmed unused via grep before deletion. `tsc --noEmit` clean. Build clean. No behavior change in app.
- **verify:** `grep -r "useUserData\|useUserProfile\|useDailyActivity\|useUserProgress\|duaLibrary" src/` returns nothing after deletion. App still loads and the admin dashboard still shows correct stats.
- **hint:** Verification grep BEFORE deleting: any false positives mean the hook is still in use and needs migration first. For admin dashboard duplicate: if it uses `useDuas`/`useJourneys`/`useAdminUsers` directly with local aggregation, replace with the existing admin hooks that already aggregate.
- **commit-msg:** `audit(#13): delete dead web hooks (useUserData, duaLibrary) and unify admin dashboard stats`
- **conflicts-m1:** **YES** — M1 Step 3 rewrites the admin/data hooks. After M1 lands, re-verify deletions are still safe; M1 may have already deleted some of these.

### #14 — Add `"foundation"` to `DuaCategory` type union

- **sev:** P1 | **type:** commit | **status:** `[ ]`
- **files:** `src/types/dua.ts` (line 27)
- **dod:** `DuaCategory = "morning" | "evening" | "rizq" | "gratitude" | "foundation"`. Any switch statements on category get a `foundation` branch (or default fallthrough).
- **verify:** `npx tsc --noEmit` clean; any UI that color-codes by category renders foundation appropriately (probably needs a `badge-foundation` Tailwind class — add it).
- **hint:** Grep for all consumers: `grep -rn "DuaCategory\|'rizq'\|'gratitude'" src/`. Any `switch(category)` with no `default` and missing `foundation` is a type-narrowing bug to fix.
- **commit-msg:** `audit(#14): add foundation slug to DuaCategory type union`
- **conflicts-m1:** no

### #15 — Web a11y sweep

- **sev:** P1 | **type:** PR-scope commit | **status:** `[ ]`
- **files:**
  - `src/components/WelcomeModal.tsx` (focus trap + aria-*)
  - `src/components/BottomNav.tsx` (aria-current on Links)
  - `src/pages/SignUpPage.tsx` (`navigate()` outside try/catch)
- **dod:** WelcomeModal traps focus per WCAG 2.1 (use Radix Dialog primitive if not already, or manual focus management). BottomNav `<Link>` carries `aria-current={isActive ? "page" : undefined}`. SignUpPage error path doesn't navigate; shows toast and stays on form.
- **verify:** axe-core run via Playwright shows no critical issues on those three components. Manual keyboard test: Tab into modal, can't escape it; Tab through bottom nav announces current page.
- **hint:** Welcome modal probably *should* be using `Dialog` from `@radix-ui/react-dialog` since it's already a dep — that gets focus trap for free. For SignUpPage, wrap the success-only logic in the resolve branch of the promise chain.
- **commit-msg:** `audit(#15): a11y pass (WelcomeModal focus trap, BottomNav aria-current, SignUp error path)`
- **conflicts-m1:** no

### #16 — Surface query errors in user-facing UI

- **sev:** P1 | **type:** commit | **status:** `[ ]`
- **files:** `src/pages/LibraryPage.tsx`, possibly `src/pages/JourneysPage.tsx`, `src/pages/DailyAdkharPage.tsx`
- **dod:** Each page renders an error state when its primary `useQuery` fails (toast + retry button + visible message). No silent empty/loading state on failure.
- **verify:** Block Firestore in DevTools → page shows error UI instead of stuck loading or empty list. Click Retry → query refires.
- **hint:** Pattern: `if (query.isError) return <ErrorState onRetry={query.refetch} />`. Create one shared `ErrorState` component in `src/components/` if not already present.
- **commit-msg:** `audit(#16): render error states for failed content queries on Library/Journeys/Adkhar pages`
- **conflicts-m1:** **YES** — M1 Step 3 rewrites `useDuas`/`useJourneys`. After M1, re-verify the error-state hook the new queries expose; should still be `query.isError` if React Query is preserved.

### #17 — Parameterize `firebase-service-account.json` path in `.mcp.json`

- **sev:** P2 | **type:** commit | **status:** `[ ]`
- **files:** `.mcp.json` (line 18)
- **dod:** Path is `${FIREBASE_SERVICE_ACCOUNT_KEY_PATH}` (or similar env-var ref). `CONTRIBUTING.md` (item #27) documents the env var.
- **verify:** Clone fresh, set env var, MCP Firebase server starts successfully.
- **hint:** Check the MCP config schema for env var interpolation syntax — varies by client. If interpolation isn't supported in `.mcp.json`, document the manual swap in CONTRIBUTING and leave the path with a `# REPLACE LOCALLY` comment.
- **commit-msg:** `audit(#17): parameterize firebase service account path in .mcp.json`
- **conflicts-m1:** no

### #18 — Add `vitest.config.ts` so `npm run test:rules` works

- **sev:** P2 | **type:** commit | **status:** `[ ]`
- **files:** `vitest.config.ts` (new)
- **dod:** `npm run test:rules` (which runs `vitest run tests/rules` inside emulator-exec) actually discovers and runs the tests in `tests/rules/`. CI (item #03) wires it in.
- **verify:** `npm run test:rules` produces test output (not "no tests found"). Currently passing tests stay passing.
- **hint:** Minimal config: `export default { test: { include: ['tests/**/*.test.ts'], globals: true } }`.
- **commit-msg:** `audit(#18): add vitest config so rules tests actually run`
- **conflicts-m1:** low — M1 Step 1 added rules tests; this makes them runnable. If M1 already added a vitest config, mark `[-] skipped`.

### #19 — Remove `lovable-tagger` dependency

- **sev:** P2 | **type:** commit | **status:** `[ ]`
- **files:** `vite.config.ts` (import + plugin call), `package.json` (`devDependencies`)
- **dod:** No reference to `lovable-tagger` remains. `npm install && npm run build` clean. Bundle output unchanged (or smaller).
- **verify:** `grep -r lovable-tagger .` returns nothing in tracked files. Build succeeds.
- **commit-msg:** `audit(#19): remove lovable-tagger dev dependency`
- **conflicts-m1:** no

### #20 — Update README + .env.example for Firebase Auth reality

- **sev:** P2 | **type:** commit | **status:** `[ ]`
- **files:** `README.md`, `.env.example`
- **dod:** README references Firebase Auth (not Better Auth), correct dev port (matches item #02), correct env vars. `.env.example` lists only `VITE_FIREBASE_*` vars; Neon vars removed entirely or under a "deprecated" comment.
- **verify:** Manual read; visually confirm no stale Better Auth / Neon Auth references; clone fresh, follow README, app runs.
- **commit-msg:** `audit(#20): update README and .env.example to reflect Firebase Auth`
- **conflicts-m1:** no — but verify M1 didn't already do this in Step 4.

### #21 — iOS widget design-token unification + streak placeholder

- **sev:** P2 | **type:** commit | **status:** `[ ]`
- **files:** `RIZQ-iOS/RIZQWidget/RIZQWidget.swift` (lines 7–43, 343–350)
- **dod:** (a) `WidgetColors` struct removed; widget imports `RIZQKit` colors (`Color.sandWarm`, `Color.streakGlow`, etc.). (b) `StreakProvider.createEntry()` returns `.placeholder` when user has zero streak + nil lastUpdated, matching `DailyProgressProvider`'s pattern at line 97.
- **verify:** Widget build passes; install on simulator with fresh user, widget shows empty state (not "12 day streak" / "Best: 45" fake values).
- **commit-msg:** `audit(#21): unify widget colors with RIZQKit and fix streak placeholder`
- **conflicts-m1:** no

### #22 — Pin `Satin` package to a tag instead of `main`

- **sev:** P2 | **type:** commit | **status:** `[ ]`
- **files:** `RIZQ-iOS/project.yml` (lines 65–66)
- **dod:** `Satin` references a specific tag or `from:` version range, not `branch: main`.
- **verify:** `xcodegen generate && xcodebuild build` succeeds.
- **hint:** Check the Satin repo for the latest stable tag; pin to that.
- **commit-msg:** `audit(#22): pin Satin package to stable tag`
- **conflicts-m1:** no

### #23 — SettingsFeature: replace UserDefaults.standard with @Shared appStorage

- **sev:** P2 | **type:** commit | **status:** `[ ]`
- **files:** `RIZQ-iOS/RIZQ/Features/Settings/SettingsFeature.swift` (lines 21–22 and downstream)
- **dod:** `isDarkMode` uses `@Shared(.appStorage("rizq_dark_mode"))` (per CLAUDE.md BindingReducer pattern); test can override without mutating real `UserDefaults`.
- **verify:** `xcodebuild test` for SettingsFeatureTests passes; new TestStore test confirms override works.
- **commit-msg:** `audit(#23): migrate SettingsFeature dark-mode flag to @Shared appStorage`
- **conflicts-m1:** no

### #24 — Snapshot tests need dependency overrides

- **sev:** P2 | **type:** commit | **status:** `[ ]`
- **files:** `RIZQ-iOS/RIZQSnapshotTests/RIZQSnapshotTests.swift` (lines 16–31, 34–44)
- **dod:** Every `Store` instantiation in snapshot tests is wrapped in `withDependencies { $0.firestoreUserClient = .testValue; $0.authClient = .testValue }` (or `.unimplemented` if no calls expected).
- **verify:** Snapshot tests run on a machine with no Firebase credentials; no Firestore network calls are attempted (verify by setting Firestore host to a deliberately broken URL in tests and confirming snapshots still render).
- **commit-msg:** `audit(#24): use test dependencies in snapshot test stores to prevent live Firestore calls`
- **conflicts-m1:** no

### #25 — Move top-level docs to docs/

- **sev:** P2 | **type:** commit | **status:** `[ ]`
- **files:** `mv PRD.md docs/product/`, `mv "design concepts.md" docs/product/`, `mv "dua library.md" docs/product/`, `mv research.md docs/product/`
- **dod:** Repo root contains only `README.md` and `CLAUDE.md` as top-level docs. Other docs live under `docs/product/`. Update any cross-references (grep first).
- **verify:** `ls *.md` at repo root shows only `README.md` and `CLAUDE.md`; CLAUDE.md and README references updated.
- **commit-msg:** `audit(#25): consolidate product docs under docs/product/`
- **conflicts-m1:** no

### #26 — Add husky + lint-staged pre-commit hook

- **sev:** P2 | **type:** commit | **status:** `[ ]`
- **files:** `package.json` (`devDependencies`, `prepare` script, `lint-staged` config), `.husky/pre-commit` (new)
- **dod:** On `git commit`, lint-staged runs `eslint --fix` and `tsc --noEmit` (project-wide) on staged files. Commit fails if either does. No `--no-verify` workaround in any committed git hook.
- **verify:** Stage a file with a lint error → commit fails → fix → commit succeeds.
- **hint:** lightweight alternative: `simple-git-hooks` instead of husky. Either works. Match whatever the team prefers.
- **commit-msg:** `audit(#26): add husky + lint-staged pre-commit hook`
- **conflicts-m1:** no

### #27 — Add CONTRIBUTING.md

- **sev:** P2 | **type:** commit | **status:** `[ ]`
- **files:** `CONTRIBUTING.md` (new)
- **dod:** Doc covers: local setup (emulator + env vars + the `.mcp.json` env var from #17), how to run tests (rules + e2e + iOS), the audit-plan and M1-plan workflows, branch naming, commit-message conventions, the audit-plan + ralph loop pattern.
- **verify:** Manual read; doc is internally consistent and matches actual setup.
- **commit-msg:** `audit(#27): add CONTRIBUTING.md with setup and workflow docs`
- **conflicts-m1:** no

### #28 — Rename package.json from "vite_react_shadcn_ts" to "rizq-app"

- **sev:** P3 | **type:** commit | **status:** `[ ]`
- **files:** `package.json` (line 2), `package-lock.json` (regenerated)
- **dod:** Name is `"rizq-app"`. `npm install` regenerates lockfile cleanly.
- **verify:** `cat package.json | head -3` shows new name; `npm install` runs clean.
- **commit-msg:** `audit(#28): rename package to rizq-app`
- **conflicts-m1:** no

### #29 — Untrack `test-results/.last-run.json`

- **sev:** P3 | **type:** commit | **status:** `[ ]`
- **files:** `test-results/.last-run.json` (untrack)
- **dod:** `git ls-files | grep test-results` returns nothing. `.gitignore` already covers it; no rule change needed.
- **verify:** `git rm --cached test-results/.last-run.json && git status` shows it deleted from index; `.gitignore` still excludes it; future test runs don't show it as modified.
- **commit-msg:** `audit(#29): untrack test-results/.last-run.json`
- **conflicts-m1:** no

### #30 — Determine Rizqapp/ directory disposition

- **sev:** P3 | **type:** issue → commit (probably delete) | **status:** `[ ]`
- **files:** `Rizqapp/` (top-level, untracked)
- **dod:** Either deleted (if confirmed legacy) or documented in README + committed (if intentional). Repo root no longer has a mystery dir.
- **verify:** Inspect contents (`ls -la Rizqapp/`), determine intent, then delete or document.
- **hint:** Almost certainly an early Xcode scaffold abandoned when `RIZQ-iOS/` superseded it. Verify by checking if any tracked file references it; if not, delete.
- **commit-msg:** `audit(#30): remove abandoned Rizqapp/ scaffold` (or `audit(#30): document Rizqapp/ purpose in README`)
- **conflicts-m1:** no

---

## 7. Mega-PR template (for when all items land)

```markdown
# Audit Sweep — 30 items

This PR drains the audit plan committed in 2026-05-12 (see `docs/audit/2026-05-12-audit-execution-plan.md`).

## Categories
- Foundations (CI, ports, lint, types): #02, #03, #04, #05, #14, #18, #26
- React anti-patterns + UX: #01, #15, #16
- iOS architecture: #06, #07, #08, #09, #10, #11
- iOS tests: #12, #23, #24
- Dead code + cleanup: #13, #19, #25, #28, #29, #30
- Docs: #20, #27
- Cosmetic / config: #17, #21, #22

## Per-commit verification
Each commit passes: tsc --noEmit, eslint, build, test:rules, playwright, iOS xcodebuild.
Run `git log audit/full-sweep --oneline` to see the 30 commits.

## How to review
Recommended: review by commit, not by combined diff. `git show <sha>` per item. Commit messages reference plan item numbers.
```

---

## 8. Stop conditions

The plan is **done** when:

1. Every item in §6 is `[x]` or `[-]` (skipped with documented reason).
2. Mega-PR `audit/full-sweep` → `main` is merged.
3. This file is updated to `Status: Complete`.

The plan is **paused** if:

1. Any aggregate-verification step (§5) fails after a batch.
2. CI (#03) breaks on `main`.
3. Wave-B items that *did* conflict with M1 turn out to need re-planning post-M1.

---

## 9. Open questions for execution time

- Should #03 (CI) become the very first commit even though it's listed third? Pro: later items rely on it. Con: not strictly required for any single item, just makes verification stricter.
- For #04 (strictNullChecks), do we want to split per-feature (one commit per src/ subdirectory of fixes) to keep diff sane? Decide at start time.
- For #15 (a11y), do we run axe-core in CI as part of #03, or just locally? Decide at start time.

---

## 10. Change log

- 2026-05-12 — initial draft, 30 items, gated behind M1 completion.
