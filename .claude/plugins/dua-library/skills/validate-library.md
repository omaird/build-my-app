---
name: validate-library
description: "Validate the dua library in Firebase Firestore for completeness, authenticity, and data quality"
---

# Validate Library Skill

This skill runs comprehensive validation checks on the dua library in Firebase Firestore.

## Validation Categories

### 1. Completeness Checks

Query the `duas` collection and check each document for:
- Missing `arabicText` (required)
- Missing `transliteration` (required)
- Missing `translationEn` (required)
- Missing `source` (required)

Flag any documents with empty or null required fields.

### 2. Referential Integrity

**Invalid category references:**
- Query all duas
- Check that `categoryId` values are 1, 2, 3, or 4
- Flag any documents with invalid categoryId

**Orphan journey_duas:**
- Query `journey_duas` collection
- For each document, verify:
  - `journeyId` exists in `journeys` collection
  - `duaId` exists in `duas` collection
- Flag any orphaned references

### 3. XP Consistency

For each journey:
1. Get the journey's `dailyXp` value
2. Query `journey_duas` where `journeyId` matches
3. For each linked dua, get its `xpValue`
4. Sum all linked dua XP values
5. Compare sum to journey's `dailyXp`
6. Flag any mismatches

### 4. Duplicate Detection

**Exact title duplicates:**
- Query all duas
- Group by lowercase `titleEn`
- Flag any groups with count > 1

**Similar Arabic text:**
- Query all duas
- Compare `arabicText` values
- Flag exact matches (potential duplicates)

### 5. Difficulty Rating Check

For each dua:
- Measure `arabicText` length
- Check against difficulty rating:
  - `beginner`: Should be < 100 characters
  - `intermediate`: 100-300 characters
  - `advanced`: > 300 characters
- Flag potentially misrated duas

### 6. Orphan Duas

- Query all duas to get their IDs
- Query `journey_duas` to get all referenced `duaId` values
- Find duas not referenced in any journey
- Report orphan duas (not necessarily an error, but worth noting)

## Validation Report Format

```
╔═══════════════════════════════════════════════╗
║         LIBRARY VALIDATION REPORT             ║
╚═══════════════════════════════════════════════╝

📊 Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Duas:        [X]
Valid:             [X] ✅
Issues Found:      [X] ⚠️
Critical:          [X] ❌

🔍 Completeness
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Missing Arabic:    [X]
Missing Translit:  [X]
Missing Source:    [X]

🔗 Referential Integrity
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Invalid Categories: [X]
Orphan Links:       [X]

📈 XP Consistency
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Mismatched Journeys: [X]

🔄 Duplicates
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Duplicate Titles:  [X]
Duplicate Arabic:  [X]

📋 Detailed Issues
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[List each issue with ID and fix suggestion]
```

## Auto-Fix Options

Some issues can be auto-fixed by updating the seed script:
- Update journey `dailyXp` to match sum of linked duas
- Remove orphan `journey_duas` entries
- Suggest difficulty adjustments

## Firestore Console

View and verify data directly at:
https://console.firebase.google.com/project/rizq-app-c6468/firestore
