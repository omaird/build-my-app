---
name: dead-code-check
description: "Determine whether a file, exported symbol, or hook is actually used anywhere in the RIZQ codebase before deleting it. Returns a confidence verdict (high/medium/low) with evidence, so you can decide whether deletion is safe. Use when the user says 'is X used?', 'can I delete this?', 'is this dead code?', or before any audit-driven deletion (items like 'remove unused hook' or 'delete legacy file'). Args: file path OR symbol name; optional --scope=<web|ios|all>."
---

# Dead Code Check

You determine whether a file or symbol is dead code with enough confidence that a human can decide to delete it. You do NOT delete it yourself — you produce a verdict.

## Input

```
/dead-code-check src/hooks/useUserData.ts
/dead-code-check useUserProfile
/dead-code-check src/data/duaLibrary.ts --scope=web
/dead-code-check NeonService --scope=ios
```

Parse:

- **target** — first positional arg. Either a file path (`.ts`, `.tsx`, `.swift`, `.js`) or a bare symbol name (function/class/hook/component). Required.
- **--scope** — `web` | `ios` | `all`. Default `all`.

## Step 1 — Determine target kind

If the target contains `/` or ends in `.ts`/`.tsx`/`.swift`/`.js` → treat as **file**.
Else → treat as **symbol** (function/class/component/hook).

## Step 2 — File target

### 2a. Confirm the file exists

```bash
ls -la <target>
```

If it doesn't exist, stop with "file not found — already deleted?".

### 2b. Extract its exports

For `.ts`/`.tsx`/`.js`:
- Grep for `export `, `export default`, `export {` in the file.
- Build a list of exported symbols.

For `.swift`:
- Grep for top-level `public class`, `public struct`, `public enum`, `public func`, `public protocol`, `public actor` in the file.
- Build a list of exported types.

If the file exports nothing (only side effects), the only relevant check is whether anything imports the *file path* itself.

### 2c. Search for importers

For TS/TSX:
```bash
# Relative imports (the most common form for src/)
grep -rn --include="*.ts" --include="*.tsx" "from ['\"].*<filename-without-ext>['\"]" src/
# Path-aliased imports
grep -rn --include="*.ts" --include="*.tsx" "from ['\"]@/.*<filename-without-ext>['\"]" src/
# Side-effect imports
grep -rn --include="*.ts" --include="*.tsx" "import ['\"].*<filename-without-ext>['\"]" src/
# Dynamic imports
grep -rn --include="*.ts" --include="*.tsx" "import(.*<filename-without-ext>" src/
```

For Swift:
```bash
# The Swift compiler resolves modules, not files — so we grep for symbol use
grep -rn --include="*.swift" "<exported-symbol-name>" RIZQ-iOS/
```

### 2d. Also check non-code references

```bash
# Test fixtures, route registrations
grep -rn --include="*.json" --include="*.md" --include="*.yaml" "<filename-or-symbol>" .
# Vite/Webpack config references
grep -n "<filename>" vite.config.ts tsconfig*.json 2>/dev/null
```

## Step 3 — Symbol target

### 3a. Find the definition

```bash
# Where is it defined?
grep -rn --include="*.ts" --include="*.tsx" "^export.* <symbol>" src/
grep -rn --include="*.ts" --include="*.tsx" "^function <symbol>\|^const <symbol>\|^class <symbol>" src/
grep -rn --include="*.swift" "^public class <symbol>\|^public func <symbol>\|^public struct <symbol>" RIZQ-iOS/
```

If not defined anywhere → "symbol not defined in repo".

### 3b. Find usages (excluding the definition)

```bash
grep -rn --include="*.ts" --include="*.tsx" --include="*.swift" "<symbol>" src/ RIZQ-iOS/ | grep -v "<definition-file>"
```

Then **filter out**:
- Comments (`//`, `/*…*/`, `# `)
- String literals where the symbol name appears coincidentally
- Test files where the symbol is imported only to assert it's not exported (unusual)

### 3c. Check for dynamic invocation patterns (common false negatives)

```bash
# Hooks invoked via React DevTools / etc — rare but happens
grep -rn "useState\|useEffect" <definition-file>
# Reflection
grep -rn "['\"]<symbol>['\"]" src/ RIZQ-iOS/
# String interpolation that might form the symbol name
grep -rn "\\\${.*<symbol-fragment>" src/
```

## Step 4 — Verdict rubric

Output one of:

### `high confidence dead`

- File: zero importers across all greps; no non-code references.
- Symbol: zero usages other than the definition; no string-literal references.
- Bonus: file/symbol named with "legacy", "old", "deprecated", "v1", or matches a known-deleted-dependency pattern.

**Action:** safe to delete. Provide the exact `git rm` or `Edit` command.

### `medium confidence dead`

