---
name: populate-batch
description: "Populate multiple duas from the dua library documentation into Firebase Firestore"
---

# Batch Populate Skill

This skill handles bulk insertion of duas from `dua library.md` into Firebase Firestore.

## Workflow

1. **Read documentation** - Parse `dua library.md`
2. **Identify target duas** - Find documented but not-yet-inserted duas
3. **Validate each** - Ensure required fields present
4. **Batch insert** - Add to seed script and run
5. **Report results** - Show success/failure count

## Documentation Format

Expected format in `dua library.md`:

```markdown
### [N]. [Title]
**Arabic:** [Arabic text]
**Transliteration:** [Romanized]
**Translation:** "[English meaning]"
**Source:** [Reference]
**When to Recite:** [Timing]
**Repetitions:** [X]x
**Difficulty:** [Level]
**XP:** [Value]
**Rizq Benefit:** [Description]
```

## Firestore Schema (camelCase)

Each dua document in Firestore:
```javascript
{
  id: number,
  categoryId: number,
  titleEn: string,
  titleAr: string,
  arabicText: string,
  transliteration: string,
  translationEn: string,
  source: string,
  repetitions: number,
  bestTime: string,
  difficulty: string,
  estDurationSec: number,
  rizqBenefit: string,
  propheticContext: string,
  xpValue: number
}
```

## Category Mapping

Map documented categories to IDs:
- morning → categoryId: 1
- evening → categoryId: 2
- rizq → categoryId: 3
- gratitude → categoryId: 4

## Batch Insert Process

### Step 1: Check Existing Duas

Query Firestore to get current duas and their IDs to avoid duplicates.

### Step 2: Parse Documentation

Extract dua information from `dua library.md` and convert to Firestore format:
- Map field names to camelCase
- Calculate XP if not specified
- Assign sequential IDs

### Step 3: Add to Seed Script

Edit `scripts/seed-firestore.cjs`:

```javascript
const duas = [
  // ... existing duas ...
  {
    id: 11,
    categoryId: 3,
    titleEn: "Dua 1 Title",
    arabicText: "Arabic 1",
    transliteration: "Translit 1",
    translationEn: "Translation 1",
    source: "Source 1",
    repetitions: 1,
    bestTime: "After Fajr",
    difficulty: "beginner",
    estDurationSec: 10,
    rizqBenefit: "Benefit 1",
    propheticContext: "Context 1",
    xpValue: 25
  },
  {
    id: 12,
    categoryId: 3,
    titleEn: "Dua 2 Title",
    // ... all fields
  },
  {
    id: 13,
    categoryId: 1,
    titleEn: "Dua 3 Title",
    // ... all fields
  }
];
```

### Step 4: Run Seed Script

```bash
node scripts/seed-firestore.cjs
```

## Duplicate Prevention

Before adding, check for existing duas by querying Firestore:
1. Get all duas from collection
2. Compare titleEn values (case-insensitive)
3. Skip any that already exist

## Progress Tracking

Report format:
```
Batch Population Report
━━━━━━━━━━━━━━━━━━━━━━━
Attempted: 10
Inserted:  8
Skipped:   1 (duplicate)
Failed:    1 (missing Arabic)

Details:
✅ Dua for Provision (ID: 11)
✅ Morning Protection (ID: 12)
⏭️ Ayatul Kursi - Already exists
❌ Dua for Success - Missing Arabic text
```

## Verification

After running the seed script, verify at:
https://console.firebase.google.com/project/rizq-app-c6468/firestore/data/duas

Query the collection to confirm:
- New documents exist
- All fields are populated correctly
- IDs are sequential and unique

## Error Handling

If a dua fails validation:
1. Log the specific error
2. Skip that dua
3. Continue with remaining duas
4. Report failures at the end
5. Suggest manual fixes for failed items

## Field Name Conversion

When parsing documentation (snake_case) to Firestore (camelCase):

| Documentation | Firestore |
|---------------|-----------|
| title_en | titleEn |
| title_ar | titleAr |
| arabic_text | arabicText |
| translation_en | translationEn |
| category_id | categoryId |
| collection_id | collectionId |
| xp_value | xpValue |
| best_time | bestTime |
| rizq_benefit | rizqBenefit |
| prophetic_context | propheticContext |
| est_duration_sec | estDurationSec |
