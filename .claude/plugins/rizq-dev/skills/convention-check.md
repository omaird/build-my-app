---
name: convention-check
description: "Flag CLAUDE.md convention violations in a git diff (or staged changes, or a specific file). Catches things like: hardcoded colors instead of CSS vars, missing pb-24 on pages, missing loading/empty states, raw <button> instead of shadcn Button, @State for domain data in Swift, missing service timeouts, print() instead of Logger, etc. Use when the user says 'check my changes', 'review this against CLAUDE.md', 'is this following conventions?', before committing, or as a pre-commit hook. Args: optional diff source (default: `git diff HEAD`), or a specific file path."
---

# Convention Check

You audit a diff (or file) for violations of the conventions documented in `CLAUDE.md` and `RIZQ-iOS/CLAUDE.md`. You produce a graded list of violations with line numbers and suggested fixes. You do NOT fix them automatically — you report.

## Input

```
/convention-check                                # checks `git diff HEAD` (unstaged + staged)
/convention-check --staged                       # checks only `git diff --cached`
/convention-check --against=main                 # checks `git diff main...HEAD`
/convention-check src/pages/NewPage.tsx          # checks one specific file
/convention-check --since=<sha>                  # checks `git diff <sha>..HEAD`
```

Parse:

- **--staged** — bool. Default false.
- **--against** — branch or ref to diff against. Mutually exclusive with --staged.
- **--since** — commit SHA. Mutually exclusive with --staged/--against.
- **positional arg** — file path. If provided, checks just that file (not a diff).

## Step 1 — Acquire the changeset

```bash
# Default mode
git diff HEAD --name-only
git diff HEAD

# Staged mode
git diff --cached --name-only
git diff --cached

# Against branch
git diff main...HEAD --name-only
git diff main...HEAD

# Since SHA
git diff <sha>..HEAD --name-only
git diff <sha>..HEAD

# Specific file
cat <file-path>
```

Build a list: `[{ file, hunks: [{ start_line, end_line, content }] }]`. If no changes, report "no changes to check" and stop.

## Step 2 — Walk the rule catalog

For each changed file, look up which rules apply by glob and apply each rule to the file's hunks (or full content for specific-file mode).

### Web Rules — `src/**/*.{ts,tsx}`

| Rule ID | Pattern | Severity | Notes |
|---------|---------|----------|-------|
| W-UI-NO-MODIFY | Any edit to `src/components/ui/**` | **P0** | CLAUDE.md: "Don't modify files in `src/components/ui/`" — these are shadcn primitives. |
| W-NO-RAW-BUTTON | `<button` in TSX (excluding `Button` import) | P1 | Use shadcn `<Button>` from `@/components/ui/button`. |
| W-PAGE-PB24 | New page file under `src/pages/` without `pb-24` class on root element | P1 | Pages need bottom padding for nav bar clearance. |
| W-HARDCODED-COLOR | Hex color in `className` or inline `style` (e.g., `#D4A574`, `rgb(...)`) | P1 | Use Tailwind class or CSS var. Exception: SVG fills with intentional design-token equivalent. |
| W-NO-LOADING-STATE | Page with `useQuery` but no rendering branch for `isLoading` | P1 | CLAUDE.md mandates loading + empty + error states on pages. |
| W-NO-EMPTY-STATE | Page rendering a list without an empty fallback | P1 | Same convention. |
| W-RAW-DB-IDENTIFIER | `_id` or `_at` in TS code outside of DB row types | P2 | Should be camelCase (`id`, `createdAt`) in frontend. |
| W-USE-CN | Multiple class strings being concatenated with `+` or template literals (not `cn()`) | P2 | `cn()` from `@/lib/utils` is the standard for conditional classes. |
| W-CONSOLE-LOG | `console.log(`, `console.warn(`, `console.error(` outside of `src/lib/logger*` | P1 | No debug leftovers in committed code. (Exception: legitimate error reporting going to a logger service.) |
| W-ANY-TYPE | `: any` or `as any` | P1 | Type properly or use `unknown` + narrowing. |
| W-MISSING-FRAMER | New page without `motion.div` entry animation | P3 | CLAUDE.md mandates Framer Motion entry animations. (Light touch — not every page needs it.) |
| W-ARABIC-NO-RTL | `font-arabic` class or `arabicText` variable without `dir="rtl"` nearby | P1 | Arabic text needs RTL direction. |
| W-NO-UUID-CAST | `${userId}` in SQL template literal without `::uuid` cast | P1 | M1-conditional: still relevant for Neon-era code; ignore on `m1-foundation` branch post-Step-3. |
| W-NEON-AUTH-QUERY | SQL touching `neon_auth.user` outside `getProfileImage` helper | P1 | M1-conditional: CLAUDE.md forbids querying neon_auth except for profile-picture sync. |

