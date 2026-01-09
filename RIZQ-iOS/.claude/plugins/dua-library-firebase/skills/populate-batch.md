---
name: populate-batch-firebase
description: "Populate multiple duas from the dua library documentation into Firebase Firestore"
---

# Batch Populate Firebase Skill

This skill helps populate multiple duas from documentation into Firebase Firestore in a single batch operation.

## Source Documentation

The main dua library documentation is at:
`/Users/omairdawood/Projects/RIZQ App/dua library.md`

## Batch Operation Strategy

For large batch operations:
1. Parse duas from documentation
2. Validate all entries before inserting
3. Use Firestore batch writes (max 500 per batch)
4. Track progress and handle failures gracefully

## Documentation Format

Duas in the library doc follow this structure:

```markdown
### [Number]. [Title]
**Arabic:** [Arabic text]
**Transliteration:** [romanized]
**Translation:** [meaning]
**Source:** [reference]
**When to Recite:** [timing]
**Repetitions:** [count]
```

## Firestore Batch JSON Format

```json
// batch-duas.json
{
  "duas": [
    {
      "id": 11,
      "categoryId": 1,
      "titleEn": "Dua 1 Title",
      "arabicText": "Arabic text here",
      "transliteration": "Transliteration here",
      "translationEn": "Translation here",
      "source": "Sahih Muslim 123",
      "repetitions": 3,
      "bestTime": "After Fajr",
      "difficulty": "beginner",
      "xpValue": 20
    },
    {
      "id": 12,
      "categoryId": 2,
      "titleEn": "Dua 2 Title",
      "arabicText": "Arabic text here",
      "transliteration": "Transliteration here",
      "translationEn": "Translation here",
      "source": "Bukhari 456",
      "repetitions": 1,
      "difficulty": "intermediate",
      "xpValue": 25
    }
  ]
}
```

## Running Batch Script

```bash
cd /Users/omairdawood/Projects/RIZQ\ App && node scripts/batch-add-duas.cjs batch-duas.json
```

## Pre-Population Checks

Before batch populating:
1. **Query existing duas** to find the highest ID
2. **Check for duplicates** by title or Arabic text
3. **Validate Arabic text** contains Arabic Unicode
4. **Validate sources** follow proper format
5. **Calculate missing XP values**

## Category Mapping

| Slug | ID | Description |
|------|-----|-------------|
| morning | 1 | Morning adhkar, after Fajr duas |
| evening | 2 | Evening adhkar, after Maghrib duas |
| rizq | 3 | Provision, sustenance, wealth duas |
| gratitude | 4 | Thankfulness, contentment duas |

## Difficulty Assignment

| Criteria | Difficulty |
|----------|------------|
| Short (< 50 chars), 1-3 reps | beginner |
| Medium (50-150 chars) or 4-7 reps | intermediate |
| Long (> 150 chars) or 7+ reps | advanced |

## XP Calculation for Batch

```javascript
function calculateXp(dua) {
  let xp = 15; // base

  // Length bonus
  const arabicLen = dua.arabicText.length;
  if (arabicLen > 150) xp += 10;
  else if (arabicLen > 50) xp += 5;

  // Repetition bonus
  xp += Math.min((dua.repetitions - 1) * 5, 20);

  // Difficulty bonus
  if (dua.difficulty === 'intermediate') xp += 10;
  if (dua.difficulty === 'advanced') xp += 20;

  return Math.min(xp, 100);
}
```

## Error Handling

If a batch fails:
1. Identify which documents failed
2. Log the specific error
3. Retry individual documents if needed
4. Report final status with successes/failures

## Progress Tracking

For large batches, track:
- Total to process
- Successfully added
- Skipped (duplicates)
- Failed with errors

## Example Workflow

1. Read `dua library.md` and parse unpopulated duas
2. Check each dua against existing Firebase data
3. Prepare batch JSON with new duas only
4. Assign IDs starting from highest existing + 1
5. Run batch script
6. Verify all duas were added correctly
7. Generate summary report
