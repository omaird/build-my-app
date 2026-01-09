---
name: validate-library-firebase
description: "Validate the dua library in Firebase for completeness, authenticity, and data quality"
---

# Validate Firebase Library Skill

This skill validates the dua library in Firebase Firestore for completeness, authenticity, and data quality.

## Validation Categories

### 1. Data Completeness

Check that all required fields are present:

| Field | Required | Validation |
|-------|----------|------------|
| id | ✅ | Must be unique integer |
| titleEn | ✅ | Non-empty string |
| arabicText | ✅ | Contains Arabic Unicode characters |
| translationEn | ✅ | Non-empty string |
| transliteration | ✅ | Non-empty string |
| source | ✅ | Valid hadith or Quran reference |
| categoryId | ✅ | Must be 1, 2, 3, or 4 |

### 2. Data Quality

| Check | Rule |
|-------|------|
| Arabic text | Must contain Arabic Unicode (U+0600-U+06FF) |
| Source format | "[Collection] [Number]" or "Quran [S]:[A]" |
| XP range | Between 15-100 |
| Difficulty | One of: beginner, intermediate, advanced |
| Repetitions | Positive integer, typically 1-100 |

### 3. Consistency

| Check | Rule |
|-------|------|
| Category references | All categoryId values exist in categories collection |
| Journey references | All duaId values in journey_duas exist in duas |
| No orphaned journey_duas | All journeyId values exist in journeys |
| Unique IDs | No duplicate id values |
| Unique titles | No duplicate titleEn values |

### 4. Content Authenticity

| Check | Flag |
|-------|------|
| Source verification | Source should be traceable to authentic hadith |
| Arabic accuracy | Arabic text matches known authentic versions |
| Translation accuracy | Translation captures meaning appropriately |

## Running Validation

Use the Firebase MCP tools to query and validate:

```
1. Fetch all duas from Firebase
2. Fetch all categories
3. Fetch all journeys
4. Fetch all journey_duas
5. Run validation checks
6. Generate report
```

## Validation Report Format

```markdown
# RIZQ Firebase Library Validation Report

Generated: [timestamp]

## Summary
- Total Duas: X
- Valid: X
- Issues Found: X

## Completeness
- [✓] All required fields present
- [✗] 2 duas missing transliteration

## Data Quality
- [✓] All Arabic text valid
- [✗] 1 dua has invalid XP value (105)

## Consistency
- [✓] All category references valid
- [✓] All journey references valid

## Issues

### Critical (must fix)
1. Dua ID 15: Missing arabicText
2. Journey ID 3: References non-existent dua ID 99

### Warnings (should review)
1. Dua ID 7: Source "Hadith" is too generic
2. Dua ID 12: XP value 105 exceeds maximum
```

## Automated Checks

### Arabic Text Validation
```javascript
function hasArabicText(text) {
  return /[\u0600-\u06FF]/.test(text);
}
```

### Source Format Validation
```javascript
function isValidSource(source) {
  // Hadith format: "Collection Name Number"
  const hadithPattern = /^[A-Za-z\s]+ \d+$/;
  // Quran format: "Quran S:A" or "Quran S:A-B"
  const quranPattern = /^Quran \d+:\d+(-\d+)?$/;
  // General "authentic" sources
  const generalPattern = /^(Authentic|General|Well-known)/i;

  return hadithPattern.test(source) ||
         quranPattern.test(source) ||
         generalPattern.test(source);
}
```

## Fix Workflows

### Missing Field
1. Identify the dua with missing field
2. Research the correct value
3. Update using admin script or Firebase console

### Invalid Reference
1. Identify the broken reference
2. Either add the missing document
3. Or update the reference to correct ID

### Duplicate ID
1. Identify conflicting documents
2. Decide which to keep
3. Update or delete the duplicate

## Scheduling

Recommend running validation:
- After any batch population
- Before deploying new app versions
- Weekly during active development