### iOS Rules — `RIZQ-iOS/**/*.swift`

| Rule ID | Pattern | Severity | Notes |
|---------|---------|----------|-------|
| I-STATE-DOMAIN-DATA | `@State` storing arrays/dicts/custom-types in a `View` | **P0** | Domain data goes in TCA `@ObservableState`, not `@State`. |
| I-DEPS-OUTSIDE-REDUCER | `@Dependency(...)` accessed in a `View` body or non-reducer function | **P0** | TCA dependencies only inside reducers. |
| I-DEPENDENCY-CLIENT-MACRO | `@DependencyClient` macro on a struct | **P0** | RIZQ-iOS/CLAUDE.md: "Don't use `@DependencyClient` macro (use manual struct registration)". |
| I-PRINT-NOT-LOGGER | `print(` outside test files | P1 | Use `Logger(subsystem:category:)` per CLAUDE.md. |
| I-NO-SERVICE-TIMEOUT | Service call (`firestoreClient.fetch*`) inside a `.run` effect without `withThrowingTaskGroup` + timeout | P1 | CLAUDE.md mandates 8s–10s timeout with SampleData fallback. |
| I-FORCE-UNWRAP | `!` after optional in non-test code (excluding `IBOutlet` style) | P1 | Use `guard let`, `??`, or `if let`. |
| I-DIRECT-FIREBASE-AUTH | `Auth.auth()` or `Firestore.firestore()` called outside `RIZQKit/Services/` | P1 | Go through the `authClient` / `firestoreClient` TCA dependency. |
| I-MAINACTOR-MISSING | View struct method that touches `@MainActor`-isolated state without annotation | P2 | Annotate the method or extract to a `.run { @MainActor in ... }`. |
| I-MODEL-DUPLICATE | New model definition in `Features/` when one already exists in `RIZQKit/Models/` | P1 | Reuse the kit model. |
| I-XCODEGEN-DRIFT | New `.swift` file added but not present in `project.yml` source list (if explicit) | P1 | CLAUDE.md: re-run `xcodegen generate` after adding files. |
| I-WIDGET-COLORS | Hex color in `RIZQWidget/` matching a defined RIZQKit `Color.` token | P2 | Use the kit token; widget already imports RIZQKit. |

### Cross-cutting rules — any file

| Rule ID | Pattern | Severity | Notes |
|---------|---------|----------|-------|
| X-NO-AMENDED-COMMIT | (Detect via `git reflog` showing recent `--amend`) | P2 | CLAUDE.md project rule. Informational only. |
| X-NO-NO-VERIFY | (Detect via `git config core.hooksPath` set to skip) | P1 | Never `--no-verify` unless user explicitly asked. |
| X-SECRETS-IN-DIFF | Diff adds a string matching `[A-Za-z0-9]{40,}` near an obvious key name (`api_key`, `secret`, `token`) | **P0** | Possible credential leak. Halt-grade — surface immediately. |

### Docs rules — `*.md` files

| Rule ID | Pattern | Severity | Notes |
|---------|---------|----------|-------|
| D-CLAUDE-MD-OUTDATED | Edit to a file referenced in CLAUDE.md that contradicts what CLAUDE.md says | P2 | Note the contradiction; CLAUDE.md may need updating too. |
| D-PRD-DRIFT | Edit to feature behavior that contradicts PRD.md sections still active | P3 | Informational. |

## Step 3 — Apply rules

For each rule:

