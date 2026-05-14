---
name: plan-to-issues
description: "Mirror a RIZQ plan doc to GitHub issues using `gh`. For each item in §6 of the plan, create a GitHub issue with the item's title, body (dod/verify/hint), severity/type labels, and a link back to the plan doc. Optional bidirectional sync: write issue numbers back into the plan doc; close issues when items are marked [x]. Use when the user says 'turn this plan into GitHub issues', 'mirror to GitHub', 'create issues for everything', or wants public visibility on the audit-plan items. Args: plan-doc path; optional --dry-run, --sync-back, --close-completed, --milestone=<title>, --repo=<owner/name>."
---

# Plan to Issues

You mirror items from a RIZQ plan doc (`docs/audit/*.md` or `docs/superpowers/plans/*.md`) to GitHub issues using the `gh` CLI. The plan doc remains the source of truth; issues are a visibility mirror.

This is optional infrastructure. If the user chose "plan doc only" tracking (no GitHub issues), don't run this. If they later change their mind, this skill is how they catch up.

## Input

```
/plan-to-issues docs/audit/2026-05-12-audit-execution-plan.md
/plan-to-issues docs/audit/2026-05-12-audit-execution-plan.md --dry-run
/plan-to-issues docs/audit/2026-05-12-audit-execution-plan.md --sync-back
/plan-to-issues docs/audit/2026-05-12-audit-execution-plan.md --close-completed
/plan-to-issues docs/audit/2026-05-12-audit-execution-plan.md --milestone="Audit Sweep 2026-05"
/plan-to-issues docs/audit/2026-05-12-audit-execution-plan.md --repo=owner/repo
```

Parse:

- **positional arg** — plan doc path. Required.
- **--dry-run** — print what would be created/updated, don't call GitHub. Default false.
- **--sync-back** — after creating issues, edit the plan doc to add `issue:` field to each item with the issue number. Default false.
- **--close-completed** — for any item already `[x]` that has a paired issue, close the issue. Default false.
- **--milestone** — GitHub milestone to attach to all created issues. Optional.
- **--repo** — `owner/name`. Default: inferred from `git remote get-url origin`.

## Step 0 — Pre-flight

```bash
# Confirm gh CLI is installed and authenticated
gh auth status

# Confirm we're in a git repo connected to GitHub
git remote get-url origin
```

If `gh` is missing or unauthenticated, stop and report. If origin isn't a GitHub URL, stop.

Identify the repo:

```bash
gh repo view --json nameWithOwner --jq .nameWithOwner
```

## Step 1 — Read the plan doc

`Read plan_path`. Parse §6 items into:

```
{
  number, title, severity, type, status, files, dod, verify, hint,
  commit_msg, conflicts_m1, theme (if §6 has theme headings)
}
```

Track existing `issue:` fields on items — these are already-created issues to update rather than recreate.

## Step 2 — Label setup (idempotent)

Create these labels if they don't exist (use `gh label create --force` to no-op on already-exists):

```bash
# Severity labels
gh label create "audit:p0" --color "B60205" --description "Audit-flagged P0: security/correctness" --force
gh label create "audit:p1" --color "D93F0B" --description "Audit-flagged P1: real quality issue" --force
gh label create "audit:p2" --color "FBCA04" --description "Audit-flagged P2: nice-to-have cleanup" --force
gh label create "audit:p3" --color "C2E0C6" --description "Audit-flagged P3: cosmetic" --force

# Type labels
gh label create "audit:commit" --color "1D76DB" --description "Single-commit fix" --force
gh label create "audit:pr"     --color "1D76DB" --description "PR-scope change" --force
gh label create "audit:issue"  --color "1D76DB" --description "Needs design before implementation" --force

# Workflow label
gh label create "audit" --color "0E8A16" --description "Audit-driven item; see plan doc" --force
gh label create "audit:blocked" --color "5319E7" --description "Audit item blocked; see plan doc for reason" --force
```

In `--dry-run`, print the commands and skip.

## Step 3 — Milestone setup (if requested)

If `--milestone` was provided:

```bash
# Check if milestone exists
gh api "repos/$REPO/milestones?state=open" --jq '.[] | select(.title == "<milestone>") | .number'
```

If absent, create it:

```bash
gh api "repos/$REPO/milestones" -f title="<milestone>" -f description="Audit sweep tracker — see plan doc"
```

Capture the milestone number.

## Step 4 — For each item, create or update an issue

Iterate items in plan-doc order. For each item, decide:

| State | Action |
|-------|--------|
| `[ ]` with no `issue:` field | **Create** a new issue |
| `[ ]` with `issue:` field | **Update** the existing issue (title, body, labels) |
| `[~] ...` with `issue:` field | **Update** — set issue to "In Progress" label (add `audit:in-progress`) |
| `[x] <sha>` with `issue:` field | **Close** the issue if `--close-completed`; otherwise skip |
| `[!] <reason>` with `issue:` field | **Update** — add `audit:blocked` label; reflect reason in issue comment |
| `[-] <reason>` | **Close** the issue if it exists, marked `won't fix` |
| No `issue:` field and status `[x]`/`[-]` | Skip (already completed without an issue mirror) |

