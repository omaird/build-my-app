---
name: audit-cycle
description: "Run a full RIZQ audit cycle end-to-end: dispatch parallel audit subagents (web/iOS/repo), apply the domain-knowledge severity rubric to re-grade findings, filter out items already owned by an in-flight spec, cluster atomic findings into PR-sized themes, and write the result as a plan doc that the drain-plan skill can execute. Use when the user says 'run an audit', 'do a deep dive on the app', 'audit the codebase', 'find improvements', 'tech-debt sweep', 'quarterly review', or any phrasing meaning 'survey what's wrong and give me a prioritized list'. Args: optional --exclude-spec=<path>, --surfaces=<web,ios,repo>, --output=<path>, --max-items=<N>."
---

# Audit Cycle

You orchestrate the end-to-end audit pattern: parallel investigation → re-grading → spec-boundary filtering → clustering → plan-doc emission. The output is a single `docs/audit/<date>-audit-execution-plan.md` file that conforms to the `drain-plan` skill's expected format.

This is the front-end. The back-end is `drain-plan`. They are designed together.

## Argument parsing

```
/audit-cycle
/audit-cycle --exclude-spec=docs/superpowers/specs/2026-05-08-foundation-milestone-design.md
/audit-cycle --surfaces=web,repo
/audit-cycle --max-items=20
```

Parse:

- **--exclude-spec** — path to a spec/plan whose work-items should be filtered out of audit findings. Optional.
- **--surfaces** — comma-separated subset of `{web, ios, repo}`. Default: all three.
- **--output** — destination plan-doc path. Default: `docs/audit/<YYYY-MM-DD>-audit-execution-plan.md`.
- **--max-items** — soft cap on the number of items in the final plan doc. Default: 30. Used during clustering — bundles aggressive when above the cap.

## Step 0 — Repo orientation

Quick sanity reads before dispatching agents:

```bash
git log --oneline -5
git branch --show-current
git status --porcelain
ls -la                                     # for top-level layout
find src -type f -name "*.tsx" | wc -l     # web file count
find RIZQ-iOS -type f -name "*.swift" | wc -l   # ios file count
```

Note any obvious red flags (e.g., tracked-but-shouldnt-be files, mysterious top-level directories). These get passed to the agents as hints.

## Step 1 — Dispatch parallel audit subagents

Use **one assistant message with three parallel `Agent` calls** — one per surface area in `--surfaces`. Each agent gets:

