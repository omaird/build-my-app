---
name: library-sync
description: "Sync duas from the documentation (dua library.md) to the database"
---

# Library Sync Command

You are syncing the dua library from documentation to the database. This command reads `dua library.md` and identifies duas that need to be added.

## Step 1: Read Documentation

Read the dua library documentation:
```
Read: dua library.md
```

Parse the structured content to identify all documented duas.

## Step 2: Check Current Database

Query existing duas:
```sql
SELECT id, title_en, source FROM duas ORDER BY id;
```

## Step 3: Identify Gaps

Compare documentation against database:
- List duas in documentation but not in database
- List duas in database but not in documentation (orphans)
- Identify any discrepancies

Present a sync report:
```
📊 Library Sync Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Documentation: [X] duas documented
Database: [Y] duas stored
Gap: [Z] duas to sync

✅ Already Synced:
1. [Dua Title] (ID: [X])
2. [Dua Title] (ID: [X])
...

❌ Missing from Database:
1. [Dua Title] - [Category]
2. [Dua Title] - [Category]
...

⚠️ In Database but Not Documented:
1. [Dua Title] (ID: [X])
...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 4: User Selection

Use AskUserQuestion:
- Sync all missing duas at once?
- Select specific duas to sync?
- Review each dua before adding?

## Step 5: Batch Population

For each dua to sync:

1. Parse from documentation:
   - Title
   - Arabic text
   - Transliteration
   - Translation
   - Source
   - Category
   - Repetitions
   - Best time

2. Validate data completeness

3. Insert into database:
```sql
INSERT INTO duas (
  category_id,
  title_en,
  arabic_text,
  transliteration,
  translation_en,
  source,
  repetitions,
  best_time,
  difficulty,
  xp_value
) VALUES (...) RETURNING id, title_en;
```

## Step 6: Progress Tracking

Show progress during batch sync:
```
Syncing duas...

[1/10] ✅ Ayatul Kursi - Added (ID: 11)
[2/10] ✅ Morning Protection - Added (ID: 12)
[3/10] ⏭️ Sayyidul Istighfar - Already exists
[4/10] ❌ Dua for Provision - Missing Arabic text
...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Sync Complete!

Added: 8 duas
Skipped: 1 (already exists)
Failed: 1 (missing data)
```

## Step 7: Post-Sync Verification

```sql
-- Verify new count
SELECT COUNT(*) as total_duas FROM duas;

-- Show recently added
SELECT id, title_en, created_at
FROM duas
WHERE created_at > NOW() - INTERVAL '5 minutes'
ORDER BY id;
```

## Error Recovery

If a dua fails to sync:
1. Log the specific error
2. Continue with remaining duas
3. Report failures at the end
4. Suggest manual fixes for failed items

## Documentation Format Expected

The command expects duas in this format in `dua library.md`:
```
### [Number]. [Title]
**Arabic:** [Arabic text]
**Transliteration:** [Romanized text]
**Translation:** "[English meaning]"
**Source:** [Reference]
**When to Recite:** [Timing]
**Repetitions:** [Count]x
**Difficulty:** [Level]
**XP:** [Value]
**Rizq Benefit:** [Description]
```
