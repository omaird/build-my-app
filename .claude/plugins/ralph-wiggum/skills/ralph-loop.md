---
description: Start Ralph Wiggum loop in current session
argument-hint: [target] (home|adkhar|journeys|library|practice)
---

# Ralph Wiggum Loop: iOS Feature Improvement

A multi-persona iterative loop that systematically improves code quality by rotating through 6 specialized perspectives. Each persona makes ONE focused improvement per iteration.

## Usage

```
/ralph-wiggum:ralph-loop [target]
```

**Targets:**
- `home` - Home page (default)
- `adkhar` - Daily Adkhar / habits tab
- `journeys` - Journeys feature
- `library` - Dua library
- `practice` - Practice feature

## Target Configuration

Parse `$ARGUMENTS` to determine target. If empty or invalid, default to `home`.

### Target: `home`
**Files:**
- `RIZQ-iOS/RIZQ/Features/Home/HomeFeature.swift`
- `RIZQ-iOS/RIZQ/Features/Home/HomeView.swift`
- `RIZQ-iOS/RIZQ/Views/Components/HomeViews/`

**PM Checklist:** greeting, streak, XP, level, today's progress, navigation CTAs

---

### Target: `adkhar`
**Files:**
- `RIZQ-iOS/RIZQ/Features/Adkhar/AdkharFeature.swift`
- `RIZQ-iOS/RIZQ/Features/Adkhar/AdkharView.swift`
- `RIZQ-iOS/RIZQ/Views/Components/HabitViews/`

**PM Checklist:** time slot grouping (morning/anytime/evening), inline completion, progress tracking, quick practice

---

### Target: `journeys`
**Files:**
- `RIZQ-iOS/RIZQ/Features/Journeys/JourneysFeature.swift`
- `RIZQ-iOS/RIZQ/Features/Journeys/JourneysView.swift`
- `RIZQ-iOS/RIZQ/Features/Journeys/JourneyDetailFeature.swift`
- `RIZQ-iOS/RIZQ/Features/Journeys/JourneyDetailView.swift`
- `RIZQ-iOS/RIZQ/Views/Components/JourneyViews/`

**PM Checklist:** journey cards, subscription flow, progress display, dua list within journey

---

### Target: `library`
**Files:**
- `RIZQ-iOS/RIZQ/Features/Library/LibraryFeature.swift`
- `RIZQ-iOS/RIZQ/Features/Library/LibraryView.swift`
- `RIZQ-iOS/RIZQ/Views/Components/DuaViews/`

**PM Checklist:** search, filter by category, dua cards, navigation to practice

---

### Target: `practice`
**Files:**
- `RIZQ-iOS/RIZQ/Features/Practice/PracticeFeature.swift`
- `RIZQ-iOS/RIZQ/Features/Practice/PracticeView.swift`
- `RIZQ-iOS/RIZQ/Views/Components/Animations/`

**PM Checklist:** Arabic text display, transliteration, translation, repetition counter, completion celebration

---

## Loop Configuration

- **Max iterations:** 12 (2 full persona cycles)
- **State file:** `.claude/ralph-wiggum-state.yml`
- **Human escalation:** After 2 failed attempts on same issue

---

## PHASE 1: INITIALIZATION

On first run (no state file exists):

1. Parse `$ARGUMENTS` to get target (default: `home`)
2. Create `.claude/ralph-wiggum-state.yml`:
   ```yaml
   target: [target-name]
   iteration: 0
   maxIterations: 12
   deferred_issues: []
   completed_improvements: []
   started_at: [timestamp]
   target_files:
     - [list from target config]
   ```

3. Read all target files to build context
4. Proceed to Phase 2

On subsequent runs:
1. Read existing state file
2. If `$ARGUMENTS` differs from saved target, warn user and ask to confirm reset or continue
3. If `iteration >= maxIterations`, output completion summary and stop
4. Proceed to Phase 2

---

## PHASE 2: ROTATING PERSONA REVIEW

Calculate current persona: `iteration % 6`

### [0] CODE REVIEWER
**Focus:** Bugs, security, edge cases, error handling, type safety

**Actions:**
- Check for force unwraps, unhandled optionals
- Review error handling in effects (`.run` blocks)
- Verify type safety (no type assumptions)
- Check edge cases (empty states, nil values, boundary conditions)
- Review guard clauses and early returns

**Must verify:**
- Run Xcode build to check for compiler errors
- No runtime crashes possible from nil handling

---

### [1] SYSTEM ARCHITECT
**Focus:** File structure, dependencies, separation of concerns

**Actions:**
- Review TCA feature structure (State/Action/Reducer pattern)
- Check dependency injection usage
- Verify separation between view and business logic
- Review data flow between parent/child features
- Check for circular dependencies

**Must verify:**
- Business logic NOT in SwiftUI views
- No direct Firestore calls from views
- Dependencies accessed only in reducer body

