# Contributing to Razzaq

This guide gets a new contributor from a fresh clone to running tests and shipping their first PR.

## Local setup

### Prerequisites

- **Node.js 22+** (matches CI)
- **Xcode 16+** for iOS work (currently targeting iOS 17+)
- **Firebase CLI** (`npm install -g firebase-tools`) — required for emulator-backed tests
- **Java 21+** — Firestore emulator depends on it (Temurin recommended)
- **XcodeGen** (`brew install xcodegen`) for iOS — generates `RIZQ.xcodeproj` from `project.yml`

### Web app

```bash
git clone <repo>
cd "RIZQ App"
npm install
cp .env.example .env
# Fill in VITE_FIREBASE_* values from Firebase Console → Project Settings → Web app
npm run dev   # http://localhost:8081
```

### iOS app

```bash
cd RIZQ-iOS
xcodegen generate
open RIZQ.xcodeproj
```

The first build will resolve Swift Package dependencies (TCA, Firebase, Nuke). Drop your `GoogleService-Info.plist` into `RIZQ/Resources/` before running.

### MCP / Firebase admin tooling

The `.mcp.json` Firebase server reads a service-account JSON. Either:

- Drop your service account JSON at the repo root as `firebase-service-account.json` (default; already gitignored), **or**
- Set `SERVICE_ACCOUNT_KEY_PATH` in your shell environment to override the default

Get the JSON from Firebase Console → Project Settings → Service Accounts → Generate new private key.

## Running tests

| Command | What it runs |
|---|---|
| `npm run test:rules` | Firestore Security Rules tests via `vitest` + the Firestore emulator |
| `npm run test:e2e` | Playwright e2e against Vite + Firebase Auth + Firestore emulators |
| `npm run lint` | ESLint |
| `npm run build` | Production Vite build |
| `cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' -skipMacroValidation build` | iOS build |

The `-skipMacroValidation` flag is required for headless iOS builds — TCA macros need fingerprint approval otherwise.

GitHub Actions CI ([.github/workflows/ci.yml](.github/workflows/ci.yml)) runs the full battery on every PR. The iOS job is currently non-blocking due to an Xcode version mismatch on macos-latest; the web job is the gating check.

## Workflows

### Day-to-day feature work

1. Cut a branch from `main`: `git checkout -b feat/<short-description>`
2. Write code + tests; verify locally (tsc + lint + build for web, xcodebuild for iOS)
3. Open a PR with a description that explains *why* and a `Test plan` checklist
4. CI runs automatically; iterate until green
5. Merge with `gh pr merge --merge --delete-branch` (preserves history, cleans up branch)

### Working through the audit plan

The repo has a master audit list at [docs/audit/2026-05-12-audit-execution-plan.md](docs/audit/2026-05-12-audit-execution-plan.md). Each item has a fixed number; PRs are branched per item with `audit/<number>-<slug>` naming.

When you pick up an item:

1. Read the item's `dod` (definition of done) and `verify` steps in the audit plan
2. Cut a branch: `git checkout -b audit/<n>-<slug>`
3. Implement to the DoD; nothing more (audit items are intentionally scoped)
4. Use the suggested `commit-msg` prefix: `audit(#<n>): <subject>`
5. Open a PR titled to match; reference the audit doc in the body

If you find an audit item already satisfied by prior work (M1 sometimes already did the change), close the branch without a PR and mark the item as `[-] resolved by <commit>` in the audit doc.

### Branch naming

| Prefix | Use |
|---|---|
| `feat/<name>` | New user-facing functionality |
| `fix/<name>` | Bug fixes |
| `audit/<n>-<slug>` | Items from the master audit plan |
| `ci/<name>` | CI/CD infrastructure changes |
| `chore/<name>` | Tooling, deps, repo hygiene |

### Commit messages

Conventional-style prefix + scope + subject:

```
feat(adkhar): elevate Adkhar as raised FAB; swap Library/Journeys nav order
fix(admin): remove render-and-navigate anti-pattern from AdminRoute (audit #01)
chore(tooling): add iOS sim launcher + test-user util
```

Long-form body explains *why* (the code shows *what*).

### What to test before opening a PR

- Web changes: `npx tsc --noEmit && npm run lint && npm run build && npm run test:rules`
- E2E test changes: `npm run test:e2e` (the e2e step is non-blocking in CI but locally we run it)
- iOS changes: `xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' -skipMacroValidation build`
- Cross-cutting changes: include manual smoke checkboxes in the PR's Test plan

### Working with subagents (Claude Code)

Several slash commands automate parts of this workflow:

- `/audit-cycle` — picks the next ready audit item, opens a branch, and drives it to PR
- `/drain-plan` — runs through a stack of related audit items as a chain
- `/code-review` — review a branch against project conventions
- `/feature-dev` — guided feature development with architecture focus

When dispatching review/automation subagents, **always include an explicit "do not commit/push/merge" guard in the prompt** — these agents will execute plan-doc commands literally if not forbidden.

## Don't

- Don't commit secrets. The repo's `.gitignore` already excludes `.env`, `firebase-service-account.json`, and `*-service-account*.json`. Verify before staging.
- Don't pipe `xcodebuild` output through `tail` / `grep` without `set -o pipefail`. The pipe's exit code masks the real build status; CLAUDE.md's snippet has this pitfall.
- Don't modify files in `src/components/ui/`. Those are shadcn primitives; eslint has overrides for them.
- Don't commit `test-results/.last-run.json`. It's a Playwright artifact; should be gitignored (tracked separately as audit item #29).

## Where things live

| Topic | Path |
|---|---|
| Web entry / router | [src/App.tsx](src/App.tsx) |
| Web auth context | [src/contexts/AuthContext.tsx](src/contexts/AuthContext.tsx) |
| Web Firebase init | [src/lib/firebase.ts](src/lib/firebase.ts) |
| Firestore rules + tests | [firestore.rules](firestore.rules), [tests/rules/](tests/rules/) |
| iOS app entry | [RIZQ-iOS/RIZQ/App/RIZQApp.swift](RIZQ-iOS/RIZQ/App/RIZQApp.swift) |
| iOS root reducer | [RIZQ-iOS/RIZQ/App/AppFeature.swift](RIZQ-iOS/RIZQ/App/AppFeature.swift) |
| iOS dependencies (TCA) | [RIZQ-iOS/RIZQ/Dependencies/](RIZQ-iOS/RIZQ/Dependencies/) |
| Project conventions | [CLAUDE.md](CLAUDE.md), [RIZQ-iOS/CLAUDE.md](RIZQ-iOS/CLAUDE.md) |
| Audit plan | [docs/audit/2026-05-12-audit-execution-plan.md](docs/audit/2026-05-12-audit-execution-plan.md) |
| M1 foundation spec | [docs/superpowers/plans/2026-05-08-foundation-milestone.md](docs/superpowers/plans/2026-05-08-foundation-milestone.md) |
