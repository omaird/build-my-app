---
name: library-sync
description: "Sync duas from the documentation (dua library.md) to Firebase Firestore"
---

# Library Sync Command

You are syncing the dua library from documentation to Firebase Firestore. This command reads `dua library.md` and identifies duas that need to be added.

## Step 1: Read Documentation

Read the dua library documentation:
```
Read: dua library.md
```

Parse the structured content to identify all documented duas.

## Step 2: Check Current Firestore Data

Query the `duas` collection to get all existing duas:
- List all documents
- Note their IDs and titleEn values

## Step 3: Identify Gaps

Compare documentation against Firestore:
- List duas in documentation but not in Firestore
- List duas in Firestore but not in documentation (orphans)
- Identify any discrepancies

Present a sync report:
```
📊 Library Sync Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Documentation: [X] duas documented
Firestore: [Y] duas stored
Gap: [Z] duas to sync

✅ Already Synced:
1. [Dua Title] (ID: [X])
2. [Dua Title] (ID: [X])
...

❌ Missing from Firestore:
1. [Dua Title] - [Category]
2. [Dua Title] - [Category]
...

⚠️ In Firestore but Not Documented:
1. [Dua Title] (ID: [X])
...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 4: User Selection

Use AskUserQuestion:
- Sync all missing duas at once?
- Select specific duas to sync?
- Review each dua before adding?

## Step 5: Prepare Firestore Documents

For each dua to sync:

1. Parse from documentation:
   - Title (titleEn)
   - Arabic text (arabicText)
   - Transliteration
   - Translation (translationEn)
   - Source
   - Category (categoryId)
   - Repetitions
   - Best time (bestTime)

2. Convert to Firestore schema (camelCase)

3. Add to seed script:

```javascript
// In scripts/seed-firestore.cjs
const duas = [
  // ... existing duas ...
  {
    id: [next ID],
    categoryId: [1-4],
    titleEn: "[Title]",
    arabicText: "[Arabic]",
    transliteration: "[Translit]",
    translationEn: "[Translation]",
    source: "[Source]",
    repetitions: [count],
    bestTime: "[timing]",
    difficulty: "[level]",
    estDurationSec: [seconds],
    rizqBenefit: "[benefit]",
    propheticContext: "[context]",
    xpValue: [value]
  }
];
```

## Step 6: Execute Sync

Run the seed script:
```bash
node scripts/seed-firestore.cjs
```

Show progress:
```
Syncing duas to Firestore...

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

Query Firestore to verify:
1. Total duas count
2. Recently added documents

Check the Firestore console:
https://console.firebase.google.com/project/rizq-app-c6468/firestore/data/duas

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

## Firestore Console

View synced data at:
https://console.firebase.google.com/project/rizq-app-c6468/firestore
