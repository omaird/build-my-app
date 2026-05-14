---
name: cluster-into-themes
description: "Group a flat list of atomic audit findings into PR-sized themed clusters with rationale, so each theme becomes one reviewable PR. Use when an audit produces 20–50 atomic findings and you need to decide how to package them into branches. Typically called by the audit-cycle skill, but also useful manually when reorganizing an existing plan doc's §6 items. Args: findings list (or path to a plan doc); optional --max-items-per-theme=N, --max-themes=N, --strategy=<by-concern|by-audience|by-file-overlap>."
---

# Cluster Into Themes

You take a flat list of atomic audit findings and decide how to group them into PR-sized themed clusters. Each theme becomes one logical branch + PR. You return the grouping with explicit rationale.

You do NOT change the findings themselves. You produce a *grouping structure* over them.

## Input

```
/cluster-into-themes                                          # reads from previous turn's findings
/cluster-into-themes docs/audit/2026-05-12-audit-execution-plan.md  # cluster items in an existing plan
/cluster-into-themes --max-items-per-theme=6
/cluster-into-themes --max-themes=8 --strategy=by-concern
```

Parse:

- **positional arg** — path to a plan doc whose §6 items should be re-clustered. If absent, use the most recent findings list passed to you (e.g., output of `audit-cycle`'s synthesis phase).
- **--max-items-per-theme** — soft cap on items per theme. Default: 6.
- **--max-themes** — soft cap on total themes. Default: 8.
- **--strategy** — primary clustering axis. Default: `by-concern`. See § Strategies.

## Strategies

### `by-concern` (default — best for audit results)

Group items that share a conceptual purpose. Concerns are higher-level than files:

- "type-safety" — strict mode, ESLint rules, type unions, dead-code-after-types-tighten
- "CI/build" — workflow setup, vitest config, port alignment, pre-commit hooks
- "a11y" — focus traps, aria-current, keyboard navigation, ARIA labels
- "dead-code" — orphaned files, unused exports, legacy hooks
- "iOS-architecture" — TCA dependency placement, reducer splits, sendable conformance
- "iOS-testing" — TestStore coverage, snapshot deps, timeout path tests
- "docs" — README, CONTRIBUTING, doc relocations
- "config-cleanup" — package.json rename, dependency removal, gitignore fixes

Two items belong in the same concern-theme if a reviewer would naturally think of them together.

### `by-audience`

Group by who reviews:

- "web devs" — anything in `src/`
- "iOS devs" — anything in `RIZQ-iOS/`
- "infra/CI" — `.github/`, `scripts/`, `firebase.json`, top-level configs
- "docs" — `*.md`

Use this when the team is large enough that different people own different surfaces and you want explicit hand-off.

### `by-file-overlap`

Group items that touch the same file. Most aggressive deduplication; produces fewer but bigger themes. Use when you specifically want to *minimize merge conflicts within a theme* — items in the same theme will edit the same file, so they can't conflict with each other.

## Step 1 — Read inputs

If a plan-doc path was given, parse §6 items into the standard finding shape:

```
{
  number: "07",
  title: "...",
  severity: "P1",
  type: "commit",
  files: [...],
  description: "...",
  status: "[ ]" | ...
}
```

Skip items with status `[x]`, `[!]`, or `[-]` — they're already decided.

If no path was given and no findings are in scope, stop and ask.

## Step 2 — Apply the strategy

### For `by-concern`

1. Tag each finding with one or more `concerns` based on title + files + description. Use the concern vocabulary above or coin a new one if the finding clearly belongs nowhere existing.
2. Group findings sharing a concern.
3. If any group exceeds `max-items-per-theme`, split by sub-concern (e.g., "iOS-architecture" → "iOS dependency cleanup" + "iOS reducer DRY").
4. If a finding belongs to two concerns, place it in the heavier one (the one with more other items) — minimizes orphan-singletons.

### For `by-audience`

1. Tag each by audience using file paths.
2. Group accordingly.
3. If a group exceeds `max-items-per-theme`, split by sub-concern within that audience.

### For `by-file-overlap`

1. Build a graph: nodes = findings, edges = "shares at least one file".
2. Find connected components. Each component is a theme.
3. Isolated nodes (no file overlap with anything) form a "misc-cleanup" theme.

## Step 3 — Theme naming

Each theme gets a short, imperative name suitable for a branch suffix and PR title:

- ✅ `audit-foundations`, `audit-a11y-pass`, `audit-ios-dep-cleanup`, `audit-docs-sweep`
- ❌ `theme-1`, `things to fix`, `various cleanups` (no information)

If a theme has only 1–2 items and they're trivial, fold into `audit-misc-cleanup` rather than create a vanity theme.

## Step 4 — Output format

```markdown
# Theme Clustering Result

Input: <N> findings (after filtering done/blocked).
Strategy: <strategy>
Max items per theme: <N>
Max themes: <N>

## Themes

### 1. <name> (<count> items)
**Concern:** <one-line concern summary>
**Items:** #NN, #NN, #NN, ...
**Branch suffix:** `audit/<theme-name>`
**Rationale:** <why these belong together — one sentence>
**Estimated PR size:** small | medium | large (files-touched count, lines roughly)

### 2. <name> ...

...

## Singletons (items that didn't cluster)

If any items couldn't cluster:
- #NN — <title> — reason it stayed solo

## Recommendations for plan-doc update

To apply this clustering to the plan doc, edit §6 as follows:

1. Add a `### Theme N: <name>` heading before the first item of each cluster.
2. Reorder items so all items in a theme are contiguous.
3. (Optional) Add a `theme:` field to each item's metadata block.

The `drain-plan` skill respects theme groupings when dispatching parallel batches — items in the same theme tend to share files, so it will pick across themes for parallelism.

## Sanity checks (apply before returning)

- Every theme has ≥ 2 items (or is `audit-misc-cleanup`).
- No theme exceeds `max-items-per-theme` unless the user explicitly overrode.
- No theme is empty.
- Total themes ≤ `max-themes` unless the input fundamentally requires more.
- Every input finding is accounted for exactly once (no drops, no doubles).
```

## Step 5 — Sanity self-review

Before returning, ask yourself:

1. **Would a reviewer accept this PR as one logical unit?** If a theme mixes "dead code removal" + "performance fix" + "type union update", the answer is probably no — split.
2. **Do all items in this theme need to land together?** If item A could land independently of items B/C/D, then A is a singleton (or move to misc-cleanup).
3. **Is the rationale convincing?** If you can't write one sentence explaining why these items belong together, the theme is forced.

If any answer is no, re-cluster.

## Example output

```markdown
# Theme Clustering Result

Input: 30 findings.
Strategy: by-concern.

## Themes

### 1. audit-foundations (4 items)
**Concern:** unblock everything that follows — CI, ports, vitest config, husky hook.
**Items:** #02, #03, #18, #26
**Branch suffix:** `audit/foundations`
**Rationale:** All four are infrastructure changes that other commits in later themes depend on for verification. Land first.
**Estimated PR size:** medium (~6 files, ~150 LoC, mostly new config files)

### 2. audit-types-and-lint (3 items)
**Concern:** Type safety + lint discipline.
**Items:** #04, #05, #14
**Branch suffix:** `audit/types-and-lint`
**Rationale:** All three tighten compile-time checks; #04 (strictNullChecks) is the largest fanout and the others rely on its error-clean baseline.
**Estimated PR size:** large (~30 files, ~250 LoC of null guards)

### 3. audit-react-fixes (3 items)
**Concern:** React anti-patterns + correctness in user-facing UI.
**Items:** #01 (AdminRoute), #15 (a11y), #16 (query error UI)
**Branch suffix:** `audit/react-fixes`
**Rationale:** All three touch React rendering correctness on user-facing pages; reviewer mental model is "UI behavior bugs".
**Estimated PR size:** medium

...

## Singletons
- (none)
```

## What you do NOT do

- Modify the plan doc directly. Output the clustering as a *recommendation*; the user (or the `audit-cycle` skill) applies it.
- Drop items. If a finding is in the input, it's in the output.
- Create themes with 1 item just to keep the count up.
- Re-grade severity. That's `audit-cycle`'s job.
- Override the strategy when you "think you know better" — if the user picked `by-audience`, use that.