1. A scoped surface area (don't overlap).
2. The explicit list of what NOT to flag (the contents of `--exclude-spec` if set).
3. A standardized findings format.
4. The domain severity rubric below.

### Agent prompts — templates

Each surface gets the matching prompt below. Use the `feature-dev:code-reviewer` subagent type for all three.

#### Web prompt

```
You are auditing the web app at `<repo>/src/` for quality issues.

EXCLUDED SCOPE — read `<exclude_spec_path>` and skip anything that spec already owns.
(If no exclude-spec, ignore this paragraph.)

LOOK FOR:
1. Dead code (orphaned files, unused exports, legacy fallbacks)
2. Type-safety holes (any, unsafe casts, missing return types)
3. Component anti-patterns (oversized files, prop drilling, business logic in views)
4. State management leakage (multiple sources of truth, stale cache invalidations)
5. A11y gaps (unlabeled buttons, missing focus traps, color-only state signals)
6. Bundle/perf (eager-loaded heavy libs, missing memo where it matters)
7. CLAUDE.md convention drift
8. Error handling gaps (silent catches, no UI for query errors)
9. Console.log/debug leftovers
10. Routes / unused pages

OUTPUT — punch list. Each item:
- Title (imperative, <80 chars)
- Severity: P0 (security/correctness) | P1 (real quality) | P2 (nice-to-have) | P3 (cosmetic)
- Type: issue (needs design) | commit (mechanical fix) | PR (multi-file)
- Files: paths with line numbers
- Why it matters: one sentence
- Suggested action: one-to-two sentences

SEVERITY RUBRIC (apply strictly):
- P0 = exploitable security flaw, data loss risk, broken-in-prod-right-now bug
- P1 = real correctness/UX bug; or a missing guardrail that lets bugs through; or significant convention drift
- P2 = mechanical cleanup, dead code, doc drift
- P3 = cosmetic only

DO NOT flag as P0:
- Firebase iOS API keys committed (intentionally public)
- Firebase Web project IDs in env.example (also public)
- Anything fixable by `git rm`

Aim for 15–25 high-signal items. Cite file:line for every claim. <1500 words.
```

#### iOS prompt

Same shape, replace surface area + look-for list. See `audit-cycle.md` § "iOS look-for list" for the canonical list. Key entries: TCA anti-patterns, service-layer issues, dead code in `Rizqapp/`, weak model invariants, test coverage gaps, logging discipline, build/CI/project-gen, widget integration, design-system divergence from web tailwind, concurrency/threading.

#### Repo prompt

Same shape, surface area is hygiene/security/tests/CI/docs. Key entries: secrets & sensitive files (verify gitignored AND not in git log), repo size bloat, dual lockfiles, tracked build output, doc drift, CI presence, test coverage by feature, `.gitignore` completeness, build config (port mismatches!), plugin/claude config sprawl.

## Step 2 — Collect and verify findings

When all three agents return, you have ~50–60 raw findings. Verify the headline P0/P1 items yourself by reading the cited files. Agents occasionally hallucinate line numbers or misread; spot-check the top 5.

If a finding can't be verified (file doesn't exist, line doesn't contain the claimed code), **drop it** and note the drop in the final report.

## Step 3 — Re-grade severity (domain rubric)

Apply the canonical rubric below to every finding. Demote anything that doesn't actually fit P0 criteria.

### Known overgrades (always demote)

| Agent said | Reality | New grade |
|-----------|---------|-----------|
| Firebase iOS API key committed | Intentionally public client config | P3 (or drop) |
| `VITE_FIREBASE_PROJECT_ID` in committed `.env.example` | Shipped in every prod HTML payload | P3 (or drop) |
| Firestore rules `get()` "throws on missing doc" | Returns null in v2 rules | drop (false claim) |
| `xcworkspace/` not committed | Intentional with xcodegen | P3 documentation note |
| `__Snapshots__/` directory committed but no `.gitignore` rule | Snapshot tests are test resources, intentionally tracked | drop (false flag) |
| GoogleService-Info.plist not in `.gitignore` | Public client config; iOS API keys are bundled into the .ipa | drop |

### Real P0 indicators

A finding is genuinely P0 only if it satisfies at least one:

- Plaintext secret (server-side service-account key, OAuth client secret, DB password) committed in `git log` history (verify with `git log --all -- <file>`).
- Code path that allows privilege escalation (user can self-promote to admin via API/rules).
- Code path that allows arbitrary data read/write across user boundaries (Firestore rule too loose).
- Production-down bug present in `main` (not a feature branch).

If none of the above, downgrade.

## Step 4 — Spec-boundary filter

If `--exclude-spec` was provided, walk the spec and identify which findings overlap with work it already owns. Mark them `[-] skipped — owned by <spec-name>`. They appear in the plan doc only for record-keeping.

For RIZQ specifically, the M1 spec at `docs/superpowers/specs/2026-05-08-foundation-milestone-design.md` owns:

- Neon → Firestore migration (web data layer)
- Better Auth → Firebase Auth (already done)
- `firestore.rules` content-write gating (already done)
- iOS `ContentFeature` + `CachedContentClient`
- iOS Neon code purge
- `SettingsPage` reset TODO wiring
- `firebase-debug.log` gitignoring
- `autoforge/` removal

If the user names a different spec, parse its outcomes section for the boundary.

## Step 5 — Cluster into PR-sized themes

Atomic findings (~30 after filtering) cluster into ~6–8 themes. The clustering rules:

| Cluster heuristic | Action |
|------------------|--------|
| Same file touched | Same cluster |
| Same concern (all a11y, all dead-code, all CI/build) | Same cluster |
| Same target audience (web devs, iOS devs, repo maintainers) | Same cluster |
| Genuinely unrelated single-line fixes | Cluster as "misc cleanups" |

Each cluster becomes either:

- A single commit (3+ trivially related atomic fixes that all touch <3 files)
- A PR-scope commit (1 atomic fix that touches many files)
- An issue (work that needs design/decision before code)

In the plan doc, each cluster gets one or more `#NN` items (one per atomic action, but grouped under a "Theme" heading in §6).

## Step 6 — Write the plan doc

Output path: `--output` or default `docs/audit/<YYYY-MM-DD>-audit-execution-plan.md`.

Use this template:

```markdown
# Audit Execution Plan — RIZQ App

**Date:** <YYYY-MM-DD>
**Owner:** <git config user.name>
**Status:** Drafted — execution gated on §2.
**Source:** Parallel deep-dive agents (web / iOS / repo), severity-rubric re-graded, spec-boundary filtered against <exclude-spec if any>.

---

## 1. Strategy

| Decision | Choice | Trade-off accepted |
|----------|--------|--------------------|
| Tracking | <fill from user prior choice or default to "Plan doc only"> | <...> |
| PR strategy | <single mega-PR / themed PRs / one-per-item, default themed> | <...> |
| Branch base | <main, or as user prefers> | <...> |
| Branch name | `audit/<date>-full-sweep` | — |
| Execution model | Parallel batches + Ralph loop | — |

---

## 2. Execution Gates — DO NOT START UNTIL

- [ ] G1. `git status --porcelain` is empty
- [ ] G2. `bash scripts/check-all.sh --skip-e2e --skip-ios` passes on `main`
- [ ] G3. <any spec-specific gate, e.g., "M1 fully merged">

---

## 3. Status Legend

`[ ]` todo · `[~]` in-progress · `[!]` blocked · `[x]` done · `[-]` skipped

---

## 4. How to Run

### 4a. Batch
Invoke `/drain-plan <this-path> --mode=batch --batch-size=4`. Dispatches up to 4 non-overlapping items in parallel.

### 4b. Ralph loop (overnight/unattended)
Invoke `/loop /drain-plan <this-path> --mode=batch --batch-size=4`. Self-paces to drain to completion.

### 4c. Manual single
Invoke `/drain-plan <this-path> --item=NN` for a specific item.

---

## 5. Aggregate Verification

```bash
bash scripts/check-all.sh --all
```

---

## 6. Items

<for each cluster (Theme), emit a `### Theme N: <name>` heading then the items below it>

### Theme N: <name>

### #NN — <title>
- **sev:** Px | **type:** commit|PR|issue | **status:** `[ ]`
- **files:** <paths>
- **dod:** <definition of done>
- **verify:** <command>
- **hint:** <implementation guidance>
- **commit-msg:** `<commit-msg template>`
- **conflicts-spec:** <none|excluded-spec-name|partial>

<...>

---

## 7. Mega-PR template

<as in existing audit-plan.md template — list themes, per-commit verification, review guidance>

---

## 8. Stop conditions

<as in existing>

---

## 9. Open questions

<any deferrals you noted during clustering>

---

## 10. Change log

- <date> — initial draft via /audit-cycle skill
```

## Step 7 — Final report to user

After writing the doc, output a structured summary to the user:

```
Audit cycle complete.

Plan doc: <path>
Surface areas: <web,ios,repo>
Exclude-spec: <path or "none">

Findings:
  Raw from agents: <N>
  Verified: <N>
  Dropped (false claim / overgrade): <N>
  After spec-boundary filter: <N>

Clustered into <K> themes producing <M> items in §6.

Suggested next step:
  /drain-plan <path> --mode=batch --batch-size=4

Or for unattended:
  /loop /drain-plan <path> --mode=batch --batch-size=4

User decisions still needed:
  - PR strategy (single mega vs. themed): defaulted to <choice>
  - Branch base: defaulted to <choice>
  Edit §1 of the plan doc to override before executing.
```

## What you do NOT do

- Implement any items. The plan doc is the deliverable; `drain-plan` executes it.
- Open any PRs.
- Modify any file outside the output path.
- Commit the plan doc — the user decides when to commit.
- Skip the verification step on the top P0/P1 findings — agents over-grade and we don't want false alarms in the plan.

## Quality bar

A good audit-cycle run produces:

1. A plan doc that compiles (correct §6 format, all items have all required fields).
2. Zero false-flag P0s (the severity rubric did its job).
3. Clusters that survive eyeball review — no "miscellaneous" cluster bigger than 5 items.
4. Clear next steps so the user knows what to do (`/drain-plan` invocation included).

The doc is the contract between audit and execution. Make it tight.