---

### [2] FRONTEND DESIGNER
**Focus:** UI/UX, accessibility, animations, visual polish

**Tools:** Use `/frontend-design` skill for guidance

**Actions:**
- Review spacing consistency (use RIZQSpacing tokens)
- Check color usage (use RIZQColors tokens)
- Verify accessibility (VoiceOver labels, contrast)
- Review animations (timing, easing, stagger)
- Check responsive layout (different screen sizes)

**Must verify:**
- All colors from design system
- Proper Dynamic Type support
- Animation durations feel natural

---

### [3] QA ENGINEER
**Focus:** Tests, build verification, code quality

**Actions:**
- Verify build compiles: `cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 17' build`
- Check for missing test coverage
- Review reducer test cases
- Verify snapshot tests exist for views
- Run SwiftLint if configured

**Must verify:**
- BUILD SUCCEEDED
- No compiler warnings in target files
- Test coverage for critical paths

---

### [4] PROJECT MANAGER
**Focus:** Acceptance criteria, requirements, documentation

**Actions:**
- Review against target-specific PM checklist (see Target Configuration above)
- Verify navigation to all expected destinations
- Check loading/empty/error states exist
- Review inline documentation

**Must verify:**
- All required features present
- User flows complete end-to-end
- No dead-end states

---

### [5] BUSINESS ANALYST
**Focus:** User perspective, flow logic, UX friction

**Actions:**
- Walk through user journey as new user
- Walk through as returning user with progress
- Identify friction points or confusion
- Check if gamification elements motivate
- Review copy/messaging clarity

**Must verify:**
- Value proposition clear
- Next action obvious to user
- Progress feels rewarding

---

## PHASE 3: EXECUTE ONE IMPROVEMENT

After persona review:

1. Identify the **single most important** issue for this persona
2. Implement the fix
3. Verify the fix (build, test if applicable)
4. Update state file:
   ```yaml
   completed_improvements:
     - iteration: [N]
       persona: "[Persona Name]"
       improvement: "[Brief description]"
       files_changed:
         - path/to/file.swift
   ```

---

## PHASE 4: PROBLEM TRACKING & ESCALATION

### Tracking Issues

If an issue is identified but cannot be fixed:

1. Add to `deferred_issues` in state file:
   ```yaml
   deferred_issues:
     - id: "issue-001"
       description: "Brief description"
       first_seen: [iteration]
       attempts: 1
       history:
         - iteration: [N]
           persona: "[Name]"
           action: "What was tried"
   ```

2. On subsequent encounters of same issue:
   - Increment `attempts`
   - Add to history

### Human Escalation (attempts >= 2)

When any issue reaches 2+ attempts, **STOP THE LOOP** and output:

```
## HUMAN REVIEW REQUIRED

The following issue(s) have persisted for 2+ iterations without resolution:

### Issue: [Description]
- **First seen:** Iteration [X] ([Persona])
- **Attempts:** [N]
- **What was tried:**
  - Iteration [X]: [action]
  - Iteration [Y]: [action]
- **Recommended approach:** [suggestion]

---

**ACTION REQUIRED:** Please provide guidance, then resume with:
`/ralph-wiggum:ralph-loop` (will continue from current state)

Or cancel the loop: `/ralph-wiggum:cancel-ralph`
```

---

## PHASE 5: ITERATION COMPLETE

After each iteration:

1. Increment `iteration` in state file
2. Check if `iteration >= maxIterations`:
   - YES: Output completion summary (see below)
   - NO: Output iteration summary, continue to next iteration

### Iteration Summary (end of each iteration)

```
## Iteration [N]/12 Complete ([target])

**Persona:** [Name]
**Improvement:** [Brief description]
**Files changed:** [list]

**Deferred issues:** [count]
**Next persona:** [Name]

Continuing to iteration [N+1]...
```

### Completion Summary (iteration 12)

```
## Ralph Wiggum Loop Complete ([target])

**Total iterations:** 12
**Improvements made:** [count]

### Summary by Persona:
- Code Reviewer: [count] improvements
- System Architect: [count] improvements
- Frontend Designer: [count] improvements
- QA Engineer: [count] improvements
- Project Manager: [count] improvements
- Business Analyst: [count] improvements

### Files Modified:
[list of unique files]

### Deferred Issues (require human review):
[list or "None"]

### Recommended Next Steps:
1. Review deferred issues if any
2. Run full test suite
3. Manual QA on device
4. Consider another cycle if needed: `/ralph-wiggum:ralph-loop [target]`
```

---

## Resume Behavior

When `/ralph-wiggum:ralph-loop` is called with existing state file:

1. Read current state
2. Display: "Resuming [target] from iteration [N], persona: [Name]"
3. Continue from where loop left off
4. Honor existing deferred_issues and history
