---
name: drain-plan
description: "Drain items from a RIZQ audit/execution plan doc by dispatching plan-item-implementer subagents. Supports single-item, parallel-batch, and ralph-loop modes. Use when the user says 'drain the plan', 'run the audit plan', 'work through the M1 plan', or any phrasing that means 'execute items from a RIZQ plan doc'. Args: plan-doc path; optional --mode={single|batch|loop}, --batch-size=N, --item=NN, --skip-verify-gates."
---

# Drain Plan

You orchestrate the execution of items from a RIZQ plan doc. You read the doc, check gates, pick eligible items, dispatch the `plan-item-implementer` subagent per item, aggregate results, and update progress. You do not implement items yourself — the subagent does.

## Argument parsing

The user invokes with something like:

```
/drain-plan docs/audit/2026-05-12-audit-execution-plan.md
/drain-plan docs/audit/2026-05-12-audit-execution-plan.md --mode=batch --batch-size=4
/drain-plan docs/superpowers/plans/2026-05-08-foundation-milestone.md --item=12
/drain-plan docs/audit/2026-05-12-audit-execution-plan.md --skip-verify-gates
```

Parse args:

- **plan_path** — first positional arg, required. Absolute or repo-relative path.
- **--mode** — `single` | `batch` | `loop`. Default: `batch`.
  - `single` — execute ONE next eligible item, then return.
  - `batch` — execute up to `--batch-size` items in parallel that have no file overlap, run aggregate verification, then return.
  - `loop` — keep calling `single` mode until no `[ ]` items remain or a `[!]` halts. Returns a final summary.
- **--batch-size** — integer, default 4. Only meaningful in `batch` mode.
- **--item** — integer. If set, execute that specific item number regardless of order (still respects gates and `[~]/[x]` locks).
- **--skip-verify-gates** — bool. Skip the §2 gate check. Use sparingly; intended for re-runs after a transient failure.

If `plan_path` is missing, show usage and stop.

## Step 1 — Pre-flight

### 1a. Read the plan doc

`Read plan_path`. Parse it: find §2 (execution gates), §5 (aggregate verification command), §6 (items). Each item has the standard format documented in the `plan-item-implementer` subagent.

If the file doesn't exist or doesn't have a recognizable §6, stop with a clear error.

### 1b. Verify execution gates

Read §2 of the plan doc. Each gate is a `- [ ]` or `- [x]` bullet. For each `[ ]` gate, evaluate the verification clause (e.g., "Verify: `git log main --oneline | head -5` shows the M1 merge commit"). Run the commands inline.

If any gate fails AND `--skip-verify-gates` is not set, **stop and report**:

```
gate failed: <gate-id> — <gate-text>
verify command: <command>
output: <last 10 lines of output>
```

Do not dispatch any work.

If all gates pass (or `--skip-verify-gates` is set), proceed.

### 1c. Working-tree check

`git status --porcelain` must be empty. If not, stop and report — uncommitted changes will collide with implementer agents.

### 1d. Working branch

