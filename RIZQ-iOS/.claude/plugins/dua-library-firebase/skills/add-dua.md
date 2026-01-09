---
name: add-dua-firebase
description: "Add a single dua to Firebase Firestore with all required fields (Arabic text, transliteration, translation, source, etc.)"
---

# Add Dua to Firebase Skill

This skill helps add a single dua to the RIZQ App Firebase Firestore database.

## Firestore Collection

Collection: `duas`

## Required Information

To add a dua, you need:

| Field | Required | Firestore Key | Description |
|-------|----------|---------------|-------------|
| id | ✅ | `id` | Unique integer ID (auto-increment from highest existing) |
| titleEn | ✅ | `titleEn` | English title |
| arabicText | ✅ | `arabicText` | Full Arabic script |
| translationEn | ✅ | `translationEn` | English meaning |
| transliteration | ✅ | `transliteration` | Romanized Arabic |
| source | ✅ | `source` | Hadith/Quran reference |
| categoryId | ✅ | `categoryId` | Category (1=morning, 2=evening, 3=rizq, 4=gratitude) |
| titleAr | ❌ | `titleAr` | Arabic title |
| repetitions | ❌ | `repetitions` | Times to recite (default: 1) |
| bestTime | ❌ | `bestTime` | When to recite |
| difficulty | ❌ | `difficulty` | beginner/intermediate/advanced |
| xpValue | ❌ | `xpValue` | XP points (calculated if not provided) |
| rizqBenefit | ❌ | `rizqBenefit` | Description of provision benefit |
| propheticContext | ❌ | `propheticContext` | Hadith or sunnah context for the dua |
| estDurationSec | ❌ | `estDurationSec` | Estimated time to recite in seconds |
| collectionId | ❌ | `collectionId` | Content collection ID |

## XP Calculation

If xpValue not provided, calculate:
- Base: 15 XP
- Medium length (50-150 chars): +5
- Long (>150 chars): +10
- Per repetition: +5 (max +20)
- Intermediate difficulty: +10
- Advanced difficulty: +20

## Adding via Firebase Admin Script

Create a temporary JSON file and run the admin script:

```json
// dua-to-add.json
{
  "id": 11,
  "categoryId": 3,
  "titleEn": "Dua for Barakah in Work",
  "titleAr": "دعاء البركة في العمل",
  "arabicText": "اللَّهُمَّ بَارِكْ لِي فِي عَمَلِي",
  "transliteration": "Allahumma barik li fi 'amali",
  "translationEn": "O Allah, bless me in my work",
  "source": "General Dua",
  "repetitions": 1,
  "bestTime": "Before starting work",
  "difficulty": "beginner",
  "xpValue": 20,
  "rizqBenefit": "Invites divine blessing into your daily work and efforts"
}
```

```bash
cd /Users/omairdawood/Projects/RIZQ\ App && node scripts/add-dua.cjs dua-to-add.json
```

## Validation Checklist

Before inserting:
- [ ] Arabic text contains Arabic Unicode characters
- [ ] Source follows format: "[Collection] [Number]" or "Quran [S]:[A]"
- [ ] Category ID exists (1-4)
- [ ] No duplicate id exists
- [ ] No duplicate titleEn exists
- [ ] XP value is between 15-100

## Verification After Adding

Use the Firebase MCP to verify:
```
Query the duas collection to verify the new document was created correctly.
```

## Example Workflow

1. Determine the next available ID by querying existing duas
2. Gather all required dua information
3. Calculate XP value if not provided
4. Create the dua JSON object
5. Add to Firestore using the admin script
6. Verify the insertion was successful
