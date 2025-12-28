---
name: populate-batch
description: "Populate multiple duas from the dua library documentation into the database"
---

# Batch Populate Skill

This skill handles bulk insertion of duas from `dua library.md` into the database.

## Workflow

1. **Read documentation** - Parse `dua library.md`
2. **Identify target duas** - Find documented but not-yet-inserted duas
3. **Validate each** - Ensure required fields present
4. **Batch insert** - Use transaction for atomicity
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

## Parsing Logic

```javascript
// Regex patterns for extraction
const patterns = {
  title: /### \d+\. (.+)/,
  arabic: /\*\*Arabic:\*\* (.+)/,
  transliteration: /\*\*Transliteration:\*\* (.+)/,
  translation: /\*\*Translation:\*\* "(.+)"/,
  source: /\*\*Source:\*\* (.+)/,
  bestTime: /\*\*When to Recite:\*\* (.+)/,
  repetitions: /\*\*Repetitions:\*\* (\d+)x/,
  difficulty: /\*\*Difficulty:\*\* (beginner|intermediate|advanced)/,
  xp: /\*\*XP:\*\* (\d+)/,
  rizqBenefit: /\*\*Rizq Benefit:\*\* (.+)/
};
```

## Category Mapping

Map documented categories to IDs:
```sql
SELECT id, slug FROM categories;
-- morning → 1
-- evening → 2
-- rizq → 3
-- gratitude → 4
```

## Batch Insert SQL

```sql
BEGIN;

INSERT INTO duas (category_id, title_en, arabic_text, transliteration, translation_en, source, repetitions, best_time, difficulty, xp_value, rizq_benefit)
VALUES
  (3, 'Dua 1 Title', 'Arabic 1', 'Translit 1', 'Translation 1', 'Source 1', 1, 'After Fajr', 'beginner', 25, 'Benefit 1'),
  (3, 'Dua 2 Title', 'Arabic 2', 'Translit 2', 'Translation 2', 'Source 2', 3, 'Anytime', 'intermediate', 35, 'Benefit 2'),
  (1, 'Dua 3 Title', 'Arabic 3', 'Translit 3', 'Translation 3', 'Source 3', 1, 'Morning', 'beginner', 20, 'Benefit 3');

COMMIT;
```

## Duplicate Prevention

Before inserting, check for existing:
```sql
SELECT title_en FROM duas
WHERE title_en IN ('Dua 1', 'Dua 2', 'Dua 3');
```

Skip any that already exist.

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

## Rollback on Error

If critical error occurs:
```sql
ROLLBACK;
-- Report which dua caused the issue
-- Allow retry after fixing
```
