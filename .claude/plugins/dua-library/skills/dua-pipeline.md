---
name: dua-pipeline
description: "Complete dua processing pipeline - takes a dua through research, validation, population, and integration into journeys. Use this skill to fully process a new dua from start to finish."
---

# Dua Pipeline Skill

This skill runs a complete dua processing pipeline, taking a dua from initial concept through research, validation, database population, and journey integration.

## Pipeline Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     DUA PIPELINE WORKFLOW                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. RESEARCH          2. VALIDATE           3. POPULATE          │
│  ┌──────────┐        ┌──────────┐         ┌──────────┐          │
│  │   Dua    │───────▶│ Content  │────────▶│   Dua    │          │
│  │Researcher│        │Validator │         │Populator │          │
│  └──────────┘        └──────────┘         └──────────┘          │
│       │                   │                    │                  │
│       ▼                   ▼                    ▼                  │
│  Research Report    Validation Report    Firestore Entry         │
│                                                                   │
│  4. CURATE             5. BUILD JOURNEY                          │
│  ┌──────────┐         ┌──────────┐                               │
│  │ Library  │────────▶│ Journey  │                               │
│  │ Curator  │         │ Builder  │                               │
│  └──────────┘         └──────────┘                               │
│       │                    │                                      │
│       ▼                    ▼                                      │
│  Gap Analysis        Journey Assignment                          │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Input Format

Provide dua information in one of these formats:

### Option 1: Dua Topic/Request
```
Process dua: "dua for seeking provision after waking"
```

### Option 2: Partial Dua Data
```
Process dua:
- Title: Dua for Morning Provision
- Arabic: اللَّهُمَّ إِنِّي أَسْأَلُكَ رِزْقًا طَيِّبًا
- Category: rizq
```

### Option 3: Complete Dua Data
```
Process dua:
- Title: Dua for Opening Doors of Rizq
- Arabic: اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رِزْقِكَ
- Transliteration: Allahumma iftah li abwaba rizqik
- Translation: O Allah, open for me the doors of Your provision
- Source: General Dua
- Repetitions: 3
- Best Time: Morning
```

## Pipeline Stages

### Stage 1: Research (dua-researcher agent)

**Purpose:** Find/verify authentic dua with complete information

**Input:** Dua topic or partial data
**Output:** Complete dua research report with:
- Full Arabic text with diacritics
- Accurate transliteration
- Clear translation
- Verified source (hadith reference with grade)
- Prophetic context
- Recommended timing and repetitions

**Skip if:** Complete, verified data already provided

### Stage 2: Validate (content-validator agent)

**Purpose:** Ensure data quality and authenticity

**Checks:**
- Arabic text is valid and complete
- Transliteration follows standards
- Translation is accurate
- Source is verifiable
- XP value is reasonable (15-100)
- No duplicate exists in Firestore

**Output:** Validation report with any issues found

**Action on failure:** Return to research stage or request user input

### Stage 3: Populate (dua-populator agent)

**Purpose:** Add dua to Firebase Firestore

**Process:**
1. Get next available ID from Firestore
2. Format data in camelCase schema
3. Add to `scripts/seed-firestore.cjs`
4. Run: `node scripts/seed-firestore.cjs`
5. Verify in Firestore console

**Output:** Confirmation with new dua ID

### Stage 4: Curate (library-curator agent)

**Purpose:** Analyze library and suggest placement

**Analysis:**
- Current category distribution
- Journey coverage gaps
- Recommended journey assignments
- Priority for featuring

**Output:** Curation recommendations

### Stage 5: Build Journey (journey-builder agent)

**Purpose:** Integrate dua into appropriate journeys

**Process:**
1. Identify suitable journeys based on category/theme
2. Determine time slot (morning/anytime/evening)
3. Set sort order
4. Add journey_duas entries
5. Update journey dailyXp totals

**Output:** Journey assignment confirmation

## State File

Pipeline state is tracked in `.claude/plugins/dua-library/pipeline-state.yml`:

```yaml
pipeline:
  status: in_progress  # idle, in_progress, completed, failed
  current_stage: validate
  dua_title: "Dua for Morning Provision"

  stages:
    research:
      status: completed
      output: "Full research report..."

    validate:
      status: in_progress
      issues: []

    populate:
      status: pending
      dua_id: null

    curate:
      status: pending
      recommendations: []

    journey_build:
      status: pending
      assignments: []

  created_at: "2026-01-12T10:30:00Z"
  updated_at: "2026-01-12T10:35:00Z"
```

## Pipeline Commands

### Start Pipeline
```
/dua-pipeline "dua for seeking provision"
```

### Check Status
```
/dua-pipeline-status
```

### Resume Pipeline
```
/dua-pipeline-resume
```

### Cancel Pipeline
```
/dua-pipeline-cancel
```

## Success Criteria

Pipeline is complete when:
- [ ] Dua has verified, authentic source
- [ ] All required fields populated
- [ ] Dua exists in Firestore
- [ ] Dua assigned to at least one journey
- [ ] XP values and journey totals updated

## Output Report

```
═══════════════════════════════════════════════════════════════
                    DUA PIPELINE COMPLETE
═══════════════════════════════════════════════════════════════

✅ RESEARCH
   Title: Dua for Opening Doors of Rizq
   Source: General Dua (Verified)
   Grade: Acceptable

✅ VALIDATION
   Arabic: Valid ✓
   Transliteration: Valid ✓
   Translation: Valid ✓
   No duplicates found ✓

✅ POPULATION
   Firestore ID: 11
   Collection: duas
   Category: Rizq (3)

✅ CURATION
   Recommendations:
   - Add to "Rizq Seeker" journey
   - Consider for "Morning Warrior" journey
   - Feature in morning time slot

✅ JOURNEY INTEGRATION
   Assigned to:
   - Rizq Seeker (morning slot, order 4)
   Journey XP updated: 270 → 295

═══════════════════════════════════════════════════════════════
                     ALL STAGES COMPLETE
═══════════════════════════════════════════════════════════════

View in Firestore:
https://console.firebase.google.com/project/rizq-app-c6468/firestore/data/duas/11
```

## Error Handling

If any stage fails:
1. Log the error with details
2. Update state file with failure status
3. Provide clear error message to user
4. Suggest resolution steps
5. Allow resume from failed stage

## Agents Used

| Stage | Agent | Purpose |
|-------|-------|---------|
| 1 | dua-researcher | Find/verify authentic dua |
| 2 | content-validator | Quality and authenticity checks |
| 3 | dua-populator | Add to Firestore |
| 4 | library-curator | Analyze and recommend |
| 5 | journey-builder | Integrate into journeys |

## Usage Examples

### Example 1: New Dua from Topic
```
User: Process a dua for relief from anxiety

Pipeline:
1. Research: Finds authentic anxiety relief duas from hadith
2. Validate: Verifies source and content
3. Populate: Adds to Firestore as ID 11
4. Curate: Recommends adding to "Anxiety to Tranquility" journey
5. Build: Assigns to journey with anytime time slot
```

### Example 2: User-Provided Dua
```
User: Process this dua:
- Title: Dua Before Sleeping
- Arabic: بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا
- Source: Bukhari

Pipeline:
1. Research: Verifies Bukhari reference, completes missing fields
2. Validate: Confirms authenticity
3. Populate: Adds to Firestore
4. Curate: Suggests evening category
5. Build: Assigns to "Evening Peace" journey
```