### Issue body template

```markdown
> Mirrored from [<plan-doc-filename>](<github-permalink-to-plan-doc-anchor>) — item #<NN>.
> The plan doc is the source of truth.

## Definition of done
<dod>

## Verification
```
<verify command>
```

## Implementation hint
<hint>

## Commit message template
```
<commit-msg>
```

## Plan doc context
- Severity: <P0/P1/P2/P3>
- Type: <commit|PR|issue>
- Conflicts with M1: <yes|no|partial>
- Theme: <theme name from §6 if any>
- Files: <files list>

---

When you (or an agent) implement this item, update the plan doc's status marker per the [`drain-plan`](https://...) workflow, not the issue. The issue auto-closes when the plan doc is updated and `/plan-to-issues --close-completed` runs.
```

### Issue title

```
[audit #NN] <title>
```

### Issue labels

`audit`, `audit:p<severity>`, `audit:<type>`. Plus `audit:blocked` for `[!]` items, `audit:in-progress` for `[~]`.

### Issue command

```bash
gh issue create \
  --repo "$REPO" \
  --title "[audit #NN] <title>" \
  --body-file <(cat <<'EOF'
... body ...
EOF
) \
  --label "audit,audit:p1,audit:commit" \
  --milestone "<milestone-num if set>"
```

Capture the issue number from `gh issue create` stdout (URL or number).

## Step 5 — Sync back (if `--sync-back`)

After all issues are created, edit the plan doc:

For each item, find its status line and insert `issue: #NNN` as an additional metadata field:

```
- **sev:** P1 | **type:** commit | **status:** `[ ]` | **issue:** #42
```

Use `Edit` operations one at a time so the diff is clean.

Commit the sync-back? **No** — leave the plan doc modified in the working tree; the user decides when to commit.

## Step 6 — Close completed (if `--close-completed`)

For items with status `[x] <sha>` that have `issue:` numbers:

```bash
gh issue close <num> --repo "$REPO" --comment "Completed in commit <sha>. See plan doc for details."
```

For items with status `[-] <reason>`:

```bash
gh issue close <num> --repo "$REPO" --reason "not planned" --comment "Skipped: <reason>"
```

## Step 7 — Final report

```
plan-to-issues complete.

Plan doc: <path>
Repo: <owner/name>
Milestone: <name or "(none)">

Issues created:    <N>
Issues updated:    <N>
Issues closed:     <N>
Skipped:           <N>
Errors:            <N>

Sync-back: <applied to plan doc | --sync-back not set>

Open issues now tracking this plan: <count>
GitHub view: https://github.com/<repo>/issues?q=is%3Aissue+label%3Aaudit
```

If `--dry-run`, all "created/updated/closed" counts are "would-be".

## Failure modes

| Situation | Action |
|-----------|--------|
| `gh` not installed | Stop. Tell user to `brew install gh` (or platform equivalent) and run `gh auth login`. |
| `gh auth status` fails | Stop. Tell user to `gh auth login`. |
| `--repo` invalid or no access | Stop. Report. |
| Item parse fails (malformed status line) | Skip that item, log warning, continue with rest. |
| Issue already exists with same title (race) | Update it instead of creating duplicate. |
| `--close-completed` on an item whose linked issue is already closed | Skip silently. |
| GitHub API rate-limited | Stop, report retry-after time. Save progress. |

## Idempotency

Running this skill twice on the same plan doc should produce identical state:

- First run: creates N issues, optional sync-back inserts `issue:` numbers.
- Second run: detects existing `issue:` numbers, updates them in place. Net change: zero (unless plan content drifted, in which case issue body refreshes).

## What you do NOT do

- Implement the plan items themselves. The `plan-item-implementer` agent does that.
- Open PRs. The user does that when the audit branch is ready.
- Delete or rename issues from previous runs. If an item was removed from the plan doc, do NOT auto-close its issue — surface "orphan issues" in the final report and let the user decide.
- Modify the plan doc beyond inserting `issue:` numbers (when `--sync-back`).

## Example — first run

```
/plan-to-issues docs/audit/2026-05-12-audit-execution-plan.md --sync-back --milestone="Audit Sweep 2026-05"

plan-to-issues complete.

Plan doc: docs/audit/2026-05-12-audit-execution-plan.md
Repo: omairdawood/rizq-app
Milestone: Audit Sweep 2026-05 (#3)

Issues created:    30
Issues updated:    0
Issues closed:     0
Skipped:           0
Errors:            0

Sync-back: applied to plan doc — review and commit.

Open issues now tracking this plan: 30
GitHub view: https://github.com/omairdawood/rizq-app/issues?q=is%3Aissue+label%3Aaudit
```

## Integration with drain-plan

The `drain-plan` skill is unaware of GitHub. When it marks an item `[x]`, no issue update happens automatically.

To keep issues in sync, the user runs `plan-to-issues --close-completed` periodically — typically once per drain-plan batch, or once at the end of the sweep before merging the mega-PR.

(Future enhancement: a `drain-plan --emit-issue-events` flag that fires `gh issue close` after each item — not built yet, by design.)
