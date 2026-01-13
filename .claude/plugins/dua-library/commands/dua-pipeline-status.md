---
name: dua-pipeline-status
description: "Check the status of the current dua pipeline"
---

# Dua Pipeline Status Command

Check the current status of any running dua pipeline.

## Process

1. Read the state file at `.claude/plugins/dua-library/pipeline-state.yml`
2. Display current pipeline status

## Output Format

### If Pipeline is Running

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DUA PIPELINE STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Dua: [Title]
Status: In Progress
Current Stage: [Stage Name]

Progress:
[1/5] ✅ Research    - Complete
[2/5] 🔄 Validate    - In Progress
[3/5] ⏳ Populate    - Pending
[4/5] ⏳ Curate      - Pending
[5/5] ⏳ Journey     - Pending

Started: [timestamp]
Last Update: [timestamp]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Commands:
- /dua-pipeline-resume  - Continue the pipeline
- /dua-pipeline-cancel  - Cancel and reset
```

### If Pipeline is Paused (Error)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DUA PIPELINE STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Dua: [Title]
Status: ⚠️ Paused (Error)
Error Stage: [Stage Name]

Progress:
[1/5] ✅ Research    - Complete
[2/5] ❌ Validate    - Failed
[3/5] ⏳ Populate    - Pending
[4/5] ⏳ Curate      - Pending
[5/5] ⏳ Journey     - Pending

Error Details:
[Error message and details]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

To fix:
1. [Suggested fix]
2. Run /dua-pipeline-resume to retry
```

### If No Pipeline Running

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DUA PIPELINE STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status: Idle

No pipeline currently running.

To start a new pipeline:
/dua-pipeline "dua topic or title"

Examples:
- /dua-pipeline "dua for seeking provision"
- /dua-pipeline "morning protection dua"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### If Pipeline Completed

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DUA PIPELINE STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Last Pipeline: ✅ Complete

Dua: [Title]
Firestore ID: [ID]
Journey: [Journey Name]

Completed: [timestamp]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

To start a new pipeline:
/dua-pipeline "dua topic or title"
```
