---
description: Execute a plan file with multi-persona iterative improvement on each feature
---

# Plan-Driven Ralph Loop

Execute a structured plan where each feature/task gets the full multi-persona treatment.

## How It Works

1. **You provide a plan file** (markdown with numbered features/tasks)
2. **Loop processes each feature** one at a time
3. **Each feature gets 6-persona review cycle** before moving to next
4. **Progress tracked** in state file

## Usage

```
/ralph-wiggum:plan-loop <plan-file-path> [--personas-per-feature 6] [--max-iterations 50]
```

## Plan File Format

Create a markdown file with this structure:

```markdown
# Plan: [Feature Name]

## Overview
Brief description of what we're building.

## Features

### 1. [Feature Name]
**Files:** list of files to create/modify
**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

### 2. [Feature Name]
**Files:** list of files
**Acceptance Criteria:**
- [ ] Criterion 1
```

## Execution Flow

```
┌─────────────────────────────────────────────────────────┐
│                    PLAN LOOP                            │
│                                                         │
│  ┌─────────────┐                                        │
│  │ Feature 1   │◄──────────────────────────────┐        │
│  └──────┬──────┘                               │        │
│         ▼                                      │        │
│  ┌─────────────────────────────────────────┐   │        │
│  │         PERSONA CYCLE (6 passes)        │   │        │
│  │  ┌──────────────┐  ┌──────────────────┐ │   │        │
│  │  │Code Reviewer │→ │System Architect  │ │   │        │
│  │  └──────────────┘  └────────┬─────────┘ │   │        │
│  │         ┌───────────────────┘           │   │        │
│  │         ▼                               │   │        │
│  │  ┌──────────────┐  ┌──────────────────┐ │   │        │
│  │  │Frontend      │→ │QA Engineer       │ │   │        │
│  │  │Designer      │  │                  │ │   │        │
│  │  └──────────────┘  └────────┬─────────┘ │   │        │
│  │         ┌───────────────────┘           │   │        │
│  │         ▼                               │   │        │
│  │  ┌──────────────┐  ┌──────────────────┐ │   │        │
│  │  │Project       │→ │Business Analyst  │ │   │ Repeat │
│  │  │Manager       │  │                  │ │   │ if     │
│  │  └──────────────┘  └────────┬─────────┘ │   │ needed │
│  └─────────────────────────────┼───────────┘   │        │
│                                ▼               │        │
│                    ┌───────────────────┐       │        │
│                    │ Acceptance Check  │───No──┘        │
│                    └─────────┬─────────┘                │
│                              │ Yes                      │
│                              ▼                          │
│                    ┌─────────────┐                      │
│                    │ Feature 2   │ → (repeat cycle)     │
│                    └─────────────┘                      │
└─────────────────────────────────────────────────────────┘
```

## State File Structure

State is tracked in `.claude/ralph-plan-state.yml`:

```yaml
plan_file: path/to/plan.md
current_feature: 2
current_persona: 3  # 0-5
total_features: 5
max_personas_per_feature: 6
started_at: 2024-01-15T10:00:00

features:
  - name: "User Authentication"
    status: completed
    iterations: 6

  - name: "Dashboard View"
    status: in_progress
    iterations: 3

  - name: "API Integration"
    status: pending

improvements:
  - feature: 1
    persona: Code Reviewer
    description: "Added error handling to auth flow"
```

---

## EXECUTION INSTRUCTIONS

When this skill is invoked:

### Phase 1: Parse Arguments

Extract from command args:
- `plan_file`: Path to the plan markdown file (REQUIRED)
- `personas_per_feature`: How many persona passes per feature (default: 6)
- `max_iterations`: Total iteration cap (default: 50)

### Phase 2: Initialize or Resume

**If no state file exists:**
1. Read and parse the plan file
2. Extract features (look for `### N.` pattern)
3. Create `.claude/ralph-plan-state.yml`
4. Start with feature 1, persona 0

**If state file exists:**
1. Read current state
2. Resume from `current_feature` and `current_persona`
3. Display: "Resuming plan: Feature N, Persona: [Name]"

### Phase 3: Execute Current Step

Based on `current_persona % 6`:

| Persona | Focus |
|---------|-------|
| 0 | **Code Reviewer**: Implement feature, check bugs/security/edge cases |
| 1 | **System Architect**: Review structure, dependencies, patterns |
| 2 | **Frontend Designer**: UI/UX, accessibility, animations |
| 3 | **QA Engineer**: Write tests, verify build |
| 4 | **Project Manager**: Check acceptance criteria, documentation |
| 5 | **Business Analyst**: User perspective, UX friction |

**Actions:**
1. Read the feature's target files
2. Apply persona-specific improvements
3. Verify build compiles
4. Update state file with improvement

### Phase 4: Check Completion

After each persona pass:

1. If `current_persona < personas_per_feature - 1`:
   - Increment `current_persona`
   - Continue to next persona

2. If `current_persona == personas_per_feature - 1`:
   - Check acceptance criteria for current feature
   - If ALL criteria met OR max personas reached:
     - Mark feature complete
     - Move to next feature (`current_feature++`, `current_persona = 0`)
   - If criteria NOT met:
     - Start another persona cycle (reset `current_persona = 0`)

3. If `current_feature > total_features`:
   - Output completion summary
   - Remove state file
   - **STOP LOOP**

### Phase 5: Output Status

After each iteration, output:

```
## Feature [N]/[Total]: [Feature Name]
**Persona:** [Name] ([M]/[personas_per_feature])
**Action:** [What was done]
**Files:** [Changed files]
**Build:** [SUCCEEDED/FAILED]

Continuing...
```

---

## Completion Criteria

The loop completes when:
1. All features processed through full persona cycle
2. Max iterations reached
3. User runs `/ralph-wiggum:cancel-ralph`

Output completion summary:
```
## Plan Complete!

**Features:** [N] completed
**Total Iterations:** [M]
**Time:** [duration]

### Summary by Feature:
1. [Feature] - [N] improvements
2. [Feature] - [N] improvements
...
```
