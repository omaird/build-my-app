---
name: run-pipeline
description: "Run the complete dua processing pipeline - research, validate, populate, curate, and integrate into journeys"
args:
  - name: dua
    description: "Dua topic, title, or partial data to process"
    required: true
---

# Dua Pipeline Command

You are running the complete dua processing pipeline. This command orchestrates all agents to fully process a dua from research through journey integration.

## Pipeline Initialization

1. Read the user's dua input from the command arguments
2. Create/update state file at `.claude/plugins/dua-library/pipeline-state.yml`
3. Begin the pipeline stages in sequence

## Pipeline Stages

Execute each stage in order, updating state after each:

### Stage 1: Research

Spawn the `dua-researcher` agent with the task:
```
Research and find complete, authentic information for this dua: [user input]

Required output:
- Full Arabic text with diacritics
- Transliteration following standard conventions
- Clear English translation
- Verified source (hadith collection and number, or Quran reference)
- Hadith grade (Sahih/Hasan)
- When to recite
- Recommended repetitions
- Prophetic context
- Rizq benefit (if applicable)
```

**Success criteria:** Complete dua data with verified source

### Stage 2: Validate

Spawn the `content-validator` agent with the task:
```
Validate this dua data for the RIZQ App:

[Insert research output]

Check:
1. Arabic text is valid Unicode
2. Transliteration follows standards
3. Translation is accurate
4. Source is verifiable online
5. No duplicate exists in Firestore
6. XP value is reasonable (15-100)
7. Category assignment is correct
```

**Success criteria:** All validation checks pass

### Stage 3: Populate

Spawn the `dua-populator` agent with the task:
```
Add this validated dua to Firebase Firestore:

[Insert validated dua data]

Steps:
1. Query Firestore to get next available ID
2. Format as Firestore document (camelCase)
3. Add to scripts/seed-firestore.cjs
4. Run: node scripts/seed-firestore.cjs
5. Verify the document was created
```

**Success criteria:** Dua exists in Firestore with assigned ID

### Stage 4: Curate

Spawn the `library-curator` agent with the task:
```
Analyze the library and provide recommendations for this new dua:

Dua ID: [new ID]
Title: [title]
Category: [category]

Analyze:
1. Current category distribution
2. Which journeys could include this dua
3. Recommended time slot
4. Whether to feature this dua
5. Any gap this dua fills
```

**Success criteria:** Clear journey recommendations

### Stage 5: Build Journey

Spawn the `journey-builder` agent with the task:
```
Integrate this dua into the recommended journeys:

Dua ID: [ID]
Title: [title]
Category: [category]
Recommended journeys: [from curation]
Recommended time slot: [slot]

Steps:
1. Add journey_duas entries to seed script
2. Update journey dailyXp totals
3. Run seed script
4. Verify assignments
```

**Success criteria:** Dua assigned to at least one journey

## State Management

Update `.claude/plugins/dua-library/pipeline-state.yml` after each stage:

```yaml
pipeline:
  status: in_progress
  current_stage: validate
  dua_title: "[title]"

  input:
    raw: "[user input]"

  stages:
    research:
      status: completed
      data:
        titleEn: "..."
        arabicText: "..."
        # ... all fields

    validate:
      status: in_progress
      checks:
        arabic: pending
        transliteration: pending
        source: pending
        duplicate: pending

    populate:
      status: pending
      dua_id: null

    curate:
      status: pending
      recommendations: []

    journey_build:
      status: pending
      assignments: []

  timestamps:
    started: "2026-01-12T10:30:00Z"
    updated: "2026-01-12T10:35:00Z"
```

## Progress Reporting

After each stage, report progress:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DUA PIPELINE: [Dua Title]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/5] ✅ Research    - Complete
[2/5] 🔄 Validate    - In Progress
[3/5] ⏳ Populate    - Pending
[4/5] ⏳ Curate      - Pending
[5/5] ⏳ Journey     - Pending

Current: Validating source reference...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Error Handling

If a stage fails:

1. Update state with error details
2. Report the failure clearly:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ PIPELINE PAUSED: Validation Failed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Issue: Could not verify hadith source
Details: "Tirmidhi 1234" not found in sunnah.com

Options:
1. Provide correct source reference
2. Skip validation and proceed anyway
3. Cancel pipeline

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

3. Ask user for resolution using AskUserQuestion

## Completion Report

When all stages complete successfully:

```
═══════════════════════════════════════════════════════════════
                    DUA PIPELINE COMPLETE
═══════════════════════════════════════════════════════════════

✅ RESEARCH
   Title: Dua for Opening Doors of Rizq
   Source: General Dua (Verified)

✅ VALIDATION
   All checks passed

✅ POPULATION
   Firestore ID: 11
   Category: Rizq (3)

✅ CURATION
   Recommended: Rizq Seeker, Morning Warrior

✅ JOURNEY INTEGRATION
   Added to: Rizq Seeker (morning, order 4)

═══════════════════════════════════════════════════════════════

View: https://console.firebase.google.com/project/rizq-app-c6468/firestore/data/duas/11

Next: Run /dua-pipeline with another dua, or /library-report to see updated stats
```

## Resume Support

If pipeline was interrupted, check state file and resume:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 RESUMING PIPELINE: [Dua Title]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Previous progress:
[1/5] ✅ Research    - Complete
[2/5] ✅ Validate    - Complete
[3/5] ❌ Populate    - Failed (interrupted)
[4/5] ⏳ Curate      - Pending
[5/5] ⏳ Curate      - Pending

Resuming from: Populate stage
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
