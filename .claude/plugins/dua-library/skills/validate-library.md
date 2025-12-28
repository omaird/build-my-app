---
name: validate-library
description: "Validate the dua library for completeness, authenticity, and data quality"
---

# Validate Library Skill

This skill runs comprehensive validation checks on the dua library.

## Validation Categories

### 1. Completeness Checks

```sql
-- Duas with missing required fields
SELECT
  id,
  title_en,
  CASE WHEN arabic_text IS NULL OR arabic_text = '' THEN '❌ Arabic' END,
  CASE WHEN transliteration IS NULL OR transliteration = '' THEN '❌ Translit' END,
  CASE WHEN translation_en IS NULL OR translation_en = '' THEN '❌ Translation' END,
  CASE WHEN source IS NULL OR source = '' THEN '❌ Source' END
FROM duas
WHERE
  arabic_text IS NULL OR arabic_text = '' OR
  transliteration IS NULL OR transliteration = '' OR
  translation_en IS NULL OR translation_en = '' OR
  source IS NULL OR source = '';
```

### 2. Referential Integrity

```sql
-- Invalid category references
SELECT d.id, d.title_en, d.category_id
FROM duas d
LEFT JOIN categories c ON d.category_id = c.id
WHERE c.id IS NULL;

-- Orphan journey_duas
SELECT jd.*
FROM journey_duas jd
LEFT JOIN journeys j ON jd.journey_id = j.id
LEFT JOIN duas d ON jd.dua_id = d.id
WHERE j.id IS NULL OR d.id IS NULL;
```

### 3. XP Consistency

```sql
-- Journey XP mismatch
SELECT
  j.name,
  j.daily_xp as stated,
  SUM(d.xp_value) as actual,
  j.daily_xp - SUM(d.xp_value) as diff
FROM journeys j
JOIN journey_duas jd ON j.id = jd.journey_id
JOIN duas d ON jd.dua_id = d.id
GROUP BY j.id
HAVING j.daily_xp != SUM(d.xp_value);
```

### 4. Duplicate Detection

```sql
-- Exact duplicates
SELECT title_en, COUNT(*) as count
FROM duas
GROUP BY LOWER(title_en)
HAVING COUNT(*) > 1;

-- Similar Arabic text
SELECT d1.id, d1.title_en, d2.id, d2.title_en
FROM duas d1
JOIN duas d2 ON d1.id < d2.id
WHERE d1.arabic_text = d2.arabic_text;
```

### 5. Difficulty Rating Check

```sql
-- Potentially misrated duas
SELECT
  id, title_en, difficulty,
  LENGTH(arabic_text) as length,
  CASE
    WHEN LENGTH(arabic_text) < 50 AND difficulty != 'beginner'
      THEN 'Too short for ' || difficulty
    WHEN LENGTH(arabic_text) > 200 AND difficulty = 'beginner'
      THEN 'Too long for beginner'
    ELSE 'OK'
  END as assessment
FROM duas
WHERE
  (LENGTH(arabic_text) < 50 AND difficulty != 'beginner') OR
  (LENGTH(arabic_text) > 200 AND difficulty = 'beginner');
```

### 6. Orphan Duas

```sql
-- Duas not in any journey
SELECT d.id, d.title_en
FROM duas d
LEFT JOIN journey_duas jd ON d.id = jd.dua_id
WHERE jd.id IS NULL;
```

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

Some issues can be auto-fixed:
- Update journey daily_xp to match sum
- Remove orphan journey_duas entries
- Suggest difficulty adjustments
