---
name: add-dua
description: "Add a single dua to Firebase Firestore with all required fields (Arabic text, transliteration, translation, source, etc.)"
---

# Add Dua Skill

This skill helps add a single dua to the RIZQ App Firebase Firestore database.

## Required Information

To add a dua, you need:

| Field | Required | Description |
|-------|----------|-------------|
| titleEn | Yes | English title |
| arabicText | Yes | Full Arabic script |
| transliteration | Yes | Romanized Arabic |
| translationEn | Yes | English meaning |
| source | Yes | Hadith/Quran reference |
| categoryId | Yes | Category (1=morning, 2=evening, 3=rizq, 4=gratitude) |
| titleAr | No | Arabic title |
| repetitions | No | Times to recite (default: 1) |
| bestTime | No | When to recite |
| difficulty | No | beginner/intermediate/advanced |
| xpValue | No | XP points (calculated if not provided) |
| rizqBenefit | No | Description of provision benefit |
| propheticContext | No | Historical context from Prophet (ﷺ) |

## Firestore Document Schema

```javascript
{
  id: number,              // Next available sequential ID
  categoryId: number,      // 1-4
  collectionId: number,    // Optional
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

## XP Calculation

If xpValue not provided, calculate:
- Base: 15 XP
- Medium length (50-150 chars): +5
- Long (>150 chars): +10
- Per repetition: +5 (max +20)
- Intermediate difficulty: +10
- Advanced difficulty: +20

## Adding to Firestore

Since Firebase MCP tools are read-only for content collections, add duas via the seed script:

### Step 1: Get Next Available ID

Query existing duas to find the highest ID and add 1.

### Step 2: Add to Seed Script

Edit `scripts/seed-firestore.cjs` and add the new dua to the `duas` array:

```javascript
const duas = [
  // ... existing duas ...
  {
    id: 11,  // Next available ID
    categoryId: 3,
    collectionId: 1,
    titleEn: "Dua for Barakah in Work",
    titleAr: "دعاء البركة في العمل",
    arabicText: "اللَّهُمَّ بَارِكْ لِي فِي عَمَلِي",
    transliteration: "Allahumma barik li fi 'amali",
    translationEn: "O Allah, bless me in my work",
    source: "General Dua",
    repetitions: 1,
    bestTime: "Before starting work",
    difficulty: "beginner",
    estDurationSec: 10,
    rizqBenefit: "Invites divine blessing into your daily work and efforts",
    propheticContext: "Seeking barakah is encouraged in all endeavors",
    xpValue: 20
  }
];
```

### Step 3: Run the Seed Script

```bash
node scripts/seed-firestore.cjs
```

### Step 4: Verify in Firestore Console

Check the document was created at:
https://console.firebase.google.com/project/rizq-app-c6468/firestore/data/duas

## Validation Checklist

Before inserting:
- [ ] Arabic text contains Arabic Unicode characters
- [ ] Source follows format: "[Collection] [Number]" or "Quran [S]:[A]"
- [ ] Category ID exists (1-4)
- [ ] No duplicate titleEn exists
- [ ] XP value is between 15-100

## Example: Complete Dua Entry

```javascript
{
  id: 11,
  categoryId: 3,
  collectionId: 1,
  titleEn: "Dua for Opening Doors of Rizq",
  titleAr: "دعاء فتح أبواب الرزق",
  arabicText: "اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رِزْقِكَ",
  transliteration: "Allahumma iftah li abwaba rizqik",
  translationEn: "O Allah, open for me the doors of Your provision",
  source: "General Dua",
  repetitions: 3,
  bestTime: "Morning, after Fajr",
  difficulty: "beginner",
  estDurationSec: 15,
  rizqBenefit: "Asking Allah to open multiple avenues of sustenance",
  propheticContext: "The Prophet (ﷺ) encouraged asking Allah for provision from His vast treasures",
  xpValue: 25
}
```

## Field Naming Convention

Firestore uses **camelCase** (not snake_case):
- `titleEn` not `title_en`
- `categoryId` not `category_id`
- `arabicText` not `arabic_text`
- `translationEn` not `translation_en`
- `xpValue` not `xp_value`
