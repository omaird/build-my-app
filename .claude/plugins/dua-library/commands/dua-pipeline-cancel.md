---
name: dua-pipeline-cancel
description: "Cancel the current dua pipeline and reset state"
---

# Dua Pipeline Cancel Command

Cancel any running dua pipeline and reset the state.

## Process

1. Read the state file at `.claude/plugins/dua-library/pipeline-state.yml`
2. If pipeline exists, confirm cancellation with user
3. Reset state file to idle
4. Report cancellation

## Confirmation

Use AskUserQuestion to confirm:

```
Are you sure you want to cancel the pipeline for "[Dua Title]"?

Progress will be lost:
- Research: [status]
- Validate: [status]
- Populate: [status]
- Curate: [status]
- Journey: [status]
```

Options:
- Yes, cancel pipeline
- No, continue pipeline

## Output

### After Cancellation

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DUA PIPELINE CANCELLED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Pipeline for "[Dua Title]" has been cancelled.

Note: Any data already added to Firestore remains.
If you need to remove it, use the Firebase console.

To start a new pipeline:
/dua-pipeline "dua topic or title"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### If No Pipeline Running

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
NO PIPELINE TO CANCEL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

No pipeline is currently running.

To start a new pipeline:
/dua-pipeline "dua topic or title"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## State Reset

Reset the state file to:

```yaml
pipeline:
  status: idle
  current_stage: null
  dua_title: null

  stages:
    research:
      status: pending
    validate:
      status: pending
    populate:
      status: pending
    curate:
      status: pending
    journey_build:
      status: pending

  timestamps:
    cancelled: "2026-01-12T10:45:00Z"
```