- File: only test files import it, OR only imports are inside the same file's own directory.
- Symbol: only usages are inside the defining file (private-helper-promoted-to-export pattern).
- Bonus: re-exports through `index.ts` that nothing further consumes.

**Action:** deletable but verify with one extra check. Suggest the check. Common: "run `npm run build` after deletion; expect clean. Or: convert the export to non-exported (`export function foo` → `function foo`) and re-run tsc; if tsc passes, the export is truly unused."

### `low confidence dead`

- Some usages exist that grep can't disambiguate (e.g., `Settings` is both a Lucide icon import and a possible custom component).
- String-literal references found.
- Used in JSX as a component without a clear import (might be globally registered).

**Action:** do NOT delete. Investigate further. Suggest specific manual checks.

### `alive`

- ≥ 1 clear usage.

**Action:** not dead code. List the top 5 usage sites with file:line.

## Step 5 — Output format

```
target: <input>
kind: file | symbol
scope: <web|ios|all>

definition: <file:line if symbol, or "file itself" if file target>
exports: <list of exported symbols if file target>

usage search results:
  importers found: <N>
  non-code refs found: <N>
  dynamic-pattern matches: <N>

verdict: high | medium | low confidence dead | alive

evidence:
  <if alive: top 5 usage sites with file:line>
  <if dead: where you looked and what you didn't find>

suggested action:
  <verbatim command — git rm, Edit to remove export, etc.>
  <if low/medium: the verification step that would raise confidence>
```

## Known false-positive patterns (always check these)

The RIZQ codebase has several patterns that grep alone gets wrong:

| Pattern | Why grep misses | How to check |
|---------|----------------|-------------|
| Lazy-loaded routes in `App.tsx` | `lazy(() => import('./Page'))` — file path is a string | Read `src/App.tsx` directly for lazy imports |
| Lucide icon imports named like custom components (`Settings`, `Home`) | Lucide imports and component names collide | Disambiguate by checking the import source — `from "lucide-react"` vs `from "@/pages/..."` |
| Storybook / Playwright fixture references | Often in non-`src/` directories | Always grep `e2e/`, `tests/` too |
| Dynamic dispatch via `switch(slug)` or registry maps | The symbol is a key, not an identifier | Grep for the string form of the symbol name |
| Re-exports from `src/components/ui/` (shadcn primitives) | Often unused locally but valid for future use; CLAUDE.md says don't modify | If target is in `src/components/ui/`, mark `alive (do not modify per CLAUDE.md)` regardless |

## Always-alive list (never report as dead)

These are alive by convention even if grep finds zero usages:

- Any file under `src/components/ui/` (shadcn primitives — kept for future feature use)
- Any Swift file under `RIZQ-iOS/RIZQKit/Models/` (shared model surface for the kit)
- `RIZQ-iOS/RIZQ/Resources/GoogleService-Info.plist` (loaded at runtime by FirebaseApp.configure())
- `src/main.tsx`, `src/App.tsx`, `index.html` (entry points)

## What you do NOT do

- Delete anything. Verdict only.
- Modify the file you're checking.
- Skip the false-positive checks because "the answer is obvious".
- Return `alive` based on a single ambiguous match — investigate to disambiguate.

## Examples

### Example 1 — clear dead file

```
target: src/data/duaLibrary.ts
kind: file
verdict: high confidence dead
evidence:
  Exports: SAMPLE_DUAS array.
  Searched: 0 importers in src/, 0 in tests/, 0 in e2e/.
  No dynamic imports of this path.
  No JSON config references.
suggested action: git rm src/data/duaLibrary.ts
```

### Example 2 — alive after disambiguation

```
target: Settings
kind: symbol
verdict: alive
evidence:
  Definition: lucide-react node module (external).
  Top usages:
    src/components/BottomNav.tsx:3 - import { ..., Settings } from "lucide-react"
    src/components/BottomNav.tsx:10 - icon: Settings
    src/pages/SettingsPage.tsx:1 - export function SettingsPage() {}
  Note: two distinct "Settings" — the Lucide icon (alive) and the page component (also alive via App.tsx route).
suggested action: not dead — both definitions are in active use.
```

### Example 3 — low confidence

```
target: src/hooks/useUserData.ts
kind: file
verdict: medium confidence dead
evidence:
  Exports: useUserProfile, useDailyActivity, useUserProgress.
  Searched: 0 importers of the file path across src/ and tests/.
  However, grep for "useUserProfile" finds matches in:
    src/contexts/AuthContext.tsx:42 (a comment: "// replaces useUserProfile from useUserData")
    src/types/dua.ts:50 (an interface UserProfile that's separately exported)
  No actual code-level usages of the three hooks.
suggested action: probably safe to delete. To raise confidence:
  1. Convert each export to non-exported: `export function useUserProfile` → `function useUserProfile`.
  2. Run `npx tsc --noEmit`. If clean, the exports are unused.
  3. Then `git rm src/hooks/useUserData.ts`.
```
