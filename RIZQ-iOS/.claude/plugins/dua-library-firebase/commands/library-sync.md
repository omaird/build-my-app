---
name: library-sync-firebase
description: "Sync duas from documentation to Firebase Firestore"
---

# Library Sync to Firebase Command

This command syncs duas from the `dua library.md` documentation file to Firebase Firestore.

## Overview

The sync process:
1. Reads the dua library documentation
2. Parses structured dua entries
3. Compares with existing Firebase data
4. Identifies new/updated duas
5. Syncs changes to Firestore

## Source File

Documentation location:
`/Users/omairdawood/Projects/RIZQ App/dua library.md`

## Step 1: Read Documentation

Read and parse the dua library documentation file.

## Step 2: Query Current Firebase State

Query Firebase to get:
- All existing duas (by ID and title)
- Current highest ID
- Category mappings

## Step 3: Parse Documentation Format

Expected format in documentation:

```markdown
### [Number]. [Title]
**Arabic:** [Arabic text]
**Transliteration:** [romanized]
**Translation:** [meaning]
**Source:** [reference]
**When to Recite:** [timing]
**Repetitions:** [count]
**Category:** [category name]
```

Alternative formats may include:
```markdown
## [Title]
- Arabic: [text]
- Source: [reference]
...
```

## Step 4: Identify Sync Actions

For each dua in documentation:
1. **NEW**: Not in Firebase → Add
2. **UNCHANGED**: Matches Firebase → Skip
3. **UPDATED**: Content differs → Update (with confirmation)

Display summary:
```
📚 Sync Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Documentation duas: XX
Firebase duas: XX

Actions:
  - New to add: X
  - Already synced: X
  - Updates needed: X

New Duas:
  1. [Title 1]
  2. [Title 2]
  ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Ask for confirmation before syncing.

## Step 5: Execute Sync

For each new dua:
1. Assign next available ID
2. Map category name to ID
3. Calculate XP value
4. Determine difficulty
5. Add to Firebase

```bash
# Create batch file
cat > /tmp/sync-batch.json << 'EOF'
{
  "duas": [
    { /* dua 1 */ },
    { /* dua 2 */ },
    ...
  ]
}
EOF

# Run batch sync
cd /Users/omairdawood/Projects/RIZQ\ App && node scripts/batch-add-duas.cjs /tmp/sync-batch.json
```

## Step 6: Report Results

```
✅ Sync Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Summary:
  - Added: X duas
  - Skipped: X (already synced)
  - Errors: X

New IDs assigned: [list]

Firebase collections updated:
  - duas: X new documents

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Category Mapping

When parsing, map category names to IDs:

| Name | Variations | ID |
|------|-----------|-----|
| Morning | morning, adhkar, fajr | 1 |
| Evening | evening, maghrib, night | 2 |
| Rizq | rizq, provision, sustenance, wealth | 3 |
| Gratitude | gratitude, thanks, shukr | 4 |

## Difficulty Assignment

Auto-assign based on content:
- **beginner**: Short text, 1-3 repetitions
- **intermediate**: Medium text or 4-7 repetitions
- **advanced**: Long text or 7+ repetitions

## XP Calculation

```javascript
function calculateXp(dua) {
  let xp = 15; // base

  // Length (Arabic text)
  if (dua.arabicText.length > 150) xp += 10;
  else if (dua.arabicText.length > 50) xp += 5;

  // Repetitions
  xp += Math.min((dua.repetitions - 1) * 5, 20);

  // Difficulty
  if (dua.difficulty === 'intermediate') xp += 10;
  if (dua.difficulty === 'advanced') xp += 20;

  return Math.min(xp, 100);
}
```

## Error Handling

- **Parse errors**: Skip malformed entries, report which ones
- **Duplicate titles**: Ask user to resolve
- **Missing Arabic**: Flag as incomplete
- **Firebase errors**: Retry or report

## Incremental Sync

For subsequent syncs:
- Only process new documentation entries
- Track "last synced" position if needed
- Report differences since last sync

## Manual Review Triggers

Require manual review when:
- Source is "unknown" or generic
- Arabic text is missing
- Category cannot be determined
- Duplicate title detected
