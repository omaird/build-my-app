# Plan: [Feature/Project Name]

## Overview

Brief description of what we're building and the goals.

## Target Files

List the main directories/files this plan affects:
- `path/to/feature/`
- `path/to/tests/`

---

## Features

### 1. [First Feature Name]

**Description:** What this feature does and why.

**Files:**
- `path/to/file1.swift` - Create/Modify
- `path/to/file2.swift` - Modify

**Acceptance Criteria:**
- [ ] Criterion 1 - specific, testable requirement
- [ ] Criterion 2 - specific, testable requirement
- [ ] Build compiles without errors
- [ ] Tests pass

---

### 2. [Second Feature Name]

**Description:** What this feature does and why.

**Files:**
- `path/to/file.swift`

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

---

### 3. [Third Feature Name]

**Description:** What this feature does and why.

**Files:**
- `path/to/file.swift`

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

---

## Notes

Any additional context, constraints, or considerations.

---

## Usage

To execute this plan with multi-persona review:

```
/ralph-wiggum:plan-loop .claude/plans/my-plan.md
```

Options:
- `--personas-per-feature 6` - Full 6-persona cycle per feature (default)
- `--personas-per-feature 3` - Quick 3-persona cycle (Code Reviewer, QA, PM)
- `--max-iterations 50` - Cap total iterations
