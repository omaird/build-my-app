---
description: Cancel active Ralph Wiggum loop
---

# Cancel Ralph Wiggum Loop

This cancels the active loop and preserves the current state.

## Action

1. Read `.claude/ralph-wiggum-state.yml`
2. Add `cancelled_at: [timestamp]` to state
3. Output summary of progress so far
4. Confirm loop is cancelled

## Output

```
## Ralph Wiggum Loop Cancelled

**Completed iterations:** [N]/12
**Improvements made:** [count]

State preserved in `.claude/ralph-wiggum-state.yml`

To resume later: `/ralph-wiggum:ralph-loop`
To start fresh: Delete state file, then run `/ralph-wiggum:ralph-loop`
```