1. Quickly check whether the file is in-scope via the glob.
2. Apply the pattern (regex + AST-light heuristics; you have file content, do a string-level pass).
3. For each match, record: `file`, `line`, `rule_id`, `severity`, `excerpt`, `suggestion`.

**False-positive handling — always apply these dampeners:**

- If the file is in `tests/`, `e2e/`, or `*Tests.swift` — most rules are relaxed. Especially: `I-PRINT-NOT-LOGGER`, `W-CONSOLE-LOG`, `W-ANY-TYPE` (mocks need permissive types), `I-FORCE-UNWRAP` (assertions can force-unwrap).
- If the file is the diff source itself (a doc or config), skip code rules.
- If the violation is in an unmodified line of the diff context (i.e., the surrounding 3 lines), **don't flag it** — it's pre-existing and not introduced by this change. Only flag changes in added lines (lines starting with `+`).
- If the file is under `src/components/ui/` and the change is a shadcn primitive upgrade (matches the upstream shadcn diff), the W-UI-NO-MODIFY rule downgrades to a P1 advisory.

## Step 4 — Output

Two output sections:

### Section A — Blocking (P0)

```
P0 violations — must fix before commit
─────────────────────────────────────────

[W-UI-NO-MODIFY] src/components/ui/button.tsx:42
  Modifying shadcn primitive.
  Why: CLAUDE.md prohibits direct edits to src/components/ui/ — these are shadcn primitives
       managed by the CLI. Local edits drift from upstream and complicate future re-syncs.
  Fix: revert this file. If you need a customized button, create src/components/CustomButton.tsx
       that wraps the shadcn Button.

[I-STATE-DOMAIN-DATA] RIZQ-iOS/RIZQ/Features/Foo/FooView.swift:18
  @State var items: [Dua] = []
  Why: Domain data must live in TCA @ObservableState, not SwiftUI @State.
  Fix: Move `items` to FooFeature.State and observe via @Bindable var store.
```

If section A is non-empty, end the report with: `STATUS: BLOCKED. Fix P0 violations before committing.`

### Section B — Should-fix (P1 + P2 + P3)

```
P1 violations — strongly recommended fix
─────────────────────────────────────────

[W-NO-LOADING-STATE] src/pages/NewPage.tsx
  Page uses `useDuas()` but does not render a loading state.
  Suggest: `if (query.isLoading) return <Loader2 className="animate-spin" />;`

P2 violations — small fix nits
────────────────────────────────
  ...
```

If only Section B is non-empty, end with: `STATUS: OK. No blockers; address P1s if time permits.`

If both sections empty: `STATUS: CLEAN. No convention violations found in this changeset.`

## Step 5 — Aggregate counters

End every report with a per-rule tally:

```
RULES TRIGGERED:
  W-UI-NO-MODIFY  × 1
  I-STATE-DOMAIN-DATA × 1
  W-NO-LOADING-STATE × 1
  TOTAL: 3 violations across 3 files

RULES NOT APPLICABLE: <count> (skipped because file globs didn't match)
```

## Use as a pre-commit hook

The skill is designed to be invocable from a `.husky/pre-commit`:

```bash
#!/usr/bin/env bash
# .husky/pre-commit
# Run convention check on staged files
claude-code skill convention-check --staged
```

(The invocation syntax depends on the harness; if the hook target is a shell script, it shells out and exits non-zero on `STATUS: BLOCKED`.)

## What you do NOT do

- Fix violations. Report only.
- Edit any source file.
- Edit CLAUDE.md to "loosen" a rule. If a rule is wrong, the user fixes the rule.
- Flag pre-existing violations not in the diff (unless `--against=main` is used, in which case the diff is the entire branch).
- Skip P0s with a "minor" downgrade. P0 is non-negotiable.

## When to be skeptical of your own output

- If you flag >10 P1s in a single diff, the diff is probably very large — reconsider whether you're flagging style preferences rather than convention violations.
- If you flag a P0 on a file that the user clearly intended to refactor (e.g., the commit message says "rewrite shadcn button to match design system"), surface the violation but note that the user may be overriding intentionally.
- If a rule fires on something the user just demonstrably authored well (e.g., they used `cn()` correctly two lines earlier), look harder — you probably misread.