If the plan doc specifies a branch in §1 (Strategy section, "Branch name" row), checkout that branch (`git checkout <branch>` or `git checkout -b <branch> main` if it doesn't exist).

If the doc doesn't specify a branch, use the current branch (and log a warning).

## Step 2 — Pick item(s)

### 2a. Parse §6 — Items

Walk §6 and build an array of items:

```
{
  number: "07",
  title: "...",
  severity: "P1",
  type: "commit",
  status: "[ ]" | "[~] agent=... branch=... started=..." | "[x] <sha>" | "[!] <reason>" | "[-] <reason>",
  files: [...],
  conflicts_m1: "yes" | "no" | "partial",
  blocked_by: <item number from hint, if any>
}
```

### 2b. Eligibility filter

An item is eligible if:

- status is `[ ]`
- `conflicts_m1` is `no` OR M1 is verified merged (item #03 of any audit plan typically asserts this in §2 gates)
- no `blocked_by` reference to an item that's not yet `[x]` or `[-]`

If `--item=NN` is set, find that specific item. If it's not eligible, stop with explanation. Otherwise, single-item mode regardless of `--mode`.

### 2c. Mode-specific picking

- **single** — pick the first eligible item (lowest NN). Set `dispatch_set = [item]`.
- **batch** — pick eligible items in order, accumulating into `dispatch_set` while ensuring no two items in the set share any `files:` entry. Stop at `--batch-size`.
- **loop** — pick the first eligible item; `dispatch_set = [item]`. (The loop comes from re-invoking this skill, not from a batch.)

If `dispatch_set` is empty:

- If §6 has no `[ ]` items at all → all done. Report "plan drained" and stop.
- If `[ ]` items exist but all are blocked → report which items are blocked by what.

## Step 3 — Dispatch

For each item in `dispatch_set`, dispatch the `plan-item-implementer` subagent with these inputs:

```
plan_path: <absolute path>
item_number: <NN>
branch: <branch from §1 or current branch>
agent_id: <a generated short ID, e.g., "drain-<random-4-chars>">
```

In `batch` mode, **dispatch all agents in a single message** (multiple `Agent` tool calls in one assistant turn). They run concurrently in their own context windows.

In `single` and `loop` modes, dispatch one agent (foreground, await result).

## Step 4 — Aggregate

Wait for all dispatched agents to return. Each returns a structured summary (see plan-item-implementer §8). Collect them.

For each agent result:

- If `Status: done` → fine, plan doc is already updated by the agent.
- If `Status: blocked` → log the blocker, continue. The plan doc is already updated to `[!]` by the agent.
- If the agent returned without updating the plan doc (i.e., failed to flip its `[~]` to `[x]` or `[!]`) → manually flip the claim back to `[ ]` and log a recovery note.

## Step 5 — Aggregate verification (batch mode only)

In `batch` mode, after all agents return done:

```bash
bash scripts/check-all.sh --skip-e2e --skip-ios
```

(Use `--all` if the batch touched iOS or e2e flow files. The plan-item-implementer already ran per-item verify, this is the cross-cut.)

If aggregate verify fails:

1. Identify the failing check.
2. Try to `git bisect` between the batch start commit and HEAD to find the breaking commit.
3. Report the breaking item number and what broke.
4. Stop. Do NOT auto-revert — the user decides.

## Step 6 — Loop continuation (loop mode only)

If `--mode=loop` and the just-completed item finished successfully:

- If §6 still has eligible `[ ]` items, **re-invoke this skill** with the same args. (Use the Skill tool to invoke `drain-plan` again, not Agent — we want to stay in the same conversation context.)
- If §6 is drained, fall through to Step 7.

## Step 7 — Final report

Output a structured summary:

```
Drain-plan run complete.

Plan: <plan_path>
Mode: <mode>
Items attempted: <N>
  done: <list of NN>
  blocked: <list of NN with reasons>
  skipped (gate): <list of NN if --skip-verify-gates blocked any>
Aggregate verification: <pass|fail|skipped>
Branch: <branch>
Commits added: <count> (see `git log <branch> --oneline`)

Remaining in plan: <count of [ ] items>
Next step: <suggested action — run again? open PR? investigate blocker?>
```

## Failure modes — explicit

| Situation | Action |
|-----------|--------|
| Plan doc not found | Stop. Report path. |
| Gate fails, no `--skip-verify-gates` | Stop. Report gate. |
| Working tree dirty | Stop. Report `git status`. |
| `--item=NN` not eligible | Stop. Report status of that item. |
| All items blocked, no eligible | Report. Stop. |
| Aggregate verification fails after a batch | Stop. Identify breaking commit. Do not auto-revert. |
| Subagent times out / returns nothing | Manually flip its `[~]` back to `[ ]`. Log. Continue with other batch results. |
| Plan doc has no §6 | Stop. Report — wrong file format. |

## What you do NOT do

- Implement items yourself. Always dispatch the plan-item-implementer subagent.
- Run the per-item `verify:` command yourself. The subagent does that.
- Modify items in the plan doc that aren't owned by your current dispatch. The subagent owns its item's status line.
- Open the PR. The mega-PR template lives in §7 of the plan doc; opening is a human decision.
- Skip the gate check by default. Use `--skip-verify-gates` only when the user explicitly says so.

## Example invocations

```
# Drain one item, see how it goes:
/drain-plan docs/audit/2026-05-12-audit-execution-plan.md --mode=single

# Parallel batch of up to 4 non-overlapping items:
/drain-plan docs/audit/2026-05-12-audit-execution-plan.md --mode=batch --batch-size=4

# Re-execute item #07 specifically (e.g., after fixing a blocker):
/drain-plan docs/audit/2026-05-12-audit-execution-plan.md --item=7

# Full unattended sweep (use with /loop for overnight):
/drain-plan docs/audit/2026-05-12-audit-execution-plan.md --mode=loop
```

## Integration with `/loop`

For overnight or unattended runs, the user wraps this skill in `/loop`:

```
/loop /drain-plan docs/audit/2026-05-12-audit-execution-plan.md --mode=batch --batch-size=4
```

When `/loop` fires this skill repeatedly:

- First fire — pre-flight + dispatch batch + report.
- Subsequent fires — same. Each batch shrinks the plan; eventually `dispatch_set` is empty and you report "plan drained" then stop.
- The `/loop` skill itself decides when to stop (when there's no `[ ]` left); we just report cleanly.
